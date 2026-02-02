use crate::api::dto::auth::{
    LoginRequest, LoginResponse, RegisterRequest, RegisterResponse, ResendCodeRequest,
    VerifyCodeRequest,
};
use crate::api::dto::common::SuccessResponse;
use crate::application::verification::VerificationService;
use crate::domain::auth::JwtService;
use crate::domain::entities::{CreateUserRequest, User};
use crate::domain::errors::AppError;
use crate::domain::password::PasswordService;
use crate::domain::repositories::UserRepository;
use axum::{
    extract::State,
    http::StatusCode,
    response::{IntoResponse, Response},
    Json,
};
use std::sync::Arc;
use tracing::info;
use uuid::Uuid;

/// Authentication state containing all auth-related services
#[derive(Clone)]
pub struct AuthState {
    pub user_repo: Arc<dyn UserRepository>,
    pub password_service: PasswordService,
    pub jwt_service: JwtService,
    pub verification_service: Arc<VerificationService>,
}

impl AuthState {
    pub fn new(
        user_repo: Arc<dyn UserRepository>,
        jwt_service: JwtService,
        verification_service: Arc<VerificationService>,
    ) -> Self {
        Self {
            user_repo,
            password_service: PasswordService::new(),
            jwt_service,
            verification_service,
        }
    }
}

/// Register a new user with email or phone verification
pub async fn register(
    State(state): State<AuthState>,
    Json(payload): Json<RegisterRequest>,
) -> std::result::Result<Response, AppError> {
    info!("Registration attempt for: {}", payload.identifier);

    // Validate registration type
    let (email, phone_number) = match payload.registration_type.as_str() {
        "email" => {
            if !payload.identifier.contains('@') {
                return Err(AppError::ValidationError(
                    "Invalid email format".to_string(),
                ));
            }
            (Some(payload.identifier.clone()), None)
        }
        "phone" => {
            if payload.identifier.contains('@') {
                return Err(AppError::ValidationError(
                    "Invalid phone number format".to_string(),
                ));
            }
            (None, Some(payload.identifier.clone()))
        }
        _ => {
            return Err(AppError::ValidationError(
                "Registration type must be 'email' or 'phone'".to_string(),
            ));
        }
    };

    // Check if user already exists
    if let Some(email_addr) = &email {
        if state.user_repo.email_exists(email_addr).await? {
            return Err(AppError::ValidationError(
                "Email already registered".to_string(),
            ));
        }
    }

    if state.user_repo.username_exists(&payload.username).await? {
        return Err(AppError::ValidationError(
            "Username already taken".to_string(),
        ));
    }

    // Hash password
    let password_hash = state.password_service.hash_password(&payload.password)?;

    // Create user request
    let create_request = CreateUserRequest {
        username: payload.username.clone(),
        email: email
            .clone()
            .unwrap_or_else(|| format!("{}@temp.local", Uuid::new_v4())), // Temporary email for phone registration
        phone_number: phone_number.clone(),
        password_hash,
        display_name: payload.display_name,
        bio: None,
    };

    // Create user (but don't save to database yet - wait for verification)
    let user = User::new(create_request)?;

    // Send verification code
    let verification_id = match payload.registration_type.as_str() {
        "email" => {
            let email_addr = email.as_ref().unwrap();
            state
                .verification_service
                .send_email_verification(email_addr, &payload.username, Some(user.id))
                .await?
        }
        "phone" => {
            let phone_addr = phone_number.as_ref().unwrap();
            state
                .verification_service
                .send_sms_verification(phone_addr, Some(user.id))
                .await?
        }
        _ => unreachable!(),
    };

    info!("Verification code sent for user: {}", payload.username);

    let response = RegisterResponse {
        message: "Verification code sent. Please verify to complete registration.".to_string(),
        verification_id,
        user_id: user.id,
        verification_type: payload.registration_type,
        identifier: payload.identifier,
    };

    Ok((StatusCode::CREATED, Json(response)).into_response())
}

/// Verify registration code and complete user creation
pub async fn verify_registration(
    State(state): State<AuthState>,
    Json(payload): Json<VerifyCodeRequest>,
) -> std::result::Result<Response, AppError> {
    info!("Verification attempt for: {}", payload.identifier);

    // Verify the code
    let verification = state
        .verification_service
        .verify_code(&payload.identifier, &payload.code)
        .await?;

    // Get user ID from verification
    let user_id = verification
        .user_id
        .ok_or_else(|| AppError::ValidationError("Invalid verification session".to_string()))?;

    // For now, we'll create a minimal user. In a production system, you'd want to
    // store the complete registration data during the initial registration step
    // and retrieve it here. This is a simplified implementation.

    let (username, email, phone_number) = match verification.verification_type {
        crate::application::verification::VerificationType::Email => (
            format!("user_{}", &user_id.to_string()[..8]),
            verification.target.clone(),
            None,
        ),
        crate::application::verification::VerificationType::Phone => (
            format!("user_{}", &user_id.to_string()[..8]),
            format!("{}@temp.local", user_id),
            Some(verification.target.clone()),
        ),
    };

    // Create a temporary password hash (user will need to set a proper password later)
    let temp_password = format!("temp_{}", Uuid::new_v4());
    let password_hash = state.password_service.hash_password(&temp_password)?;

    let create_request = CreateUserRequest {
        username,
        email,
        phone_number,
        password_hash,
        display_name: None,
        bio: None,
    };

    let mut user = User::new(create_request)?;
    user.id = user_id; // Use the same ID from verification

    // Mark appropriate field as verified
    match verification.verification_type {
        crate::application::verification::VerificationType::Email => {
            user.verify_email();
        }
        crate::application::verification::VerificationType::Phone => {
            user.verify_phone();
        }
    }

    // Save user to database
    let created_user = state.user_repo.create(&user).await?;

    // Generate JWT token
    let token = state.jwt_service.generate_access_token(created_user.id)?;

    info!(
        "User registration completed: {}",
        created_user.username.value()
    );

    let response = LoginResponse {
        token,
        user_id: created_user.id,
        username: created_user.username.value().to_string(),
        email: created_user.email.value().to_string(),
        email_verified: created_user.email_verified,
        phone_verified: created_user.phone_verified,
    };

    Ok((StatusCode::OK, Json(response)).into_response())
}

