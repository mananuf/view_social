use crate::domain::entities::{
    CreateNotificationRequest, DeviceToken, Notification, NotificationPreferences,
    NotificationType, Post, UpdateUserRequest, User,
};
use crate::domain::errors::{AppError, Result};
use crate::domain::repositories::{
    DeviceTokenRepository, NotificationPreferencesRepository, NotificationRepository,
    PostRepository, UserRepository, WalletRepository,
};
use crate::infrastructure::cache::{CacheConfig, RedisCache};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use uuid::Uuid;

/// User management service for coordinating user-related operations
pub struct UserManagementService {
    user_repository: Arc<dyn UserRepository>,
    wallet_repository: Arc<dyn WalletRepository>,
}

/// Feed generation service for creating and managing user feeds
pub struct FeedGenerationService {
    post_repository: Arc<dyn PostRepository>,
    user_repository: Arc<dyn UserRepository>,
    cache: Option<RedisCache>,
}

/// Feed sorting strategy
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum FeedSortStrategy {
    Chronological,
    Algorithmic,
}

/// Feed filter options
#[derive(Debug, Clone)]
pub struct FeedFilters {
    pub reels_only: bool,
    pub exclude_reels: bool,
    pub content_types: Option<Vec<String>>,
    pub min_engagement: Option<i32>,
}

impl Default for FeedFilters {
    fn default() -> Self {
        Self {
            reels_only: false,
            exclude_reels: false,
            content_types: None,
            min_engagement: None,
        }
    }
}

/// Cached feed item for efficient storage
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CachedFeedItem {
    pub post_id: Uuid,
    pub user_id: Uuid,
    pub created_at: DateTime<Utc>,
    pub engagement_score: f64,
    pub is_reel: bool,
    pub content_type: String,
}

impl From<&Post> for CachedFeedItem {
    fn from(post: &Post) -> Self {
        let content_type = match post.content_type {
            crate::domain::entities::PostContentType::Text => "text",
            crate::domain::entities::PostContentType::Image => "image",
            crate::domain::entities::PostContentType::Video => "video",
            crate::domain::entities::PostContentType::Mixed => "mixed",
        };

        Self {
            post_id: post.id,
            user_id: post.user_id,
            created_at: post.created_at,
            engagement_score: calculate_engagement_score(post),
            is_reel: post.is_reel,
            content_type: content_type.to_string(),
        }
    }
}

/// Calculate engagement score for algorithmic sorting
fn calculate_engagement_score(post: &Post) -> f64 {
    let total_engagement = post.like_count + post.comment_count + (post.reshare_count * 2);
    let hours_since_creation = (Utc::now() - post.created_at).num_hours() as f64;

    // Decay factor to prioritize recent posts
    let time_decay = (-hours_since_creation / 24.0).exp();

    // Base score from engagement
    let engagement_score = total_engagement as f64;

    // Apply time decay and boost for reels
    let mut final_score = engagement_score * time_decay;

    if post.is_reel {
        final_score *= 1.5; // Boost reels in algorithmic feed
    }

    final_score
}

impl FeedGenerationService {
    pub fn new(
        post_repository: Arc<dyn PostRepository>,
        user_repository: Arc<dyn UserRepository>,
        cache: Option<RedisCache>,
    ) -> Self {
        Self {
            post_repository,
            user_repository,
            cache,
        }
    }

    /// Generate feed for a user with specified strategy and filters
    pub async fn generate_feed(
        &self,
        user_id: Uuid,
        strategy: FeedSortStrategy,
        filters: FeedFilters,
        limit: i64,
        offset: i64,
    ) -> Result<Vec<Post>> {
        // Validate pagination parameters
        let limit = limit.min(100).max(1);
        let offset = offset.max(0);

        // Try to get from cache first if caching is enabled
        if let Some(ref cache) = self.cache {
            let cache_key = self.generate_cache_key(user_id, &strategy, &filters, limit, offset);

            if let Ok(Some(cached_items)) = cache.get::<Vec<CachedFeedItem>>(&cache_key) {
                // Convert cached items back to full posts
                return self.hydrate_cached_feed(cached_items).await;
            }
        }

        // Cache miss or no cache - generate feed from database
        let posts = match strategy {
            FeedSortStrategy::Chronological => {
                self.generate_chronological_feed(user_id, &filters, limit, offset)
                    .await?
            }
            FeedSortStrategy::Algorithmic => {
                self.generate_algorithmic_feed(user_id, &filters, limit, offset)
                    .await?
            }
        };

        // Cache the results if caching is enabled
        if let Some(ref cache) = self.cache {
            let cache_key = self.generate_cache_key(user_id, &strategy, &filters, limit, offset);
            let cached_items: Vec<CachedFeedItem> =
                posts.iter().map(CachedFeedItem::from).collect();

            // Cache for 5 minutes (feed data changes frequently)
            if let Err(e) = cache.set(&cache_key, &cached_items, CacheConfig::FEED_TTL) {
                tracing::warn!("Failed to cache feed for user {}: {}", user_id, e);
            }
        }

        Ok(posts)
    }

