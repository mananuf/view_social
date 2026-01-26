use crate::domain::errors::{AppError, Result};
use chrono::{DateTime, Duration, Utc};
use jsonwebtoken::{decode, encode, DecodingKey, EncodingKey, Header, Validation};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Claims {
    pub sub: String,        // Subject (user ID)
    pub exp: i64,           // Expiration time
    pub iat: i64,           // Issued at
    pub token_type: TokenType,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum TokenType {
    Access,
    Refresh,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TokenPair {
    pub access_token: String,
    pub refresh_token: String,
    pub expires_in: i64,
}

#[derive(Clone)]
pub struct JwtService {
    encoding_key: EncodingKey,
    decoding_key: DecodingKey,
    access_token_expiry: Duration,
    refresh_token_expiry: Duration,
}

impl JwtService {
    pub fn new(secret: &str) -> Self {
        Self {
            encoding_key: EncodingKey::from_secret(secret.as_bytes()),
            decoding_key: DecodingKey::from_secret(secret.as_bytes()),
            access_token_expiry: Duration::minutes(15),
            refresh_token_expiry: Duration::days(7),
        }
    }

    pub fn generate_token_pair(&self, user_id: Uuid) -> Result<TokenPair> {
        let access_token = self.generate_access_token(user_id)?;
        let refresh_token = self.generate_refresh_token(user_id)?;
        
        Ok(TokenPair {
            access_token,
            refresh_token,
            expires_in: self.access_token_expiry.num_seconds(),
        })
    }

    pub fn generate_access_token(&self, user_id: Uuid) -> Result<String> {
        let now = Utc::now();
        let expiration = now + self.access_token_expiry;
        
        let claims = Claims {
            sub: user_id.to_string(),
            exp: expiration.timestamp(),
            iat: now.timestamp(),
            token_type: TokenType::Access,
        };
        
        encode(&Header::default(), &claims, &self.encoding_key)
            .map_err(|e| AppError::AuthenticationError(format!("Failed to generate access token: {}", e)))
    }

    pub fn generate_refresh_token(&self, user_id: Uuid) -> Result<String> {
        let now = Utc::now();
        let expiration = now + self.refresh_token_expiry;
        
        let claims = Claims {
            sub: user_id.to_string(),
            exp: expiration.timestamp(),
            iat: now.timestamp(),
            token_type: TokenType::Refresh,
        };
        
        encode(&Header::default(), &claims, &self.encoding_key)
            .map_err(|e| AppError::AuthenticationError(format!("Failed to generate refresh token: {}", e)))
    }

    pub fn validate_token(&self, token: &str) -> Result<Claims> {
        let token_data = decode::<Claims>(
            token,
            &self.decoding_key,
            &Validation::default(),
        )
        .map_err(|e| AppError::AuthenticationError(format!("Invalid token: {}", e)))?;
        
        Ok(token_data.claims)
    }

    pub fn validate_access_token(&self, token: &str) -> Result<Uuid> {
        let claims = self.validate_token(token)?;
        
        if claims.token_type != TokenType::Access {
            return Err(AppError::AuthenticationError("Invalid token type".to_string()));
        }
        
        let user_id = Uuid::parse_str(&claims.sub)
            .map_err(|e| AppError::AuthenticationError(format!("Invalid user ID in token: {}", e)))?;
        
        Ok(user_id)
    }

    pub fn validate_refresh_token(&self, token: &str) -> Result<Uuid> {
        let claims = self.validate_token(token)?;
        
        if claims.token_type != TokenType::Refresh {
            return Err(AppError::AuthenticationError("Invalid token type".to_string()));
        }
        
        let user_id = Uuid::parse_str(&claims.sub)
            .map_err(|e| AppError::AuthenticationError(format!("Invalid user ID in token: {}", e)))?;
        
        Ok(user_id)
    }

    pub fn refresh_access_token(&self, refresh_token: &str) -> Result<String> {
        let user_id = self.validate_refresh_token(refresh_token)?;
        self.generate_access_token(user_id)
    }

    pub fn get_user_id_from_token(&self, token: &str) -> Result<Uuid> {
        let claims = self.validate_token(token)?;
        
        Uuid::parse_str(&claims.sub)
            .map_err(|e| AppError::AuthenticationError(format!("Invalid user ID in token: {}", e)))
    }

    pub fn is_token_expired(&self, token: &str) -> bool {
        match self.validate_token(token) {
            Ok(claims) => {
                let expiration = DateTime::from_timestamp(claims.exp, 0);
                if let Some(exp_time) = expiration {
                    Utc::now() > exp_time
                } else {
                    true
                }
            }
            Err(_) => true,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use proptest::prelude::*;

    // **Feature: view-social-mvp, Property 17: JWT token security**
    // **Validates: Requirements 9.1**
    proptest! {
        #[test]
        fn test_jwt_token_security(
            user_ids in prop::collection::vec("[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}", 1..10),
            secret in "[a-zA-Z0-9]{16,64}",
        ) {
            // For any authentication request, JWT tokens should be generated with proper expiration and refresh mechanisms
            let jwt_service = JwtService::new(&secret);
            
            for user_id_str in &user_ids {
                if let Ok(user_id) = user_id_str.parse::<Uuid>() {
                    // Generate token pair
                    let token_pair = jwt_service.generate_token_pair(user_id)?;
                    
                    // Property 1: Tokens should not be empty
                    prop_assert!(!token_pair.access_token.is_empty());
                    prop_assert!(!token_pair.refresh_token.is_empty());
                    
                    // Property 2: Expiry should be positive
                    prop_assert!(token_pair.expires_in > 0);
                    
                    // Property 3: Access token should be valid and contain correct user ID
                    let validated_user_id = jwt_service.validate_access_token(&token_pair.access_token)?;
                    prop_assert_eq!(user_id, validated_user_id);
                    
                    // Property 4: Refresh token should be valid and contain correct user ID
                    let refresh_user_id = jwt_service.validate_refresh_token(&token_pair.refresh_token)?;
                    prop_assert_eq!(user_id, refresh_user_id);
                    
                    // Property 5: Access token should not be valid as refresh token
                    let wrong_type_result = jwt_service.validate_refresh_token(&token_pair.access_token);
                    prop_assert!(wrong_type_result.is_err());
                    
                    // Property 6: Refresh token should not be valid as access token
                    let wrong_type_result2 = jwt_service.validate_access_token(&token_pair.refresh_token);
                    prop_assert!(wrong_type_result2.is_err());
                    
                    // Property 7: Refresh token can be used to generate new access token
                    let new_access_token = jwt_service.refresh_access_token(&token_pair.refresh_token)?;
                    prop_assert!(!new_access_token.is_empty());
                    
                    // Property 8: New access token should be valid
                    let new_validated_user_id = jwt_service.validate_access_token(&new_access_token)?;
                    prop_assert_eq!(user_id, new_validated_user_id);
                    
                    // Property 9: Token generated with one secret should not be valid with different secret
                    let different_jwt_service = JwtService::new("different-secret-key-12345");
                    let invalid_result = different_jwt_service.validate_access_token(&token_pair.access_token);
                    prop_assert!(invalid_result.is_err());
                }
            }
        }
    }

    #[test]
    fn test_generate_token_pair() {
        let jwt_service = JwtService::new("test-secret-key");
        let user_id = Uuid::new_v4();
        
        let token_pair = jwt_service.generate_token_pair(user_id).unwrap();
        
        assert!(!token_pair.access_token.is_empty());
        assert!(!token_pair.refresh_token.is_empty());
        assert!(token_pair.expires_in > 0);
    }

    #[test]
    fn test_validate_access_token() {
        let jwt_service = JwtService::new("test-secret-key");
        let user_id = Uuid::new_v4();
        
        let access_token = jwt_service.generate_access_token(user_id).unwrap();
        let validated_user_id = jwt_service.validate_access_token(&access_token).unwrap();
        
        assert_eq!(user_id, validated_user_id);
    }

    #[test]
    fn test_validate_refresh_token() {
        let jwt_service = JwtService::new("test-secret-key");
        let user_id = Uuid::new_v4();
        
        let refresh_token = jwt_service.generate_refresh_token(user_id).unwrap();
        let validated_user_id = jwt_service.validate_refresh_token(&refresh_token).unwrap();
        
        assert_eq!(user_id, validated_user_id);
    }

    #[test]
    fn test_refresh_access_token() {
        let jwt_service = JwtService::new("test-secret-key");
        let user_id = Uuid::new_v4();
        
        let refresh_token = jwt_service.generate_refresh_token(user_id).unwrap();
        let new_access_token = jwt_service.refresh_access_token(&refresh_token).unwrap();
        
        let validated_user_id = jwt_service.validate_access_token(&new_access_token).unwrap();
        assert_eq!(user_id, validated_user_id);
    }

    #[test]
    fn test_invalid_token() {
        let jwt_service = JwtService::new("test-secret-key");
        
        let result = jwt_service.validate_access_token("invalid-token");
        assert!(result.is_err());
    }

    #[test]
    fn test_wrong_token_type() {
        let jwt_service = JwtService::new("test-secret-key");
        let user_id = Uuid::new_v4();
        
        let refresh_token = jwt_service.generate_refresh_token(user_id).unwrap();
        
        // Try to validate refresh token as access token
        let result = jwt_service.validate_access_token(&refresh_token);
        assert!(result.is_err());
    }

    #[test]
    fn test_get_user_id_from_token() {
        let jwt_service = JwtService::new("test-secret-key");
        let user_id = Uuid::new_v4();
        
        let access_token = jwt_service.generate_access_token(user_id).unwrap();
        let extracted_user_id = jwt_service.get_user_id_from_token(&access_token).unwrap();
        
        assert_eq!(user_id, extracted_user_id);
    }
}
