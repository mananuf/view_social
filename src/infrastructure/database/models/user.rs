use chrono::{DateTime, Utc};
use sqlx::FromRow;
use uuid::Uuid;

/// Database model for users table
#[derive(FromRow)]
pub struct UserModel {
    pub id: Uuid,
    pub username: String,
    pub email: String,
    pub phone_number: Option<String>,
    pub password_hash: String,
    pub display_name: Option<String>,
    pub bio: Option<String>,
    pub avatar_url: Option<String>,
    pub is_verified: bool,
    pub email_verified: bool,
    pub phone_verified: bool,
    pub follower_count: i32,
    pub following_count: i32,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}