    /// Generate chronological feed (newest first)
    async fn generate_chronological_feed(
        &self,
        user_id: Uuid,
        filters: &FeedFilters,
        limit: i64,
        offset: i64,
    ) -> Result<Vec<Post>> {
        let mut posts = if filters.reels_only {
            // Get reels only from followed users
            self.post_repository
                .find_reels(Some(user_id), limit, offset)
                .await?
        } else {
            // Get all posts from followed users
            self.post_repository
                .find_feed(user_id, limit, offset)
                .await?
        };

        // Apply additional filters
        posts = self.apply_filters(posts, filters);

        // Sort chronologically (newest first) - should already be sorted by database
        posts.sort_by(|a, b| b.created_at.cmp(&a.created_at));

        Ok(posts)
    }

    /// Generate algorithmic feed (engagement-based with time decay)
    async fn generate_algorithmic_feed(
        &self,
        user_id: Uuid,
        filters: &FeedFilters,
        limit: i64,
        offset: i64,
    ) -> Result<Vec<Post>> {
        // Get more posts than requested to allow for better algorithmic sorting
        let fetch_limit = (limit * 3).min(300);

        let mut posts = if filters.reels_only {
            self.post_repository
                .find_reels(Some(user_id), fetch_limit, 0)
                .await?
        } else {
            self.post_repository
                .find_feed(user_id, fetch_limit, 0)
                .await?
        };

        // Apply filters before sorting
        posts = self.apply_filters(posts, filters);

        // Sort by engagement score (algorithmic)
        posts.sort_by(|a, b| {
            let score_a = calculate_engagement_score(a);
            let score_b = calculate_engagement_score(b);
            score_b
                .partial_cmp(&score_a)
                .unwrap_or(std::cmp::Ordering::Equal)
        });

        // Apply pagination after sorting
        let start = offset as usize;
        let end = (start + limit as usize).min(posts.len());

        if start >= posts.len() {
            return Ok(vec![]);
        }

        Ok(posts[start..end].to_vec())
    }

    /// Apply content filters to posts
    fn apply_filters(&self, mut posts: Vec<Post>, filters: &FeedFilters) -> Vec<Post> {
        posts.retain(|post| {
            // Filter by reel preference
            if filters.reels_only && !post.is_reel {
                return false;
            }
            if filters.exclude_reels && post.is_reel {
                return false;
            }

            // Filter by content types
            if let Some(ref content_types) = filters.content_types {
                let post_content_type = match post.content_type {
                    crate::domain::entities::PostContentType::Text => "text",
                    crate::domain::entities::PostContentType::Image => "image",
                    crate::domain::entities::PostContentType::Video => "video",
                    crate::domain::entities::PostContentType::Mixed => "mixed",
                };

                if !content_types.contains(&post_content_type.to_string()) {
                    return false;
                }
            }

            // Filter by minimum engagement
            if let Some(min_engagement) = filters.min_engagement {
                let total_engagement = post.like_count + post.comment_count + post.reshare_count;
                if total_engagement < min_engagement {
                    return false;
                }
            }

            true
        });

        posts
    }

    /// Generate cache key for feed
    fn generate_cache_key(
        &self,
        user_id: Uuid,
        strategy: &FeedSortStrategy,
        filters: &FeedFilters,
        limit: i64,
        offset: i64,
    ) -> String {
        let strategy_str = match strategy {
            FeedSortStrategy::Chronological => "chrono",
            FeedSortStrategy::Algorithmic => "algo",
        };

        let mut key_parts = vec![
            format!("feed:{}:{}", user_id, strategy_str),
            format!("limit:{}", limit),
            format!("offset:{}", offset),
        ];

        if filters.reels_only {
            key_parts.push("reels_only".to_string());
        }
        if filters.exclude_reels {
            key_parts.push("no_reels".to_string());
        }
        if let Some(ref content_types) = filters.content_types {
            key_parts.push(format!("types:{}", content_types.join(",")));
        }
        if let Some(min_engagement) = filters.min_engagement {
            key_parts.push(format!("min_eng:{}", min_engagement));
        }

        key_parts.join(":")
    }

    /// Convert cached feed items back to full posts
    async fn hydrate_cached_feed(&self, cached_items: Vec<CachedFeedItem>) -> Result<Vec<Post>> {
        let mut posts = Vec::new();

        for item in cached_items {
            if let Some(post) = self.post_repository.find_by_id(item.post_id).await? {
                posts.push(post);
            }
        }

        Ok(posts)
    }

