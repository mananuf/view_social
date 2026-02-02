// Messaging-related DTOs
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use super::{PaymentDataDTO, UserDTO};

#[derive(Debug, Deserialize)]
pub struct CreateConversationRequest {
    pub participant_ids: Vec<Uuid>,
    pub is_group: bool,
    pub group_name: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct ConversationDTO {
    pub id: Uuid,
    pub participants: Vec<UserDTO>,
    pub is_group: bool,
    pub group_name: Option<String>,
    pub last_message: Option<MessageDTO>,
    pub unread_count: i64,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Deserialize)]
pub struct SendMessageRequest {
    pub message_type: String,
    pub content: Option<String>,
    pub media_url: Option<String>,
    pub reply_to_id: Option<Uuid>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MessageDTO {
    pub id: Uuid,
    pub conversation_id: Uuid,
    pub sender: Option<UserDTO>,
    pub message_type: String,
    pub content: Option<String>,
    pub media_url: Option<String>,
    pub payment_data: Option<PaymentDataDTO>,
    pub reply_to_id: Option<Uuid>,
    pub is_read: bool,
    pub created_at: DateTime<Utc>,
}
