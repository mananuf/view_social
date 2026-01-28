use axum::{
    extract::{
        ws::{Message, WebSocket, WebSocketUpgrade},
        State,
    },
    response::IntoResponse,
};
use futures::{sink::SinkExt, stream::StreamExt};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::{mpsc, RwLock};
use uuid::Uuid;

/// WebSocket event types that can be sent to clients
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum WebSocketEvent {
    MessageSent {
        conversation_id: Uuid,
        message_id: Uuid,
        sender_id: Uuid,
        content: String,
    },
    MessageRead {
        message_id: Uuid,
        user_id: Uuid,
    },
    TypingStarted {
        conversation_id: Uuid,
        user_id: Uuid,
    },
    TypingStopped {
        conversation_id: Uuid,
        user_id: Uuid,
    },
    PaymentReceived {
        transaction_id: Uuid,
        amount: String,
        sender_id: Uuid,
    },
    PostLiked {
        post_id: Uuid,
        user_id: Uuid,
    },
    UserOnline {
        user_id: Uuid,
    },
    UserOffline {
        user_id: Uuid,
    },
    Error {
        message: String,
    },
}

/// Represents a connected WebSocket client
#[derive(Debug)]
struct Connection {
    user_id: Uuid,
    sender: mpsc::UnboundedSender<WebSocketEvent>,
}

/// Manages all WebSocket connections and user presence
/// 
/// The ConnectionManager provides:
/// - Connection lifecycle management (register/unregister)
/// - User presence tracking (online/offline status)
/// - Automatic cleanup of stale connections
/// - Broadcasting events to users and all connections
/// 
/// # Requirements
/// - Implements Requirements 4.1 (real-time message delivery)
/// - Implements Requirements 4.2 (typing indicators and presence)
#[derive(Clone)]
pub struct ConnectionManager {
    /// Map of user_id to their active connections
    connections: Arc<RwLock<HashMap<Uuid, Vec<Connection>>>>,
    /// Map of user_id to their online status
    presence: Arc<RwLock<HashMap<Uuid, bool>>>,
}

impl ConnectionManager {
    /// Create a new connection manager
    pub fn new() -> Self {
        Self {
            connections: Arc::new(RwLock::new(HashMap::new())),
            presence: Arc::new(RwLock::new(HashMap::new())),
        }
    }

    /// Register a new connection for a user
    pub async fn register_connection(
        &self,
        user_id: Uuid,
        sender: mpsc::UnboundedSender<WebSocketEvent>,
    ) {
        let connection = Connection { user_id, sender };

        let mut connections = self.connections.write().await;
        connections
            .entry(user_id)
            .or_insert_with(Vec::new)
            .push(connection);

        // Update presence status
        let mut presence = self.presence.write().await;
        let was_offline = !presence.get(&user_id).copied().unwrap_or(false);
        presence.insert(user_id, true);

        // If user was offline, broadcast online status
        if was_offline {
            drop(connections);
            drop(presence);
            self.broadcast_user_status(user_id, true).await;
        }

        tracing::info!("User {} connected via WebSocket", user_id);
    }

    /// Unregister a connection for a user
    pub async fn unregister_connection(&self, user_id: Uuid, connection_index: usize) {
        let mut connections = self.connections.write().await;

        if let Some(user_connections) = connections.get_mut(&user_id) {
            if connection_index < user_connections.len() {
                user_connections.remove(connection_index);

                // If no more connections, mark user as offline
                if user_connections.is_empty() {
                    connections.remove(&user_id);

                    let mut presence = self.presence.write().await;
                    presence.insert(user_id, false);

                    drop(connections);
                    drop(presence);

                    // Broadcast offline status
                    self.broadcast_user_status(user_id, false).await;

                    tracing::info!("User {} disconnected from WebSocket", user_id);
                }
            }
        }
    }

    /// Send an event to a specific user (all their connections)
    pub async fn send_to_user(&self, user_id: Uuid, event: WebSocketEvent) {
        let connections = self.connections.read().await;

        if let Some(user_connections) = connections.get(&user_id) {
            for connection in user_connections {
                if let Err(e) = connection.sender.send(event.clone()) {
                    tracing::error!(
                        "Failed to send event to user {}: {}",
                        user_id,
                        e
                    );
                }
            }
        }
    }

    /// Send an event to multiple users
    pub async fn send_to_users(&self, user_ids: &[Uuid], event: WebSocketEvent) {
        for user_id in user_ids {
            self.send_to_user(*user_id, event.clone()).await;
        }
    }

    /// Broadcast an event to all connected users
    pub async fn broadcast(&self, event: WebSocketEvent) {
        let connections = self.connections.read().await;

        for user_connections in connections.values() {
            for connection in user_connections {
                if let Err(e) = connection.sender.send(event.clone()) {
                    tracing::error!(
                        "Failed to broadcast event to user {}: {}",
                        connection.user_id,
                        e
                    );
                }
            }
        }
    }

