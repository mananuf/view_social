// Data Transfer Objects for API requests and responses
use chrono::{DateTime, Utc};
use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

// ============================================================================
// Authentication DTOs
// ============================================================================

#[derive(Debug, Deserialize)]
pub struct RegisterRequest {
    pub username: String,
    pub email: String,
    pub password: String,
    pub phone_number: Option<String>,
    pub display_name: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct LoginRequest {
    pub username_or_email: String,
    pub password: String,
}

#[derive(Debug, Deserialize)]
pub struct RefreshTokenRequest {
    pub refresh_token: String,
}

#[derive(Debug, Serialize)]
pub struct AuthResponse {
    pub user: UserDTO,
    pub access_token: String,
    pub refresh_token: String,
    pub expires_in: i64,
}

#[derive(Debug, Serialize)]
pub struct RefreshTokenResponse {
    pub access_token: String,
    pub expires_in: i64,
}

// ============================================================================
// User DTOs
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UserDTO {
    pub id: Uuid,
    pub username: String,
    pub email: String,
    pub phone_number: Option<String>,
    pub display_name: Option<String>,
    pub bio: Option<String>,
    pub avatar_url: Option<String>,
    pub is_verified: bool,
    pub follower_count: i32,
    pub following_count: i32,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Deserialize)]
pub struct UpdateProfileRequest {
    pub display_name: Option<String>,
    pub bio: Option<String>,
    pub avatar_url: Option<String>,
}

// ============================================================================
// Post DTOs
// ============================================================================

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

// ============================================================================
// Messaging DTOs
// ============================================================================

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

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PaymentDataDTO {
    pub transaction_id: Uuid,
    pub amount: String,
    pub currency: String,
    pub status: String,
}

// ============================================================================
// Payment DTOs
// ============================================================================

#[derive(Debug, Serialize)]
pub struct WalletDTO {
    pub id: Uuid,
    pub user_id: Uuid,
    pub balance: String,
    pub currency: String,
    pub status: String,
    pub has_pin: bool,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Deserialize)]
pub struct SetPinRequest {
    pub pin: String,
    pub confirm_pin: String,
}

#[derive(Debug, Deserialize)]
pub struct TransferRequest {
    pub receiver_user_id: Uuid,
    pub amount: String,
    pub pin: String,
    pub description: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct TransactionDTO {
    pub id: Uuid,
    pub sender: Option<UserDTO>,
    pub receiver: Option<UserDTO>,
    pub transaction_type: String,
    pub amount: String,
    pub currency: String,
    pub status: String,
    pub description: Option<String>,
    pub reference: String,
    pub created_at: DateTime<Utc>,
}

// ============================================================================
// Common Response DTOs
// ============================================================================

#[derive(Debug, Serialize)]
pub struct SuccessResponse<T> {
    pub success: bool,
    pub data: T,
}

#[derive(Debug, Serialize)]
pub struct ErrorResponse {
    pub success: bool,
    pub error: ErrorDetail,
}

#[derive(Debug, Serialize)]
pub struct ErrorDetail {
    pub code: String,
    pub message: String,
}

#[derive(Debug, Serialize)]
pub struct PaginatedResponse<T> {
    pub success: bool,
    pub data: Vec<T>,
    pub pagination: PaginationMeta,
}

#[derive(Debug, Serialize)]
pub struct PaginationMeta {
    pub total: i64,
    pub limit: i64,
    pub offset: i64,
    pub has_more: bool,
}

impl<T> SuccessResponse<T> {
    pub fn new(data: T) -> Self {
        Self {
            success: true,
            data,
        }
    }
}

impl ErrorResponse {
    pub fn new(code: String, message: String) -> Self {
        Self {
            success: false,
            error: ErrorDetail { code, message },
        }
    }
}

impl<T> PaginatedResponse<T> {
    pub fn new(data: Vec<T>, total: i64, limit: i64, offset: i64) -> Self {
        let has_more = offset + (data.len() as i64) < total;
        Self {
            success: true,
            data,
            pagination: PaginationMeta {
                total,
                limit,
                offset,
                has_more,
            },
        }
    }
}
