// Post-related DTOs
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use super::UserDTO;

#[derive(Debug, Deserialize)]
pub struct CreatePostRequest {
    pub text_content: Option<String>,
    pub media_attachments: Vec<MediaAttachmentDTO>,
    pub is_reel: bool,
    pub visibility: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MediaAttachmentDTO {
    pub url: String,
    pub media_type: String,
    pub size: i64,
    pub width: Option<i32>,
    pub height: Option<i32>,
    pub duration: Option<i32>,
}

#[derive(Debug, Serialize)]
pub struct PostDTO {
    pub id: Uuid,
    pub user: UserDTO,
    pub content_type: String,
    pub text_content: Option<String>,
    pub media_attachments: Vec<MediaAttachmentDTO>,
    pub is_reel: bool,
    pub visibility: String,
    pub like_count: i32,
    pub comment_count: i32,
    pub reshare_count: i32,
    pub is_liked: bool,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Deserialize)]
pub struct CreateCommentRequest {
    pub content: String,
    pub parent_comment_id: Option<Uuid>,
}

#[derive(Debug, Serialize)]
pub struct CommentDTO {
    pub id: Uuid,
    pub post_id: Uuid,
    pub user: UserDTO,
    pub content: String,
    pub like_count: i32,
    pub parent_comment_id: Option<Uuid>,
    pub created_at: DateTime<Utc>,
}
