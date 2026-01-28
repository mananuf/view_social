use view_social_backend::domain::password::PasswordService;

#[test]
fn test_password_hashing_with_bcrypt_cost_12() {
    let service = PasswordService::new();
    let password = "SecurePass123";

    let hash = service.hash_password(password).unwrap();

    // Verify hash is not empty and uses bcrypt format with cost 12
    assert!(!hash.is_empty());
    assert_ne!(hash, password);
    assert!(
        hash.starts_with("$2b$12$") || hash.starts_with("$2a$12$") || hash.starts_with("$2y$12$")
    );
}

#[test]
fn test_password_verification_success() {
    let service = PasswordService::new();
    let password = "SecurePass123";

    let hash = service.hash_password(password).unwrap();

    // Correct password should verify
    assert!(service.verify_password(password, &hash).unwrap());
}

#[test]
fn test_password_verification_failure() {
    let service = PasswordService::new();
    let password = "SecurePass123";

    let hash = service.hash_password(password).unwrap();

    // Wrong password should not verify
    assert!(!service.verify_password("WrongPassword123", &hash).unwrap());
    assert!(!service.verify_password("securepass123", &hash).unwrap());
    assert!(!service.verify_password("SECUREPASS123", &hash).unwrap());
}

#[test]
fn test_password_validation_requirements() {
    let service = PasswordService::new();

    // Valid password
    assert!(service.validate_password("SecurePass123").is_ok());
    assert!(service.validate_password("MyP@ssw0rd").is_ok());
    assert!(service.validate_password("Test1234Pass").is_ok());
}

#[test]
fn test_password_validation_too_short() {
    let service = PasswordService::new();

    // Too short (less than 8 characters)
    assert!(service.validate_password("Short1A").is_err());
    assert!(service.validate_password("Pass1").is_err());
}

#[test]
fn test_password_validation_missing_requirements() {
    let service = PasswordService::new();

    // No uppercase
    assert!(service.validate_password("securepass123").is_err());

    // No lowercase
    assert!(service.validate_password("SECUREPASS123").is_err());

    // No digit
    assert!(service.validate_password("SecurePassword").is_err());
}

#[test]
fn test_password_validation_too_long() {
    let service = PasswordService::new();

    // Too long (more than 128 characters)
    let long_password = "A".repeat(129) + "a1";
    assert!(service.validate_password(&long_password).is_err());
}

#[test]
fn test_same_password_different_hashes() {
    let service = PasswordService::new();
    let password = "SecurePass123";

    let hash1 = service.hash_password(password).unwrap();
    let hash2 = service.hash_password(password).unwrap();

    // Same password should produce different hashes (due to random salt)
    assert_ne!(hash1, hash2);

    // But both should verify correctly
    assert!(service.verify_password(password, &hash1).unwrap());
    assert!(service.verify_password(password, &hash2).unwrap());
}

#[test]
fn test_password_reset_token_generation() {
    let service = PasswordService::new();

    let token1 = service.generate_reset_token();
    let token2 = service.generate_reset_token();

    // Tokens should be non-empty and unique
    assert!(!token1.is_empty());
    assert!(!token2.is_empty());
    assert_ne!(token1, token2);
}

#[test]
fn test_needs_rehash() {
    let service = PasswordService::new();
    let password = "SecurePass123";

    let hash = service.hash_password(password).unwrap();

    // Hash with correct cost (12) should not need rehashing
    assert!(!service.needs_rehash(&hash));
}