    /// Get reels feed specifically
    pub async fn get_reels_feed(
        &self,
        user_id: Uuid,
        limit: i64,
        offset: i64,
    ) -> Result<Vec<Post>> {
        let filters = FeedFilters {
            reels_only: true,
            ..Default::default()
        };

        // Use algorithmic sorting for reels to promote engaging content
        self.generate_feed(
            user_id,
            FeedSortStrategy::Algorithmic,
            filters,
            limit,
            offset,
        )
        .await
    }

    /// Get trending posts (public posts with high engagement)
    pub async fn get_trending_posts(&self, limit: i64, offset: i64) -> Result<Vec<Post>> {
        // Try cache first
        if let Some(ref cache) = self.cache {
            let cache_key = format!("trending:posts:{}:{}", limit, offset);

            if let Ok(Some(cached_items)) = cache.get::<Vec<CachedFeedItem>>(&cache_key) {
                return self.hydrate_cached_feed(cached_items).await;
            }
        }

        // Get public posts with high engagement
        let mut posts = self.post_repository.find_public(limit * 3, 0).await?;

        // Filter for high engagement (at least 5 total interactions)
        posts.retain(|post| {
            let total_engagement = post.like_count + post.comment_count + post.reshare_count;
            total_engagement >= 5
        });

        // Sort by engagement score
        posts.sort_by(|a, b| {
            let score_a = calculate_engagement_score(a);
            let score_b = calculate_engagement_score(b);
            score_b
                .partial_cmp(&score_a)
                .unwrap_or(std::cmp::Ordering::Equal)
        });

        // Apply pagination
        let start = offset as usize;
        let end = (start + limit as usize).min(posts.len());

        let result = if start >= posts.len() {
            vec![]
        } else {
            posts[start..end].to_vec()
        };

        // Cache trending posts for 10 minutes
        if let Some(ref cache) = self.cache {
            let cache_key = format!("trending:posts:{}:{}", limit, offset);
            let cached_items: Vec<CachedFeedItem> =
                result.iter().map(CachedFeedItem::from).collect();

            if let Err(e) = cache.set(&cache_key, &cached_items, 10 * 60) {
                tracing::warn!("Failed to cache trending posts: {}", e);
            }
        }

        Ok(result)
    }

    /// Invalidate feed cache for a user
    pub async fn invalidate_user_feed_cache(&self, user_id: Uuid) -> Result<()> {
        if let Some(ref cache) = self.cache {
            // Invalidate common feed cache keys for this user
            let strategies = ["chrono", "algo"];
            let limits = [20, 50, 100];
            let offsets = [0, 20, 40, 60, 80];

            for strategy in &strategies {
                for limit in &limits {
                    for offset in &offsets {
                        let key = format!(
                            "feed:{}:{}:limit:{}:offset:{}",
                            user_id, strategy, limit, offset
                        );
                        let _ = cache.delete(&key); // Ignore errors for cache invalidation
                    }
                }
            }
        }
        Ok(())
    }

    /// Invalidate trending posts cache
    pub async fn invalidate_trending_cache(&self) -> Result<()> {
        if let Some(ref cache) = self.cache {
            // Invalidate common trending cache keys
            let limits = [20, 50, 100];
            let offsets = [0, 20, 40, 60, 80];

            for limit in &limits {
                for offset in &offsets {
                    let key = format!("trending:posts:{}:{}", limit, offset);
                    let _ = cache.delete(&key); // Ignore errors for cache invalidation
                }
            }
        }
        Ok(())
    }

    /// Get feed statistics for analytics
    pub async fn get_feed_stats(&self, user_id: Uuid) -> Result<FeedStats> {
        // Get user's following count
        let user = self
            .user_repository
            .find_by_id(user_id)
            .await?
            .ok_or_else(|| AppError::NotFound("User not found".to_string()))?;

        // Get sample of recent posts from feed
        let recent_posts = self.post_repository.find_feed(user_id, 50, 0).await?;

        let total_posts = recent_posts.len() as i32;
        let reel_count = recent_posts.iter().filter(|p| p.is_reel).count() as i32;
        let avg_engagement = if total_posts > 0 {
            recent_posts
                .iter()
                .map(|p| p.like_count + p.comment_count + p.reshare_count)
                .sum::<i32>() as f64
                / total_posts as f64
        } else {
            0.0
        };

        Ok(FeedStats {
            following_count: user.following_count,
            recent_posts_count: total_posts,
            reel_percentage: if total_posts > 0 {
                (reel_count as f64 / total_posts as f64) * 100.0
            } else {
                0.0
            },
            avg_engagement,
        })
    }
}

/// Feed statistics for analytics
#[derive(Debug, Serialize, Deserialize)]
pub struct FeedStats {
    pub following_count: i32,
    pub recent_posts_count: i32,
    pub reel_percentage: f64,
    pub avg_engagement: f64,
}

/// Notification service for managing notifications and push notifications
pub struct NotificationService {
    notification_repository: Arc<dyn NotificationRepository>,
    device_token_repository: Arc<dyn DeviceTokenRepository>,
    preferences_repository: Arc<dyn NotificationPreferencesRepository>,
    user_repository: Arc<dyn UserRepository>,
}

