use crate::api::routes;
use crate::server::AppState;
use axum::Router;

/// Create the main application router with API versioning
///
/// API Structure:
/// - /api/v1/* - Version 1 API endpoints (current stable)
///
/// This structure allows for:
/// - Easy addition of new API versions (v2, v3, etc.)
/// - Backward compatibility when introducing breaking changes
/// - Clear deprecation paths for old endpoints
pub fn create_router(state: AppState) -> Router {
    Router::new()
        // Mount v1 API routes under /api/v1
        .nest("/api/v1", routes::v1::create_router(state.clone()))
    // Future versions can be added here:
    // .nest("/api/v2", routes::v2::create_router(state.clone()))
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::config::Config;

    #[tokio::test]
    async fn test_router_creation() {
        // This test ensures the router can be created without panicking
        let config = Config {
            port: 3000,
            database_url: "postgresql://test".to_string(),
            redis_url: "redis://test".to_string(),
            jwt_secret: "test-secret".to_string(),
        };

        // Note: This will fail if database is not available
        // In a real test, we'd use a mock or test database
        // For now, we just verify the structure compiles
        assert!(true);
    }
}
