use crate::api::dto::common::{PaginatedResponse, SuccessResponse};
use crate::api::dto::messaging::{
    ConversationDTO, CreateConversationRequest, MessageDTO, SendMessageRequest,
};
use crate::api::dto::payment::PaymentDataDTO;
use crate::api::handlers::user_handlers::user_to_dto;
use crate::api::middleware::auth::AuthUser;
use crate::api::websocket::{ConnectionManager, WebSocketEvent};
use crate::domain::entities::{CreateMessageRequest, Message, MessageType};
use crate::domain::errors::AppError;
use crate::domain::repositories::{ConversationRepository, MessageRepository, UserRepository};
use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    response::{IntoResponse, Response},
    Json,
};
use chrono::Utc;
use serde::Deserialize;
use std::sync::Arc;
use uuid::Uuid;

// Application state for message handlers
#[derive(Clone)]
pub struct MessageState {
    pub conversation_repo: Arc<dyn ConversationRepository>,
    pub message_repo: Arc<dyn MessageRepository>,
    pub user_repo: Arc<dyn UserRepository>,
    pub connection_manager: ConnectionManager,
}

#[derive(Debug, Deserialize)]
pub struct ConversationQuery {
    #[serde(default = "default_limit")]
    pub limit: i64,
    #[serde(default)]
    pub offset: i64,
}

#[derive(Debug, Deserialize)]
pub struct MessageQuery {
    #[serde(default = "default_message_limit")]
    pub limit: i64,
    pub before_id: Option<Uuid>,
}

#[derive(Debug, Deserialize)]
pub struct TypingIndicatorRequest {
    pub is_typing: bool,
}

#[derive(Debug, Deserialize)]
pub struct MarkReadRequest {
    pub message_id: Uuid,
}

fn default_limit() -> i64 {
    20
}

fn default_message_limit() -> i64 {
    50
}

// GET /conversations - Get user conversations
pub async fn get_conversations(
    auth_user: AuthUser,
    Query(query): Query<ConversationQuery>,
    State(state): State<MessageState>,
) -> Result<Response, AppError> {
    // Validate pagination parameters
    let limit = query.limit.min(100).max(1);
    let offset = query.offset.max(0);

    // Get conversations for the user
    let conversations = state
        .conversation_repo
        .find_by_user(auth_user.user_id, limit, offset)
        .await?;

    // Convert to DTOs
    let mut conversation_dtos = Vec::new();
    for (conv_id, participant_ids, is_group, group_name, created_at) in conversations {
        // Get participant users
        let mut participants = Vec::new();
        for participant_id in &participant_ids {
            if let Some(user) = state.user_repo.find_by_id(*participant_id).await? {
                participants.push(user_to_dto(&user));
            }
        }

        // Get last message
        let last_message = state
            .message_repo
            .find_latest_in_conversation(conv_id)
            .await?;
        let last_message_dto = if let Some(msg) = last_message {
            Some(message_to_dto(&msg, &state).await?)
        } else {
            None
        };

        // Get unread count
        let unread_count = state
            .message_repo
            .get_unread_count(conv_id, auth_user.user_id)
            .await?;

        conversation_dtos.push(ConversationDTO {
            id: conv_id,
            participants,
            is_group,
            group_name,
            last_message: last_message_dto,
            unread_count,
            created_at,
        });
    }

    let response = PaginatedResponse::new(conversation_dtos, 0, limit, offset);

    Ok((StatusCode::OK, Json(response)).into_response())
}

