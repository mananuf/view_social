use crate::api::dto::{
    PaginatedResponse, SetPinRequest, SuccessResponse, TransactionDTO, TransferRequest, WalletDTO,
};
use crate::api::middleware::AuthUser;
use crate::api::user_handlers::user_to_dto;
use crate::domain::entities::{CreateTransactionRequest, Transaction, TransactionType, Wallet};
use crate::domain::errors::AppError;
use crate::domain::repositories::{UserRepository, WalletRepository};
use axum::{
    extract::{Query, State},
    http::StatusCode,
    response::{IntoResponse, Response},
    Json,
};
use rust_decimal::Decimal;
use serde::Deserialize;
use std::str::FromStr;
use std::sync::Arc;

// Application state for payment handlers
#[derive(Clone)]
pub struct PaymentState {
    pub wallet_repo: Arc<dyn WalletRepository>,
    pub user_repo: Arc<dyn UserRepository>,
}

// Query parameters for transaction history
#[derive(Debug, Deserialize)]
pub struct TransactionQuery {
    #[serde(default = "default_limit")]
    pub limit: i64,
    #[serde(default)]
    pub offset: i64,
}

fn default_limit() -> i64 {
    20
}

// GET /wallet - Get wallet information
pub async fn get_wallet(
    auth_user: AuthUser,
    State(state): State<PaymentState>,
) -> Result<Response, AppError> {
    let wallet = state
        .wallet_repo
        .find_by_user_id(auth_user.user_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Wallet not found".to_string()))?;

    let wallet_dto = wallet_to_dto(&wallet);

    Ok((StatusCode::OK, Json(SuccessResponse::new(wallet_dto))).into_response())
}

// POST /wallet/pin - Set or update wallet PIN
pub async fn set_wallet_pin(
    auth_user: AuthUser,
    State(state): State<PaymentState>,
    Json(payload): Json<SetPinRequest>,
) -> Result<Response, AppError> {
    // Validate PIN confirmation
    if payload.pin != payload.confirm_pin {
        return Err(AppError::ValidationError(
            "PIN and confirmation do not match".to_string(),
        ));
    }

    // Get wallet
    let mut wallet = state
        .wallet_repo
        .find_by_user_id(auth_user.user_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Wallet not found".to_string()))?;

    // Set PIN
    wallet.set_pin(payload.pin)?;

    // Update wallet
    let updated_wallet = state.wallet_repo.update(&wallet).await?;

    let wallet_dto = wallet_to_dto(&updated_wallet);

    Ok((StatusCode::OK, Json(SuccessResponse::new(wallet_dto))).into_response())
}

// POST /transfers - Create money transfer
pub async fn create_transfer(
    auth_user: AuthUser,
    State(state): State<PaymentState>,
    Json(payload): Json<TransferRequest>,
) -> Result<Response, AppError> {
    // Validate amount
    let amount = Decimal::from_str(&payload.amount)
        .map_err(|_| AppError::ValidationError("Invalid amount format".to_string()))?;

    if amount <= Decimal::ZERO {
        return Err(AppError::ValidationError(
            "Amount must be positive".to_string(),
        ));
    }

    // Get sender wallet
    let sender_wallet = state
        .wallet_repo
        .find_by_user_id(auth_user.user_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Sender wallet not found".to_string()))?;

    // Verify PIN
    if !sender_wallet.verify_pin(&payload.pin)? {
        return Err(AppError::AuthenticationError("Invalid PIN".to_string()));
    }

    // Check if sender has sufficient balance
    if !sender_wallet.has_sufficient_balance(amount) {
        return Err(AppError::InsufficientFunds);
    }

    // Get receiver wallet
    let receiver_wallet = state
        .wallet_repo
        .find_by_user_id(payload.receiver_user_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Receiver wallet not found".to_string()))?;

    // Prevent self-transfer
    if sender_wallet.id == receiver_wallet.id {
        return Err(AppError::ValidationError(
            "Cannot transfer to yourself".to_string(),
        ));
    }

    // Create transaction
    let transaction_request = CreateTransactionRequest {
        sender_wallet_id: Some(sender_wallet.id),
        receiver_wallet_id: Some(receiver_wallet.id),
        transaction_type: TransactionType::Transfer,
        amount,
        currency: "NGN".to_string(),
        description: payload.description,
    };

    let transaction = Transaction::new(transaction_request)?;

    // Process transfer atomically
    let completed_transaction = state
        .wallet_repo
        .process_transfer(sender_wallet.id, receiver_wallet.id, amount, &transaction)
        .await?;

    // Get sender and receiver user info for response
    let sender_user = state
        .user_repo
        .find_by_id(auth_user.user_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Sender user not found".to_string()))?;

    let receiver_user = state
        .user_repo
        .find_by_id(payload.receiver_user_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Receiver user not found".to_string()))?;

    let transaction_dto = transaction_to_dto(
        &completed_transaction,
        Some(&sender_user),
        Some(&receiver_user),
    );

    Ok((
        StatusCode::CREATED,
        Json(SuccessResponse::new(transaction_dto)),
    )
        .into_response())
}

// GET /transactions - Get transaction history
pub async fn get_transaction_history(
    auth_user: AuthUser,
    State(state): State<PaymentState>,
    Query(params): Query<TransactionQuery>,
) -> Result<Response, AppError> {
    // Get user's wallet
    let wallet = state
        .wallet_repo
        .find_by_user_id(auth_user.user_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Wallet not found".to_string()))?;

    // Get transaction history
    let transactions = state
        .wallet_repo
        .get_transaction_history(wallet.id, params.limit, params.offset)
        .await?;

    // Convert transactions to DTOs with user information
    let mut transaction_dtos = Vec::new();
    for transaction in &transactions {
        // Get sender user if exists
        let sender_user = if let Some(sender_wallet_id) = transaction.sender_wallet_id {
            let sender_wallet = state.wallet_repo.find_by_id(sender_wallet_id).await?;
            if let Some(sw) = sender_wallet {
                state.user_repo.find_by_id(sw.user_id).await?
            } else {
                None
            }
        } else {
            None
        };

        // Get receiver user if exists
        let receiver_user = if let Some(receiver_wallet_id) = transaction.receiver_wallet_id {
            let receiver_wallet = state.wallet_repo.find_by_id(receiver_wallet_id).await?;
            if let Some(rw) = receiver_wallet {
                state.user_repo.find_by_id(rw.user_id).await?
            } else {
                None
            }
        } else {
            None
        };

        transaction_dtos.push(transaction_to_dto(
            transaction,
            sender_user.as_ref(),
            receiver_user.as_ref(),
        ));
    }

    // For pagination, we would need to count total transactions
    // For now, we'll use a simple approach
    let total = transaction_dtos.len() as i64;

    let response = PaginatedResponse::new(transaction_dtos, total, params.limit, params.offset);

    Ok((StatusCode::OK, Json(response)).into_response())
}

// Helper function to convert Wallet entity to WalletDTO
fn wallet_to_dto(wallet: &Wallet) -> WalletDTO {
    WalletDTO {
        id: wallet.id,
        user_id: wallet.user_id,
        balance: wallet.balance.to_string(),
        currency: wallet.currency.clone(),
        status: format!("{:?}", wallet.status),
        has_pin: wallet.pin_hash.is_some(),
        created_at: wallet.created_at,
    }
}

// Helper function to convert Transaction entity to TransactionDTO
fn transaction_to_dto(
    transaction: &Transaction,
    sender_user: Option<&crate::domain::entities::User>,
    receiver_user: Option<&crate::domain::entities::User>,
) -> TransactionDTO {
    TransactionDTO {
        id: transaction.id,
        sender: sender_user.map(user_to_dto),
        receiver: receiver_user.map(user_to_dto),
        transaction_type: format!("{:?}", transaction.transaction_type),
        amount: transaction.amount.to_string(),
        currency: transaction.currency.clone(),
        status: format!("{:?}", transaction.status),
        description: transaction.description.clone(),
        reference: transaction.reference.clone(),
        created_at: transaction.created_at,
    }
}
