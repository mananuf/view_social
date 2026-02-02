use crate::domain::errors::{AppError, Result};
use crate::infrastructure::{email::EmailService, sms::SmsService};
use chrono::{DateTime, Duration, Utc};
use rand::{distributions::Alphanumeric, Rng};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use tokio::sync::RwLock;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum VerificationType {
    Email,
    Phone,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VerificationCode {
    pub id: Uuid,
    pub code: String,
    pub verification_type: VerificationType,
    pub target: String, // email or phone number
    pub user_id: Option<Uuid>,
    pub expires_at: DateTime<Utc>,
    pub attempts: u32,
    pub verified: bool,
    pub created_at: DateTime<Utc>,
}

impl VerificationCode {
    pub fn new_email(email: &str, user_id: Option<Uuid>) -> Self {
        let code = generate_numeric_code(6);
        Self {
            id: Uuid::new_v4(),
            code,
            verification_type: VerificationType::Email,
            target: email.to_string(),
            user_id,
            expires_at: Utc::now() + Duration::minutes(10),
            attempts: 0,
            verified: false,
            created_at: Utc::now(),
        }
    }

    pub fn new_phone(phone: &str, user_id: Option<Uuid>) -> Self {
        let code = generate_numeric_code(6);
        Self {
            id: Uuid::new_v4(),
            code,
            verification_type: VerificationType::Phone,
            target: phone.to_string(),
            user_id,
            expires_at: Utc::now() + Duration::minutes(10),
            attempts: 0,
            verified: false,
            created_at: Utc::now(),
        }
    }

    pub fn is_expired(&self) -> bool {
        Utc::now() > self.expires_at
    }

    pub fn is_valid(&self) -> bool {
        !self.is_expired() && !self.verified && self.attempts < 3
    }

    pub fn verify(&mut self, input_code: &str) -> bool {
        self.attempts += 1;

        if self.code == input_code && self.is_valid() {
            self.verified = true;
            true
        } else {
            false
        }
    }
}

/// In-memory verification code storage
/// In production, this should be replaced with Redis or database storage
pub struct VerificationStorage {
    codes: RwLock<HashMap<String, VerificationCode>>,
}

impl VerificationStorage {
    pub fn new() -> Self {
        Self {
            codes: RwLock::new(HashMap::new()),
        }
    }

    pub async fn store(&self, code: VerificationCode) {
        let mut codes = self.codes.write().await;
        codes.insert(code.target.clone(), code);
    }

    pub async fn get(&self, target: &str) -> Option<VerificationCode> {
        let codes = self.codes.read().await;
        codes.get(target).cloned()
    }

    pub async fn remove(&self, target: &str) -> Option<VerificationCode> {
        let mut codes = self.codes.write().await;
        codes.remove(target)
    }

    pub async fn cleanup_expired(&self) {
        let mut codes = self.codes.write().await;
        codes.retain(|_, code| !code.is_expired());
    }
}

impl Default for VerificationStorage {
    fn default() -> Self {
        Self::new()
    }
}

pub struct VerificationService {
    email_service: EmailService,
    sms_service: SmsService,
    storage: VerificationStorage,
}

impl VerificationService {
    pub fn new() -> Result<Self> {
        let email_service = EmailService::new()
            .map_err(|e| AppError::ExternalServiceError(format!("Email service error: {}", e)))?;

        let sms_service = SmsService::new()
            .map_err(|e| AppError::ExternalServiceError(format!("SMS service error: {}", e)))?;

        Ok(Self {
            email_service,
            sms_service,
            storage: VerificationStorage::new(),
        })
    }

    /// Send email verification code
    pub async fn send_email_verification(
        &self,
        email: &str,
        user_name: &str,
        user_id: Option<Uuid>,
    ) -> Result<Uuid> {
        // Check if there's already a recent verification code
        if let Some(existing) = self.storage.get(email).await {
            if existing.is_valid() {
                return Err(AppError::ValidationError(
                    "Verification code already sent. Please wait before requesting a new one."
                        .to_string(),
                ));
            }
        }

        let verification = VerificationCode::new_email(email, user_id);
        let verification_id = verification.id;

        // Generate email template
        let template = self
            .email_service
            .generate_verification_template(user_name, &verification.code);

        // Send email
        self.email_service
            .send_email(email, Some(user_name), template)
            .map_err(|e| AppError::ExternalServiceError(format!("Failed to send email: {}", e)))?;

        // Store verification code
        self.storage.store(verification).await;

        Ok(verification_id)
    }

    /// Send SMS verification code
    pub async fn send_sms_verification(&self, phone: &str, user_id: Option<Uuid>) -> Result<Uuid> {
        // Check if there's already a recent verification code
        if let Some(existing) = self.storage.get(phone).await {
            if existing.is_valid() {
                return Err(AppError::ValidationError(
                    "Verification code already sent. Please wait before requesting a new one."
                        .to_string(),
                ));
            }
        }

        let verification = VerificationCode::new_phone(phone, user_id);
        let verification_id = verification.id;

        // Send SMS
        self.sms_service
            .send_verification_code(phone, &verification.code)
            .await
            .map_err(|e| AppError::ExternalServiceError(format!("Failed to send SMS: {}", e)))?;

        // Store verification code
        self.storage.store(verification).await;

        Ok(verification_id)
    }

    /// Verify code
    pub async fn verify_code(&self, target: &str, input_code: &str) -> Result<VerificationCode> {
        let mut verification = self
            .storage
            .get(target)
            .await
            .ok_or_else(|| AppError::NotFound("Verification code not found".to_string()))?;

        if !verification.verify(input_code) {
            // Update the verification in storage with incremented attempts
            self.storage.store(verification.clone()).await;

            if verification.attempts >= 3 {
                return Err(AppError::ValidationError(
                    "Too many failed attempts. Please request a new verification code.".to_string(),
                ));
            }

            if verification.is_expired() {
                return Err(AppError::ValidationError(
                    "Verification code has expired. Please request a new one.".to_string(),
                ));
            }

            return Err(AppError::ValidationError(
                "Invalid verification code".to_string(),
            ));
        }

        // Remove the verified code from storage
        self.storage.remove(target).await;

        Ok(verification)
    }

    /// Get verification status
    pub async fn get_verification_status(&self, target: &str) -> Option<VerificationCode> {
        self.storage.get(target).await
    }

    /// Cleanup expired codes (should be called periodically)
    pub async fn cleanup_expired(&self) {
        self.storage.cleanup_expired().await;
    }
}

fn generate_numeric_code(length: usize) -> String {
    (0..length)
        .map(|_| rand::thread_rng().gen_range(0..10).to_string())
        .collect()
}

fn generate_alphanumeric_code(length: usize) -> String {
    rand::thread_rng()
        .sample_iter(&Alphanumeric)
        .take(length)
        .map(char::from)
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_verification_code_creation() {
        let email_code = VerificationCode::new_email("test@example.com", None);
        assert_eq!(email_code.verification_type, VerificationType::Email);
        assert_eq!(email_code.target, "test@example.com");
        assert_eq!(email_code.code.len(), 6);
        assert!(!email_code.is_expired());
        assert!(email_code.is_valid());

        let phone_code = VerificationCode::new_phone("+1234567890", None);
        assert_eq!(phone_code.verification_type, VerificationType::Phone);
        assert_eq!(phone_code.target, "+1234567890");
        assert_eq!(phone_code.code.len(), 6);
    }

    #[test]
    fn test_verification_code_verification() {
        let mut code = VerificationCode::new_email("test@example.com", None);
        let original_code = code.code.clone();

        // Valid verification
        assert!(code.verify(&original_code));
        assert!(code.verified);

        // Already verified
        let mut code2 = VerificationCode::new_email("test2@example.com", None);
        code2.verified = true;
        assert!(!code2.verify(&code2.code.clone()));
    }

    #[test]
    fn test_code_generation() {
        let numeric = generate_numeric_code(6);
        assert_eq!(numeric.len(), 6);
        assert!(numeric.chars().all(|c| c.is_ascii_digit()));

        let alphanumeric = generate_alphanumeric_code(8);
        assert_eq!(alphanumeric.len(), 8);
        assert!(alphanumeric.chars().all(|c| c.is_ascii_alphanumeric()));
    }
}
