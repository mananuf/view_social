use crate::domain::entities::{
    Transaction, TransactionStatus, TransactionType, Wallet, WalletStatus,
};
use crate::domain::errors::{AppError, Result};
use crate::domain::repositories::WalletRepository;
use crate::infrastructure::database::models::{TransactionModel, WalletModel};
use async_trait::async_trait;
use chrono::Utc;
use rust_decimal::Decimal;
use sqlx::PgPool;
use uuid::Uuid;

/// PostgreSQL implementation of WalletRepository
pub struct PostgresWalletRepository {
    pool: PgPool,
}

impl PostgresWalletRepository {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    fn wallet_to_domain(model: WalletModel) -> Result<Wallet> {
        let status = match model.status.as_str() {
            "active" => WalletStatus::Active,
            "suspended" => WalletStatus::Suspended,
            "locked" => WalletStatus::Locked,
            _ => WalletStatus::Active,
        };

        Ok(Wallet {
            id: model.id,
            user_id: model.user_id,
            balance: model.balance,
            currency: model.currency,
            status,
            pin_hash: model.pin_hash,
            created_at: model.created_at,
            updated_at: model.updated_at,
        })
    }

    fn transaction_to_domain(model: TransactionModel) -> Result<Transaction> {
        let transaction_type = match model.transaction_type.as_str() {
            "transfer" => TransactionType::Transfer,
            "deposit" => TransactionType::Deposit,
            "withdrawal" => TransactionType::Withdrawal,
            _ => TransactionType::Transfer,
        };

        let status = match model.status.as_str() {
            "pending" => TransactionStatus::Pending,
            "completed" => TransactionStatus::Completed,
            "failed" => TransactionStatus::Failed,
            "cancelled" => TransactionStatus::Cancelled,
            _ => TransactionStatus::Pending,
        };

        Ok(Transaction {
            id: model.id,
            sender_wallet_id: model.sender_wallet_id,
            receiver_wallet_id: model.receiver_wallet_id,
            transaction_type,
            amount: model.amount,
            currency: model.currency,
            status,
            description: model.description,
            reference: model.reference,
            created_at: model.created_at,
            updated_at: model.updated_at,
        })
    }
}

