use crate::api::middleware::auth_middleware;
use crate::api::websocket::ws_handler;
use crate::server::AppState;
use axum::{middleware, routing::get, Router};

/// Create WebSocket routes
///
/// Protected routes (require authentication):
/// - GET /ws - WebSocket connection endpoint for real-time features
pub fn create_router(state: AppState) -> Router {
    Router::new()
        .route("/ws", get(ws_handler))
        .layer(middleware::from_fn_with_state(
            state.auth_state,
            auth_middleware,
        ))
        .with_state(state.ws_state)
}
