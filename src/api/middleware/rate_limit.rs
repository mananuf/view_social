// Rate limiting middleware
use axum::{
    extract::{Request, State},
    http::StatusCode,
    middleware::Next,
    response::{IntoResponse, Response},
    Json,
};
use governor::{Quota, RateLimiter};
use serde_json::json;
use std::{
    collections::HashMap,
    net::IpAddr,
    num::NonZeroU32,
    sync::{Arc, Mutex},
};

pub type SharedRateLimiter = Arc<
    RateLimiter<
        governor::state::NotKeyed,
        governor::state::InMemoryState,
        governor::clock::DefaultClock,
        governor::middleware::NoOpMiddleware,
    >,
>;

#[derive(Clone)]
pub struct RateLimitState {
    pub limiters: Arc<Mutex<HashMap<String, SharedRateLimiter>>>,
}

impl RateLimitState {
    pub fn new() -> Self {
        Self {
            limiters: Arc::new(Mutex::new(HashMap::new())),
        }
    }

    pub fn get_or_create_limiter(&self, key: &str, quota: Quota) -> SharedRateLimiter {
        let mut limiters = self.limiters.lock().unwrap();
        limiters
            .entry(key.to_string())
            .or_insert_with(|| Arc::new(RateLimiter::direct(quota)))
            .clone()
    }
}

impl Default for RateLimitState {
    fn default() -> Self {
        Self::new()
    }
}

pub async fn rate_limit_middleware(
    State(rate_limit_state): State<RateLimitState>,
    request: Request,
    next: Next,
) -> Result<Response, RateLimitError> {
    // Extract client IP
    let client_ip = extract_client_ip(&request);
    let key = format!("ip:{}", client_ip);

    // Create quota: 100 requests per minute
    let quota = Quota::per_minute(NonZeroU32::new(100).unwrap());
    let limiter = rate_limit_state.get_or_create_limiter(&key, quota);

    // Check rate limit
    match limiter.check() {
        Ok(_) => Ok(next.run(request).await),
        Err(_) => Err(RateLimitError::RateLimitExceeded),
    }
}

pub async fn auth_rate_limit_middleware(
    State(rate_limit_state): State<RateLimitState>,
    request: Request,
    next: Next,
) -> Result<Response, RateLimitError> {
    // Extract client IP
    let client_ip = extract_client_ip(&request);
    let key = format!("auth:{}", client_ip);

    // Create stricter quota for auth endpoints: 10 requests per minute
    let quota = Quota::per_minute(NonZeroU32::new(10).unwrap());
    let limiter = rate_limit_state.get_or_create_limiter(&key, quota);

    // Check rate limit
    match limiter.check() {
        Ok(_) => Ok(next.run(request).await),
        Err(_) => Err(RateLimitError::RateLimitExceeded),
    }
}

fn extract_client_ip(request: &Request) -> IpAddr {
    // Try to get IP from X-Forwarded-For header first
    if let Some(forwarded_for) = request.headers().get("x-forwarded-for") {
        if let Ok(forwarded_str) = forwarded_for.to_str() {
            if let Some(first_ip) = forwarded_str.split(',').next() {
                if let Ok(ip) = first_ip.trim().parse::<IpAddr>() {
                    return ip;
                }
            }
        }
    }

    // Try X-Real-IP header
    if let Some(real_ip) = request.headers().get("x-real-ip") {
        if let Ok(ip_str) = real_ip.to_str() {
            if let Ok(ip) = ip_str.parse::<IpAddr>() {
                return ip;
            }
        }
    }

    // Fallback to connection info (this might not work in all setups)
    "127.0.0.1".parse().unwrap()
}

#[derive(Debug)]
pub enum RateLimitError {
    RateLimitExceeded,
}

impl IntoResponse for RateLimitError {
    fn into_response(self) -> Response {
        let (status, error_code, message) = match self {
            RateLimitError::RateLimitExceeded => (
                StatusCode::TOO_MANY_REQUESTS,
                "RATE_LIMIT_EXCEEDED",
                "Too many requests. Please try again later.",
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