#[async_trait]
impl WalletRepository for PostgresWalletRepository {
    async fn create(&self, wallet: &Wallet) -> Result<Wallet> {
        let status_str = match wallet.status {
            WalletStatus::Active => "active",
            WalletStatus::Suspended => "suspended",
            WalletStatus::Locked => "locked",
        };

        let model: WalletModel = sqlx::query_as(
            "INSERT INTO wallets (id, user_id, balance, currency, status, pin_hash, created_at, updated_at)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
            RETURNING *")
            .bind(wallet.id)
            .bind(wallet.user_id)
            .bind(wallet.balance)
            .bind(&wallet.currency)
            .bind(status_str)
            .bind(&wallet.pin_hash)
            .bind(wallet.created_at)
            .bind(wallet.updated_at)
        .fetch_one(&self.pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to create wallet: {}", e)))?;

        Self::wallet_to_domain(model)
    }

    async fn find_by_id(&self, id: Uuid) -> Result<Option<Wallet>> {
        let model: Option<WalletModel> = sqlx::query_as("SELECT * FROM wallets WHERE id = $1")
            .bind(id)
            .fetch_optional(&self.pool)
            .await
            .map_err(|e| AppError::DatabaseError(format!("Failed to find wallet: {}", e)))?;

        model.map(Self::wallet_to_domain).transpose()
    }

    async fn find_by_user_id(&self, user_id: Uuid) -> Result<Option<Wallet>> {
        let model: Option<WalletModel> = sqlx::query_as("SELECT * FROM wallets WHERE user_id = $1")
            .bind(user_id)
            .fetch_optional(&self.pool)
            .await
            .map_err(|e| {
                AppError::DatabaseError(format!("Failed to find wallet by user: {}", e))
            })?;

        model.map(Self::wallet_to_domain).transpose()
    }

    async fn update(&self, wallet: &Wallet) -> Result<Wallet> {
        let status_str = match wallet.status {
            WalletStatus::Active => "active",
            WalletStatus::Suspended => "suspended",
            WalletStatus::Locked => "locked",
        };

        let model: WalletModel = sqlx::query_as(
            "UPDATE wallets
            SET balance = $2, status = $3, pin_hash = $4, updated_at = $5
            WHERE id = $1
            RETURNING *",
        )
        .bind(wallet.id)
        .bind(wallet.balance)
        .bind(status_str)
        .bind(&wallet.pin_hash)
        .bind(Utc::now())
        .fetch_one(&self.pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to update wallet: {}", e)))?;

        Self::wallet_to_domain(model)
    }

    async fn update_balance(&self, wallet_id: Uuid, amount: Decimal) -> Result<()> {
        sqlx::query("UPDATE wallets SET balance = balance + $2, updated_at = $3 WHERE id = $1")
            .bind(wallet_id)
            .bind(amount)
            .bind(Utc::now())
            .execute(&self.pool)
            .await
            .map_err(|e| AppError::DatabaseError(format!("Failed to update balance: {}", e)))?;

        Ok(())
    }

    async fn credit_balance(&self, wallet_id: Uuid, amount: Decimal) -> Result<()> {
        if amount <= Decimal::ZERO {
            return Err(AppError::ValidationError(
                "Credit amount must be positive".to_string(),
            ));
        }

        sqlx::query("UPDATE wallets SET balance = balance + $2, updated_at = $3 WHERE id = $1")
            .bind(wallet_id)
            .bind(amount)
            .bind(Utc::now())
            .execute(&self.pool)
            .await
            .map_err(|e| AppError::DatabaseError(format!("Failed to credit balance: {}", e)))?;

        Ok(())
    }

    async fn debit_balance(&self, wallet_id: Uuid, amount: Decimal) -> Result<()> {
        if amount <= Decimal::ZERO {
            return Err(AppError::ValidationError(
                "Debit amount must be positive".to_string(),
            ));
        }

        let wallet = self
            .find_by_id(wallet_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Wallet not found".to_string()))?;

        if wallet.balance < amount {
            return Err(AppError::InsufficientFunds);
        }

        sqlx::query("UPDATE wallets SET balance = balance - $2, updated_at = $3 WHERE id = $1")
            .bind(wallet_id)
            .bind(amount)
            .bind(Utc::now())
            .execute(&self.pool)
            .await
            .map_err(|e| AppError::DatabaseError(format!("Failed to debit balance: {}", e)))?;

        Ok(())
    }

    async fn get_balance(&self, wallet_id: Uuid) -> Result<Decimal> {
        let row: (Decimal,) = sqlx::query_as("SELECT balance FROM wallets WHERE id = $1")
            .bind(wallet_id)
            .fetch_one(&self.pool)
            .await
            .map_err(|e| AppError::DatabaseError(format!("Failed to get balance: {}", e)))?;

        Ok(row.0)
    }

    async fn has_sufficient_balance(&self, wallet_id: Uuid, amount: Decimal) -> Result<bool> {
        let balance = self.get_balance(wallet_id).await?;
        Ok(balance >= amount)
    }

    async fn lock_wallet(&self, wallet_id: Uuid) -> Result<()> {
        sqlx::query("UPDATE wallets SET status = 'locked', updated_at = $2 WHERE id = $1")
            .bind(wallet_id)
            .bind(Utc::now())
            .execute(&self.pool)
            .await
            .map_err(|e| AppError::DatabaseError(format!("Failed to lock wallet: {}", e)))?;

        Ok(())
    }

    async fn unlock_wallet(&self, wallet_id: Uuid) -> Result<()> {
        sqlx::query("UPDATE wallets SET status = 'active', updated_at = $2 WHERE id = $1")
            .bind(wallet_id)
            .bind(Utc::now())
            .execute(&self.pool)
            .await
            .map_err(|e| AppError::DatabaseError(format!("Failed to unlock wallet: {}", e)))?;

        Ok(())
    }

    async fn create_transaction(&self, transaction: &Transaction) -> Result<Transaction> {
        let transaction_type_str = match transaction.transaction_type {
            TransactionType::Transfer => "transfer",
            TransactionType::Deposit => "deposit",
            TransactionType::Withdrawal => "withdrawal",
        };

        let status_str = match transaction.status {
            TransactionStatus::Pending => "pending",
            TransactionStatus::Completed => "completed",
            TransactionStatus::Failed => "failed",
            TransactionStatus::Cancelled => "cancelled",
        };

        let model: TransactionModel = sqlx::query_as(
            "INSERT INTO transactions (id, sender_wallet_id, receiver_wallet_id, transaction_type, amount, currency, status, description, reference, created_at, updated_at)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
            RETURNING *")
            .bind(transaction.id)
            .bind(transaction.sender_wallet_id)
            .bind(transaction.receiver_wallet_id)
            .bind(transaction_type_str)
            .bind(transaction.amount)
            .bind(&transaction.currency)
            .bind(status_str)
            .bind(&transaction.description)
            .bind(&transaction.reference)
            .bind(transaction.created_at)
            .bind(transaction.updated_at)
        .fetch_one(&self.pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to create transaction: {}", e)))?;

        Self::transaction_to_domain(model)
    }

    async fn find_transaction_by_id(&self, id: Uuid) -> Result<Option<Transaction>> {
        let model: Option<TransactionModel> =
            sqlx::query_as("SELECT * FROM transactions WHERE id = $1")
                .bind(id)
                .fetch_optional(&self.pool)
                .await
                .map_err(|e| {
                    AppError::DatabaseError(format!("Failed to find transaction: {}", e))
                })?;

        model.map(Self::transaction_to_domain).transpose()
    }

    async fn find_transaction_by_reference(&self, reference: &str) -> Result<Option<Transaction>> {
        let model: Option<TransactionModel> =
            sqlx::query_as("SELECT * FROM transactions WHERE reference = $1")
                .bind(reference)
                .fetch_optional(&self.pool)
                .await
                .map_err(|e| {
                    AppError::DatabaseError(format!(
                        "Failed to find transaction by reference: {}",
                        e
                    ))
                })?;

        model.map(Self::transaction_to_domain).transpose()
    }

    async fn update_transaction(&self, transaction: &Transaction) -> Result<Transaction> {
        let transaction_type_str = match transaction.transaction_type {
            TransactionType::Transfer => "transfer",
            TransactionType::Deposit => "deposit",
            TransactionType::Withdrawal => "withdrawal",
        };

        let status_str = match transaction.status {
            TransactionStatus::Pending => "pending",
            TransactionStatus::Completed => "completed",
            TransactionStatus::Failed => "failed",
            TransactionStatus::Cancelled => "cancelled",
        };

        let model: TransactionModel = sqlx::query_as(
            "UPDATE transactions
            SET transaction_type = $2, amount = $3, status = $4, description = $5, updated_at = $6
            WHERE id = $1
            RETURNING *",
        )
        .bind(transaction.id)
        .bind(transaction_type_str)
        .bind(transaction.amount)
        .bind(status_str)
        .bind(&transaction.description)
        .bind(Utc::now())
        .fetch_one(&self.pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to update transaction: {}", e)))?;

        Self::transaction_to_domain(model)
    }

    async fn get_transaction_history(
        &self,
        wallet_id: Uuid,
        limit: i64,
        offset: i64,
    ) -> Result<Vec<Transaction>> {
        let models: Vec<TransactionModel> = sqlx::query_as(
            "SELECT * FROM transactions
            WHERE sender_wallet_id = $1 OR receiver_wallet_id = $1
            ORDER BY created_at DESC
            LIMIT $2 OFFSET $3",
        )
        .bind(wallet_id)
        .bind(limit)
        .bind(offset)
        .fetch_all(&self.pool)
        .await
        .map_err(|e| {
            AppError::DatabaseError(format!("Failed to get transaction history: {}", e))
        })?;

        models
            .into_iter()
            .map(Self::transaction_to_domain)
            .collect()
    }

    async fn get_pending_transactions(&self, wallet_id: Uuid) -> Result<Vec<Transaction>> {
        let models: Vec<TransactionModel> = sqlx::query_as(
            "SELECT * FROM transactions
            WHERE (sender_wallet_id = $1 OR receiver_wallet_id = $1)
            AND status = 'pending'
            ORDER BY created_at DESC",
        )
        .bind(wallet_id)
        .fetch_all(&self.pool)
        .await
        .map_err(|e| {
            AppError::DatabaseError(format!("Failed to get pending transactions: {}", e))
        })?;

        models
            .into_iter()
            .map(Self::transaction_to_domain)
            .collect()
    }

    async fn process_transfer(
        &self,
        sender_wallet_id: Uuid,
        receiver_wallet_id: Uuid,
        amount: Decimal,
        transaction: &Transaction,
    ) -> Result<Transaction> {
        let mut tx =
            self.pool.begin().await.map_err(|e| {
                AppError::DatabaseError(format!("Failed to start transaction: {}", e))
            })?;

        let sender_row: (Decimal, String) =
            sqlx::query_as("SELECT balance, status FROM wallets WHERE id = $1 FOR UPDATE")
                .bind(sender_wallet_id)
                .fetch_one(&mut *tx)
                .await
                .map_err(|e| {
                    AppError::DatabaseError(format!("Failed to lock sender wallet: {}", e))
                })?;

        if sender_row.1 != "active" {
            return Err(AppError::PaymentError(
                "Sender wallet is not active".to_string(),
            ));
        }

        if sender_row.0 < amount {
            return Err(AppError::InsufficientFunds);
        }

        let receiver_row: (String,) =
            sqlx::query_as("SELECT status FROM wallets WHERE id = $1 FOR UPDATE")
                .bind(receiver_wallet_id)
                .fetch_one(&mut *tx)
                .await
                .map_err(|e| {
                    AppError::DatabaseError(format!("Failed to lock receiver wallet: {}", e))
                })?;

        if receiver_row.0 != "active" {
            return Err(AppError::PaymentError(
                "Receiver wallet is not active".to_string(),
            ));
        }

        sqlx::query("UPDATE wallets SET balance = balance - $2, updated_at = $3 WHERE id = $1")
            .bind(sender_wallet_id)
            .bind(amount)
            .bind(Utc::now())
            .execute(&mut *tx)
            .await
            .map_err(|e| AppError::DatabaseError(format!("Failed to debit sender: {}", e)))?;

        sqlx::query("UPDATE wallets SET balance = balance + $2, updated_at = $3 WHERE id = $1")
            .bind(receiver_wallet_id)
            .bind(amount)
            .bind(Utc::now())
            .execute(&mut *tx)
            .await
            .map_err(|e| AppError::DatabaseError(format!("Failed to credit receiver: {}", e)))?;

        let model: TransactionModel = sqlx::query_as(
            "INSERT INTO transactions (id, sender_wallet_id, receiver_wallet_id, transaction_type, amount, currency, status, description, reference, created_at, updated_at)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
            RETURNING *")
            .bind(transaction.id)
            .bind(transaction.sender_wallet_id)
            .bind(transaction.receiver_wallet_id)
            .bind("transfer")
            .bind(transaction.amount)
            .bind(&transaction.currency)
            .bind("completed")
            .bind(&transaction.description)
            .bind(&transaction.reference)
            .bind(transaction.created_at)
            .bind(Utc::now())
        .fetch_one(&mut *tx)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to create transaction record: {}", e)))?;

        tx.commit()
            .await
            .map_err(|e| AppError::DatabaseError(format!("Failed to commit transfer: {}", e)))?;

        Self::transaction_to_domain(model)
    }
}
