use crate::domain::errors::{AppError, Result};
use bcrypt::{hash, verify};

const BCRYPT_COST: u32 = 12;

pub struct PasswordService;

impl PasswordService {
    pub fn new() -> Self {
        Self
    }

    /// Hash a password using bcrypt with cost factor 12
    pub fn hash_password(&self, password: &str) -> Result<String> {
        // Validate password requirements
        self.validate_password(password)?;
        
        // Hash with cost factor 12
        hash(password, BCRYPT_COST)
            .map_err(|e| AppError::AuthenticationError(format!("Failed to hash password: {}", e)))
    }

    /// Verify a password against a hash
    pub fn verify_password(&self, password: &str, hash: &str) -> Result<bool> {
        verify(password, hash)
            .map_err(|e| AppError::AuthenticationError(format!("Failed to verify password: {}", e)))
    }

    /// Validate password meets security requirements
    pub fn validate_password(&self, password: &str) -> Result<()> {
        if password.len() < 8 {
            return Err(AppError::ValidationError(
                "Password must be at least 8 characters long".to_string(),
            ));
        }

        if password.len() > 128 {
            return Err(AppError::ValidationError(
                "Password cannot exceed 128 characters".to_string(),
            ));
        }

        // Check for at least one uppercase letter
        if !password.chars().any(|c| c.is_uppercase()) {
            return Err(AppError::ValidationError(
                "Password must contain at least one uppercase letter".to_string(),
            ));
        }

        // Check for at least one lowercase letter
        if !password.chars().any(|c| c.is_lowercase()) {
            return Err(AppError::ValidationError(
                "Password must contain at least one lowercase letter".to_string(),
            ));
        }

        // Check for at least one digit
        if !password.chars().any(|c| c.is_ascii_digit()) {
            return Err(AppError::ValidationError(
                "Password must contain at least one digit".to_string(),
            ));
        }

        Ok(())
    }

    /// Check if a password hash needs to be rehashed (e.g., if cost factor changed)
    pub fn needs_rehash(&self, hash: &str) -> bool {
        // Extract cost from hash (bcrypt hash format: $2b$cost$salt+hash)
        if let Some(cost_str) = hash.split('$').nth(2) {
            if let Ok(cost) = cost_str.parse::<u32>() {
                return cost != BCRYPT_COST;
            }
        }
        true // If we can't parse, assume it needs rehashing
    }

    /// Generate a password reset token (simple implementation)
    pub fn generate_reset_token(&self) -> String {
        use uuid::Uuid;
        Uuid::new_v4().to_string()
    }
}

impl Default for PasswordService {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use proptest::prelude::*;

    // **Feature: view-social-mvp, Property 18: Password hashing security**
    // **Validates: Requirements 9.2**
    proptest! {
        #[test]
        fn test_password_hashing_security(
            passwords in prop::collection::vec("[A-Z][a-z]{5,20}[0-9]{1,5}", 1..10),
        ) {
            // For any password storage, bcrypt hashing with cost factor 12 should be used
            let service = PasswordService::new();
            
            for password in &passwords {
                // Hash the password
                let hash_result = service.hash_password(password);
                
                if let Ok(hash) = hash_result {
                    // Property 1: Hash should not be empty
                    prop_assert!(!hash.is_empty());
                    
                    // Property 2: Hash should not equal the original password
                    prop_assert_ne!(&hash, password);
                    
                    // Property 3: Hash should use bcrypt format with cost factor 12
                    // Bcrypt format: $2b$12$... or $2a$12$... or $2y$12$...
                    prop_assert!(
                        hash.starts_with("$2b$12$") || 
                        hash.starts_with("$2a$12$") || 
                        hash.starts_with("$2y$12$"),
                        "Hash does not use bcrypt with cost factor 12: {}", hash
                    );
                    
                    // Property 4: Original password should verify against hash
                    let verify_result = service.verify_password(password, &hash)?;
                    prop_assert!(verify_result, "Original password should verify against its hash");
                    
                    // Property 5: Different password should not verify
                    let wrong_password = format!("{}X", password);
                    if service.validate_password(&wrong_password).is_ok() {
                        let wrong_verify = service.verify_password(&wrong_password, &hash)?;
                        prop_assert!(!wrong_verify, "Wrong password should not verify");
                    }
                    
                    // Property 6: Same password hashed twice should produce different hashes (salt)
                    let hash2 = service.hash_password(password)?;
                    prop_assert_ne!(hash.clone(), hash2.clone(), "Same password should produce different hashes due to salt");
                    
                    // Property 7: Both hashes should verify the original password
                    prop_assert!(service.verify_password(password, &hash2)?);
                    
                    // Property 8: Hash should not need rehashing (correct cost factor)
                    prop_assert!(!service.needs_rehash(&hash), "Hash with cost 12 should not need rehashing");
                }
            }
        }
    }

    #[test]
    fn test_password_hashing() {
        let service = PasswordService::new();
        let password = "SecurePass123";
        
        let hash = service.hash_password(password).unwrap();
        
        assert!(!hash.is_empty());
        assert_ne!(hash, password);
        assert!(hash.starts_with("$2b$12$")); // bcrypt format with cost 12
    }

    #[test]
    fn test_password_verification() {
        let service = PasswordService::new();
        let password = "SecurePass123";
        
        let hash = service.hash_password(password).unwrap();
        
        // Correct password should verify
        assert!(service.verify_password(password, &hash).unwrap());
        
        // Wrong password should not verify
        assert!(!service.verify_password("WrongPassword123", &hash).unwrap());
    }

    #[test]
    fn test_password_validation() {
        let service = PasswordService::new();
        
        // Valid password
        assert!(service.validate_password("SecurePass123").is_ok());
        
        // Too short
        assert!(service.validate_password("Short1A").is_err());
        
        // No uppercase
        assert!(service.validate_password("securepass123").is_err());
        
        // No lowercase
        assert!(service.validate_password("SECUREPASS123").is_err());
        
        // No digit
        assert!(service.validate_password("SecurePassword").is_err());
        
        // Too long
        let long_password = "A".repeat(129) + "a1";
        assert!(service.validate_password(&long_password).is_err());
    }

    #[test]
    fn test_needs_rehash() {
        let service = PasswordService::new();
        let password = "SecurePass123";
        
        let hash = service.hash_password(password).unwrap();
        
        // Hash with correct cost should not need rehashing
        assert!(!service.needs_rehash(&hash));
        
        // Hash with different cost should need rehashing
        let old_hash = bcrypt::hash(password, 10).unwrap(); // Cost 10
        assert!(service.needs_rehash(&old_hash));
    }

    #[test]
    fn test_generate_reset_token() {
        let service = PasswordService::new();
        
        let token1 = service.generate_reset_token();
        let token2 = service.generate_reset_token();
        
        assert!(!token1.is_empty());
        assert!(!token2.is_empty());
        assert_ne!(token1, token2); // Tokens should be unique
    }

    #[test]
    fn test_same_password_different_hashes() {
        let service = PasswordService::new();
        let password = "SecurePass123";
        
        let hash1 = service.hash_password(password).unwrap();
        let hash2 = service.hash_password(password).unwrap();
        
        // Same password should produce different hashes (due to salt)
        assert_ne!(hash1, hash2);
        
        // But both should verify correctly
        assert!(service.verify_password(password, &hash1).unwrap());
        assert!(service.verify_password(password, &hash2).unwrap());
    }
}