// POST /conversations - Create a new conversation
pub async fn create_conversation(
    auth_user: AuthUser,
    State(state): State<MessageState>,
    Json(payload): Json<CreateConversationRequest>,
) -> Result<Response, AppError> {
    // Validate participants
    if payload.participant_ids.is_empty() {
        return Err(AppError::ValidationError(
            "At least one participant is required".to_string(),
        ));
    }

    // Check if all participants exist
    for participant_id in &payload.participant_ids {
        if state.user_repo.find_by_id(*participant_id).await?.is_none() {
            return Err(AppError::NotFound(format!(
                "User {} not found",
                participant_id
            )));
        }
    }

    // For direct conversations, check if one already exists
    if !payload.is_group && payload.participant_ids.len() == 1 {
        let other_user_id = payload.participant_ids[0];
        if let Some(existing_conv_id) = state
            .conversation_repo
            .find_direct_conversation(auth_user.user_id, other_user_id)
            .await?
        {
            // Return existing conversation
            let (conv_id, participant_ids, is_group, group_name, created_at) = state
                .conversation_repo
                .find_by_id(existing_conv_id)
                .await?
                .ok_or_else(|| AppError::NotFound("Conversation not found".to_string()))?;

            let mut participants = Vec::new();
            for participant_id in &participant_ids {
                if let Some(user) = state.user_repo.find_by_id(*participant_id).await? {
                    participants.push(user_to_dto(&user));
                }
            }

            let conversation_dto = ConversationDTO {
                id: conv_id,
                participants,
                is_group,
                group_name,
                last_message: None,
                unread_count: 0,
                created_at,
            };

            return Ok((
                StatusCode::OK,
                Json(SuccessResponse::new(
                    "Conversation created successfully".to_string(),
                    Some(serde_json::to_value(conversation_dto).unwrap()),
                )),
            )
                .into_response());
        }
    }

    // Validate group conversation requirements
    if payload.is_group {
        if payload.participant_ids.len() < 2 {
            return Err(AppError::ValidationError(
                "Group conversations require at least 2 participants".to_string(),
            ));
        }
        if payload.group_name.is_none() {
            return Err(AppError::ValidationError(
                "Group conversations require a name".to_string(),
            ));
        }
    }

    // Create conversation with current user included
    let mut all_participants = payload.participant_ids.clone();
    if !all_participants.contains(&auth_user.user_id) {
        all_participants.push(auth_user.user_id);
    }

    let conversation_id = Uuid::new_v4();
    let conv_id = state
        .conversation_repo
        .create(
            conversation_id,
            all_participants.clone(),
            payload.is_group,
            payload.group_name.clone(),
            auth_user.user_id,
        )
        .await?;

    // Get participant users
    let mut participants = Vec::new();
    for participant_id in &all_participants {
        if let Some(user) = state.user_repo.find_by_id(*participant_id).await? {
            participants.push(user_to_dto(&user));
        }
    }

    let conversation_dto = ConversationDTO {
        id: conv_id,
        participants,
        is_group: payload.is_group,
        group_name: payload.group_name,
        last_message: None,
        unread_count: 0,
        created_at: Utc::now(),
    };

    Ok((
        StatusCode::CREATED,
        Json(SuccessResponse::new(
            "Conversations retrieved successfully".to_string(),
            Some(serde_json::to_value(conversation_dto).unwrap()),
        )),
    )
        .into_response())
}

// GET /conversations/:id/messages - Get message history
pub async fn get_messages(
    auth_user: AuthUser,
    Path(conversation_id): Path<Uuid>,
    Query(query): Query<MessageQuery>,
    State(state): State<MessageState>,
) -> Result<Response, AppError> {
    // Check if user is participant in conversation
    if !state
        .conversation_repo
        .is_participant(conversation_id, auth_user.user_id)
        .await?
    {
        return Err(AppError::Forbidden);
    }

    // Validate pagination parameters
    let limit = query.limit.min(100).max(1);

    // Get messages
    let messages = state
        .message_repo
        .find_by_conversation(conversation_id, limit, query.before_id)
        .await?;

    // Convert to DTOs
    let mut message_dtos = Vec::new();
    for message in messages {
        message_dtos.push(message_to_dto(&message, &state).await?);
    }

    let response = PaginatedResponse::new(message_dtos, 0, limit, 0);

    Ok((StatusCode::OK, Json(response)).into_response())
}

