use crate::api::message_handlers::MessageState;
use crate::api::middleware::AuthState;
use crate::api::payment_handlers::PaymentState;
use crate::api::post_handlers::PostState;
use crate::api::websocket::WebSocketState;
use crate::config::Config;
use crate::domain::auth::JwtService;
use crate::infrastructure::database::{
    PostgresConversationRepository, PostgresMessageRepository, PostgresPostRepository,
    PostgresUserRepository, PostgresWalletRepository,
};
use anyhow::Result;
use std::sync::Arc;

/// Centralized application state containing all domain-specific states
#[derive(Clone)]
pub struct AppState {
    pub auth_state: AuthState,
    pub post_state: PostState,
    pub message_state: MessageState,
    pub payment_state: PaymentState,
    pub ws_state: WebSocketState,
}

impl AppState {
    /// Create application state from configuration
    pub async fn from_config(config: &Config) -> Result<Self> {
        // Initialize database connection pool
        let pool = sqlx::postgres::PgPoolOptions::new()
            .max_connections(5)
            .connect(&config.database_url)
            .await?;

        tracing::info!("✅ Database connection pool initialized");

        // Initialize JWT service
        let jwt_service = JwtService::new(&config.jwt_secret);
        let auth_state = AuthState::new(jwt_service);

        tracing::info!("✅ JWT authentication service initialized");

        // Initialize repositories
        let post_repo = Arc::new(PostgresPostRepository::new(pool.clone()))
            as Arc<dyn crate::domain::repositories::PostRepository>;
        let user_repo = Arc::new(PostgresUserRepository::new(pool.clone()))
            as Arc<dyn crate::domain::repositories::UserRepository>;
        let conversation_repo = Arc::new(PostgresConversationRepository::new(pool.clone()))
            as Arc<dyn crate::domain::repositories::ConversationRepository>;
        let message_repo = Arc::new(PostgresMessageRepository::new(pool.clone()))
            as Arc<dyn crate::domain::repositories::MessageRepository>;
        let wallet_repo = Arc::new(PostgresWalletRepository::new(pool.clone()))
            as Arc<dyn crate::domain::repositories::WalletRepository>;

        tracing::info!("✅ Repository layer initialized");

        // Create domain-specific states
        let post_state = PostState {
            post_repo,
            user_repo: user_repo.clone(),
        };

        let message_state = MessageState {
            conversation_repo,
            message_repo,
            user_repo: user_repo.clone(),
        };

        let payment_state = PaymentState {
            wallet_repo,
            user_repo: user_repo.clone(),
        };

        // Create WebSocket state and start cleanup task
        let ws_state = WebSocketState::new();
        ws_state.start_cleanup_task();

        tracing::info!("✅ WebSocket connection manager initialized");

        Ok(Self {
            auth_state,
            post_state,
            message_state,
            payment_state,
            ws_state,
        })
    }
}
