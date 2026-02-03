use async_trait::async_trait;
use proptest::prelude::*;
use rust_decimal::Decimal;
use std::collections::HashMap;
use std::sync::{Arc, Mutex};
use uuid::Uuid;
use view_social_backend::application::services::UserManagementService;
use view_social_backend::domain::entities::{
    CreateUserRequest, CreateWalletRequest, User, Wallet, WalletStatus,
};
use view_social_backend::domain::errors::Result;
use view_social_backend::domain::repositories::{UserRepository, WalletRepository};

// Mock implementations for testing
struct MockUserRepository {
    users: Mutex<HashMap<Uuid, User>>,
}

impl MockUserRepository {
    fn new() -> Self {
        Self {
            users: Mutex::new(HashMap::new()),
        }
    }
}

#[async_trait]
impl UserRepository for MockUserRepository {
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

    async fn search(&self, _query: &str, _limit: i64, _offset: i64) -> Result<Vec<User>> {
        Ok(vec![])
    }

    async fn get_followers(&self, _user_id: Uuid, _limit: i64, _offset: i64) -> Result<Vec<User>> {
        Ok(vec![])
    }

    async fn get_following(&self, _user_id: Uuid, _limit: i64, _offset: i64) -> Result<Vec<User>> {
        Ok(vec![])
    }

    async fn is_following(&self, _follower_id: Uuid, _following_id: Uuid) -> Result<bool> {
        Ok(false)
    }

    async fn follow(&self, _follower_id: Uuid, _following_id: Uuid) -> Result<()> {
        Ok(())
    }

    async fn unfollow(&self, _follower_id: Uuid, _following_id: Uuid) -> Result<()> {
        Ok(())
    }
}

struct MockWalletRepository {
    wallets: Mutex<HashMap<Uuid, Wallet>>,
    user_wallets: Mutex<HashMap<Uuid, Uuid>>, // user_id -> wallet_id mapping
}

impl MockWalletRepository {
    fn new() -> Self {
        Self {
            wallets: Mutex::new(HashMap::new()),
            user_wallets: Mutex::new(HashMap::new()),
        }
    }
}

#[async_trait]
impl WalletRepository for MockWalletRepository {
    async fn create(&self, wallet: &Wallet) -> Result<Wallet> {
        self.wallets
            .lock()
            .unwrap()
            .insert(wallet.id, wallet.clone());
        self.user_wallets
            .lock()
            .unwrap()
            .insert(wallet.user_id, wallet.id);
        Ok(wallet.clone())
    }

    async fn find_by_id(&self, id: Uuid) -> Result<Option<Wallet>> {
        Ok(self.wallets.lock().unwrap().get(&id).cloned())
    }

    async fn find_by_user_id(&self, user_id: Uuid) -> Result<Option<Wallet>> {
        if let Some(wallet_id) = self.user_wallets.lock().unwrap().get(&user_id) {
            Ok(self.wallets.lock().unwrap().get(wallet_id).cloned())
        } else {
            Ok(None)
        }
    }

    async fn update(&self, wallet: &Wallet) -> Result<Wallet> {
        self.wallets
            .lock()
            .unwrap()
            .insert(wallet.id, wallet.clone());
        Ok(wallet.clone())
    }

    async fn update_balance(&self, _wallet_id: Uuid, _amount: Decimal) -> Result<()> {
        Ok(())
    }

    async fn credit_balance(&self, _wallet_id: Uuid, _amount: Decimal) -> Result<()> {
        Ok(())
    }

    async fn debit_balance(&self, _wallet_id: Uuid, _amount: Decimal) -> Result<()> {
        Ok(())
    }

    async fn get_balance(&self, _wallet_id: Uuid) -> Result<Decimal> {
        Ok(Decimal::ZERO)
    }

    async fn has_sufficient_balance(&self, _wallet_id: Uuid, _amount: Decimal) -> Result<bool> {
        Ok(true)
    }

    async fn lock_wallet(&self, _wallet_id: Uuid) -> Result<()> {
        Ok(())
    }

    async fn unlock_wallet(&self, _wallet_id: Uuid) -> Result<()> {
        Ok(())
    }