// POST /conversations/:id/messages - Send a message
pub async fn send_message(
    auth_user: AuthUser,
    Path(conversation_id): Path<Uuid>,
    State(state): State<MessageState>,
    Json(payload): Json<SendMessageRequest>,
) -> Result<Response, AppError> {
    // Check if user is participant in conversation
    if !state
        .conversation_repo
        .is_participant(conversation_id, auth_user.user_id)
        .await?
    {
        return Err(AppError::Forbidden);
    }

    // Parse message type
    let message_type = match payload.message_type.as_str() {
        "text" => MessageType::Text,
        "image" => MessageType::Image,
        "video" => MessageType::Video,
        "audio" => MessageType::Audio,
        "payment" => MessageType::Payment,
        "system" => MessageType::System,
        _ => {
            return Err(AppError::ValidationError(
                "Invalid message type".to_string(),
            ))
        }
    };

    // Create message
    let message_request = CreateMessageRequest {
        conversation_id,
        sender_id: Some(auth_user.user_id),
        message_type,
        content: payload.content,
        media_url: payload.media_url,
        payment_data: None, // Payment data would be set by payment service
        reply_to_id: payload.reply_to_id,
    };

    let message = Message::new(message_request)?;
    let created_message = state.message_repo.create(&message).await?;

    let message_dto = message_to_dto(&created_message, &state).await?;

    // Broadcast message to conversation participants via WebSocket
    let (_, participant_ids, _, _, _) = state
        .conversation_repo
        .find_by_id(conversation_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Conversation not found".to_string()))?;

    // Send WebSocket event to all participants except sender
    let recipients: Vec<Uuid> = participant_ids
        .into_iter()
        .filter(|id| *id != auth_user.user_id)
        .collect();

    if !recipients.is_empty() {
        let ws_event = WebSocketEvent::MessageSent {
            conversation_id,
            message_id: created_message.id,
            sender_id: auth_user.user_id,
            content: created_message.content.unwrap_or_default(),
        };

        state
            .connection_manager
            .send_to_users(&recipients, ws_event)
            .await;

        tracing::debug!(
            "Broadcasted message {} to {} participants",
            created_message.id,
            recipients.len()
        );
    }

    Ok((
        StatusCode::CREATED,
        Json(SuccessResponse::new(
            "Message sent successfully".to_string(),
            Some(serde_json::to_value(message_dto).unwrap()),
        )),
    )
        .into_response())
}

// POST /conversations/:id/typing - Send typing indicator
pub async fn send_typing_indicator(
    auth_user: AuthUser,
    Path(conversation_id): Path<Uuid>,
    State(state): State<MessageState>,
    Json(payload): Json<TypingIndicatorRequest>,
) -> Result<Response, AppError> {
    // Check if user is participant in conversation
    if !state
        .conversation_repo
        .is_participant(conversation_id, auth_user.user_id)
        .await?
    {
        return Err(AppError::Forbidden);
    }

    // Get conversation participants
    let (_, participant_ids, _, _, _) = state
        .conversation_repo
        .find_by_id(conversation_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Conversation not found".to_string()))?;

    // Send typing indicator to all participants except sender
    let recipients: Vec<Uuid> = participant_ids
        .into_iter()
        .filter(|id| *id != auth_user.user_id)
        .collect();

    if !recipients.is_empty() {
        let ws_event = if payload.is_typing {
            WebSocketEvent::TypingStarted {
                conversation_id,
                user_id: auth_user.user_id,
            }
        } else {
            WebSocketEvent::TypingStopped {
                conversation_id,
                user_id: auth_user.user_id,
            }
        };

        state
            .connection_manager
            .send_to_users(&recipients, ws_event)
            .await;

        tracing::debug!(
            "Sent typing indicator ({}) from user {} to {} participants in conversation {}",
            if payload.is_typing {
                "started"
            } else {
                "stopped"
            },
            auth_user.user_id,
            recipients.len(),
            conversation_id
        );
    }

    Ok((
        StatusCode::OK,
        Json(SuccessResponse::new(
            "Typing indicator sent successfully".to_string(),
            None,
        )),
    )
        .into_response())
}

// POST /conversations/:id/read - Mark messages as read
pub async fn mark_messages_read(
    auth_user: AuthUser,
    Path(conversation_id): Path<Uuid>,
    State(state): State<MessageState>,
    Json(payload): Json<MarkReadRequest>,
) -> Result<Response, AppError> {
    // Check if user is participant in conversation
    if !state
        .conversation_repo
        .is_participant(conversation_id, auth_user.user_id)
        .await?
    {
        return Err(AppError::Forbidden);
    }

    // Mark message as read
    state
        .message_repo
        .mark_as_read(payload.message_id, auth_user.user_id)
        .await?;

    // Get conversation participants to broadcast read receipt
    let (_, participant_ids, _, _, _) = state
        .conversation_repo
        .find_by_id(conversation_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Conversation not found".to_string()))?;

    // Send read receipt to all participants except the reader
    let recipients: Vec<Uuid> = participant_ids
        .into_iter()
        .filter(|id| *id != auth_user.user_id)
        .collect();

    if !recipients.is_empty() {
        let ws_event = WebSocketEvent::MessageRead {
            message_id: payload.message_id,
            user_id: auth_user.user_id,
        };

        state
            .connection_manager
            .send_to_users(&recipients, ws_event)
            .await;

        tracing::debug!(
            "Sent read receipt for message {} from user {} to {} participants",
            payload.message_id,
            auth_user.user_id,
            recipients.len()
        );
    }

    Ok((
        StatusCode::OK,
        Json(SuccessResponse::new(
            "Message marked as read".to_string(),
            None,
        )),
    )
        .into_response())
}

// Helper function to convert Message entity to MessageDTO
async fn message_to_dto(message: &Message, state: &MessageState) -> Result<MessageDTO, AppError> {
    let message_type = match message.message_type {
        MessageType::Text => "text",
        MessageType::Image => "image",
        MessageType::Video => "video",
        MessageType::Audio => "audio",
        MessageType::Payment => "payment",
        MessageType::System => "system",
    };

    let sender = if let Some(sender_id) = message.sender_id {
        state
            .user_repo
            .find_by_id(sender_id)
            .await?
            .map(|u| user_to_dto(&u))
    } else {
        None
    };

    let payment_data = message.payment_data.as_ref().map(|pd| PaymentDataDTO {
        transaction_id: pd.transaction_id,
        amount: pd.amount.to_string(),
        currency: pd.currency.clone(),
        status: pd.status.clone(),
    });

    // For simplicity, we'll assume message is read if it's the sender's own message
    // In a real implementation, we'd check the message_reads table
    let is_read = false;

    Ok(MessageDTO {
        id: message.id,
        conversation_id: message.conversation_id,
        sender,
        message_type: message_type.to_string(),
        content: message.content.clone(),
        media_url: message.media_url.clone(),
        payment_data,
        reply_to_id: message.reply_to_id,
        is_read,
        created_at: message.created_at,
    })
}
