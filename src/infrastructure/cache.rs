use crate::domain::errors::{AppError, Result};
use redis::{Client, Commands, Connection};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// Redis cache implementation for session and feed caching
pub struct RedisCache {
    client: Client,
}

impl RedisCache {
    /// Create a new Redis cache instance
    pub fn new(redis_url: &str) -> Result<Self> {
        let client = Client::open(redis_url)
            .map_err(|e| AppError::DatabaseError(format!("Failed to connect to Redis: {}", e)))?;

        Ok(RedisCache { client })
    }

    /// Get a Redis connection
    fn get_connection(&self) -> Result<Connection> {
        self.client
            .get_connection()
            .map_err(|e| AppError::DatabaseError(format!("Failed to get Redis connection: {}", e)))
    }

    /// Set a value in cache with expiration
    pub fn set<T>(&self, key: &str, value: &T, ttl_seconds: u64) -> Result<()>
    where
        T: Serialize,
    {
        let mut conn = self.get_connection()?;
        let serialized = serde_json::to_string(value).map_err(|e| {
            AppError::ValidationError(format!("Failed to serialize cache value: {}", e))
        })?;

        conn.set_ex::<_, _, ()>(key, serialized, ttl_seconds as usize)
            .map_err(|e| AppError::DatabaseError(format!("Failed to set cache value: {}", e)))?;

        Ok(())
    }

    /// Get a value from cache
    pub fn get<T>(&self, key: &str) -> Result<Option<T>>
    where
        T: for<'de> Deserialize<'de>,
    {
        let mut conn = self.get_connection()?;
        let result: Option<String> = conn
            .get(key)
            .map_err(|e| AppError::DatabaseError(format!("Failed to get cache value: {}", e)))?;

        match result {
            Some(serialized) => {
                let value = serde_json::from_str(&serialized).map_err(|e| {
                    AppError::ValidationError(format!("Failed to deserialize cache value: {}", e))
                })?;
                Ok(Some(value))
            }
            None => Ok(None),
        }
    }

    /// Delete a value from cache
    pub fn delete(&self, key: &str) -> Result<()> {
        let mut conn = self.get_connection()?;
        conn.del::<_, ()>(key)
            .map_err(|e| AppError::DatabaseError(format!("Failed to delete cache value: {}", e)))?;
        Ok(())
    }

    /// Check if a key exists in cache
    pub fn exists(&self, key: &str) -> Result<bool> {
        let mut conn = self.get_connection()?;
        let exists: bool = conn.exists(key).map_err(|e| {
            AppError::DatabaseError(format!("Failed to check cache key existence: {}", e))
        })?;
        Ok(exists)
    }

    /// Set multiple values in cache
    pub fn set_multiple<T>(&self, items: Vec<(String, T, u64)>) -> Result<()>
    where
        T: Serialize,
    {
        let mut conn = self.get_connection()?;

        for (key, value, ttl_seconds) in items {
            let serialized = serde_json::to_string(&value).map_err(|e| {
                AppError::ValidationError(format!("Failed to serialize cache value: {}", e))
            })?;

            conn.set_ex::<_, _, ()>(&key, serialized, ttl_seconds as usize)
                .map_err(|e| {
                    AppError::DatabaseError(format!("Failed to set cache value: {}", e))
                })?;
        }

        Ok(())
    }

    /// Get multiple values from cache
    pub fn get_multiple<T>(&self, keys: &[String]) -> Result<Vec<Option<T>>>
    where
        T: for<'de> Deserialize<'de>,
    {
        let mut conn = self.get_connection()?;
        let results: Vec<Option<String>> = conn.get(keys).map_err(|e| {
            AppError::DatabaseError(format!("Failed to get multiple cache values: {}", e))
        })?;

        let mut values = Vec::new();
        for result in results {
            match result {
                Some(serialized) => {
                    let value = serde_json::from_str(&serialized).map_err(|e| {
                        AppError::ValidationError(format!(
                            "Failed to deserialize cache value: {}",
                            e
                        ))
                    })?;
                    values.push(Some(value));
                }
                None => values.push(None),
            }
        }

        Ok(values)
    }

    /// Increment a counter in cache
    pub fn increment(&self, key: &str, by: i64) -> Result<i64> {
        let mut conn = self.get_connection()?;
        let result: i64 = conn.incr(key, by).map_err(|e| {
            AppError::DatabaseError(format!("Failed to increment cache counter: {}", e))
        })?;
        Ok(result)
    }

    /// Set expiration for a key
    pub fn expire(&self, key: &str, ttl_seconds: u64) -> Result<()> {
        let mut conn = self.get_connection()?;
        conn.expire::<_, ()>(key, ttl_seconds as usize)
            .map_err(|e| {
                AppError::DatabaseError(format!("Failed to set cache expiration: {}", e))
            })?;
        Ok(())
    }