/// Push notification payload
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PushNotificationPayload {
    pub title: String,
    pub body: String,
    pub data: serde_json::Value,
    pub badge_count: Option<i32>,
}

/// Notification statistics
#[derive(Debug, Serialize, Deserialize)]
pub struct NotificationStats {
    pub total_notifications: i64,
    pub unread_count: i64,
    pub recent_count: i64, // Last 24 hours
    pub by_type: std::collections::HashMap<String, i64>,
}

impl NotificationService {
    pub fn new(
        notification_repository: Arc<dyn NotificationRepository>,
        device_token_repository: Arc<dyn DeviceTokenRepository>,
        preferences_repository: Arc<dyn NotificationPreferencesRepository>,
        user_repository: Arc<dyn UserRepository>,
    ) -> Self {
        Self {
            notification_repository,
            device_token_repository,
            preferences_repository,
            user_repository,
        }
    }

    /// Create and send a notification
    pub async fn create_notification(
        &self,
        request: CreateNotificationRequest,
    ) -> Result<Notification> {
        // Check if user exists
        let _user = self
            .user_repository
            .find_by_id(request.user_id)
            .await?
            .ok_or_else(|| AppError::NotFound("User not found".to_string()))?;

        // Check user preferences
        let preferences = self
            .get_user_preferences(request.user_id)
            .await?
            .unwrap_or_else(|| NotificationPreferences::new(request.user_id));

        // Check if this type of notification is enabled
        if !preferences.is_notification_enabled(&request.notification_type) {
            return Err(AppError::ValidationError(
                "Notification type is disabled for this user".to_string(),
            ));
        }

        // Create the notification
        let notification = Notification::new(request)?;
        let created_notification = self.notification_repository.create(&notification).await?;

        // Send push notification if enabled
        if preferences.push_notifications_enabled {
            if let Err(e) = self.send_push_notification(&created_notification).await {
                tracing::warn!(
                    "Failed to send push notification for notification {}: {}",
                    created_notification.id,
                    e
                );
                // Don't fail the entire operation if push notification fails
            }
        }

        Ok(created_notification)
    }

    /// Send push notification to user's devices
    async fn send_push_notification(&self, notification: &Notification) -> Result<()> {
        let device_tokens = self
            .device_token_repository
            .find_active_by_user_id(notification.user_id)
            .await?;

        if device_tokens.is_empty() {
            tracing::debug!(
                "No active device tokens found for user {}",
                notification.user_id
            );
            return Ok(());
        }

        let unread_count = self
            .notification_repository
            .get_unread_count(notification.user_id)
            .await?;

        let payload = PushNotificationPayload {
            title: notification.title.clone(),
            body: notification.body.clone(),
            data: notification.data.clone(),
            badge_count: Some(unread_count as i32),
        };

        // Send to each device
        for device_token in device_tokens {
            if let Err(e) = self.send_to_device(&device_token, &payload).await {
                tracing::warn!(
                    "Failed to send push notification to device {}: {}",
                    device_token.id,
                    e
                );
                // Consider deactivating invalid tokens
                if e.to_string().contains("invalid token") {
                    let _ = self
                        .device_token_repository
                        .deactivate(device_token.id)
                        .await;
                }
            }
        }

        Ok(())
    }

    /// Send push notification to a specific device
    async fn send_to_device(
        &self,
        device_token: &DeviceToken,
        payload: &PushNotificationPayload,
    ) -> Result<()> {
        // This is a placeholder for actual push notification implementation
        // In a real implementation, you would integrate with:
        // - Firebase Cloud Messaging (FCM) for Android
        // - Apple Push Notification Service (APNs) for iOS
        // - Web Push for web browsers

        tracing::info!(
            "Sending push notification to {} device {}: {}",
            device_token.platform,
            device_token.id,
            payload.title
        );

        // Simulate push notification sending
        // In production, replace this with actual push service calls
        match device_token.platform {
            crate::domain::entities::DevicePlatform::Android => {
                // Send via FCM
                self.send_fcm_notification(device_token, payload).await
            }
            crate::domain::entities::DevicePlatform::Ios => {
                // Send via APNs
                self.send_apns_notification(device_token, payload).await
            }
            crate::domain::entities::DevicePlatform::Web => {
                // Send via Web Push
                self.send_web_push_notification(device_token, payload).await
            }
        }
    }

    /// Send FCM notification (Android)
    async fn send_fcm_notification(
        &self,
        device_token: &DeviceToken,
        payload: &PushNotificationPayload,
    ) -> Result<()> {
        // Placeholder for FCM implementation
        tracing::debug!(
            "FCM notification sent to token {}: {}",
            device_token.token,
            payload.title
        );
        Ok(())
    }

