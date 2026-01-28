use chrono::{DateTime, Utc};
use sqlx::FromRow;
use uuid::Uuid;

/// Database model for posts table
#[derive(FromRow)]
pub struct PostModel {
    pub id: Uuid,
    pub user_id: Uuid,
    pub content_type: String,
    pub text_content: Option<String>,
    pub media_attachments: serde_json::Value,
    pub is_reel: bool,
    pub visibility: String,
    pub like_count: i32,
    pub comment_count: i32,
    pub reshare_count: i32,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}