    /// Check if a user is currently online
    pub async fn is_user_online(&self, user_id: Uuid) -> bool {
        let presence = self.presence.read().await;
        presence.get(&user_id).copied().unwrap_or(false)
    }

    /// Get all online users
    pub async fn get_online_users(&self) -> Vec<Uuid> {
        let presence = self.presence.read().await;
        presence
            .iter()
            .filter_map(|(user_id, is_online)| {
                if *is_online {
                    Some(*user_id)
                } else {
                    None
                }
            })
            .collect()
    }

    /// Get the number of active connections for a user
    pub async fn get_connection_count(&self, user_id: Uuid) -> usize {
        let connections = self.connections.read().await;
        connections
            .get(&user_id)
            .map(|conns| conns.len())
            .unwrap_or(0)
    }

    /// Get total number of active connections
    pub async fn get_total_connections(&self) -> usize {
        let connections = self.connections.read().await;
        connections.values().map(|conns| conns.len()).sum()
    }

    /// Broadcast user online/offline status
    async fn broadcast_user_status(&self, user_id: Uuid, is_online: bool) {
        let event = if is_online {
            WebSocketEvent::UserOnline { user_id }
        } else {
            WebSocketEvent::UserOffline { user_id }
        };

        self.broadcast(event).await;
    }

    /// Clean up stale connections (called periodically)
    pub async fn cleanup_stale_connections(&self) {
        let mut connections = self.connections.write().await;
        let mut users_to_remove = Vec::new();

        for (user_id, user_connections) in connections.iter_mut() {
            // Remove closed connections
            user_connections.retain(|conn| !conn.sender.is_closed());

            // Mark users with no connections for removal
            if user_connections.is_empty() {
                users_to_remove.push(*user_id);
            }
        }

        // Remove users with no connections
        for user_id in &users_to_remove {
            connections.remove(user_id);
        }

        // Update presence
        if !users_to_remove.is_empty() {
            let mut presence = self.presence.write().await;
            for user_id in &users_to_remove {
                presence.insert(*user_id, false);
            }
        }

        if !users_to_remove.is_empty() {
            tracing::info!(
                "Cleaned up {} stale connections",
                users_to_remove.len()
            );
        }
    }
}

impl Default for ConnectionManager {
    fn default() -> Self {
        Self::new()
    }
}

/// State for WebSocket handlers
#[derive(Clone)]
pub struct WebSocketState {
    pub connection_manager: ConnectionManager,
}

impl WebSocketState {
    pub fn new() -> Self {
        Self {
            connection_manager: ConnectionManager::new(),
        }
    }

    /// Start a background task to periodically clean up stale connections
    pub fn start_cleanup_task(&self) {
        let manager = self.connection_manager.clone();
        tokio::spawn(async move {
            let mut interval = tokio::time::interval(tokio::time::Duration::from_secs(60));
            loop {
                interval.tick().await;
                manager.cleanup_stale_connections().await;
            }
        });
    }
}

impl Default for WebSocketState {
    fn default() -> Self {
        Self::new()
    }
}

/// WebSocket upgrade handler
pub async fn ws_handler(
    ws: WebSocketUpgrade,
    State(state): State<WebSocketState>,
    axum::extract::Extension(user_id): axum::extract::Extension<Uuid>,
) -> impl IntoResponse {
    ws.on_upgrade(move |socket| handle_socket(socket, state, user_id))
}