    /// Add item to a list (for feed caching)
    pub fn list_push<T>(&self, key: &str, value: &T, max_length: Option<usize>) -> Result<()>
    where
        T: Serialize,
    {
        let mut conn = self.get_connection()?;
        let serialized = serde_json::to_string(value).map_err(|e| {
            AppError::ValidationError(format!("Failed to serialize list value: {}", e))
        })?;

        // Push to the left (newest items first)
        conn.lpush::<_, _, ()>(key, serialized)
            .map_err(|e| AppError::DatabaseError(format!("Failed to push to cache list: {}", e)))?;

        // Trim list to max length if specified
        if let Some(max_len) = max_length {
            conn.ltrim::<_, ()>(key, 0, (max_len as isize) - 1)
                .map_err(|e| {
                    AppError::DatabaseError(format!("Failed to trim cache list: {}", e))
                })?;
        }

        Ok(())
    }

    /// Get items from a list (for feed caching)
    pub fn list_range<T>(&self, key: &str, start: isize, end: isize) -> Result<Vec<T>>
    where
        T: for<'de> Deserialize<'de>,
    {
        let mut conn = self.get_connection()?;
        let results: Vec<String> = conn.lrange(key, start, end).map_err(|e| {
            AppError::DatabaseError(format!("Failed to get cache list range: {}", e))
        })?;

        let mut values = Vec::new();
        for serialized in results {
            let value = serde_json::from_str(&serialized).map_err(|e| {
                AppError::ValidationError(format!("Failed to deserialize list value: {}", e))
            })?;
            values.push(value);
        }

        Ok(values)
    }

    /// Remove items from a list
    pub fn list_remove<T>(&self, key: &str, value: &T) -> Result<i64>
    where
        T: Serialize,
    {
        let mut conn = self.get_connection()?;
        let serialized = serde_json::to_string(value).map_err(|e| {
            AppError::ValidationError(format!("Failed to serialize list value: {}", e))
        })?;

        let removed: i64 = conn.lrem(key, 0, serialized).map_err(|e| {
            AppError::DatabaseError(format!("Failed to remove from cache list: {}", e))
        })?;

        Ok(removed)
    }

    /// Clear all items from cache (use with caution)
    pub fn flush_all(&self) -> Result<()> {
        let mut conn = self.get_connection()?;
        redis::cmd("FLUSHALL").execute(&mut conn);
        Ok(())
    }
}

/// Cache-aside pattern implementation for frequently accessed data
pub struct CacheAsidePattern {
    cache: RedisCache,
}

impl CacheAsidePattern {
    pub fn new(cache: RedisCache) -> Self {
        Self { cache }
    }

    /// Get data with cache-aside pattern
    /// If data exists in cache, return it. Otherwise, fetch from source and cache it.
    pub async fn get_or_fetch<T, F, Fut>(
        &self,
        key: &str,
        ttl_seconds: u64,
        fetch_fn: F,
    ) -> Result<T>
    where
        T: Serialize + for<'de> Deserialize<'de> + Clone,
        F: FnOnce() -> Fut,
        Fut: std::future::Future<Output = Result<T>>,
    {
        // Try to get from cache first
        if let Some(cached_value) = self.cache.get::<T>(key)? {
            return Ok(cached_value);
        }

        // Cache miss - fetch from source
        let value = fetch_fn().await?;

        // Cache the fetched value
        self.cache.set(key, &value, ttl_seconds)?;

        Ok(value)
    }

    /// Invalidate cache entry
    pub fn invalidate(&self, key: &str) -> Result<()> {
        self.cache.delete(key)
    }

    /// Invalidate multiple cache entries by pattern
    pub fn invalidate_pattern(&self, pattern: &str) -> Result<()> {
        let mut conn = self.cache.get_connection()?;

        // Get all keys matching the pattern
        let keys: Vec<String> = conn.keys(pattern).map_err(|e| {
            AppError::DatabaseError(format!("Failed to get keys by pattern: {}", e))
        })?;

        // Delete all matching keys
        if !keys.is_empty() {
            conn.del::<_, ()>(&keys).map_err(|e| {
                AppError::DatabaseError(format!("Failed to delete keys by pattern: {}", e))
            })?;
        }

        Ok(())
    }
}

/// Cache key generators for consistent key naming
pub struct CacheKeys;

impl CacheKeys {
    /// Generate user session cache key
    pub fn user_session(user_id: Uuid) -> String {
        format!("session:user:{}", user_id)
    }

    /// Generate user feed cache key
    pub fn user_feed(user_id: Uuid, page: u32) -> String {
        format!("feed:user:{}:page:{}", user_id, page)
    }

    /// Generate post cache key
    pub fn post(post_id: Uuid) -> String {
        format!("post:{}", post_id)
    }

    /// Generate user profile cache key
    pub fn user_profile(user_id: Uuid) -> String {
        format!("profile:user:{}", user_id)
    }

    /// Generate conversation cache key
    pub fn conversation(conversation_id: Uuid) -> String {
        format!("conversation:{}", conversation_id)
    }

    /// Generate conversation messages cache key
    pub fn conversation_messages(conversation_id: Uuid, page: u32) -> String {
        format!("messages:conversation:{}:page:{}", conversation_id, page)
    }

    /// Generate wallet cache key
    pub fn wallet(user_id: Uuid) -> String {
        format!("wallet:user:{}", user_id)
    }

