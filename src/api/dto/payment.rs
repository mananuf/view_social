// Payment-related DTOs
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use super::UserDTO;

#[derive(Debug, Serialize)]
pub struct WalletDTO {
    pub id: Uuid,
    pub user_id: Uuid,
    pub balance: String,
    pub currency: String,
    pub status: String,
    pub has_pin: bool,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Deserialize)]
pub struct SetPinRequest {
    pub pin: String,
    pub confirm_pin: String,
}

#[derive(Debug, Deserialize)]
pub struct TransferRequest {
    pub receiver_user_id: Uuid,
    pub amount: String,
    pub pin: String,
    pub description: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct TransactionDTO {
    pub id: Uuid,
    pub sender: Option<UserDTO>,
    pub receiver: Option<UserDTO>,
    pub transaction_type: String,
    pub amount: String,
    pub currency: String,
    pub status: String,
    pub description: Option<String>,
    pub reference: String,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PaymentDataDTO {
    pub transaction_id: Uuid,
    pub amount: String,
    pub currency: String,
    pub status: String,
}
