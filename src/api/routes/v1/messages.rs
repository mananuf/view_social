use crate::api::handlers::message_handlers::{
    create_conversation, get_conversations, get_messages, send_message,
};
use crate::api::middleware::auth_middleware;
use crate::server::AppState;
use axum::{
    middleware,
    routing::{get, post},
    Router,
};

/// Create messaging-related routes
///
/// All routes require authentication:
/// - GET /conversations - Get user's conversations
/// - POST /conversations - Create a new conversation
/// - GET /conversations/:id/messages - Get messages in a conversation
/// - POST /conversations/:id/messages - Send a message in a conversation
pub fn create_router(state: AppState) -> Router {
    Router::new()
        .route("/conversations", get(get_conversations))
        .route("/conversations", post(create_conversation))
        .route("/conversations/:id/messages", get(get_messages))
        .route("/conversations/:id/messages", post(send_message))
        .layer(middleware::from_fn_with_state(
            state.auth_state.clone(),
            auth_middleware,
        ))
        .with_state(state.message_state)
}