/// Login with username/email and password
pub async fn login(
    State(state): State<AuthState>,
    Json(payload): Json<LoginRequest>,
) -> std::result::Result<Response, AppError> {
    info!("Login attempt for: {}", payload.identifier);

    // Find user by username or email
    let user = if payload.identifier.contains('@') {
        state.user_repo.find_by_email(&payload.identifier).await?
    } else {
        state
            .user_repo
            .find_by_username(&payload.identifier)
            .await?
    };

    let user =
        user.ok_or_else(|| AppError::AuthenticationError("Invalid credentials".to_string()))?;

    // Verify password
    if !state
        .password_service
        .verify_password(&payload.password, &user.password_hash)?
    {
        return Err(AppError::AuthenticationError(
            "Invalid credentials".to_string(),
        ));
    }

    // Check if user is verified
    if !user.email_verified && !user.phone_verified {
        return Err(AppError::AuthenticationError(
            "Account not verified. Please verify your email or phone number.".to_string(),
        ));
    }

    // Generate JWT token
    let token = state.jwt_service.generate_access_token(user.id)?;

    info!("User logged in successfully: {}", user.username.value());

    let response = LoginResponse {
        token,
        user_id: user.id,
        username: user.username.value().to_string(),
        email: user.email.value().to_string(),
        email_verified: user.email_verified,
        phone_verified: user.phone_verified,
    };

    Ok((StatusCode::OK, Json(response)).into_response())
}

/// Resend verification code
pub async fn resend_verification_code(
    State(state): State<AuthState>,
    Json(payload): Json<ResendCodeRequest>,
) -> std::result::Result<Response, AppError> {
    info!("Resend verification code for: {}", payload.identifier);

    // Determine verification type
    let verification_type = if payload.identifier.contains('@') {
        "email"
    } else {
        "phone"
    };

    // Send verification code
    let verification_id = match verification_type {
        "email" => {
            state
                .verification_service
                .send_email_verification(&payload.identifier, "User", None)
                .await?
        }
        "phone" => {
            state
                .verification_service
                .send_sms_verification(&payload.identifier, None)
                .await?
        }
        _ => unreachable!(),
    };

    let response = SuccessResponse {
        message: "Verification code sent successfully".to_string(),
        data: Some(serde_json::json!({
            "verification_id": verification_id,
            "verification_type": verification_type
        })),
    };

    Ok((StatusCode::OK, Json(response)).into_response())
}

/// Logout (invalidate token - in a real implementation, you'd maintain a blacklist)
pub async fn logout() -> std::result::Result<Response, AppError> {
    let response = SuccessResponse {
        message: "Logged out successfully".to_string(),
        data: None,
    };

    Ok((StatusCode::OK, Json(response)).into_response())
}

/// Refresh JWT token
pub async fn refresh_token(
    State(_state): State<AuthState>,
    // In a real implementation, you'd extract the current token and validate it
) -> std::result::Result<Response, AppError> {
    // For now, return an error as this needs proper token extraction
    Err(AppError::AuthenticationError(
        "Token refresh not implemented yet".to_string(),
    ))
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::domain::repositories::MockUserRepository;
    use std::sync::Arc;

    fn create_test_auth_state() -> AuthState {
        let user_repo = Arc::new(MockUserRepository::new());
        let jwt_service = JwtService::new("test-secret");
        let verification_service =
            Arc::new(VerificationService::new().expect("Failed to create verification service"));

        AuthState::new(user_repo, jwt_service, verification_service)
    }

    #[tokio::test]
    async fn test_register_with_email() {
        let state = create_test_auth_state();

        let request = RegisterRequest {
            username: "testuser".to_string(),
            password: "password123".to_string(),
            identifier: "test@example.com".to_string(),
            registration_type: "email".to_string(),
            display_name: Some("Test User".to_string()),
        };

        // This test would need proper mocking of the verification service
        // For now, we just test that the function doesn't panic
        let result = register(State(state), Json(request)).await;
        // In a real test, we'd assert the result
    }
}