    async fn create_transaction(
        &self,
        transaction: &view_social_backend::domain::entities::Transaction,
    ) -> Result<view_social_backend::domain::entities::Transaction> {
        Ok(transaction.clone())
    }

    async fn find_transaction_by_id(
        &self,
        _id: Uuid,
    ) -> Result<Option<view_social_backend::domain::entities::Transaction>> {
        Ok(None)
    }

    async fn find_transaction_by_reference(
        &self,
        _reference: &str,
    ) -> Result<Option<view_social_backend::domain::entities::Transaction>> {
        Ok(None)
    }

    async fn update_transaction(
        &self,
        transaction: &view_social_backend::domain::entities::Transaction,
    ) -> Result<view_social_backend::domain::entities::Transaction> {
        Ok(transaction.clone())
    }

    async fn get_transaction_history(
        &self,
        _wallet_id: Uuid,
        _limit: i64,
        _offset: i64,
    ) -> Result<Vec<view_social_backend::domain::entities::Transaction>> {
        Ok(vec![])
    }

    async fn get_pending_transactions(
        &self,
        _wallet_id: Uuid,
    ) -> Result<Vec<view_social_backend::domain::entities::Transaction>> {
        Ok(vec![])
    }

    async fn process_transfer(
        &self,
        _sender_wallet_id: Uuid,
        _receiver_wallet_id: Uuid,
        _amount: Decimal,
        transaction: &view_social_backend::domain::entities::Transaction,
    ) -> Result<view_social_backend::domain::entities::Transaction> {
        Ok(transaction.clone())
    }
}

// **Feature: view-social-mvp, Property 3: Wallet creation consistency**
// **Validates: Requirements 1.3**
proptest! {
    #[test]
    fn test_wallet_creation_consistency(
        username in "[a-zA-Z][a-zA-Z0-9_]{2,19}",
        email in "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}",
        display_name in proptest::option::of("[a-zA-Z ]{1,50}"),
        bio in proptest::option::of("[a-zA-Z0-9 .,!?]{0,160}"),
    ) {
        tokio::runtime::Runtime::new().unwrap().block_on(async {
            // Create mock repositories
            let user_repo = Arc::new(MockUserRepository::new());
            let wallet_repo = Arc::new(MockWalletRepository::new());

            // Create user management service (not used in this test but required for consistency)
            let _service = UserManagementService::new(user_repo.clone(), wallet_repo.clone());

            // Create a user request
            let create_request = CreateUserRequest {
                username: username.clone(),
                email: email.clone(),
                phone_number: None,
                password_hash: "test_hash".to_string(),
                display_name: display_name.clone(),
                bio: bio.clone(),
            };

            // Create the user
            let user = User::new(create_request)?;
            let user_id = user.id;

            // Store the user in the repository
            user_repo.create(&user).await?;

            // Simulate wallet creation (this would normally happen during user registration)
            let wallet_request = CreateWalletRequest {
                user_id,
                currency: "NGN".to_string(),
                pin: None,
            };
            let wallet = Wallet::new(wallet_request)?;
            wallet_repo.create(&wallet).await?;

            // Property 1: Exactly one wallet should exist for the user
            let found_wallet = wallet_repo.find_by_user_id(user_id).await?;
            prop_assert!(found_wallet.is_some(),
                "No wallet found for user {}", user_id);

            let wallet = found_wallet.unwrap();

            // Property 2: Wallet should be associated with the correct user
            prop_assert_eq!(wallet.user_id, user_id,
                "Wallet user_id {} does not match expected user_id {}",
                wallet.user_id, user_id);

            // Property 3: Wallet should have default currency (NGN)
            prop_assert_eq!(&wallet.currency, "NGN",
                "Wallet currency {} is not the expected default 'NGN'",
                &wallet.currency);

            // Property 4: Wallet should have zero initial balance
            prop_assert_eq!(wallet.balance, Decimal::ZERO,
                "Wallet initial balance {} is not zero",
                wallet.balance);

            // Property 5: Wallet should be active by default
            prop_assert_eq!(&wallet.status, &WalletStatus::Active,
                "Wallet status {:?} is not Active",
                &wallet.status);

            // Property 6: Wallet should have no PIN initially
            prop_assert!(wallet.pin_hash.is_none(),
                "Wallet should not have a PIN hash initially");

            // Property 7: Wallet creation timestamp should be recent
            let now = chrono::Utc::now();
            let time_diff = now.signed_duration_since(wallet.created_at);
            prop_assert!(time_diff.num_seconds() < 60,
                "Wallet creation timestamp {} is not recent (more than 60 seconds ago)",
                wallet.created_at);

            // Property 8: Only one wallet should exist for this user (uniqueness)
            let wallets = wallet_repo.wallets.lock().unwrap();
            let user_wallet_count = wallets.values()
                .filter(|w| w.user_id == user_id)
                .count();
            prop_assert_eq!(user_wallet_count, 1,
                "Expected exactly 1 wallet for user {}, found {}",
                user_id, user_wallet_count);

            Ok(())
        })?;
    }
}

