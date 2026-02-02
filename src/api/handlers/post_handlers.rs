use crate::api::dto::common::{PaginatedResponse, SuccessResponse};
use crate::api::dto::post::{CreatePostRequest, MediaAttachmentDTO, PostDTO};
use crate::api::handlers::user_handlers::user_to_dto;
use crate::api::middleware::auth::AuthUser;
use crate::domain::entities::{
    CreatePostRequest as DomainCreatePostRequest, MediaAttachment, Post, PostContentType,
    PostVisibility,
};
use crate::domain::errors::AppError;
use crate::domain::repositories::{PostRepository, UserRepository};
use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    response::{IntoResponse, Response},
    Json,
};
use serde::Deserialize;
use std::sync::Arc;
use uuid::Uuid;

// Application state for post handlers
#[derive(Clone)]
pub struct PostState {
    pub post_repo: Arc<dyn PostRepository>,
    pub user_repo: Arc<dyn UserRepository>,
}

#[derive(Debug, Deserialize)]
pub struct FeedQuery {
    #[serde(default = "default_limit")]
    pub limit: i64,
    #[serde(default)]
    pub offset: i64,
}

fn default_limit() -> i64 {
    20
}

// GET /posts/feed - Get user feed
pub async fn get_feed(
    auth_user: AuthUser,
    Query(query): Query<FeedQuery>,
    State(state): State<PostState>,
) -> Result<Response, AppError> {
    // Validate pagination parameters
    let limit = query.limit.min(100).max(1);
    let offset = query.offset.max(0);

    // Get posts from followed users
    let posts = state
        .post_repo
        .find_feed(auth_user.user_id, limit, offset)
        .await?;

    // Convert posts to DTOs
    let mut post_dtos = Vec::new();
    for post in posts {
        // Get post author
        let author = state
            .user_repo
            .find_by_id(post.user_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Post author not found".to_string()))?;

        // Check if current user has liked the post
        let is_liked = state
            .post_repo
            .has_user_liked(auth_user.user_id, post.id)
            .await?;

        post_dtos.push(post_to_dto(&post, &author, is_liked));
    }

    // For simplicity, we'll return the posts without total count
    // In a real implementation, we'd query the total count separately
    let response = PaginatedResponse::new(post_dtos, 0, limit, offset);

    Ok((StatusCode::OK, Json(response)).into_response())
}

// POST /posts - Create a new post
pub async fn create_post(
    auth_user: AuthUser,
    State(state): State<PostState>,
    Json(payload): Json<CreatePostRequest>,
) -> Result<Response, AppError> {
    // Convert DTO media attachments to domain entities
    let mut media_attachments = Vec::new();
    for media_dto in payload.media_attachments {
        let media = MediaAttachment::new(
            media_dto.url,
            media_dto.media_type,
            media_dto.size,
            media_dto.width,
            media_dto.height,
            media_dto.duration,
        )?;
        media_attachments.push(media);
    }

    // Parse visibility
    let visibility = match payload.visibility.as_str() {
        "public" => PostVisibility::Public,
        "followers" => PostVisibility::Followers,
        "private" => PostVisibility::Private,
        _ => {
            return Err(AppError::ValidationError(
                "Invalid visibility value".to_string(),
            ))
        }
    };

    // Create post
    let post_request = DomainCreatePostRequest {
        user_id: auth_user.user_id,
        text_content: payload.text_content,
        media_attachments,
        is_reel: payload.is_reel,
        visibility,
    };

    let post = Post::new(post_request)?;
    let created_post = state.post_repo.create(&post).await?;

    // Get post author
    let author = state
        .user_repo
        .find_by_id(auth_user.user_id)
        .await?
        .ok_or_else(|| AppError::NotFound("User not found".to_string()))?;

    let post_dto = post_to_dto(&created_post, &author, false);

    Ok((
        StatusCode::CREATED,
        Json(SuccessResponse::new(
            "Post created successfully".to_string(),
            Some(serde_json::to_value(post_dto).unwrap()),
        )),
    )
        .into_response())
}

// POST /posts/:id/like - Like a post
pub async fn like_post(
    auth_user: AuthUser,
    Path(post_id): Path<Uuid>,
    State(state): State<PostState>,
) -> Result<Response, AppError> {
    // Check if post exists
    let _post = state
        .post_repo
        .find_by_id(post_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Post not found".to_string()))?;

    // Check if already liked
    if state
        .post_repo
        .has_user_liked(auth_user.user_id, post_id)
        .await?
    {
        return Err(AppError::Conflict("Post already liked".to_string()));
    }

    // Like the post
    state
        .post_repo
        .like_post(auth_user.user_id, post_id)
        .await?;
    state.post_repo.increment_like_count(post_id).await?;

    let response = serde_json::json!({
        "success": true,
        "message": "Post liked successfully"
    });

    Ok((StatusCode::OK, Json(response)).into_response())
}

// DELETE /posts/:id/like - Unlike a post
pub async fn unlike_post(
    auth_user: AuthUser,
    Path(post_id): Path<Uuid>,
    State(state): State<PostState>,
) -> Result<Response, AppError> {
    // Check if post exists
    let _post = state
        .post_repo
        .find_by_id(post_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Post not found".to_string()))?;

    // Check if currently liked
    if !state
        .post_repo
        .has_user_liked(auth_user.user_id, post_id)
        .await?
    {
        return Err(AppError::BadRequest("Post not liked".to_string()));
    }

    // Unlike the post
    state
        .post_repo
        .unlike_post(auth_user.user_id, post_id)
        .await?;
    state.post_repo.decrement_like_count(post_id).await?;

    let response = serde_json::json!({
        "success": true,
        "message": "Post unliked successfully"
    });

    Ok((StatusCode::OK, Json(response)).into_response())
}

// GET /posts/:id/comments - Get post comments (placeholder)
pub async fn get_post_comments(
    Path(post_id): Path<Uuid>,
    State(state): State<PostState>,
) -> Result<Response, AppError> {
    // Check if post exists
    let _post = state
        .post_repo
        .find_by_id(post_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Post not found".to_string()))?;

    // For MVP, return empty comments list
    // Full comment implementation would be in a later task
    let response = PaginatedResponse::new(Vec::<serde_json::Value>::new(), 0, 20, 0);

    Ok((StatusCode::OK, Json(response)).into_response())
}

// POST /posts/:id/comments - Add a comment (placeholder)
pub async fn create_comment(
    _auth_user: AuthUser,
    Path(_post_id): Path<Uuid>,
    State(state): State<PostState>,
    Json(_payload): Json<serde_json::Value>,
) -> Result<Response, AppError> {
    // Check if post exists
    let _post = state
        .post_repo
        .find_by_id(_post_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Post not found".to_string()))?;

    // For MVP, return a placeholder response
    // Full comment implementation would be in a later task
    let response = serde_json::json!({
        "success": true,
        "message": "Comment feature coming soon"
    });

    Ok((StatusCode::OK, Json(response)).into_response())
}

// Helper function to convert Post entity to PostDTO
fn post_to_dto(post: &Post, author: &crate::domain::entities::User, is_liked: bool) -> PostDTO {
    let content_type = match post.content_type {
        PostContentType::Text => "text",
        PostContentType::Image => "image",
        PostContentType::Video => "video",
        PostContentType::Mixed => "mixed",
    };

    let visibility = match post.visibility {
        PostVisibility::Public => "public",
        PostVisibility::Followers => "followers",
        PostVisibility::Private => "private",
    };

    let media_attachments = post
        .media_attachments
        .iter()
        .map(|media| MediaAttachmentDTO {
            url: media.url.clone(),
            media_type: media.media_type.clone(),
            size: media.size,
            width: media.width,
            height: media.height,
            duration: media.duration,
        })
        .collect();

    PostDTO {
        id: post.id,
        user: user_to_dto(author),
        content_type: content_type.to_string(),
        text_content: post.text_content.clone(),
        media_attachments,
        is_reel: post.is_reel,
        visibility: visibility.to_string(),
        like_count: post.like_count,
        comment_count: post.comment_count,
        reshare_count: post.reshare_count,
        is_liked,
        created_at: post.created_at,
    }
}
