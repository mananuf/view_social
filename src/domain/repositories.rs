use crate::domain::entities::{Message, MessageRead, Post, Transaction, User, Wallet};
use crate::domain::errors::Result;
use async_trait::async_trait;
use chrono::DateTime;
use rust_decimal::Decimal;
use uuid::Uuid;

/// Repository trait for User entity operations
#[async_trait::async_trait]
pub trait UserRepository: Send + Sync {
    /// Create a new user
    async fn create(&self, user: &User) -> Result<User>;

    /// Find user by ID
    async fn find_by_id(&self, id: Uuid) -> Result<Option<User>>;

    /// Find user by username
    async fn find_by_username(&self, username: &str) -> Result<Option<User>>;

    /// Find user by email
    async fn find_by_email(&self, email: &str) -> Result<Option<User>>;

    /// Find user by phone number
    async fn find_by_phone_number(&self, phone_number: &str) -> Result<Option<User>>;

    /// Update user information
    async fn update(&self, user: &User) -> Result<User>;

    /// Delete user by ID
    async fn delete(&self, id: Uuid) -> Result<()>;

    /// Check if username exists
    async fn username_exists(&self, username: &str) -> Result<bool>;

    /// Check if email exists
    async fn email_exists(&self, email: &str) -> Result<bool>;

    /// Find users by search query (username or display name)
    async fn search(&self, query: &str, limit: i64, offset: i64) -> Result<Vec<User>>;

    /// Get user followers
    async fn get_followers(&self, user_id: Uuid, limit: i64, offset: i64) -> Result<Vec<User>>;

    /// Get users that a user is following
    async fn get_following(&self, user_id: Uuid, limit: i64, offset: i64) -> Result<Vec<User>>;

    /// Check if user A follows user B
    async fn is_following(&self, follower_id: Uuid, following_id: Uuid) -> Result<bool>;

    /// Follow a user
    async fn follow(&self, follower_id: Uuid, following_id: Uuid) -> Result<()>;

    /// Unfollow a user
    async fn unfollow(&self, follower_id: Uuid, following_id: Uuid) -> Result<()>;
}

/// Repository trait for Post entity operations
#[async_trait]
pub trait PostRepository: Send + Sync {
    /// Create a new post
    async fn create(&self, post: &Post) -> Result<Post>;

    /// Find post by ID
    async fn find_by_id(&self, id: Uuid) -> Result<Option<Post>>;

    /// Update post
    async fn update(&self, post: &Post) -> Result<Post>;

    /// Delete post by ID
    async fn delete(&self, id: Uuid) -> Result<()>;

    /// Get user's feed (posts from followed users)
    async fn find_feed(&self, user_id: Uuid, limit: i64, offset: i64) -> Result<Vec<Post>>;

    /// Get posts by user ID
    async fn find_by_user_id(&self, user_id: Uuid, limit: i64, offset: i64) -> Result<Vec<Post>>;

    /// Get public posts (for discovery)
    async fn find_public(&self, limit: i64, offset: i64) -> Result<Vec<Post>>;

    /// Get reels only
    async fn find_reels(&self, user_id: Option<Uuid>, limit: i64, offset: i64)
        -> Result<Vec<Post>>;

    /// Search posts by content
    async fn search(&self, query: &str, limit: i64, offset: i64) -> Result<Vec<Post>>;

    /// Increment engagement count (likes, comments, reshares)
    async fn increment_like_count(&self, post_id: Uuid) -> Result<()>;
    async fn decrement_like_count(&self, post_id: Uuid) -> Result<()>;
    async fn increment_comment_count(&self, post_id: Uuid) -> Result<()>;
    async fn decrement_comment_count(&self, post_id: Uuid) -> Result<()>;
    async fn increment_reshare_count(&self, post_id: Uuid) -> Result<()>;
    async fn decrement_reshare_count(&self, post_id: Uuid) -> Result<()>;

    /// Check if user has liked a post
    async fn has_user_liked(&self, user_id: Uuid, post_id: Uuid) -> Result<bool>;

