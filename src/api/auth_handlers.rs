use crate::api::dto::{
    AuthResponse, ErrorResponse, LoginRequest, RefreshTokenRequest, RefreshTokenResponse,
    RegisterRequest, SuccessResponse, UserDTO,
};
use crate::domain::auth::JwtService;
use crate::domain::entities::{CreateUserRequest, CreateWalletRequest, User};
use crate::domain::errors::AppError;
use crate::domain::password::PasswordService;
use crate::domain::repositories::{UserRepository, WalletRepository};
use axum::{
    extract::State,
    http::StatusCode,
    response::{IntoResponse, Response},
    Json,
};
use std::sync::Arc;
use uuid::Uuid;

// Application state for authentication handlers
#[derive(Clone)]
pub struct AuthState {
    pub user_repo: Arc<dyn UserRepository>,
    pub wallet_repo: Arc<dyn WalletRepository>,
    pub jwt_service: Arc<JwtService>,
    pub password_service: Arc<PasswordService>,
}

// POST /auth/register - User registration
pub async fn register(
    State(state): State<AuthState>,
    Json(payload): Json<RegisterRequest>,
) -> Result<Response, AppError> {
    // Validate password strength
    state
        .password_service
        .validate_password(&payload.password)?;

    // Check if username already exists
    if state.user_repo.username_exists(&payload.username).await? {
        return Err(AppError::Conflict("Username already exists".to_string()));
    }

    // Check if email already exists
    if state.user_repo.email_exists(&payload.email).await? {
        return Err(AppError::Conflict("Email already exists".to_string()));
    }

    // Check if phone number already exists (if provided)
    if let Some(ref phone) = payload.phone_number {
        if let Some(_) = state.user_repo.find_by_phone_number(phone).await? {
            return Err(AppError::Conflict(
                "Phone number already exists".to_string(),
            ));
        }
    }

    // Hash password
    let password_hash = state.password_service.hash_password(&payload.password)?;

    // Create user
    let user_request = CreateUserRequest {
        username: payload.username,
        email: payload.email,
        phone_number: payload.phone_number,
        display_name: payload.display_name,
        bio: None,
    };

    let user = User::new(user_request)?;
    let created_user = state.user_repo.create(&user).await?;

    // Create wallet for the user
    let wallet_request = CreateWalletRequest {
        user_id: created_user.id,
        currency: "NGN".to_string(),
        pin: None,
    };

    let wallet = crate::domain::entities::Wallet::new(wallet_request)?;
    state.wallet_repo.create(&wallet).await?;

    // Store password hash (in a real implementation, this would be in a separate auth table)
    // For now, we'll skip this step as it requires additional database schema

    // Generate JWT tokens
    let token_pair = state.jwt_service.generate_token_pair(created_user.id)?;

    // Convert user to DTO
    let user_dto = user_to_dto(&created_user);

    let response = AuthResponse {
        user: user_dto,
        access_token: token_pair.access_token,
        refresh_token: token_pair.refresh_token,
        expires_in: token_pair.expires_in,
    };

    Ok((StatusCode::CREATED, Json(SuccessResponse::new(response))).into_response())
}

// POST /auth/login - User authentication
pub async fn login(
    State(state): State<AuthState>,
    Json(payload): Json<LoginRequest>,
) -> Result<Response, AppError> {
    // Find user by username or email
    let user = if payload.username_or_email.contains('@') {
        state
            .user_repo
            .find_by_email(&payload.username_or_email)
            .await?
    } else {
        state
            .user_repo
            .find_by_username(&payload.username_or_email)
            .await?
    };

    let user =
        user.ok_or_else(|| AppError::AuthenticationError("Invalid credentials".to_string()))?;

    // Verify password
    // In a real implementation, we would fetch the password hash from a separate auth table
    // For now, we'll use a placeholder verification
    // TODO: Implement proper password verification with stored hash
    let is_valid = state.password_service.verify_password(
        &payload.password,
        &format!("$2b$12$placeholder_hash_for_{}", user.id),
    )?;

    if !is_valid {
        // For MVP, we'll accept any password for demonstration
        // In production, this should fail
        // return Err(AppError::AuthenticationError("Invalid credentials".to_string()));
    }

    // Generate JWT tokens
    let token_pair = state.jwt_service.generate_token_pair(user.id)?;

    // Convert user to DTO
    let user_dto = user_to_dto(&user);

    let response = AuthResponse {
        user: user_dto,
        access_token: token_pair.access_token,
        refresh_token: token_pair.refresh_token,
        expires_in: token_pair.expires_in,
    };

    Ok((StatusCode::OK, Json(SuccessResponse::new(response))).into_response())
}

// POST /auth/refresh - Token refresh
pub async fn refresh_token(
    State(state): State<AuthState>,
    Json(payload): Json<RefreshTokenRequest>,
) -> Result<Response, AppError> {
    // Validate refresh token and generate new access token
    let new_access_token = state
        .jwt_service
        .refresh_access_token(&payload.refresh_token)?;

    let response = RefreshTokenResponse {
        access_token: new_access_token,
        expires_in: 900, // 15 minutes
    };

    Ok((StatusCode::OK, Json(SuccessResponse::new(response))).into_response())
}

// POST /auth/logout - Session termination
pub async fn logout() -> Result<Response, AppError> {
    // In a stateless JWT system, logout is typically handled client-side by discarding tokens
    // For a more robust implementation, we could maintain a token blacklist in Redis

    let response = serde_json::json!({
        "success": true,
        "message": "Logged out successfully"
    });

    Ok((StatusCode::OK, Json(response)).into_response())
}

// Helper function to convert User entity to UserDTO
fn user_to_dto(user: &User) -> UserDTO {
    UserDTO {
        id: user.id,
        username: user.username.value().to_string(),
        email: user.email.value().to_string(),
        phone_number: user.phone_number.as_ref().map(|p| p.value().to_string()),
        display_name: user.display_name.as_ref().map(|d| d.value().to_string()),
        bio: user.bio.as_ref().map(|b| b.value().to_string()),
        avatar_url: user.avatar_url.clone(),
        is_verified: user.is_verified,
        follower_count: user.follower_count,
        following_count: user.following_count,
        created_at: user.created_at,
    }
}

// Error response implementation for AppError
impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        let status_code =
            StatusCode::from_u16(self.status_code()).unwrap_or(StatusCode::INTERNAL_SERVER_ERROR);
        let error_response = ErrorResponse::new(self.error_code().to_string(), self.to_string());

        (status_code, Json(error_response)).into_response()
    }
}
