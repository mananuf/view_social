use crate::api::handlers::payment_handlers::{
    create_transfer, get_transaction_history, get_wallet, send_payment_request, set_wallet_pin,
};
use crate::api::middleware::auth::auth_middleware;
use crate::server::AppState;
use axum::{
    middleware,
    routing::{get, post},
    Router,
};

/// Create payment-related routes
///
/// All routes require authentication:
/// - GET /wallet - Get user's wallet information
/// - POST /wallet/pin - Set or update wallet PIN
/// - POST /transfers - Create a money transfer
/// - GET /transactions - Get transaction history
/// - POST /payment-requests - Send payment request notification
pub fn create_router(state: AppState) -> Router {
    Router::new()
        .route("/wallet", get(get_wallet))
        .route("/wallet/pin", post(set_wallet_pin))
        .route("/transfers", post(create_transfer))
        .route("/transactions", get(get_transaction_history))
        .route("/payment-requests", post(send_payment_request))
        .layer(middleware::from_fn_with_state(
            state.auth_state.clone(),
            auth_middleware,
        ))
        .with_state(state.payment_state)
}