    /// Send APNs notification (iOS)
    async fn send_apns_notification(
        &self,
        device_token: &DeviceToken,
        payload: &PushNotificationPayload,
    ) -> Result<()> {
        // Placeholder for APNs implementation
        tracing::debug!(
            "APNs notification sent to token {}: {}",
            device_token.token,
            payload.title
        );
        Ok(())
    }

    /// Send Web Push notification
    async fn send_web_push_notification(
        &self,
        device_token: &DeviceToken,
        payload: &PushNotificationPayload,
    ) -> Result<()> {
        // Placeholder for Web Push implementation
        tracing::debug!(
            "Web Push notification sent to token {}: {}",
            device_token.token,
            payload.title
        );
        Ok(())
    }

    /// Get notifications for a user
    pub async fn get_user_notifications(
        &self,
        user_id: Uuid,
        limit: i64,
        offset: i64,
    ) -> Result<Vec<Notification>> {
        // Validate that user exists
        let _user = self
            .user_repository
            .find_by_id(user_id)
            .await?
            .ok_or_else(|| AppError::NotFound("User not found".to_string()))?;

        self.notification_repository
            .find_by_user_id(user_id, limit, offset)
            .await
    }

    /// Get unread notifications for a user
    pub async fn get_unread_notifications(&self, user_id: Uuid) -> Result<Vec<Notification>> {
        // Validate that user exists
        let _user = self
            .user_repository
            .find_by_id(user_id)
            .await?
            .ok_or_else(|| AppError::NotFound("User not found".to_string()))?;

        self.notification_repository
            .find_unread_by_user_id(user_id)
            .await
    }

