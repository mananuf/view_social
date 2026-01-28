use crate::api::middleware::auth_middleware;
use crate::api::post_handlers::{
    create_comment, create_post, get_feed, get_post_comments, like_post, unlike_post,
};
use crate::server::AppState;
use axum::{
    middleware,
    routing::{delete, get, post},
    Router,
};

/// Create post-related routes
///
/// Protected routes (require authentication):
/// - GET /posts/feed - Get user's personalized feed
/// - POST /posts - Create a new post
/// - POST /posts/:id/like - Like a post
/// - DELETE /posts/:id/like - Unlike a post
/// - POST /posts/:id/comments - Add a comment to a post
///
/// Public routes:
/// - GET /posts/:id/comments - Get comments for a post
pub fn create_router(state: AppState) -> Router {
    let protected = Router::new()
        .route("/posts/feed", get(get_feed))
        .route("/posts", post(create_post))
        .route("/posts/:id/like", post(like_post))
        .route("/posts/:id/like", delete(unlike_post))
        .route("/posts/:id/comments", post(create_comment))
        .layer(middleware::from_fn_with_state(
            state.auth_state.clone(),
            auth_middleware,
        ))
        .with_state(state.post_state.clone());

    let public = Router::new()
        .route("/posts/:id/comments", get(get_post_comments))
        .with_state(state.post_state);

    Router::new().merge(protected).merge(public)
}
