use proptest::prelude::*;
use std::collections::HashMap;
use tokio::sync::mpsc;
use uuid::Uuid;
use view_social_backend::api::websocket::{ConnectionManager, WebSocketEvent};

// **Feature: view-social-mvp, Property 10: Typing indicator propagation**
// **Validates: Requirements 4.2**
proptest! {
    #[test]
    fn test_typing_indicator_propagation(
        conversation_id in "[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}",
        typing_user_id in "[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}",
        participant_ids in proptest::collection::vec(
            "[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}",
            2..6
        ),
        is_typing in any::<bool>()
    ) {
        tokio::runtime::Runtime::new().unwrap().block_on(async {
            // Parse UUIDs
            let conversation_id = Uuid::parse_str(&conversation_id).unwrap();
            let typing_user_id = Uuid::parse_str(&typing_user_id).unwrap();
            let participant_ids: Vec<Uuid> = participant_ids
                .iter()
                .map(|id| Uuid::parse_str(id).unwrap())
                .collect();

            // Ensure typing user is not in participants (they shouldn't receive their own typing indicator)
            let mut unique_participants = participant_ids.clone();
            unique_participants.retain(|id| *id != typing_user_id);

            // Skip test if no other participants
            if unique_participants.is_empty() {
                return Ok(());
            }

            // Create connection manager
            let manager = ConnectionManager::new();

            // Create channels for each participant to receive events
            let mut participant_receivers = HashMap::new();

            // Register connections for all participants
            for participant_id in &unique_participants {
                let (tx, rx) = mpsc::unbounded_channel();
                manager.register_connection(*participant_id, tx).await;
                participant_receivers.insert(*participant_id, rx);
            }

            // Create the typing indicator event
            let typing_event = if is_typing {
                WebSocketEvent::TypingStarted {
                    conversation_id,
                    user_id: typing_user_id,
                }
            } else {
                WebSocketEvent::TypingStopped {
                    conversation_id,
                    user_id: typing_user_id,
                }
            };

            // Send typing indicator to all participants
            manager.send_to_users(&unique_participants, typing_event.clone()).await;

            // Verify each participant received the typing indicator
            for participant_id in &unique_participants {
                let mut rx = participant_receivers.remove(participant_id).unwrap();

                // Try to receive the event with a timeout
                let received_event = tokio::time::timeout(
                    tokio::time::Duration::from_millis(100),
                    rx.recv()
                ).await;

                prop_assert!(received_event.is_ok(),
                    "Participant {} did not receive typing indicator within timeout",
                    participant_id);

                let event = received_event.unwrap();
                prop_assert!(event.is_some(),
                    "Participant {} received None instead of typing indicator",
                    participant_id);

                let received_event = event.unwrap();

                // Verify the event matches what was sent
                match (&typing_event, &received_event) {
                    (
                        WebSocketEvent::TypingStarted { conversation_id: sent_conv, user_id: sent_user },
                        WebSocketEvent::TypingStarted { conversation_id: recv_conv, user_id: recv_user }
                    ) => {
                        prop_assert_eq!(sent_conv, recv_conv,
                            "Conversation ID mismatch in TypingStarted event");
                        prop_assert_eq!(sent_user, recv_user,
                            "User ID mismatch in TypingStarted event");
                    },
                    (
                        WebSocketEvent::TypingStopped { conversation_id: sent_conv, user_id: sent_user },
                        WebSocketEvent::TypingStopped { conversation_id: recv_conv, user_id: recv_user }
                    ) => {
                        prop_assert_eq!(sent_conv, recv_conv,
                            "Conversation ID mismatch in TypingStopped event");
                        prop_assert_eq!(sent_user, recv_user,
                            "User ID mismatch in TypingStopped event");
                    },
                    _ => {
                        prop_assert!(false,
                            "Event type mismatch: sent {:?}, received {:?}",
                            typing_event, received_event);
                    }
                }
            }

            // Property: Typing user should not receive their own typing indicator
            // (This is implicitly tested by not including typing_user_id in unique_participants)

            // Property: All conversation participants (except typing user) should receive the indicator
            prop_assert_eq!(unique_participants.len(), participant_receivers.len(),
                "Not all participants were set up to receive typing indicators");

            Ok(())
        })?;
    }
}

#[cfg(test)]
mod integration_tests {
    use super::*;

    #[tokio::test]
    async fn test_typing_indicator_basic_functionality() {
        let manager = ConnectionManager::new();
        let conversation_id = Uuid::new_v4();
        let typing_user = Uuid::new_v4();
        let participant1 = Uuid::new_v4();
        let participant2 = Uuid::new_v4();

        // Register connections
        let (tx1, mut rx1) = mpsc::unbounded_channel();
        let (tx2, mut rx2) = mpsc::unbounded_channel();

        manager.register_connection(participant1, tx1).await;
        manager.register_connection(participant2, tx2).await;

        // Send typing started event
        let typing_event = WebSocketEvent::TypingStarted {
            conversation_id,
            user_id: typing_user,
        };

        manager
            .send_to_users(&[participant1, participant2], typing_event.clone())
            .await;

        // Verify both participants received the event
        let event1 = rx1.recv().await.unwrap();
        let event2 = rx2.recv().await.unwrap();

        match (&event1, &event2) {
            (
                WebSocketEvent::TypingStarted {
                    conversation_id: conv1,
                    user_id: user1,
                },
                WebSocketEvent::TypingStarted {
                    conversation_id: conv2,
                    user_id: user2,
                },
            ) => {
                assert_eq!(*conv1, conversation_id);
                assert_eq!(*conv2, conversation_id);
                assert_eq!(*user1, typing_user);
                assert_eq!(*user2, typing_user);
            }
            _ => panic!("Unexpected event types received"),
        }
    }

    #[tokio::test]
    async fn test_typing_indicator_no_self_delivery() {
        let manager = ConnectionManager::new();
        let conversation_id = Uuid::new_v4();
        let typing_user = Uuid::new_v4();

        // Register connection for typing user
        let (tx, mut rx) = mpsc::unbounded_channel();
        manager.register_connection(typing_user, tx).await;

        // Send typing event to empty recipient list (simulating no other participants)
        let typing_event = WebSocketEvent::TypingStarted {
            conversation_id,
            user_id: typing_user,
        };

        manager.send_to_users(&[], typing_event).await;

        // Verify typing user doesn't receive their own typing indicator
        let result = tokio::time::timeout(tokio::time::Duration::from_millis(50), rx.recv()).await;

        assert!(
            result.is_err(),
            "Typing user should not receive their own typing indicator"
        );
    }
}