    /// Mark notification as read
    pub async fn mark_notification_as_read(&self, notification_id: Uuid) -> Result<()> {
        // Check if notification exists
        let _notification = self
            .notification_repository
            .find_by_id(notification_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Notification not found".to_string()))?;

        self.notification_repository
            .mark_as_read(notification_id)
            .await
    }

    /// Mark all notifications as read for a user
    pub async fn mark_all_notifications_as_read(&self, user_id: Uuid) -> Result<()> {
        // Validate that user exists
        let _user = self
            .user_repository
            .find_by_id(user_id)
            .await?
            .ok_or_else(|| AppError::NotFound("User not found".to_string()))?;

        self.notification_repository.mark_all_as_read(user_id).await
    }

    /// Get notification statistics for a user
    pub async fn get_notification_stats(&self, user_id: Uuid) -> Result<NotificationStats> {
        // Validate that user exists
        let _user = self
            .user_repository
            .find_by_id(user_id)
            .await?
            .ok_or_else(|| AppError::NotFound("User not found".to_string()))?;

        let unread_count = self
            .notification_repository
            .get_unread_count(user_id)
            .await?;

        // Get recent notifications (last 100) to calculate stats
        let recent_notifications = self
            .notification_repository
            .find_by_user_id(user_id, 100, 0)
            .await?;

        let total_notifications = recent_notifications.len() as i64;
        let recent_count = recent_notifications
            .iter()
            .filter(|n| n.is_recent())
            .count() as i64;

        // Count by type
        let mut by_type = std::collections::HashMap::new();
        for notification in &recent_notifications {
            let type_str = notification.notification_type.to_string();
            *by_type.entry(type_str).or_insert(0) += 1;
        }

        Ok(NotificationStats {
            total_notifications,
            unread_count,
            recent_count,
            by_type,
        })
    }

    /// Register device token for push notifications
    pub async fn register_device_token(&self, device_token: &DeviceToken) -> Result<DeviceToken> {
        // Validate that user exists
        let _user = self
            .user_repository
            .find_by_id(device_token.user_id)
            .await?
            .ok_or_else(|| AppError::NotFound("User not found".to_string()))?;

        self.device_token_repository.upsert(device_token).await
    }

    /// Unregister device token
    pub async fn unregister_device_token(&self, token_id: Uuid) -> Result<()> {
        self.device_token_repository.deactivate(token_id).await
    }

    /// Get user notification preferences
    pub async fn get_user_preferences(
        &self,
        user_id: Uuid,
    ) -> Result<Option<NotificationPreferences>> {
        self.preferences_repository.find_by_user_id(user_id).await
    }

    /// Update user notification preferences
    pub async fn update_user_preferences(
        &self,
        preferences: &NotificationPreferences,
    ) -> Result<NotificationPreferences> {
        // Validate that user exists
        let _user = self
            .user_repository
            .find_by_id(preferences.user_id)
            .await?
            .ok_or_else(|| AppError::NotFound("User not found".to_string()))?;

        self.preferences_repository.upsert(preferences).await
    }

    /// Create notification for message received
    pub async fn notify_message_received(
        &self,
        recipient_id: Uuid,
        sender_name: &str,
        message_preview: &str,
        conversation_id: Uuid,
    ) -> Result<()> {
        let request = CreateNotificationRequest {
            user_id: recipient_id,
            notification_type: NotificationType::Message,
            title: format!("New message from {}", sender_name),
            body: message_preview.to_string(),
            data: Some(serde_json::json!({
                "conversation_id": conversation_id,
                "sender_name": sender_name
            })),
        };

        self.create_notification(request).await?;
        Ok(())
    }

    /// Create notification for post liked
    pub async fn notify_post_liked(
        &self,
        post_author_id: Uuid,
        liker_name: &str,
        post_id: Uuid,
    ) -> Result<()> {
        let request = CreateNotificationRequest {
            user_id: post_author_id,
            notification_type: NotificationType::Like,
            title: format!("{} liked your post", liker_name),
            body: "Your post received a new like".to_string(),
            data: Some(serde_json::json!({
                "post_id": post_id,
                "liker_name": liker_name
            })),
        };

        self.create_notification(request).await?;
        Ok(())
    }

    /// Create notification for new follower
    pub async fn notify_new_follower(
        &self,
        followed_user_id: Uuid,
        follower_name: &str,
        follower_id: Uuid,
    ) -> Result<()> {
        let request = CreateNotificationRequest {
            user_id: followed_user_id,
            notification_type: NotificationType::Follow,
            title: format!("{} started following you", follower_name),
            body: "You have a new follower".to_string(),
            data: Some(serde_json::json!({
                "follower_id": follower_id,
                "follower_name": follower_name
            })),
        };

        self.create_notification(request).await?;
        Ok(())
    }

    /// Create notification for payment received
    pub async fn notify_payment_received(
        &self,
        recipient_id: Uuid,
        sender_name: &str,
        amount: &str,
        transaction_id: Uuid,
    ) -> Result<()> {
        let request = CreateNotificationRequest {
            user_id: recipient_id,
            notification_type: NotificationType::PaymentReceived,
            title: format!("Payment received from {}", sender_name),
            body: format!("You received {} from {}", amount, sender_name),
            data: Some(serde_json::json!({
                "transaction_id": transaction_id,
                "sender_name": sender_name,
                "amount": amount
            })),
        };

        self.create_notification(request).await?;
        Ok(())
    }

    /// Clean up old notifications
    pub async fn cleanup_old_notifications(&self, days: i32) -> Result<i64> {
        self.notification_repository
            .delete_old_notifications(days)
            .await
    }

    /// Clean up inactive device tokens
    pub async fn cleanup_inactive_tokens(&self, days: i32) -> Result<i64> {
        self.device_token_repository
            .delete_inactive_tokens(days)
            .await
    }
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
#[cfg(test)]
mod feed_generation_tests {
    use super::*;
    use crate::domain::entities::{CreatePostRequest, PostContentType, PostVisibility};
    use crate::domain::repositories::{MockUserRepository, PostRepository};
    use async_trait::async_trait;
    use std::collections::HashMap;
    use std::sync::Mutex;

    // Mock PostRepository for testing
    struct MockPostRepository {
        posts: Mutex<HashMap<Uuid, Post>>,
        user_feeds: Mutex<HashMap<Uuid, Vec<Uuid>>>, // user_id -> post_ids
    }

    impl MockPostRepository {
        fn new() -> Self {
            Self {
                posts: Mutex::new(HashMap::new()),
                user_feeds: Mutex::new(HashMap::new()),
            }
        }

        fn add_post(&self, post: Post) {
            self.posts.lock().unwrap().insert(post.id, post);
        }

        fn set_user_feed(&self, user_id: Uuid, post_ids: Vec<Uuid>) {
            self.user_feeds.lock().unwrap().insert(user_id, post_ids);
        }
    }

    #[async_trait]
    impl PostRepository for MockPostRepository {
        async fn create(&self, post: &Post) -> Result<Post> {
            self.posts.lock().unwrap().insert(post.id, post.clone());
            Ok(post.clone())
        }

        async fn find_by_id(&self, id: Uuid) -> Result<Option<Post>> {
            Ok(self.posts.lock().unwrap().get(&id).cloned())
        }

        async fn update(&self, post: &Post) -> Result<Post> {
            self.posts.lock().unwrap().insert(post.id, post.clone());
            Ok(post.clone())
        }

        async fn delete(&self, id: Uuid) -> Result<()> {
            self.posts.lock().unwrap().remove(&id);
            Ok(())
        }

        async fn find_feed(&self, user_id: Uuid, limit: i64, offset: i64) -> Result<Vec<Post>> {
            let feeds = self.user_feeds.lock().unwrap();
            let posts = self.posts.lock().unwrap();

            if let Some(post_ids) = feeds.get(&user_id) {
                let mut user_posts: Vec<Post> = post_ids
                    .iter()
                    .filter_map(|id| posts.get(id).cloned())
                    .collect();

                // Sort by created_at descending (newest first)
                user_posts.sort_by(|a, b| b.created_at.cmp(&a.created_at));

                let start = offset as usize;
                let end = (start + limit as usize).min(user_posts.len());

                if start >= user_posts.len() {
                    Ok(vec![])
                } else {
                    Ok(user_posts[start..end].to_vec())
                }
            } else {
                Ok(vec![])
            }
        }

        async fn find_by_user_id(
            &self,
            user_id: Uuid,
            limit: i64,
            offset: i64,
        ) -> Result<Vec<Post>> {
            let posts = self.posts.lock().unwrap();
            let mut user_posts: Vec<Post> = posts
                .values()
                .filter(|p| p.user_id == user_id)
                .cloned()
                .collect();

            user_posts.sort_by(|a, b| b.created_at.cmp(&a.created_at));

            let start = offset as usize;
            let end = (start + limit as usize).min(user_posts.len());

            if start >= user_posts.len() {
                Ok(vec![])
            } else {
                Ok(user_posts[start..end].to_vec())
            }
        }

        async fn find_public(&self, limit: i64, offset: i64) -> Result<Vec<Post>> {
            let posts = self.posts.lock().unwrap();
            let mut public_posts: Vec<Post> = posts
                .values()
                .filter(|p| p.visibility == PostVisibility::Public)
                .cloned()
                .collect();

            public_posts.sort_by(|a, b| b.created_at.cmp(&a.created_at));

            let start = offset as usize;
            let end = (start + limit as usize).min(public_posts.len());

            if start >= public_posts.len() {
                Ok(vec![])
            } else {
                Ok(public_posts[start..end].to_vec())
            }
        }

        async fn find_reels(
            &self,
            user_id: Option<Uuid>,
            limit: i64,
            offset: i64,
        ) -> Result<Vec<Post>> {
            let posts = self.posts.lock().unwrap();
            let feeds = self.user_feeds.lock().unwrap();

            let mut reels = if let Some(uid) = user_id {
                // Get reels from user's feed
                if let Some(post_ids) = feeds.get(&uid) {
                    post_ids
                        .iter()
                        .filter_map(|id| posts.get(id))
                        .filter(|p| p.is_reel)
                        .cloned()
                        .collect()
                } else {
                    vec![]
                }
            } else {
                // Get all public reels
                posts
                    .values()
                    .filter(|p| p.is_reel && p.visibility == PostVisibility::Public)
                    .cloned()
                    .collect()
            };

            reels.sort_by(|a, b| b.created_at.cmp(&a.created_at));

            let start = offset as usize;
            let end = (start + limit as usize).min(reels.len());

            if start >= reels.len() {
                Ok(vec![])
            } else {
                Ok(reels[start..end].to_vec())
            }
        }

        async fn search(&self, _query: &str, _limit: i64, _offset: i64) -> Result<Vec<Post>> {
            Ok(vec![])
        }

        async fn increment_like_count(&self, _post_id: Uuid) -> Result<()> {
            Ok(())
        }

        async fn decrement_like_count(&self, _post_id: Uuid) -> Result<()> {
            Ok(())
        }

        async fn increment_comment_count(&self, _post_id: Uuid) -> Result<()> {
            Ok(())
        }

        async fn decrement_comment_count(&self, _post_id: Uuid) -> Result<()> {
            Ok(())
        }

        async fn increment_reshare_count(&self, _post_id: Uuid) -> Result<()> {
            Ok(())
        }

        async fn decrement_reshare_count(&self, _post_id: Uuid) -> Result<()> {
            Ok(())
        }

        async fn has_user_liked(&self, _user_id: Uuid, _post_id: Uuid) -> Result<bool> {
            Ok(false)
        }

        async fn like_post(&self, _user_id: Uuid, _post_id: Uuid) -> Result<()> {
            Ok(())
        }

        async fn unlike_post(&self, _user_id: Uuid, _post_id: Uuid) -> Result<()> {
            Ok(())
        }

        async fn get_post_likes(
            &self,
            _post_id: Uuid,
            _limit: i64,
            _offset: i64,
        ) -> Result<Vec<User>> {
            Ok(vec![])
        }
    }

    fn create_test_post(user_id: Uuid, content: &str, is_reel: bool) -> Post {
        use crate::domain::entities::MediaAttachment;

        let media_attachments = if is_reel {
            // Reels need video content
            vec![MediaAttachment::new(
                "https://example.com/video.mp4".to_string(),
                "video/mp4".to_string(),
                1024 * 1024, // 1MB
                Some(1920),
                Some(1080),
                Some(30), // 30 seconds
            )
            .unwrap()]
        } else {
            vec![]
        };

        let request = CreatePostRequest {
            user_id,
            text_content: Some(content.to_string()),
            media_attachments,
            is_reel,
            visibility: PostVisibility::Public,
        };
        Post::new(request).unwrap()
    }

    #[tokio::test]
    async fn test_chronological_feed_generation() {
        let post_repo = Arc::new(MockPostRepository::new());
        let user_repo = Arc::new(MockUserRepository::new());
        let service = FeedGenerationService::new(post_repo.clone(), user_repo, None);

        let user_id = Uuid::new_v4();
        let post1 = create_test_post(user_id, "First post", false);
        let post2 = create_test_post(user_id, "Second post", false);

        post_repo.add_post(post1.clone());
        post_repo.add_post(post2.clone());
        post_repo.set_user_feed(user_id, vec![post1.id, post2.id]);

        let filters = FeedFilters::default();
        let result = service
            .generate_feed(user_id, FeedSortStrategy::Chronological, filters, 10, 0)
            .await
            .unwrap();

        assert_eq!(result.len(), 2);
        // Should be sorted by created_at descending (newest first)
        assert!(result[0].created_at >= result[1].created_at);
    }

    #[tokio::test]
    async fn test_reels_only_filter() {
        let post_repo = Arc::new(MockPostRepository::new());
        let user_repo = Arc::new(MockUserRepository::new());
        let service = FeedGenerationService::new(post_repo.clone(), user_repo, None);

        let user_id = Uuid::new_v4();
        let regular_post = create_test_post(user_id, "Regular post", false);
        let reel_post = create_test_post(user_id, "Reel post", true);

        post_repo.add_post(regular_post.clone());
        post_repo.add_post(reel_post.clone());
        post_repo.set_user_feed(user_id, vec![regular_post.id, reel_post.id]);

        let filters = FeedFilters {
            reels_only: true,
            ..Default::default()
        };

        let result = service
            .generate_feed(user_id, FeedSortStrategy::Chronological, filters, 10, 0)
            .await
            .unwrap();

        assert_eq!(result.len(), 1);
        assert!(result[0].is_reel);
    }

    #[tokio::test]
    async fn test_algorithmic_feed_sorting() {
        let post_repo = Arc::new(MockPostRepository::new());
        let user_repo = Arc::new(MockUserRepository::new());
        let service = FeedGenerationService::new(post_repo.clone(), user_repo, None);

        let user_id = Uuid::new_v4();

        // Create posts with different engagement levels
        let mut low_engagement_post = create_test_post(user_id, "Low engagement", false);
        low_engagement_post.like_count = 1;

        let mut high_engagement_post = create_test_post(user_id, "High engagement", false);
        high_engagement_post.like_count = 50;
        high_engagement_post.comment_count = 10;

        post_repo.add_post(low_engagement_post.clone());
        post_repo.add_post(high_engagement_post.clone());
        post_repo.set_user_feed(
            user_id,
            vec![low_engagement_post.id, high_engagement_post.id],
        );

        let filters = FeedFilters::default();
        let result = service
            .generate_feed(user_id, FeedSortStrategy::Algorithmic, filters, 10, 0)
            .await
            .unwrap();

        assert_eq!(result.len(), 2);
        // High engagement post should come first in algorithmic feed
        assert_eq!(result[0].id, high_engagement_post.id);
    }

    #[tokio::test]
    async fn test_get_reels_feed() {
        let post_repo = Arc::new(MockPostRepository::new());
        let user_repo = Arc::new(MockUserRepository::new());
        let service = FeedGenerationService::new(post_repo.clone(), user_repo, None);

        let user_id = Uuid::new_v4();
        let regular_post = create_test_post(user_id, "Regular post", false);
        let reel_post = create_test_post(user_id, "Reel post", true);

        post_repo.add_post(regular_post.clone());
        post_repo.add_post(reel_post.clone());
        post_repo.set_user_feed(user_id, vec![regular_post.id, reel_post.id]);

        let result = service.get_reels_feed(user_id, 10, 0).await.unwrap();

        assert_eq!(result.len(), 1);
        assert!(result[0].is_reel);
        assert_eq!(result[0].id, reel_post.id);
    }

    #[tokio::test]
    async fn test_get_trending_posts() {
        let post_repo = Arc::new(MockPostRepository::new());
        let user_repo = Arc::new(MockUserRepository::new());
        let service = FeedGenerationService::new(post_repo.clone(), user_repo, None);

        // Create posts with different engagement levels
        let mut low_engagement_post = create_test_post(Uuid::new_v4(), "Low engagement", false);
        low_engagement_post.like_count = 2;

        let mut high_engagement_post = create_test_post(Uuid::new_v4(), "High engagement", false);
        high_engagement_post.like_count = 20;
        high_engagement_post.comment_count = 5;

        post_repo.add_post(low_engagement_post.clone());
        post_repo.add_post(high_engagement_post.clone());

        let result = service.get_trending_posts(10, 0).await.unwrap();

        // Only high engagement post should be in trending (>= 5 total engagement)
        assert_eq!(result.len(), 1);
        assert_eq!(result[0].id, high_engagement_post.id);
    }
}
