pub mod auth;
pub mod health;
pub mod home;
pub mod messages;
pub mod notifications;
pub mod payments;
pub mod posts;
pub mod websocket;

use crate::server::AppState;
use axum::Router;

/// Create the v1 API router with all versioned routes
pub fn create_router(state: AppState) -> Router {
    Router::new()
        .merge(health::create_router())
        .nest("/auth", auth::create_router(state.clone()))
        .merge(posts::create_router(state.clone()))
        .merge(messages::create_router(state.clone()))
        .merge(payments::create_router(state.clone()))
        .nest(
            "/notifications",
            notifications::create_router(state.notification_state.clone()),
        )
        .merge(websocket::create_router(state.clone()))
        .merge(home::create_router(state))
}
