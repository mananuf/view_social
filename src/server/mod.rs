pub mod config;
pub mod router;
pub mod state;

use crate::config::Config;
use anyhow::Result;
use axum::Router;
use std::net::SocketAddr;
use tower_http::cors::CorsLayer;

pub use state::AppState;

/// Main server struct responsible for application lifecycle
pub struct Server {
    config: Config,
    state: AppState,
}

impl Server {
    /// Create a new server instance with the given configuration
    pub async fn new(config: Config) -> Result<Self> {
        // Initialize application state from configuration
        let state = AppState::from_config(&config).await?;

        Ok(Self { config, state })
    }

    /// Run the server
    pub async fn run(self) -> Result<()> {
        // Build the application router
        let app = self.build_router();

        // Create socket address
        let addr = SocketAddr::from(([0, 0, 0, 0], self.config.port));
        tracing::info!("🚀 Server starting on {}", addr);
        tracing::info!(
            "📡 Health check: http://{}:{}/api/v1/health",
            addr.ip(),
            addr.port()
        );
        tracing::info!("🔌 WebSocket: ws://{}:{}/api/v1/ws", addr.ip(), addr.port());

        // Start the server
        let listener = tokio::net::TcpListener::bind(addr).await?;
        axum::serve(listener, app).await?;

        Ok(())
    }

    /// Build the application router with all routes and middleware
    fn build_router(&self) -> Router {
        router::create_router(self.state.clone()).layer(CorsLayer::permissive())
    }
}
