use chrono::{DateTime, Utc};
use sqlx::FromRow;
use uuid::Uuid;

/// Database model for conversations table
#[derive(FromRow)]
pub struct ConversationModel {
    pub id: Uuid,
    pub conversation_type: String,
    pub title: Option<String>,
    pub created_at: DateTime<Utc>,
}

/// Database model for conversation_participants table
#[derive(FromRow)]
pub struct ParticipantModel {
    pub user_id: Uuid,
}
