use crate::api::dto::common::SuccessResponse;
use crate::api::dto::user::{UpdateProfileRequest, UserDTO};
use crate::api::middleware::auth::AuthUser;
use crate::application::services::UserManagementService;
use crate::domain::entities::{UpdateUserRequest, User};
use crate::domain::errors::AppError;
use axum::{
    extract::{Path, State},
    http::StatusCode,
    response::{IntoResponse, Response},
    Json,
};
use std::sync::Arc;
use uuid::Uuid;

// Application state for user handlers
#[derive(Clone)]
pub struct UserState {
    pub user_service: Arc<UserManagementService>,
}

// GET /users/me - Get current user profile
pub async fn get_current_user(
    auth_user: AuthUser,
    State(state): State<UserState>,
) -> Result<Response, AppError> {
    let user = state
        .user_service
        .get_user_profile(auth_user.user_id)
        .await?;

    let user_dto = user_to_dto(&user);

    Ok((
        StatusCode::OK,
        Json(SuccessResponse::new(
            "User profile retrieved successfully".to_string(),
            Some(serde_json::to_value(user_dto).unwrap()),
        )),
    )
        .into_response())
}

// PUT /users/me - Update current user profile
pub async fn update_current_user(
    auth_user: AuthUser,
    State(state): State<UserState>,
    Json(payload): Json<UpdateProfileRequest>,
) -> Result<Response, AppError> {
    // Update user with new data using the service
    let update_request = UpdateUserRequest {
        display_name: payload.display_name,
        bio: payload.bio,
        avatar_url: payload.avatar_url,
    };

    let updated_user = state
        .user_service
        .update_profile(auth_user.user_id, update_request)
        .await?;

    let user_dto = user_to_dto(&updated_user);

    Ok((
        StatusCode::OK,
        Json(SuccessResponse::new(
            "User profile updated successfully".to_string(),
            Some(serde_json::to_value(user_dto).unwrap()),
        )),
    )
        .into_response())
}

// GET /users/:id - Get public user profile
pub async fn get_user_by_id(
    Path(user_id): Path<Uuid>,
    State(state): State<UserState>,
) -> Result<Response, AppError> {
    let user = state.user_service.get_user_profile(user_id).await?;

    let user_dto = user_to_dto(&user);

    Ok((
        StatusCode::OK,
        Json(SuccessResponse::new(
            "User profile retrieved successfully".to_string(),
            Some(serde_json::to_value(user_dto).unwrap()),
        )),
    )
        .into_response())
}

// POST /users/:id/follow - Follow a user
pub async fn follow_user(
    auth_user: AuthUser,
    Path(user_id): Path<Uuid>,
    State(state): State<UserState>,
) -> Result<Response, AppError> {
    // Use the service to handle follow logic with proper validation
    state
        .user_service
        .follow_user(auth_user.user_id, user_id)
        .await?;

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
    // Use the service to handle unfollow logic with proper validation
    state
        .user_service
        .unfollow_user(auth_user.user_id, user_id)
        .await?;

    let response = serde_json::json!({
        "success": true,
        "message": "Successfully unfollowed user"
    });

    Ok((StatusCode::OK, Json(response)).into_response())
}

// GET /users/:id/followers - Get user's followers
pub async fn get_user_followers(
    Path(user_id): Path<Uuid>,
    State(state): State<UserState>,
) -> Result<Response, AppError> {
    let followers = state
        .user_service
        .get_user_followers(user_id, 50, 0) // Default pagination
        .await?;

    let follower_dtos: Vec<UserDTO> = followers.iter().map(user_to_dto).collect();

    Ok((
        StatusCode::OK,
        Json(SuccessResponse::new(
            "Followers retrieved successfully".to_string(),
            Some(serde_json::to_value(follower_dtos).unwrap()),
        )),
    )
        .into_response())
}

// GET /users/:id/following - Get users that a user is following
pub async fn get_user_following(
    Path(user_id): Path<Uuid>,
    State(state): State<UserState>,
) -> Result<Response, AppError> {
    let following = state
        .user_service
        .get_user_following(user_id, 50, 0) // Default pagination
        .await?;

    let following_dtos: Vec<UserDTO> = following.iter().map(user_to_dto).collect();

    Ok((
        StatusCode::OK,
        Json(SuccessResponse::new(
            "Following list retrieved successfully".to_string(),
            Some(serde_json::to_value(following_dtos).unwrap()),
        )),
    )
        .into_response())
}

// GET /users/search?q=query - Search for users
pub async fn search_users(
    axum::extract::Query(params): axum::extract::Query<std::collections::HashMap<String, String>>,
    State(state): State<UserState>,
) -> Result<Response, AppError> {
    let query = params
        .get("q")
        .ok_or_else(|| AppError::BadRequest("Query parameter 'q' is required".to_string()))?;

    let users = state
        .user_service
        .search_users(query, 20, 0) // Default pagination
        .await?;

    let user_dtos: Vec<UserDTO> = users.iter().map(user_to_dto).collect();

    Ok((
        StatusCode::OK,
        Json(SuccessResponse::new(
            "Users found successfully".to_string(),
            Some(serde_json::to_value(user_dtos).unwrap()),
        )),
    )
        .into_response())
}

// GET /users/:follower_id/following/:following_id - Check if user A follows user B
pub async fn check_following_status(
    Path((follower_id, following_id)): Path<(Uuid, Uuid)>,
    State(state): State<UserState>,
) -> Result<Response, AppError> {
    let is_following = state
        .user_service
        .is_following(follower_id, following_id)
        .await?;

    let response = serde_json::json!({
        "success": true,
        "is_following": is_following
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
        email_verified: user.email_verified,
        phone_verified: user.phone_verified,
        follower_count: user.follower_count,
        following_count: user.following_count,
        created_at: user.created_at,
    }
}
