use chrono::{DateTime, Utc};
use sqlx::FromRow;
use uuid::Uuid;

/// Database model for messages table
#[derive(FromRow)]
pub struct MessageModel {
    pub id: Uuid,
    pub conversation_id: Uuid,
    pub sender_id: Option<Uuid>,
    pub message_type: String,
    pub content: Option<String>,
    pub media_url: Option<String>,
    pub payment_data: Option<serde_json::Value>,
    pub reply_to_id: Option<Uuid>,
    pub created_at: DateTime<Utc>,
}

/// Database model for message_reads table
#[derive(FromRow)]
pub struct MessageReadModel {
    pub id: Uuid,
    pub message_id: Uuid,
    pub user_id: Uuid,
    pub read_at: DateTime<Utc>,
}