/// Handle individual WebSocket connection
async fn handle_socket(socket: WebSocket, state: WebSocketState, user_id: Uuid) {
    // Split the socket into sender and receiver
    let (mut sender, mut receiver) = socket.split();

    // Create a channel for sending events to this connection
    let (tx, mut rx) = mpsc::unbounded_channel::<WebSocketEvent>();

    // Register the connection
    state
        .connection_manager
        .register_connection(user_id, tx)
        .await;

    // Get the connection index for cleanup
    let connection_index = state
        .connection_manager
        .get_connection_count(user_id)
        .await
        - 1;

    // Spawn a task to send events to the client
    let mut send_task = tokio::spawn(async move {
        while let Some(event) = rx.recv().await {
            // Serialize event to JSON
            if let Ok(json) = serde_json::to_string(&event) {
                if sender.send(Message::Text(json)).await.is_err() {
                    break;
                }
            }
        }
    });

    // Spawn a task to receive messages from the client
    let manager = state.connection_manager.clone();
    let mut recv_task = tokio::spawn(async move {
        while let Some(Ok(msg)) = receiver.next().await {
            match msg {
                Message::Text(text) => {
                    // Handle incoming text messages
                    tracing::debug!("Received text message from user {}: {}", user_id, text);
                    // TODO: Parse and handle client events
                }
                Message::Binary(_) => {
                    // Handle binary messages if needed
                    tracing::debug!("Received binary message from user {}", user_id);
                }
                Message::Ping(_) => {
                    // Respond to ping with pong
                    tracing::debug!("Received ping from user {}", user_id);
                    // The WebSocket implementation handles pong automatically
                }
                Message::Pong(_) => {
                    // Handle pong
                    tracing::debug!("Received pong from user {}", user_id);
                }
                Message::Close(_) => {
                    // Client closed the connection
                    tracing::info!("User {} closed WebSocket connection", user_id);
                    break;
                }
            }
        }

        // Unregister connection on disconnect
        manager.unregister_connection(user_id, connection_index).await;
    });

    // Wait for either task to finish
    tokio::select! {
        _ = &mut send_task => {
            recv_task.abort();
        }
        _ = &mut recv_task => {
            send_task.abort();
        }
    }

    tracing::info!("WebSocket connection closed for user {}", user_id);
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_connection_manager_register_and_unregister() {
        let manager = ConnectionManager::new();
        let user_id = Uuid::new_v4();
        let (tx, _rx) = mpsc::unbounded_channel();

        // Register connection
        manager.register_connection(user_id, tx).await;

        // Check user is online
        assert!(manager.is_user_online(user_id).await);
        assert_eq!(manager.get_connection_count(user_id).await, 1);

        // Unregister connection
        manager.unregister_connection(user_id, 0).await;

        // Check user is offline
        assert!(!manager.is_user_online(user_id).await);
        assert_eq!(manager.get_connection_count(user_id).await, 0);
    }

    #[tokio::test]
    async fn test_connection_manager_multiple_connections() {
        let manager = ConnectionManager::new();
        let user_id = Uuid::new_v4();

        // Register multiple connections for the same user
        let (tx1, _rx1) = mpsc::unbounded_channel();
        let (tx2, _rx2) = mpsc::unbounded_channel();

        manager.register_connection(user_id, tx1).await;
        manager.register_connection(user_id, tx2).await;

        // Check connection count
        assert_eq!(manager.get_connection_count(user_id).await, 2);
        assert!(manager.is_user_online(user_id).await);

        // Unregister one connection
        manager.unregister_connection(user_id, 0).await;

        // User should still be online with one connection
        assert_eq!(manager.get_connection_count(user_id).await, 1);
        assert!(manager.is_user_online(user_id).await);

        // Unregister last connection
        manager.unregister_connection(user_id, 0).await;

        // User should now be offline
        assert_eq!(manager.get_connection_count(user_id).await, 0);
        assert!(!manager.is_user_online(user_id).await);
    }

    #[tokio::test]
    async fn test_send_to_user() {
        let manager = ConnectionManager::new();
        let user_id = Uuid::new_v4();
        let (tx, mut rx) = mpsc::unbounded_channel();

        // Register connection
        manager.register_connection(user_id, tx).await;

        // Send event to user
        let event = WebSocketEvent::UserOnline { user_id };
        manager.send_to_user(user_id, event.clone()).await;

        // Verify event was received
        let received = rx.recv().await.unwrap();
        match received {
            WebSocketEvent::UserOnline { user_id: id } => {
                assert_eq!(id, user_id);
            }
            _ => panic!("Unexpected event type"),
        }
    }

    #[tokio::test]
    async fn test_get_online_users() {
        let manager = ConnectionManager::new();
        let user1 = Uuid::new_v4();
        let user2 = Uuid::new_v4();

        let (tx1, _rx1) = mpsc::unbounded_channel();
        let (tx2, _rx2) = mpsc::unbounded_channel();

        // Register connections
        manager.register_connection(user1, tx1).await;
        manager.register_connection(user2, tx2).await;

        // Get online users
        let online_users = manager.get_online_users().await;
        assert_eq!(online_users.len(), 2);
        assert!(online_users.contains(&user1));
        assert!(online_users.contains(&user2));
    }

    #[tokio::test]
    async fn test_cleanup_stale_connections() {
        let manager = ConnectionManager::new();
        let user_id = Uuid::new_v4();
        let (tx, rx) = mpsc::unbounded_channel();

        // Register connection
        manager.register_connection(user_id, tx).await;
        assert_eq!(manager.get_connection_count(user_id).await, 1);

        // Drop the receiver to close the channel
        drop(rx);

        // Run cleanup
        manager.cleanup_stale_connections().await;

        // Connection should be cleaned up
        assert_eq!(manager.get_connection_count(user_id).await, 0);
        assert!(!manager.is_user_online(user_id).await);
    }
}
