use view_social_backend::domain::auth::{JwtService, TokenType};
use uuid::Uuid;

#[test]
fn test_jwt_token_generation_and_validation() {
    let jwt_service = JwtService::new("test-secret-key-for-testing");
    let user_id = Uuid::new_v4();
    
    // Generate token pair
    let token_pair = jwt_service.generate_token_pair(user_id).unwrap();
    
    // Verify tokens are not empty
    assert!(!token_pair.access_token.is_empty());
    assert!(!token_pair.refresh_token.is_empty());
    assert!(token_pair.expires_in > 0);
    
    // Validate access token
    let validated_user_id = jwt_service.validate_access_token(&token_pair.access_token).unwrap();
    assert_eq!(user_id, validated_user_id);
    
    // Validate refresh token
    let refresh_user_id = jwt_service.validate_refresh_token(&token_pair.refresh_token).unwrap();
    assert_eq!(user_id, refresh_user_id);
}

#[test]
fn test_token_type_validation() {
    let jwt_service = JwtService::new("test-secret-key-for-testing");
    let user_id = Uuid::new_v4();
    
    let access_token = jwt_service.generate_access_token(user_id).unwrap();
    let refresh_token = jwt_service.generate_refresh_token(user_id).unwrap();
    
    // Access token should not validate as refresh token
    assert!(jwt_service.validate_refresh_token(&access_token).is_err());
    
    // Refresh token should not validate as access token
    assert!(jwt_service.validate_access_token(&refresh_token).is_err());
}

#[test]
fn test_refresh_token_mechanism() {
    let jwt_service = JwtService::new("test-secret-key-for-testing");
    let user_id = Uuid::new_v4();
    
    // Generate refresh token
    let refresh_token = jwt_service.generate_refresh_token(user_id).unwrap();
    
    // Use refresh token to get new access token
    let new_access_token = jwt_service.refresh_access_token(&refresh_token).unwrap();
    
    // Verify new access token is valid
    let validated_user_id = jwt_service.validate_access_token(&new_access_token).unwrap();
    assert_eq!(user_id, validated_user_id);
}

#[test]
fn test_invalid_token_rejection() {
    let jwt_service = JwtService::new("test-secret-key-for-testing");
    
    // Invalid token format
    assert!(jwt_service.validate_access_token("invalid-token").is_err());
    assert!(jwt_service.validate_refresh_token("invalid-token").is_err());
    
    // Empty token
    assert!(jwt_service.validate_access_token("").is_err());
}

#[test]
fn test_token_with_different_secret() {
    let jwt_service1 = JwtService::new("secret-key-1");
    let jwt_service2 = JwtService::new("secret-key-2");
    let user_id = Uuid::new_v4();
    
    // Generate token with first service
    let token = jwt_service1.generate_access_token(user_id).unwrap();
    
    // Try to validate with second service (different secret)
    assert!(jwt_service2.validate_access_token(&token).is_err());
}
