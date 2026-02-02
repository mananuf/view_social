use crate::api::handlers::auth_handlers::{
    login, logout, refresh_token, register, resend_verification_code, verify_registration,
};
use crate::server::AppState;
use axum::{routing::post, Router};

/// Create authentication routes
///
/// Routes:
/// - POST /auth/register - Register a new user
/// - POST /auth/verify - Verify registration code
/// - POST /auth/login - Login and get JWT token
/// - POST /auth/refresh - Refresh JWT token
/// - POST /auth/logout - Logout (invalidate token)
/// - POST /auth/resend - Resend verification code
pub fn create_router(state: AppState) -> Router {
    Router::new()
        .route("/register", post(register))
        .route("/verify", post(verify_registration))
        .route("/login", post(login))
        .route("/refresh", post(refresh_token))
        .route("/logout", post(logout))
        .route("/resend", post(resend_verification_code))
        .with_state(state.auth_state)
}
