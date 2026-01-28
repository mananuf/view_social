use chrono::{DateTime, Utc};
use rust_decimal::Decimal;
use sqlx::FromRow;
use uuid::Uuid;

/// Database model for transactions table
#[derive(FromRow)]
pub struct TransactionModel {
    pub id: Uuid,
    pub sender_wallet_id: Option<Uuid>,
    pub receiver_wallet_id: Option<Uuid>,
    pub transaction_type: String,
    pub amount: Decimal,
    pub currency: String,
    pub status: String,
    pub description: Option<String>,
    pub reference: String,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}
