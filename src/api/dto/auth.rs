// Authentication-related DTOs
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Deserialize)]
pub struct RegisterRequest {
    pub username: String,
    pub password: String,
    pub identifier: String,        // email or phone number
    pub registration_type: String, // "email" or "phone"
    pub display_name: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct RegisterResponse {
    pub message: String,
    pub verification_id: Uuid,
    pub user_id: Uuid,
    pub verification_type: String,
    pub identifier: String,
}

#[derive(Debug, Deserialize)]
pub struct VerifyCodeRequest {
    pub identifier: String, // email or phone number
    pub code: String,
}

#[derive(Debug, Deserialize)]
pub struct ResendCodeRequest {
    pub identifier: String, // email or phone number
}

#[derive(Debug, Deserialize)]
pub struct LoginRequest {
    pub identifier: String, // username, email, or phone
    pub password: String,
}

#[derive(Debug, Serialize)]
pub struct LoginResponse {
    pub token: String,
    pub user_id: Uuid,
    pub username: String,
    pub email: String,
    pub email_verified: bool,
    pub phone_verified: bool,
}

#[derive(Debug, Deserialize)]
pub struct RefreshTokenRequest {
    pub refresh_token: String,
}

#[derive(Debug, Serialize)]
pub struct AuthResponse {
    pub user: super::UserDTO,
    pub access_token: String,
    pub refresh_token: String,
    pub expires_in: i64,
}

#[derive(Debug, Serialize)]
pub struct RefreshTokenResponse {
    pub access_token: String,
    pub expires_in: i64,
}