    /// Like a post
    async fn like_post(&self, user_id: Uuid, post_id: Uuid) -> Result<()>;

    /// Unlike a post
    async fn unlike_post(&self, user_id: Uuid, post_id: Uuid) -> Result<()>;

    /// Get post likes
    async fn get_post_likes(&self, post_id: Uuid, limit: i64, offset: i64) -> Result<Vec<User>>;
}

/// Repository trait for Conversation entity operations
#[async_trait]
pub trait ConversationRepository: Send + Sync {
    /// Create a new conversation
    async fn create(
        &self,
        conversation_id: Uuid,
        participant_ids: Vec<Uuid>,
        is_group: bool,
        group_name: Option<String>,
        created_by: Uuid,
    ) -> Result<Uuid>;

    /// Find conversation by ID
    async fn find_by_id(
        &self,
        id: Uuid,
    ) -> Result<Option<(Uuid, Vec<Uuid>, bool, Option<String>, DateTime<chrono::Utc>)>>;

    /// Get all conversations for a user
    async fn find_by_user(
        &self,
        user_id: Uuid,
        limit: i64,
        offset: i64,
    ) -> Result<Vec<(Uuid, Vec<Uuid>, bool, Option<String>, DateTime<chrono::Utc>)>>;

    /// Check if user is participant in conversation
    async fn is_participant(&self, conversation_id: Uuid, user_id: Uuid) -> Result<bool>;

    /// Add participant to conversation
    async fn add_participant(&self, conversation_id: Uuid, user_id: Uuid) -> Result<()>;

    /// Remove participant from conversation
    async fn remove_participant(&self, conversation_id: Uuid, user_id: Uuid) -> Result<()>;

    /// Get conversation participants
    async fn get_participants(&self, conversation_id: Uuid) -> Result<Vec<Uuid>>;

    /// Find direct conversation between two users
    async fn find_direct_conversation(
        &self,
        user1_id: Uuid,
        user2_id: Uuid,
    ) -> Result<Option<Uuid>>;
}

/// Repository trait for Message entity operations
#[async_trait]
pub trait MessageRepository: Send + Sync {
    /// Create a new message
    async fn create(&self, message: &Message) -> Result<Message>;

    /// Find message by ID
    async fn find_by_id(&self, id: Uuid) -> Result<Option<Message>>;

    /// Update message
    async fn update(&self, message: &Message) -> Result<Message>;

    /// Delete message by ID
    async fn delete(&self, id: Uuid) -> Result<()>;

    /// Get messages in a conversation with pagination
    async fn find_by_conversation(
        &self,
        conversation_id: Uuid,
        limit: i64,
        before_id: Option<Uuid>,
    ) -> Result<Vec<Message>>;

    /// Get latest message in a conversation
    async fn find_latest_in_conversation(&self, conversation_id: Uuid) -> Result<Option<Message>>;

    /// Search messages by content
    async fn search_in_conversation(
        &self,
        conversation_id: Uuid,
        query: &str,
        limit: i64,
        offset: i64,
    ) -> Result<Vec<Message>>;

    /// Mark message as read by user
    async fn mark_as_read(&self, message_id: Uuid, user_id: Uuid) -> Result<()>;

    /// Get message read status
    async fn get_message_reads(&self, message_id: Uuid) -> Result<Vec<MessageRead>>;

    /// Check if message is read by user
    async fn is_read_by_user(&self, message_id: Uuid, user_id: Uuid) -> Result<bool>;

    /// Get unread message count for user in conversation
    async fn get_unread_count(&self, conversation_id: Uuid, user_id: Uuid) -> Result<i64>;

    /// Get all unread messages for user across all conversations
    async fn get_all_unread_count(&self, user_id: Uuid) -> Result<i64>;

    /// Find messages by type (e.g., payment messages)
    async fn find_by_type(
        &self,
        conversation_id: Uuid,
        message_type: &str,
        limit: i64,
        offset: i64,
    ) -> Result<Vec<Message>>;
}

