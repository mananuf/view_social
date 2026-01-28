use axum::{
    routing::{get, post, delete},
    Router,
    middleware,
};
use std::net::SocketAddr;
use std::sync::Arc;
use tower_http::cors::CorsLayer;
use tracing_subscriber;

mod domain;
mod infrastructure;
mod application;
mod api;
mod config;

use config::Config;
use domain::auth::JwtService;
use infrastructure::database::{PostgresPostRepository, PostgresUserRepository, PostgresConversationRepository, PostgresMessageRepository, PostgresWalletRepository};
use api::post_handlers::{PostState, get_feed, create_post, like_post, unlike_post, get_post_comments, create_comment};
use api::message_handlers::{MessageState, get_conversations, create_conversation, get_messages, send_message};
use api::payment_handlers::{PaymentState, get_wallet, set_wallet_pin, create_transfer, get_transaction_history};
use api::middleware::{AuthState, auth_middleware};
use api::websocket::{WebSocketState, ws_handler};

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // Initialize tracing
    tracing_subscriber::fmt::init();

    // Load configuration
    let config = Config::from_env()?;

    // Initialize database connection pool
    let database_url = std::env::var("DATABASE_URL")
        .unwrap_or_else(|_| "postgresql://postgres:postgres@localhost:5432/view_social".to_string());
    
    let pool = sqlx::postgres::PgPoolOptions::new()
        .max_connections(5)
        .connect(&database_url)
        .await?;

    // Initialize JWT service
    let jwt_secret = std::env::var("JWT_SECRET")
        .unwrap_or_else(|_| "your-secret-key-change-in-production".to_string());
    let jwt_service = JwtService::new(&jwt_secret);
    let auth_state = AuthState::new(jwt_service);

    // Initialize repositories
    let post_repo = Arc::new(PostgresPostRepository::new(pool.clone())) as Arc<dyn domain::repositories::PostRepository>;
    let user_repo = Arc::new(PostgresUserRepository::new(pool.clone())) as Arc<dyn domain::repositories::UserRepository>;
    let conversation_repo = Arc::new(PostgresConversationRepository::new(pool.clone())) as Arc<dyn domain::repositories::ConversationRepository>;
    let message_repo = Arc::new(PostgresMessageRepository::new(pool.clone())) as Arc<dyn domain::repositories::MessageRepository>;
    let wallet_repo = Arc::new(PostgresWalletRepository::new(pool.clone())) as Arc<dyn domain::repositories::WalletRepository>;

    // Create post state
    let post_state = PostState {
        post_repo,
        user_repo: user_repo.clone(),
    };

    // Create message state
    let message_state = MessageState {
        conversation_repo,
        message_repo,
        user_repo: user_repo.clone(),
    };

    // Create payment state
    let payment_state = PaymentState {
        wallet_repo,
        user_repo: user_repo.clone(),
    };

    // Create WebSocket state and start cleanup task
    let ws_state = WebSocketState::new();
    ws_state.start_cleanup_task();

    // Build application router with authentication
    let protected_routes = Router::new()
        // Post routes
        .route("/posts/feed", get(get_feed))
        .route("/posts", post(create_post))
        .route("/posts/:id/like", post(like_post))
        .route("/posts/:id/like", delete(unlike_post))
        .route("/posts/:id/comments", post(create_comment))
        .with_state(post_state.clone())
        // Messaging routes
        .route("/conversations", get(get_conversations))
        .route("/conversations", post(create_conversation))
        .route("/conversations/:id/messages", get(get_messages))
        .route("/conversations/:id/messages", post(send_message))
        .with_state(message_state.clone())
        // Payment routes
        .route("/wallet", get(get_wallet))
        .route("/wallet/pin", post(set_wallet_pin))
        .route("/transfers", post(create_transfer))
        .route("/transactions", get(get_transaction_history))
        .with_state(payment_state.clone())
        // WebSocket route
        .route("/ws", get(ws_handler))
        .with_state(ws_state)
        .layer(middleware::from_fn_with_state(auth_state.clone(), auth_middleware));

    // Public routes (no authentication required)
    let public_routes = Router::new()
        .route("/health", get(health_check))
        .route("/posts/:id/comments", get(get_post_comments))
        .with_state(post_state);

    // Combine routes
    let app = Router::new()
        .merge(protected_routes)
        .merge(public_routes)
        .layer(CorsLayer::permissive());

    // Start server
    let addr = SocketAddr::from(([0, 0, 0, 0], config.port));
    tracing::info!("Server starting on {}", addr);
    
    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}

async fn health_check() -> &'static str {
    "OK"
}