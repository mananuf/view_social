use axum::{routing::get, Json, Router};
use serde::{Deserialize, Serialize};

/// Health check response
#[derive(Debug, Serialize, Deserialize)]
pub struct HealthResponse {
    pub status: String,
    pub version: String,
}

/// Create health check routes
pub fn create_router() -> Router {
    Router::new().route("/health", get(health_check))
}

/// Health check endpoint
///
/// Returns the health status of the API
async fn health_check() -> Json<HealthResponse> {
    Json(HealthResponse {
        status: "OK".to_string(),
        version: "v1".to_string(),
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use axum::http::StatusCode;
    use axum_test::TestServer;

    #[tokio::test]
    async fn test_health_check() {
        let app = create_router();
        let server = TestServer::new(app).unwrap();

        let response = server.get("/health").await;
        assert_eq!(response.status_code(), StatusCode::OK);

        let health: HealthResponse = response.json();
        assert_eq!(health.status, "OK");
        assert_eq!(health.version, "v1");
    }
}