/// Repository trait for Wallet entity operations
#[async_trait]
pub trait WalletRepository: Send + Sync {
    /// Create a new wallet
    async fn create(&self, wallet: &Wallet) -> Result<Wallet>;

    /// Find wallet by ID
    async fn find_by_id(&self, id: Uuid) -> Result<Option<Wallet>>;

    /// Find wallet by user ID
    async fn find_by_user_id(&self, user_id: Uuid) -> Result<Option<Wallet>>;

    /// Update wallet
    async fn update(&self, wallet: &Wallet) -> Result<Wallet>;

    /// Update wallet balance atomically
    async fn update_balance(&self, wallet_id: Uuid, amount: Decimal) -> Result<()>;

    /// Credit wallet balance atomically
    async fn credit_balance(&self, wallet_id: Uuid, amount: Decimal) -> Result<()>;

    /// Debit wallet balance atomically (with insufficient funds check)
    async fn debit_balance(&self, wallet_id: Uuid, amount: Decimal) -> Result<()>;

    /// Get wallet balance
    async fn get_balance(&self, wallet_id: Uuid) -> Result<Decimal>;

    /// Check if wallet has sufficient balance
    async fn has_sufficient_balance(&self, wallet_id: Uuid, amount: Decimal) -> Result<bool>;

    /// Lock wallet for transaction processing
    async fn lock_wallet(&self, wallet_id: Uuid) -> Result<()>;

    /// Unlock wallet after transaction processing
    async fn unlock_wallet(&self, wallet_id: Uuid) -> Result<()>;

    /// Create transaction record
    async fn create_transaction(&self, transaction: &Transaction) -> Result<Transaction>;

    /// Find transaction by ID
    async fn find_transaction_by_id(&self, id: Uuid) -> Result<Option<Transaction>>;

    /// Find transaction by reference
    async fn find_transaction_by_reference(&self, reference: &str) -> Result<Option<Transaction>>;

    /// Update transaction status
    async fn update_transaction(&self, transaction: &Transaction) -> Result<Transaction>;

    /// Get transaction history for wallet
    async fn get_transaction_history(
        &self,
        wallet_id: Uuid,
        limit: i64,
        offset: i64,
    ) -> Result<Vec<Transaction>>;

    /// Get pending transactions for wallet
    async fn get_pending_transactions(&self, wallet_id: Uuid) -> Result<Vec<Transaction>>;

    /// Process transfer between wallets atomically
    async fn process_transfer(
        &self,
        sender_wallet_id: Uuid,
        receiver_wallet_id: Uuid,
        amount: Decimal,
        transaction: &Transaction,
    ) -> Result<Transaction>;
}

/// Mock implementation for testing
#[cfg(test)]
pub struct MockUserRepository {
    // In a real mock, you'd store data in memory
}

#[cfg(test)]
impl MockUserRepository {
    pub fn new() -> Self {
        Self {}
    }
}

#[cfg(test)]
#[async_trait::async_trait]
impl UserRepository for MockUserRepository {
    async fn create(&self, user: &User) -> Result<User> {
        Ok(user.clone())
    }

    async fn find_by_id(&self, _id: Uuid) -> Result<Option<User>> {
        Ok(None)
    }

    async fn find_by_username(&self, _username: &str) -> Result<Option<User>> {
        Ok(None)
    }

    async fn find_by_email(&self, _email: &str) -> Result<Option<User>> {
        Ok(None)
    }

    async fn find_by_phone_number(&self, _phone_number: &str) -> Result<Option<User>> {
        Ok(None)
    }

    async fn update(&self, user: &User) -> Result<User> {
        Ok(user.clone())
    }

    async fn delete(&self, _id: Uuid) -> Result<()> {
        Ok(())
    }

    async fn username_exists(&self, _username: &str) -> Result<bool> {
        Ok(false)
    }

    async fn email_exists(&self, _email: &str) -> Result<bool> {
        Ok(false)
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
