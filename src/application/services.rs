use crate::domain::entities::{UpdateUserRequest, User};
use crate::domain::errors::{AppError, Result};
use crate::domain::repositories::{UserRepository, WalletRepository};
use std::sync::Arc;
use uuid::Uuid;

/// User management service for coordinating user-related operations
pub struct UserManagementService {
    user_repository: Arc<dyn UserRepository>,
    wallet_repository: Arc<dyn WalletRepository>,
}

impl UserManagementService {
    pub fn new(
        user_repository: Arc<dyn UserRepository>,
        wallet_repository: Arc<dyn WalletRepository>,
    ) -> Self {
        Self {
            user_repository,
            wallet_repository,
        }
    }

    /// Update user profile with coordination and validation
    pub async fn update_profile(
        &self,
        user_id: Uuid,
        update_request: UpdateUserRequest,
    ) -> Result<User> {
        // Find the user first
        let mut user = self
            .user_repository
            .find_by_id(user_id)
            .await?
            .ok_or_else(|| AppError::NotFound("User not found".to_string()))?;

        // Apply the update to the user entity (this handles validation)
        user.update(update_request)?;

        // Persist the updated user
        let updated_user = self.user_repository.update(&user).await?;

        Ok(updated_user)
    }

    /// Follow another user with proper coordination
    pub async fn follow_user(&self, follower_id: Uuid, following_id: Uuid) -> Result<()> {
        // Validate that both users exist
        let _follower = self
            .user_repository
            .find_by_id(follower_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Follower user not found".to_string()))?;

        let _following = self
            .user_repository
            .find_by_id(following_id)
            .await?
            .ok_or_else(|| AppError::NotFound("User to follow not found".to_string()))?;

        // Prevent self-following
        if follower_id == following_id {
            return Err(AppError::ValidationError(
                "Users cannot follow themselves".to_string(),
            ));
        }

        // Check if already following
        let is_already_following = self
            .user_repository
            .is_following(follower_id, following_id)
            .await?;

        if is_already_following {
            return Err(AppError::ValidationError(
                "User is already following this user".to_string(),
            ));
        }

        // Perform the follow operation (this updates counts atomically)
        self.user_repository
            .follow(follower_id, following_id)
            .await?;

        Ok(())
    }

    /// Unfollow another user with proper coordination
    pub async fn unfollow_user(&self, follower_id: Uuid, following_id: Uuid) -> Result<()> {
        // Validate that both users exist
        let _follower = self
            .user_repository
            .find_by_id(follower_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Follower user not found".to_string()))?;

        let _following = self
            .user_repository
            .find_by_id(following_id)
            .await?
            .ok_or_else(|| AppError::NotFound("User to unfollow not found".to_string()))?;

        // Check if currently following
        let is_following = self
            .user_repository
            .is_following(follower_id, following_id)
            .await?;

        if !is_following {
            return Err(AppError::ValidationError(
                "User is not following this user".to_string(),
            ));
        }

        // Perform the unfollow operation (this updates counts atomically)
        self.user_repository
            .unfollow(follower_id, following_id)
            .await?;

        Ok(())
    }

    /// Get user profile by ID
    pub async fn get_user_profile(&self, user_id: Uuid) -> Result<User> {
        self.user_repository
            .find_by_id(user_id)
            .await?
            .ok_or_else(|| AppError::NotFound("User not found".to_string()))
    }

    /// Get user followers with pagination
    pub async fn get_user_followers(
        &self,
        user_id: Uuid,
        limit: i64,
        offset: i64,
    ) -> Result<Vec<User>> {
        // Validate that user exists
        let _user = self
            .user_repository
            .find_by_id(user_id)
            .await?
            .ok_or_else(|| AppError::NotFound("User not found".to_string()))?;

        self.user_repository
            .get_followers(user_id, limit, offset)
            .await
    }

    /// Get users that a user is following with pagination
    pub async fn get_user_following(
        &self,
        user_id: Uuid,
        limit: i64,
        offset: i64,
    ) -> Result<Vec<User>> {
        // Validate that user exists
        let _user = self
            .user_repository
            .find_by_id(user_id)
            .await?
            .ok_or_else(|| AppError::NotFound("User not found".to_string()))?;

        self.user_repository
            .get_following(user_id, limit, offset)
            .await
    }

    /// Check if one user follows another
    pub async fn is_following(&self, follower_id: Uuid, following_id: Uuid) -> Result<bool> {
        self.user_repository
            .is_following(follower_id, following_id)
            .await
    }

    /// Search for users by query
    pub async fn search_users(&self, query: &str, limit: i64, offset: i64) -> Result<Vec<User>> {
        if query.trim().is_empty() {
            return Err(AppError::ValidationError(
                "Search query cannot be empty".to_string(),
            ));
        }

        if query.len() < 2 {
            return Err(AppError::ValidationError(
                "Search query must be at least 2 characters".to_string(),
            ));
        }

        self.user_repository.search(query, limit, offset).await
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::domain::entities::{CreateUserRequest, UpdateUserRequest};
    use crate::domain::repositories::WalletRepository;
    use async_trait::async_trait;
    use rust_decimal::Decimal;
    use std::collections::HashMap;
    use std::sync::Mutex;
    use uuid::Uuid;

    // Mock WalletRepository for testing
    struct MockWalletRepository;

    #[async_trait]
    impl WalletRepository for MockWalletRepository {
        async fn create(
            &self,
            _wallet: &crate::domain::entities::Wallet,
        ) -> Result<crate::domain::entities::Wallet> {
            unimplemented!()
        }

        async fn find_by_id(&self, _id: Uuid) -> Result<Option<crate::domain::entities::Wallet>> {
            unimplemented!()
        }

        async fn find_by_user_id(
            &self,
            _user_id: Uuid,
        ) -> Result<Option<crate::domain::entities::Wallet>> {
            unimplemented!()
        }

        async fn update(
            &self,
            _wallet: &crate::domain::entities::Wallet,
        ) -> Result<crate::domain::entities::Wallet> {
            unimplemented!()
        }

        async fn update_balance(&self, _wallet_id: Uuid, _amount: Decimal) -> Result<()> {
            unimplemented!()
        }

        async fn credit_balance(&self, _wallet_id: Uuid, _amount: Decimal) -> Result<()> {
            unimplemented!()
        }

        async fn debit_balance(&self, _wallet_id: Uuid, _amount: Decimal) -> Result<()> {
            unimplemented!()
        }

        async fn get_balance(&self, _wallet_id: Uuid) -> Result<Decimal> {
            unimplemented!()
        }

        async fn has_sufficient_balance(&self, _wallet_id: Uuid, _amount: Decimal) -> Result<bool> {
            unimplemented!()
        }

        async fn lock_wallet(&self, _wallet_id: Uuid) -> Result<()> {
            unimplemented!()
        }

        async fn unlock_wallet(&self, _wallet_id: Uuid) -> Result<()> {
            unimplemented!()
        }

        async fn create_transaction(
            &self,
            _transaction: &crate::domain::entities::Transaction,
        ) -> Result<crate::domain::entities::Transaction> {
            unimplemented!()
        }

        async fn find_transaction_by_id(
            &self,
            _id: Uuid,
        ) -> Result<Option<crate::domain::entities::Transaction>> {
            unimplemented!()
        }

        async fn find_transaction_by_reference(
            &self,
            _reference: &str,
        ) -> Result<Option<crate::domain::entities::Transaction>> {
            unimplemented!()
        }

        async fn update_transaction(
            &self,
            _transaction: &crate::domain::entities::Transaction,
        ) -> Result<crate::domain::entities::Transaction> {
            unimplemented!()
        }

        async fn get_transaction_history(
            &self,
            _wallet_id: Uuid,
            _limit: i64,
            _offset: i64,
        ) -> Result<Vec<crate::domain::entities::Transaction>> {
            unimplemented!()
        }

        async fn get_pending_transactions(
            &self,
            _wallet_id: Uuid,
        ) -> Result<Vec<crate::domain::entities::Transaction>> {
            unimplemented!()
        }

        async fn process_transfer(
            &self,
            _sender_wallet_id: Uuid,
            _receiver_wallet_id: Uuid,
            _amount: Decimal,
            _transaction: &crate::domain::entities::Transaction,
        ) -> Result<crate::domain::entities::Transaction> {
            unimplemented!()
        }
    }

    // Enhanced MockUserRepository for testing
    struct TestUserRepository {
        users: Mutex<HashMap<Uuid, User>>,
        follows: Mutex<HashMap<(Uuid, Uuid), bool>>,
    }

    impl TestUserRepository {
        fn new() -> Self {
            Self {
                users: Mutex::new(HashMap::new()),
                follows: Mutex::new(HashMap::new()),
            }
        }

        fn add_user(&self, user: User) {
            self.users.lock().unwrap().insert(user.id, user);
        }
    }

    #[async_trait]
    impl UserRepository for TestUserRepository {
        async fn create(&self, user: &User) -> Result<User> {
            self.users.lock().unwrap().insert(user.id, user.clone());
            Ok(user.clone())
        }

        async fn find_by_id(&self, id: Uuid) -> Result<Option<User>> {
            Ok(self.users.lock().unwrap().get(&id).cloned())
        }

        async fn find_by_username(&self, username: &str) -> Result<Option<User>> {
            Ok(self
                .users
                .lock()
                .unwrap()
                .values()
                .find(|u| u.username.value() == username)
                .cloned())
        }

        async fn find_by_email(&self, email: &str) -> Result<Option<User>> {
            Ok(self
                .users
                .lock()
                .unwrap()
                .values()
                .find(|u| u.email.value() == email)
                .cloned())
        }

        async fn find_by_phone_number(&self, phone_number: &str) -> Result<Option<User>> {
            Ok(self
                .users
                .lock()
                .unwrap()
                .values()
                .find(|u| u.phone_number.as_ref().map(|p| p.value()) == Some(phone_number))
                .cloned())
        }

        async fn update(&self, user: &User) -> Result<User> {
            self.users.lock().unwrap().insert(user.id, user.clone());
            Ok(user.clone())
        }

        async fn delete(&self, id: Uuid) -> Result<()> {
            self.users.lock().unwrap().remove(&id);
            Ok(())
        }

        async fn username_exists(&self, username: &str) -> Result<bool> {
            Ok(self
                .users
                .lock()
                .unwrap()
                .values()
                .any(|u| u.username.value() == username))
        }

        async fn email_exists(&self, email: &str) -> Result<bool> {
            Ok(self
                .users
                .lock()
                .unwrap()
                .values()
                .any(|u| u.email.value() == email))
        }

        async fn search(&self, query: &str, _limit: i64, _offset: i64) -> Result<Vec<User>> {
            Ok(self
                .users
                .lock()
                .unwrap()
                .values()
                .filter(|u| {
                    u.username.value().contains(query)
                        || u.display_name
                            .as_ref()
                            .map(|d| d.value().contains(query))
                            .unwrap_or(false)
                })
                .cloned()
                .collect())
        }

        async fn get_followers(
            &self,
            _user_id: Uuid,
            _limit: i64,
            _offset: i64,
        ) -> Result<Vec<User>> {
            Ok(vec![])
        }

        async fn get_following(
            &self,
            _user_id: Uuid,
            _limit: i64,
            _offset: i64,
        ) -> Result<Vec<User>> {
            Ok(vec![])
        }

        async fn is_following(&self, follower_id: Uuid, following_id: Uuid) -> Result<bool> {
            Ok(self
                .follows
                .lock()
                .unwrap()
                .get(&(follower_id, following_id))
                .copied()
                .unwrap_or(false))
        }

        async fn follow(&self, follower_id: Uuid, following_id: Uuid) -> Result<()> {
            self.follows
                .lock()
                .unwrap()
                .insert((follower_id, following_id), true);

            // Update follower counts
            if let Some(follower) = self.users.lock().unwrap().get_mut(&follower_id) {
                follower.increment_following_count();
            }
            if let Some(following) = self.users.lock().unwrap().get_mut(&following_id) {
                following.increment_follower_count();
            }

            Ok(())
        }

        async fn unfollow(&self, follower_id: Uuid, following_id: Uuid) -> Result<()> {
            self.follows
                .lock()
                .unwrap()
                .remove(&(follower_id, following_id));

            // Update follower counts
            if let Some(follower) = self.users.lock().unwrap().get_mut(&follower_id) {
                follower.decrement_following_count();
            }
            if let Some(following) = self.users.lock().unwrap().get_mut(&following_id) {
                following.decrement_follower_count();
            }

            Ok(())
        }
    }

    fn create_test_user(username: &str, email: &str) -> User {
        let request = CreateUserRequest {
            username: username.to_string(),
            email: email.to_string(),
            phone_number: None,
            password_hash: "test_hash".to_string(),
            display_name: Some("Test User".to_string()),
            bio: None,
        };
        User::new(request).unwrap()
    }

    #[tokio::test]
    async fn test_update_profile_success() {
        let user_repo = Arc::new(TestUserRepository::new());
        let wallet_repo = Arc::new(MockWalletRepository);
        let service = UserManagementService::new(user_repo.clone(), wallet_repo);

        let user = create_test_user("testuser", "test@example.com");
        user_repo.add_user(user.clone());

        let update_request = UpdateUserRequest {
            display_name: Some("Updated Name".to_string()),
            bio: Some("Updated bio".to_string()),
            avatar_url: Some("https://example.com/avatar.jpg".to_string()),
        };

        let result = service.update_profile(user.id, update_request).await;
        assert!(result.is_ok());

        let updated_user = result.unwrap();
        assert_eq!(
            updated_user.display_name.as_ref().unwrap().value(),
            "Updated Name"
        );
        assert_eq!(updated_user.bio.as_ref().unwrap().value(), "Updated bio");
        assert_eq!(
            updated_user.avatar_url.as_ref().unwrap(),
            "https://example.com/avatar.jpg"
        );
    }

    #[tokio::test]
    async fn test_update_profile_user_not_found() {
        let user_repo = Arc::new(TestUserRepository::new());
        let wallet_repo = Arc::new(MockWalletRepository);
        let service = UserManagementService::new(user_repo, wallet_repo);

        let update_request = UpdateUserRequest {
            display_name: Some("Updated Name".to_string()),
            bio: None,
            avatar_url: None,
        };

        let result = service.update_profile(Uuid::new_v4(), update_request).await;
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), AppError::NotFound(_)));
    }

