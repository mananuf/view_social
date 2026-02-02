use axum::{
    http::StatusCode,
    response::{IntoResponse, Response},
    Json,
};
use serde_json::json;
use thiserror::Error;

#[derive(Debug, Error)]
pub enum AppError {
    #[error("Database error: {0}")]
    DatabaseError(String),

    #[error("Authentication failed: {0}")]
    AuthenticationError(String),

    #[error("Validation error: {0}")]
    ValidationError(String),

    #[error("Payment error: {0}")]
    PaymentError(String),

    #[error("Not found: {0}")]
    NotFound(String),

    #[error("Insufficient funds")]
    InsufficientFunds,

    #[error("Rate limit exceeded")]
    RateLimitExceeded,

    #[error("Unauthorized access")]
    Unauthorized,

    #[error("Forbidden operation")]
    Forbidden,

    #[error("Conflict: {0}")]
    Conflict(String),

    #[error("Internal server error")]
    InternalServerError,

    #[error("Bad request: {0}")]
    BadRequest(String),

    #[error("Service unavailable")]
    ServiceUnavailable,

    #[error("Timeout error")]
    Timeout,

    #[error("Network error: {0}")]
    NetworkError(String),

    #[error("Serialization error: {0}")]
    SerializationError(String),

    #[error("Configuration error: {0}")]
    ConfigurationError(String),

    #[error("External service error: {0}")]
    ExternalServiceError(String),
}

// Error conversion traits for external libraries
impl From<sqlx::Error> for AppError {
    fn from(err: sqlx::Error) -> Self {
        match err {
            sqlx::Error::RowNotFound => AppError::NotFound("Resource not found".to_string()),
            sqlx::Error::Database(db_err) => {
                if let Some(constraint) = db_err.constraint() {
                    AppError::Conflict(format!("Database constraint violation: {}", constraint))
                } else {
                    AppError::DatabaseError(db_err.to_string())
                }
            }
            _ => AppError::DatabaseError(err.to_string()),
        }
    }
}

impl From<redis::RedisError> for AppError {
    fn from(err: redis::RedisError) -> Self {
        AppError::DatabaseError(format!("Redis error: {}", err))
    }
}

impl From<serde_json::Error> for AppError {
    fn from(err: serde_json::Error) -> Self {
        AppError::SerializationError(err.to_string())
    }
}

impl From<jsonwebtoken::errors::Error> for AppError {
    fn from(err: jsonwebtoken::errors::Error) -> Self {
        AppError::AuthenticationError(format!("JWT error: {}", err))
    }
}

impl From<bcrypt::BcryptError> for AppError {
    fn from(err: bcrypt::BcryptError) -> Self {
        AppError::AuthenticationError(format!("Password hashing error: {}", err))
    }
}

impl From<uuid::Error> for AppError {
    fn from(err: uuid::Error) -> Self {
        AppError::ValidationError(format!("Invalid UUID: {}", err))
    }
}

impl From<std::num::ParseIntError> for AppError {
    fn from(err: std::num::ParseIntError) -> Self {
        AppError::ValidationError(format!("Invalid number format: {}", err))
    }
}

impl From<rust_decimal::Error> for AppError {
    fn from(err: rust_decimal::Error) -> Self {
        AppError::ValidationError(format!("Invalid decimal: {}", err))
    }
}

// Result type alias for consistent error handling
pub type Result<T> = std::result::Result<T, AppError>;

// HTTP status code mapping for API responses
impl AppError {
    pub fn status_code(&self) -> u16 {
        match self {
            AppError::ValidationError(_) | AppError::BadRequest(_) => 400,
            AppError::Unauthorized | AppError::AuthenticationError(_) => 401,
            AppError::Forbidden => 403,
            AppError::NotFound(_) => 404,
            AppError::Conflict(_) => 409,
            AppError::RateLimitExceeded => 429,
            AppError::InternalServerError
            | AppError::DatabaseError(_)
            | AppError::SerializationError(_)
            | AppError::ConfigurationError(_) => 500,
            AppError::ServiceUnavailable => 503,
            AppError::Timeout | AppError::NetworkError(_) => 504,
            AppError::PaymentError(_) => 402,
            AppError::InsufficientFunds => 402,
            AppError::ExternalServiceError(_) => 502,
        }
    }

    pub fn error_code(&self) -> &'static str {
        match self {
            AppError::DatabaseError(_) => "DATABASE_ERROR",
            AppError::AuthenticationError(_) => "AUTHENTICATION_ERROR",
            AppError::ValidationError(_) => "VALIDATION_ERROR",
            AppError::PaymentError(_) => "PAYMENT_ERROR",
            AppError::NotFound(_) => "NOT_FOUND",
            AppError::InsufficientFunds => "INSUFFICIENT_FUNDS",
            AppError::RateLimitExceeded => "RATE_LIMIT_EXCEEDED",
            AppError::Unauthorized => "UNAUTHORIZED",
            AppError::Forbidden => "FORBIDDEN",
            AppError::Conflict(_) => "CONFLICT",
            AppError::InternalServerError => "INTERNAL_SERVER_ERROR",
            AppError::BadRequest(_) => "BAD_REQUEST",
            AppError::ServiceUnavailable => "SERVICE_UNAVAILABLE",
            AppError::Timeout => "TIMEOUT",
            AppError::NetworkError(_) => "NETWORK_ERROR",
            AppError::SerializationError(_) => "SERIALIZATION_ERROR",
            AppError::ConfigurationError(_) => "CONFIGURATION_ERROR",
            AppError::ExternalServiceError(_) => "EXTERNAL_SERVICE_ERROR",
        }
    }
}

// Implement IntoResponse for AppError to make it work with Axum
impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        let status_code =
            StatusCode::from_u16(self.status_code()).unwrap_or(StatusCode::INTERNAL_SERVER_ERROR);

        let body = Json(json!({
            "success": false,
            "error": {
                "code": self.error_code(),
                "message": self.to_string(),
            }
        }));

        (status_code, body).into_response()
    }
}
