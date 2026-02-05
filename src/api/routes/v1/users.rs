use crate::api::handlers::user_handlers::{
    check_following_status, follow_user, get_current_user, get_user_by_id, get_user_followers,
    get_user_following, search_users, unfollow_user, update_current_user,
};
use crate::api::middleware::auth::auth_middleware;
use crate::server::AppState;
use axum::{
    middleware,
    routing::{delete, get, post, put},
    Router,
};

/// User routes
///
/// All routes require authentication except public profile views:
/// - GET /users/me - Get current user profile
/// - PUT /users/me - Update current user profile
/// - GET /users/search - Search for users
/// - GET /users/:id - Get public user profile
/// - POST /users/:id/follow - Follow a user
/// - DELETE /users/:id/follow - Unfollow a user
/// - GET /users/:id/followers - Get user's followers
/// - GET /users/:id/following - Get users that a user is following
/// - GET /users/:follower_id/following/:following_id - Check if user A follows user B
pub fn create_router(state: AppState) -> Router {
    Router::new()
        .route("/users/me", get(get_current_user))
        .route("/users/me", put(update_current_user))
        .route("/users/search", get(search_users))
        .route("/users/:id", get(get_user_by_id))
        .route("/users/:id/follow", post(follow_user))
        .route("/users/:id/follow", delete(unfollow_user))
        .route("/users/:id/followers", get(get_user_followers))
        .route("/users/:id/following", get(get_user_following))
        .route(
            "/users/:follower_id/following/:following_id",
            get(check_following_status),
        )
        .with_state(state.user_state.clone())
        .layer(middleware::from_fn_with_state(
            state.auth_state.clone(),
            auth_middleware,
        ))
}
