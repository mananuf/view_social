use crate::domain::errors::AppError;
use axum::{
    extract::{Request, State},
    http::StatusCode,
    middleware::Next,
    response::{IntoResponse, Response},
    Json,
};
use redis::{Client, Commands};
use serde_json::json;
use std::sync::Arc;
use std::time::{SystemTime, UNIX_EPOCH};

const RATE_LIMIT_REQUESTS: u32 = 100;
const RATE_LIMIT_WINDOW_SECONDS: u64 = 60;

#[derive(Clone)]
pub struct RateLimitState {
    redis_client: Arc<Client>,
}

impl RateLimitState {
    pub fn new(redis_url: &str) -> Result<Self, AppError> {
        let client = Client::open(redis_url)
            .map_err(|e| AppError::ConfigurationError(format!("Failed to connect to Redis: {}", e)))?;
        
        Ok(Self {
            redis_client: Arc::new(client),
        })
    }
}

pub async fn rate_limit_middleware(
    State(rate_limit_state): State<RateLimitState>,
    request: Request,
    next: Next,
) -> Result<Response, RateLimitError> {
    // Extract user identifier (IP address or user ID from auth)
    let user_id = extract_user_identifier(&request);
    
    // Check rate limit
    let is_allowed = check_rate_limit(&rate_limit_state.redis_client, &user_id)?;
    
    if !is_allowed {
        return Err(RateLimitError::LimitExceeded);
    }
    
    Ok(next.run(request).await)
}

fn extract_user_identifier(request: &Request) -> String {
    // Try to get authenticated user ID from extensions
    if let Some(auth_user) = request.extensions().get::<crate::api::middleware::AuthenticatedUser>() {
        return format!("user:{}", auth_user.user_id);
    }
    
    // Fall back to IP address
    if let Some(addr) = request
        .headers()
        .get("x-forwarded-for")
        .and_then(|h| h.to_str().ok())
    {
        return format!("ip:{}", addr.split(',').next().unwrap_or(addr).trim());
    }
    
    // Default identifier if nothing else works
    "unknown".to_string()
}

fn check_rate_limit(redis_client: &Client, user_id: &str) -> Result<bool, RateLimitError> {
    let mut conn = redis_client
        .get_connection()
        .map_err(|e| RateLimitError::RedisError(e.to_string()))?;
    
    let current_time = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap()
        .as_secs();
    
    let window_start = current_time - RATE_LIMIT_WINDOW_SECONDS;
    let key = format!("rate_limit:{}:{}", user_id, current_time / RATE_LIMIT_WINDOW_SECONDS);
    
    // Increment request count
    let count: u32 = conn
        .incr(&key, 1)
        .map_err(|e| RateLimitError::RedisError(e.to_string()))?;
    
    // Set expiry on first request
    if count == 1 {
        let _: () = conn
            .expire(&key, RATE_LIMIT_WINDOW_SECONDS as i64)
            .map_err(|e| RateLimitError::RedisError(e.to_string()))?;
    }
    
    Ok(count <= RATE_LIMIT_REQUESTS)
}

pub fn calculate_retry_after(attempt: u32) -> u64 {
    // Exponential backoff: 2^attempt seconds, capped at 300 seconds (5 minutes)
    let backoff = 2u64.pow(attempt).min(300);
    backoff
}

#[derive(Debug)]
pub enum RateLimitError {
    LimitExceeded,
    RedisError(String),
}

impl IntoResponse for RateLimitError {
    fn into_response(self) -> Response {
        let (status, error_code, message, retry_after) = match self {
            RateLimitError::LimitExceeded => (
                StatusCode::TOO_MANY_REQUESTS,
                "RATE_LIMIT_EXCEEDED",
                format!(
                    "Rate limit exceeded. Maximum {} requests per {} seconds allowed.",
                    RATE_LIMIT_REQUESTS, RATE_LIMIT_WINDOW_SECONDS
                ),
                Some(RATE_LIMIT_WINDOW_SECONDS),
            ),
            RateLimitError::RedisError(err) => (
                StatusCode::INTERNAL_SERVER_ERROR,
                "RATE_LIMIT_ERROR",
                format!("Rate limiting service error: {}", err),
                None,
            ),
        };

        let mut response = (
            status,
            Json(json!({
                "error": {
                    "code": error_code,
                    "message": message,
                }
            })),
        )
            .into_response();

        if let Some(retry_after_seconds) = retry_after {
            response.headers_mut().insert(
                "Retry-After",
                retry_after_seconds.to_string().parse().unwrap(),
            );
            response.headers_mut().insert(
                "X-RateLimit-Limit",
                RATE_LIMIT_REQUESTS.to_string().parse().unwrap(),
            );
            response.headers_mut().insert(
                "X-RateLimit-Window",
                RATE_LIMIT_WINDOW_SECONDS.to_string().parse().unwrap(),
            );
        }

        response
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_calculate_retry_after() {
        assert_eq!(calculate_retry_after(0), 1);
        assert_eq!(calculate_retry_after(1), 2);
        assert_eq!(calculate_retry_after(2), 4);
        assert_eq!(calculate_retry_after(3), 8);
        assert_eq!(calculate_retry_after(4), 16);
        assert_eq!(calculate_retry_after(5), 32);
        assert_eq!(calculate_retry_after(6), 64);
        assert_eq!(calculate_retry_after(7), 128);
        assert_eq!(calculate_retry_after(8), 256);
        
        // Should cap at 300 seconds
        assert_eq!(calculate_retry_after(9), 300);
        assert_eq!(calculate_retry_after(10), 300);
        assert_eq!(calculate_retry_after(100), 300);
    }

    #[test]
    fn test_rate_limit_constants() {
        assert_eq!(RATE_LIMIT_REQUESTS, 100);
        assert_eq!(RATE_LIMIT_WINDOW_SECONDS, 60);
    }
}
