use crate::domain::auth::JwtService;
use crate::domain::errors::AppError;
use axum::{
    extract::{Request, State},
    http::{header, StatusCode},
    middleware::Next,
    response::{IntoResponse, Response},
    Json,
};
use serde_json::json;
use std::sync::Arc;
use uuid::Uuid;

#[derive(Clone)]
pub struct AuthState {
    pub jwt_service: Arc<JwtService>,
}

impl AuthState {
    pub fn new(jwt_service: JwtService) -> Self {
        Self {
            jwt_service: Arc::new(jwt_service),
        }
    }
}

// Extension type to store authenticated user ID in request
#[derive(Clone, Debug)]
pub struct AuthenticatedUser {
    pub user_id: Uuid,
}

pub async fn auth_middleware(
    State(auth_state): State<AuthState>,
    mut request: Request,
    next: Next,
) -> Result<Response, AuthError> {
    // Extract authorization header
    let auth_header = request
        .headers()
        .get(header::AUTHORIZATION)
        .and_then(|h| h.to_str().ok())
        .ok_or(AuthError::MissingToken)?;

    // Check for Bearer token format
    if !auth_header.starts_with("Bearer ") {
        return Err(AuthError::InvalidTokenFormat);
    }

    let token = &auth_header[7..]; // Remove "Bearer " prefix

    // Validate token and extract user ID
    let user_id = auth_state
        .jwt_service
        .validate_access_token(token)
        .map_err(|_| AuthError::InvalidToken)?;

    // Insert authenticated user into request extensions
    request
        .extensions_mut()
        .insert(AuthenticatedUser { user_id });

    Ok(next.run(request).await)
}

// Optional authentication middleware (doesn't fail if no token)
pub async fn optional_auth_middleware(
    State(auth_state): State<AuthState>,
    mut request: Request,
    next: Next,
) -> Response {
    // Try to extract authorization header
    if let Some(auth_header) = request
        .headers()
        .get(header::AUTHORIZATION)
        .and_then(|h| h.to_str().ok())
    {
        // Check for Bearer token format
        if auth_header.starts_with("Bearer ") {
            let token = &auth_header[7..];

            // Try to validate token
            if let Ok(user_id) = auth_state.jwt_service.validate_access_token(token) {
                request
                    .extensions_mut()
                    .insert(AuthenticatedUser { user_id });
            }
        }
    }

    next.run(request).await
}

#[derive(Debug)]
pub enum AuthError {
    MissingToken,
    InvalidTokenFormat,
    InvalidToken,
}

impl IntoResponse for AuthError {
    fn into_response(self) -> Response {
        let (status, error_code, message) = match self {
            AuthError::MissingToken => (
                StatusCode::UNAUTHORIZED,
                "MISSING_TOKEN",
                "Authorization token is required",
            ),
            AuthError::InvalidTokenFormat => (
                StatusCode::UNAUTHORIZED,
                "INVALID_TOKEN_FORMAT",
                "Authorization header must be in format: Bearer <token>",
            ),
            AuthError::InvalidToken => (
                StatusCode::UNAUTHORIZED,
                "INVALID_TOKEN",
                "Invalid or expired token",
            ),
        };

        let body = Json(json!({
            "error": {
                "code": error_code,
                "message": message,
            }
        }));

        (status, body).into_response()
    }
}

// Helper function to extract authenticated user from request extensions
pub fn get_authenticated_user(request: &Request) -> Result<Uuid, AppError> {
    request
        .extensions()
        .get::<AuthenticatedUser>()
        .map(|user| user.user_id)
        .ok_or(AppError::Unauthorized)
}

// Axum extractor for authenticated user
#[derive(Clone, Debug)]
pub struct AuthUser {
    pub user_id: Uuid,
}

#[axum::async_trait]
impl<S> axum::extract::FromRequestParts<S> for AuthUser
where
    S: Send + Sync,
{
    type Rejection = AppError;

    async fn from_request_parts(
        parts: &mut axum::http::request::Parts,
        _state: &S,
    ) -> Result<Self, Self::Rejection> {
        parts
            .extensions
            .get::<AuthenticatedUser>()
            .map(|user| AuthUser {
                user_id: user.user_id,
            })
            .ok_or(AppError::Unauthorized)
    }
}
