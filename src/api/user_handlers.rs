use crate::api::dto::{UserDTO, UpdateProfileRequest, SuccessResponse};
use crate::domain::entities::{User, UpdateUserRequest};
use crate::domain::errors::AppError;
use crate::domain::repositories::UserRepository;
use crate::api::middleware::AuthUser;
use axum::{
    extract::{State, Path},
    http::StatusCode,
    response::{IntoResponse, Response},
    Json,
};
use std::sync::Arc;
use uuid::Uuid;

// Application state for user handlers
#[derive(Clone)]
pub struct UserState {
    pub user_repo: Arc<dyn UserRepository>,
}

// GET /users/me - Get current user profile
pub async fn get_current_user(
    auth_user: AuthUser,
    State(state): State<UserState>,
) -> Result<Response, AppError> {
    let user = state.user_repo.find_by_id(auth_user.user_id).await?
        .ok_or_else(|| AppError::NotFound("User not found".to_string()))?;
    
    let user_dto = user_to_dto(&user);
    
    Ok((StatusCode::OK, Json(SuccessResponse::new(user_dto))).into_response())
}

// PUT /users/me - Update current user profile
pub async fn update_current_user(
    auth_user: AuthUser,
    State(state): State<UserState>,
    Json(payload): Json<UpdateProfileRequest>,
) -> Result<Response, AppError> {
    let mut user = state.user_repo.find_by_id(auth_user.user_id).await?
        .ok_or_else(|| AppError::NotFound("User not found".to_string()))?;
    
    // Update user with new data
    let update_request = UpdateUserRequest {
        display_name: payload.display_name,
        bio: payload.bio,
        avatar_url: payload.avatar_url,
    };
    
    user.update(update_request)?;
    
    // Save updated user
    let updated_user = state.user_repo.update(&user).await?;
    
    let user_dto = user_to_dto(&updated_user);
    
    Ok((StatusCode::OK, Json(SuccessResponse::new(user_dto))).into_response())
}

// GET /users/:id - Get public user profile
pub async fn get_user_by_id(
    Path(user_id): Path<Uuid>,
    State(state): State<UserState>,
) -> Result<Response, AppError> {
    let user = state.user_repo.find_by_id(user_id).await?
        .ok_or_else(|| AppError::NotFound("User not found".to_string()))?;
    
    let user_dto = user_to_dto(&user);
    
    Ok((StatusCode::OK, Json(SuccessResponse::new(user_dto))).into_response())
}

// POST /users/:id/follow - Follow a user
pub async fn follow_user(
    auth_user: AuthUser,
    Path(user_id): Path<Uuid>,
    State(state): State<UserState>,
) -> Result<Response, AppError> {
    // Check if trying to follow self
    if auth_user.user_id == user_id {
        return Err(AppError::BadRequest("Cannot follow yourself".to_string()));
    }
    
    // Check if user to follow exists
    let _target_user = state.user_repo.find_by_id(user_id).await?
        .ok_or_else(|| AppError::NotFound("User not found".to_string()))?;
    
    // Check if already following
    if state.user_repo.is_following(auth_user.user_id, user_id).await? {
        return Err(AppError::Conflict("Already following this user".to_string()));
    }
    
    // Create follow relationship
    state.user_repo.follow(auth_user.user_id, user_id).await?;
    
    let response = serde_json::json!({
        "success": true,
        "message": "Successfully followed user"
    });
    
    Ok((StatusCode::OK, Json(response)).into_response())
}

// DELETE /users/:id/follow - Unfollow a user
pub async fn unfollow_user(
    auth_user: AuthUser,
    Path(user_id): Path<Uuid>,
    State(state): State<UserState>,
) -> Result<Response, AppError> {
    // Check if trying to unfollow self
    if auth_user.user_id == user_id {
        return Err(AppError::BadRequest("Cannot unfollow yourself".to_string()));
    }
    
    // Check if currently following
    if !state.user_repo.is_following(auth_user.user_id, user_id).await? {
        return Err(AppError::BadRequest("Not following this user".to_string()));
    }
    
    // Remove follow relationship
    state.user_repo.unfollow(auth_user.user_id, user_id).await?;
    
    let response = serde_json::json!({
        "success": true,
        "message": "Successfully unfollowed user"
    });
    
    Ok((StatusCode::OK, Json(response)).into_response())
}

// Helper function to convert User entity to UserDTO
pub fn user_to_dto(user: &User) -> UserDTO {
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