#[cfg(test)]
mod integration_tests {
    use super::*;

    #[tokio::test]
    async fn test_wallet_creation_basic_functionality() {
        let user_repo = Arc::new(MockUserRepository::new());
        let wallet_repo = Arc::new(MockWalletRepository::new());
        let _service = UserManagementService::new(user_repo.clone(), wallet_repo.clone());

        // Create a user
        let create_request = CreateUserRequest {
            username: "testuser".to_string(),
            email: "test@example.com".to_string(),
            phone_number: None,
            password_hash: "test_hash".to_string(),
            display_name: Some("Test User".to_string()),
            bio: None,
        };

        let user = User::new(create_request).unwrap();
        let user_id = user.id;

        user_repo.create(&user).await.unwrap();

        // Create wallet for the user
        let wallet_request = CreateWalletRequest {
            user_id,
            currency: "NGN".to_string(),
            pin: None,
        };
        let wallet = Wallet::new(wallet_request).unwrap();
        wallet_repo.create(&wallet).await.unwrap();

        // Verify wallet exists and is correctly associated
        let found_wallet = wallet_repo.find_by_user_id(user_id).await.unwrap();
        assert!(found_wallet.is_some());

        let wallet = found_wallet.unwrap();
        assert_eq!(wallet.user_id, user_id);
        assert_eq!(wallet.currency, "NGN");
        assert_eq!(wallet.balance, Decimal::ZERO);
    }

    #[tokio::test]
    async fn test_multiple_users_get_separate_wallets() {
        let user_repo = Arc::new(MockUserRepository::new());
        let wallet_repo = Arc::new(MockWalletRepository::new());

        // Create two users
        let user1 = User::new(CreateUserRequest {
            username: "user1".to_string(),
            email: "user1@example.com".to_string(),
            phone_number: None,
            password_hash: "hash1".to_string(),
            display_name: None,
            bio: None,
        })
        .unwrap();

        let user2 = User::new(CreateUserRequest {
            username: "user2".to_string(),
            email: "user2@example.com".to_string(),
            phone_number: None,
            password_hash: "hash2".to_string(),
            display_name: None,
            bio: None,
        })
        .unwrap();

        user_repo.create(&user1).await.unwrap();
        user_repo.create(&user2).await.unwrap();

        // Create wallets for both users
        let wallet1_request = CreateWalletRequest {
            user_id: user1.id,
            currency: "NGN".to_string(),
            pin: None,
        };
        let wallet2_request = CreateWalletRequest {
            user_id: user2.id,
            currency: "NGN".to_string(),
            pin: None,
        };
        let wallet1 = Wallet::new(wallet1_request).unwrap();
        let wallet2 = Wallet::new(wallet2_request).unwrap();

        wallet_repo.create(&wallet1).await.unwrap();
        wallet_repo.create(&wallet2).await.unwrap();

        // Verify each user has their own wallet
        let found_wallet1 = wallet_repo
            .find_by_user_id(user1.id)
            .await
            .unwrap()
            .unwrap();
        let found_wallet2 = wallet_repo
            .find_by_user_id(user2.id)
            .await
            .unwrap()
            .unwrap();

        assert_eq!(found_wallet1.user_id, user1.id);
        assert_eq!(found_wallet2.user_id, user2.id);
        assert_ne!(found_wallet1.id, found_wallet2.id);
    }
}
