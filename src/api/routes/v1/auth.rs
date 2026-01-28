use crate::server::AppState;
use axum::Router;

/// Create authentication routes
///
/// Routes:
/// - POST /auth/register - Register a new user
/// - POST /auth/login - Login and get JWT token
/// - POST /auth/refresh - Refresh JWT token
/// - POST /auth/logout - Logout (invalidate token)
pub fn create_router(_state: AppState) -> Router {
    // TODO: Implement authentication routes
    // This will be implemented when auth handlers are created
    Router::new()
}
