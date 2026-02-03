use crate::api::handlers::auth_handlers::AuthState;
use crate::api::handlers::message_handlers::MessageState;
use crate::api::handlers::notification_handlers::NotificationState;
use crate::api::handlers::payment_handlers::PaymentState;
use crate::api::handlers::post_handlers::PostState;
use crate::api::websocket::WebSocketState;
use crate::application::services::NotificationService;
use crate::application::verification::VerificationService;
use crate::config::Config;
use crate::domain::auth::JwtService;
use crate::infrastructure::database::repositories::{
    InMemoryNotificationPreferencesRepository, PostgresConversationRepository,
    PostgresDeviceTokenRepository, PostgresMessageRepository, PostgresNotificationRepository,
    PostgresPostRepository, PostgresUserRepository, PostgresWalletRepository,
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
    pub notification_state: NotificationState,
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

        // Initialize repositories first
        let user_repo = Arc::new(PostgresUserRepository::new(pool.clone()))
            as Arc<dyn crate::domain::repositories::UserRepository>;
        let post_repo = Arc::new(PostgresPostRepository::new(pool.clone()))
            as Arc<dyn crate::domain::repositories::PostRepository>;
        let conversation_repo = Arc::new(PostgresConversationRepository::new(pool.clone()))
            as Arc<dyn crate::domain::repositories::ConversationRepository>;
        let message_repo = Arc::new(PostgresMessageRepository::new(pool.clone()))
            as Arc<dyn crate::domain::repositories::MessageRepository>;
        let wallet_repo = Arc::new(PostgresWalletRepository::new(pool.clone()))
            as Arc<dyn crate::domain::repositories::WalletRepository>;

        // Initialize notification repositories
        let notification_repo = Arc::new(PostgresNotificationRepository::new(pool.clone()))
            as Arc<dyn crate::domain::repositories::NotificationRepository>;
        let device_token_repo = Arc::new(PostgresDeviceTokenRepository::new(pool.clone()))
            as Arc<dyn crate::domain::repositories::DeviceTokenRepository>;
        let preferences_repo = Arc::new(InMemoryNotificationPreferencesRepository::new())
            as Arc<dyn crate::domain::repositories::NotificationPreferencesRepository>;

        tracing::info!("✅ Repository layer initialized");

        // Initialize JWT service
        let jwt_service = JwtService::new(&config.jwt_secret);

        // Initialize verification service
        let verification_service =
            Arc::new(VerificationService::new().map_err(|e| {
                anyhow::anyhow!("Failed to initialize verification service: {}", e)
            })?);

        // Initialize auth state
        let auth_state = AuthState::new(user_repo.clone(), jwt_service, verification_service);

        tracing::info!("✅ Authentication and verification services initialized");

        // Create WebSocket state and start cleanup task
        let ws_state = WebSocketState::new();
        ws_state.start_cleanup_task();

        tracing::info!("✅ WebSocket connection manager initialized");

        // Create domain-specific states
        let post_state = PostState {
            post_repo,
            user_repo: user_repo.clone(),
            connection_manager: ws_state.connection_manager.clone(),
        };

        let message_state = MessageState {
            conversation_repo,
            message_repo,
            user_repo: user_repo.clone(),
            connection_manager: ws_state.connection_manager.clone(),
        };

        let payment_state = PaymentState {
            wallet_repo,
            user_repo: user_repo.clone(),
            connection_manager: ws_state.connection_manager.clone(),
        };

        // Initialize notification service
        let notification_service = Arc::new(NotificationService::new(
            notification_repo,
            device_token_repo,
            preferences_repo,
            user_repo.clone(),
        ));

        tracing::info!("✅ Notification service initialized");

        Ok(Self {
            auth_state,
            post_state,
            message_state,
            payment_state,
            notification_state: notification_service,
            ws_state,
        })
    }
}