    #[tokio::test]
    async fn test_follow_user_success() {
        let user_repo = Arc::new(TestUserRepository::new());
        let wallet_repo = Arc::new(MockWalletRepository);
        let service = UserManagementService::new(user_repo.clone(), wallet_repo);

        let follower = create_test_user("follower", "follower@example.com");
        let following = create_test_user("following", "following@example.com");

        user_repo.add_user(follower.clone());
        user_repo.add_user(following.clone());

        let result = service.follow_user(follower.id, following.id).await;
        assert!(result.is_ok());

        let is_following = service
            .is_following(follower.id, following.id)
            .await
            .unwrap();
        assert!(is_following);
    }

    #[tokio::test]
    async fn test_follow_user_self_follow() {
        let user_repo = Arc::new(TestUserRepository::new());
        let wallet_repo = Arc::new(MockWalletRepository);
        let service = UserManagementService::new(user_repo.clone(), wallet_repo);

        let user = create_test_user("testuser", "test@example.com");
        user_repo.add_user(user.clone());

        let result = service.follow_user(user.id, user.id).await;
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), AppError::ValidationError(_)));
    }

    #[tokio::test]
    async fn test_follow_user_already_following() {
        let user_repo = Arc::new(TestUserRepository::new());
        let wallet_repo = Arc::new(MockWalletRepository);
        let service = UserManagementService::new(user_repo.clone(), wallet_repo);

        let follower = create_test_user("follower", "follower@example.com");
        let following = create_test_user("following", "following@example.com");

        user_repo.add_user(follower.clone());
        user_repo.add_user(following.clone());

        // First follow should succeed
        service
            .follow_user(follower.id, following.id)
            .await
            .unwrap();

        // Second follow should fail
        let result = service.follow_user(follower.id, following.id).await;
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), AppError::ValidationError(_)));
    }

    #[tokio::test]
    async fn test_unfollow_user_success() {
        let user_repo = Arc::new(TestUserRepository::new());
        let wallet_repo = Arc::new(MockWalletRepository);
        let service = UserManagementService::new(user_repo.clone(), wallet_repo);

        let follower = create_test_user("follower", "follower@example.com");
        let following = create_test_user("following", "following@example.com");

        user_repo.add_user(follower.clone());
        user_repo.add_user(following.clone());

        // First follow
        service
            .follow_user(follower.id, following.id)
            .await
            .unwrap();

        // Then unfollow
        let result = service.unfollow_user(follower.id, following.id).await;
        assert!(result.is_ok());

        let is_following = service
            .is_following(follower.id, following.id)
            .await
            .unwrap();
        assert!(!is_following);
    }

    #[tokio::test]
    async fn test_unfollow_user_not_following() {
        let user_repo = Arc::new(TestUserRepository::new());
        let wallet_repo = Arc::new(MockWalletRepository);
        let service = UserManagementService::new(user_repo.clone(), wallet_repo);

        let follower = create_test_user("follower", "follower@example.com");
        let following = create_test_user("following", "following@example.com");

        user_repo.add_user(follower.clone());
        user_repo.add_user(following.clone());

        let result = service.unfollow_user(follower.id, following.id).await;
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), AppError::ValidationError(_)));
    }

    #[tokio::test]
    async fn test_search_users_success() {
        let user_repo = Arc::new(TestUserRepository::new());
        let wallet_repo = Arc::new(MockWalletRepository);
        let service = UserManagementService::new(user_repo.clone(), wallet_repo);

        let user1 = create_test_user("testuser1", "test1@example.com");
        let user2 = create_test_user("testuser2", "test2@example.com");
        let user3 = create_test_user("otheruser", "other@example.com");

        user_repo.add_user(user1);
        user_repo.add_user(user2);
        user_repo.add_user(user3);

        let result = service.search_users("test", 10, 0).await;
        assert!(result.is_ok());

        let users = result.unwrap();
        assert_eq!(users.len(), 2);
    }

    #[tokio::test]
    async fn test_search_users_empty_query() {
        let user_repo = Arc::new(TestUserRepository::new());
        let wallet_repo = Arc::new(MockWalletRepository);
        let service = UserManagementService::new(user_repo, wallet_repo);

        let result = service.search_users("", 10, 0).await;
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), AppError::ValidationError(_)));
    }

    #[tokio::test]
    async fn test_search_users_short_query() {
        let user_repo = Arc::new(TestUserRepository::new());
        let wallet_repo = Arc::new(MockWalletRepository);
        let service = UserManagementService::new(user_repo, wallet_repo);

        let result = service.search_users("a", 10, 0).await;
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), AppError::ValidationError(_)));
    }

    #[tokio::test]
    async fn test_get_user_profile_success() {
        let user_repo = Arc::new(TestUserRepository::new());
        let wallet_repo = Arc::new(MockWalletRepository);
        let service = UserManagementService::new(user_repo.clone(), wallet_repo);

        let user = create_test_user("testuser", "test@example.com");
        user_repo.add_user(user.clone());

        let result = service.get_user_profile(user.id).await;
        assert!(result.is_ok());

        let retrieved_user = result.unwrap();
        assert_eq!(retrieved_user.id, user.id);
        assert_eq!(retrieved_user.username.value(), "testuser");
    }

    #[tokio::test]
    async fn test_get_user_profile_not_found() {
        let user_repo = Arc::new(TestUserRepository::new());
        let wallet_repo = Arc::new(MockWalletRepository);
        let service = UserManagementService::new(user_repo, wallet_repo);

        let result = service.get_user_profile(Uuid::new_v4()).await;
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), AppError::NotFound(_)));
    }
}