    /// Generate transaction cache key
    pub fn transaction(transaction_id: Uuid) -> String {
        format!("transaction:{}", transaction_id)
    }

    /// Generate user following list cache key
    pub fn user_following(user_id: Uuid) -> String {
        format!("following:user:{}", user_id)
    }

    /// Generate user followers list cache key
    pub fn user_followers(user_id: Uuid) -> String {
        format!("followers:user:{}", user_id)
    }

    /// Generate trending posts cache key
    pub fn trending_posts() -> String {
        "trending:posts".to_string()
    }

    /// Generate rate limit cache key
    pub fn rate_limit(user_id: Uuid, endpoint: &str) -> String {
        format!("rate_limit:{}:{}", user_id, endpoint)
    }
}

/// Cache invalidation strategies
pub struct CacheInvalidation {
    cache_aside: CacheAsidePattern,
}

impl CacheInvalidation {
    pub fn new(cache_aside: CacheAsidePattern) -> Self {
        Self { cache_aside }
    }

    /// Invalidate user-related caches when user data changes
    pub fn invalidate_user_caches(&self, user_id: Uuid) -> Result<()> {
        self.cache_aside
            .invalidate(&CacheKeys::user_profile(user_id))?;
        self.cache_aside
            .invalidate(&CacheKeys::user_session(user_id))?;
        self.cache_aside.invalidate(&CacheKeys::wallet(user_id))?;

        // Invalidate feed caches (user's own feed and feeds of followers)
        self.cache_aside
            .invalidate_pattern(&format!("feed:user:{}:*", user_id))?;

        Ok(())
    }

    /// Invalidate post-related caches when post data changes
    pub fn invalidate_post_caches(&self, post_id: Uuid, author_id: Uuid) -> Result<()> {
        self.cache_aside.invalidate(&CacheKeys::post(post_id))?;

        // Invalidate author's profile cache (for post count updates)
        self.cache_aside
            .invalidate(&CacheKeys::user_profile(author_id))?;

        // Invalidate trending posts cache
        self.cache_aside.invalidate(&CacheKeys::trending_posts())?;

        // Invalidate feed caches of users who follow the author
        self.cache_aside.invalidate_pattern(&format!("feed:*"))?;

        Ok(())
    }

    /// Invalidate conversation-related caches when messages are added
    pub fn invalidate_conversation_caches(&self, conversation_id: Uuid) -> Result<()> {
        self.cache_aside
            .invalidate(&CacheKeys::conversation(conversation_id))?;
        self.cache_aside
            .invalidate_pattern(&format!("messages:conversation:{}:*", conversation_id))?;

        Ok(())
    }

    /// Invalidate follow-related caches when follow relationships change
    pub fn invalidate_follow_caches(&self, follower_id: Uuid, following_id: Uuid) -> Result<()> {
        self.cache_aside
            .invalidate(&CacheKeys::user_following(follower_id))?;
        self.cache_aside
            .invalidate(&CacheKeys::user_followers(following_id))?;

        // Invalidate user profiles for follower count updates
        self.cache_aside
            .invalidate(&CacheKeys::user_profile(follower_id))?;
        self.cache_aside
            .invalidate(&CacheKeys::user_profile(following_id))?;

        // Invalidate follower's feed cache
        self.cache_aside
            .invalidate_pattern(&format!("feed:user:{}:*", follower_id))?;

        Ok(())
    }

    /// Invalidate transaction-related caches when payments occur
    pub fn invalidate_transaction_caches(
        &self,
        sender_id: Uuid,
        receiver_id: Uuid,
        transaction_id: Uuid,
    ) -> Result<()> {
        self.cache_aside.invalidate(&CacheKeys::wallet(sender_id))?;
        self.cache_aside
            .invalidate(&CacheKeys::wallet(receiver_id))?;
        self.cache_aside
            .invalidate(&CacheKeys::transaction(transaction_id))?;

        Ok(())
    }
}

/// Cache configuration constants
pub struct CacheConfig;

impl CacheConfig {
    /// Session cache TTL (24 hours)
    pub const SESSION_TTL: u64 = 24 * 60 * 60;

    /// Feed cache TTL (5 minutes)
    pub const FEED_TTL: u64 = 5 * 60;

    /// Post cache TTL (1 hour)
    pub const POST_TTL: u64 = 60 * 60;

    /// User profile cache TTL (30 minutes)
    pub const PROFILE_TTL: u64 = 30 * 60;

    /// Conversation cache TTL (10 minutes)
    pub const CONVERSATION_TTL: u64 = 10 * 60;

    /// Wallet cache TTL (5 minutes)
    pub const WALLET_TTL: u64 = 5 * 60;

    /// Transaction cache TTL (1 hour)
    pub const TRANSACTION_TTL: u64 = 60 * 60;

    /// Rate limit cache TTL (1 minute)
    pub const RATE_LIMIT_TTL: u64 = 60;

    /// Maximum feed items to cache
    pub const MAX_FEED_ITEMS: usize = 100;

    /// Maximum conversation messages to cache
    pub const MAX_CONVERSATION_MESSAGES: usize = 50;
}
