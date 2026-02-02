use crate::domain::entities::{Post, PostVisibility, User};
use crate::domain::errors::{AppError, Result};
use crate::domain::repositories::PostRepository;
use crate::domain::value_objects::{Bio, DisplayName, Email, PhoneNumber, Username};
use crate::infrastructure::database::models::{PostModel, UserModel};
use async_trait::async_trait;
use chrono::Utc;
use sqlx::PgPool;
use uuid::Uuid;

/// PostgreSQL implementation of PostRepository
pub struct PostgresPostRepository {
    pool: PgPool,
}

impl PostgresPostRepository {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    /// Convert database model to domain entity
    fn to_domain(model: PostModel) -> Result<Post> {
        let media_attachments: Vec<crate::domain::entities::MediaAttachment> =
            serde_json::from_value(model.media_attachments).map_err(|e| {
                AppError::SerializationError(format!("Failed to deserialize media: {}", e))
            })?;

        let content_type = match model.content_type.as_str() {
            "text" => crate::domain::entities::PostContentType::Text,
            "image" => crate::domain::entities::PostContentType::Image,
            "video" => crate::domain::entities::PostContentType::Video,
            "mixed" => crate::domain::entities::PostContentType::Mixed,
            _ => crate::domain::entities::PostContentType::Text,
        };

        let visibility = match model.visibility.as_str() {
            "public" => PostVisibility::Public,
            "followers" => PostVisibility::Followers,
            "private" => PostVisibility::Private,
            _ => PostVisibility::Public,
        };

        Ok(Post {
            id: model.id,
            user_id: model.user_id,
            content_type,
            text_content: model.text_content,
            media_attachments,
            is_reel: model.is_reel,
            visibility,
            like_count: model.like_count,
            comment_count: model.comment_count,
            reshare_count: model.reshare_count,
            created_at: model.created_at,
            updated_at: model.updated_at,
        })
    }

    fn user_model_to_domain(model: UserModel) -> Result<User> {
        Ok(User {
            id: model.id,
            username: Username::new(model.username)?,
            email: Email::new(model.email)?,
            phone_number: model.phone_number.map(PhoneNumber::new).transpose()?,
            password_hash: model.password_hash,
            display_name: model.display_name.map(DisplayName::new).transpose()?,
            bio: model.bio.map(Bio::new).transpose()?,
            avatar_url: model.avatar_url,
            is_verified: model.is_verified,
            email_verified: model.email_verified,
            phone_verified: model.phone_verified,
            follower_count: model.follower_count,
            following_count: model.following_count,
            created_at: model.created_at,
            updated_at: model.updated_at,
        })
    }
}

#[async_trait]
impl PostRepository for PostgresPostRepository {
    async fn create(&self, post: &Post) -> Result<Post> {
        let media_json = serde_json::to_value(&post.media_attachments).map_err(|e| {
            AppError::SerializationError(format!("Failed to serialize media: {}", e))
        })?;

        let content_type_str = match post.content_type {
            crate::domain::entities::PostContentType::Text => "text",
            crate::domain::entities::PostContentType::Image => "image",
            crate::domain::entities::PostContentType::Video => "video",
            crate::domain::entities::PostContentType::Mixed => "mixed",
        };

        let visibility_str = match post.visibility {
            PostVisibility::Public => "public",
            PostVisibility::Followers => "followers",
            PostVisibility::Private => "private",
        };

        sqlx::query(
            "INSERT INTO posts (id, user_id, content_type, text_content, media_attachments, is_reel, visibility, like_count, comment_count, reshare_count, created_at, updated_at)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)")
            .bind(post.id)
            .bind(post.user_id)
            .bind(content_type_str)
            .bind(&post.text_content)
            .bind(media_json)
            .bind(post.is_reel)
            .bind(visibility_str)
            .bind(post.like_count)
            .bind(post.comment_count)
            .bind(post.reshare_count)
            .bind(post.created_at)
            .bind(post.updated_at)
        .execute(&self.pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to create post: {}", e)))?;

        Ok(post.clone())
    }

    async fn find_by_id(&self, id: Uuid) -> Result<Option<Post>> {
        let model: Option<PostModel> = sqlx::query_as("SELECT * FROM posts WHERE id = $1")
            .bind(id)
            .fetch_optional(&self.pool)
            .await
            .map_err(|e| AppError::DatabaseError(format!("Failed to find post by id: {}", e)))?;

        model.map(Self::to_domain).transpose()
    }

    async fn update(&self, post: &Post) -> Result<Post> {
        let media_json = serde_json::to_value(&post.media_attachments).map_err(|e| {
            AppError::SerializationError(format!("Failed to serialize media: {}", e))
        })?;

        let content_type_str = match post.content_type {
            crate::domain::entities::PostContentType::Text => "text",
            crate::domain::entities::PostContentType::Image => "image",
            crate::domain::entities::PostContentType::Video => "video",
            crate::domain::entities::PostContentType::Mixed => "mixed",
        };

        let visibility_str = match post.visibility {
            PostVisibility::Public => "public",
            PostVisibility::Followers => "followers",
            PostVisibility::Private => "private",
        };

        let model: PostModel = sqlx::query_as(
            "UPDATE posts 
            SET content_type = $2, text_content = $3, media_attachments = $4, is_reel = $5, 
                visibility = $6, like_count = $7, comment_count = $8, reshare_count = $9, updated_at = $10
            WHERE id = $1
            RETURNING *")
            .bind(post.id)
            .bind(content_type_str)
            .bind(&post.text_content)
            .bind(media_json)
            .bind(post.is_reel)
            .bind(visibility_str)
            .bind(post.like_count)
            .bind(post.comment_count)
            .bind(post.reshare_count)
            .bind(post.updated_at)
        .fetch_one(&self.pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to update post: {}", e)))?;

        Self::to_domain(model)
    }

    async fn delete(&self, id: Uuid) -> Result<()> {
        sqlx::query("DELETE FROM posts WHERE id = $1")
            .bind(id)
            .execute(&self.pool)
            .await
            .map_err(|e| AppError::DatabaseError(format!("Failed to delete post: {}", e)))?;
        Ok(())
    }

    async fn find_feed(&self, user_id: Uuid, limit: i64, offset: i64) -> Result<Vec<Post>> {
        let models: Vec<PostModel> = sqlx::query_as(
            "SELECT p.* FROM posts p
            INNER JOIN follows f ON p.user_id = f.following_id
            WHERE f.follower_id = $1 AND p.visibility IN ('public', 'followers')
            ORDER BY p.created_at DESC
            LIMIT $2 OFFSET $3",
        )
        .bind(user_id)
        .bind(limit)
        .bind(offset)
        .fetch_all(&self.pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to fetch feed: {}", e)))?;

        models.into_iter().map(Self::to_domain).collect()
    }

    async fn find_by_user_id(&self, user_id: Uuid, limit: i64, offset: i64) -> Result<Vec<Post>> {
        let models: Vec<PostModel> = sqlx::query_as(
            "SELECT * FROM posts
            WHERE user_id = $1
            ORDER BY created_at DESC
            LIMIT $2 OFFSET $3",
        )
        .bind(user_id)
        .bind(limit)
        .bind(offset)
        .fetch_all(&self.pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to fetch user posts: {}", e)))?;

        models.into_iter().map(Self::to_domain).collect()
    }

    async fn find_public(&self, limit: i64, offset: i64) -> Result<Vec<Post>> {
        let models: Vec<PostModel> = sqlx::query_as(
            "SELECT * FROM posts
            WHERE visibility = 'public'
            ORDER BY created_at DESC
            LIMIT $1 OFFSET $2",
        )
        .bind(limit)
        .bind(offset)
        .fetch_all(&self.pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to fetch public posts: {}", e)))?;

        models.into_iter().map(Self::to_domain).collect()
    }

    async fn find_reels(
        &self,
        user_id: Option<Uuid>,
        limit: i64,
        offset: i64,
    ) -> Result<Vec<Post>> {
        let models: Vec<PostModel> = if let Some(uid) = user_id {
            sqlx::query_as(
                "SELECT p.* FROM posts p
                INNER JOIN follows f ON p.user_id = f.following_id
                WHERE f.follower_id = $1 AND p.is_reel = true AND p.visibility IN ('public', 'followers')
                ORDER BY p.created_at DESC
                LIMIT $2 OFFSET $3")
                .bind(uid)
                .bind(limit)
                .bind(offset)
            .fetch_all(&self.pool)
            .await
            .map_err(|e| AppError::DatabaseError(format!("Failed to fetch reels: {}", e)))?
        } else {
            sqlx::query_as(
                "SELECT * FROM posts
                WHERE is_reel = true AND visibility = 'public'
                ORDER BY created_at DESC
                LIMIT $1 OFFSET $2",
            )
            .bind(limit)
            .bind(offset)
            .fetch_all(&self.pool)
            .await
            .map_err(|e| AppError::DatabaseError(format!("Failed to fetch public reels: {}", e)))?
        };

        models.into_iter().map(Self::to_domain).collect()
    }

    async fn search(&self, query: &str, limit: i64, offset: i64) -> Result<Vec<Post>> {
        let models: Vec<PostModel> = sqlx::query_as(
            "SELECT * FROM posts
            WHERE text_content ILIKE $1 AND visibility = 'public'
            ORDER BY created_at DESC
            LIMIT $2 OFFSET $3",
        )
        .bind(format!("%{}%", query))
        .bind(limit)
        .bind(offset)
        .fetch_all(&self.pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to search posts: {}", e)))?;

        models.into_iter().map(Self::to_domain).collect()
    }

    async fn increment_like_count(&self, post_id: Uuid) -> Result<()> {
        sqlx::query("UPDATE posts SET like_count = like_count + 1, updated_at = $2 WHERE id = $1")
            .bind(post_id)
            .bind(Utc::now())
            .execute(&self.pool)
            .await
            .map_err(|e| {
                AppError::DatabaseError(format!("Failed to increment like count: {}", e))
            })?;
        Ok(())
    }

    async fn decrement_like_count(&self, post_id: Uuid) -> Result<()> {
        sqlx::query("UPDATE posts SET like_count = GREATEST(like_count - 1, 0), updated_at = $2 WHERE id = $1")
            .bind(post_id)
            .bind(Utc::now())
        .execute(&self.pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to decrement like count: {}", e)))?;
        Ok(())
    }

    async fn increment_comment_count(&self, post_id: Uuid) -> Result<()> {
        sqlx::query(
            "UPDATE posts SET comment_count = comment_count + 1, updated_at = $2 WHERE id = $1",
        )
        .bind(post_id)
        .bind(Utc::now())
        .execute(&self.pool)
        .await
        .map_err(|e| {
            AppError::DatabaseError(format!("Failed to increment comment count: {}", e))
        })?;
        Ok(())
    }

    async fn decrement_comment_count(&self, post_id: Uuid) -> Result<()> {
        sqlx::query("UPDATE posts SET comment_count = GREATEST(comment_count - 1, 0), updated_at = $2 WHERE id = $1")
            .bind(post_id)
            .bind(Utc::now())
        .execute(&self.pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to decrement comment count: {}", e)))?;
        Ok(())
    }

    async fn increment_reshare_count(&self, post_id: Uuid) -> Result<()> {
        sqlx::query(
            "UPDATE posts SET reshare_count = reshare_count + 1, updated_at = $2 WHERE id = $1",
        )
        .bind(post_id)
        .bind(Utc::now())
        .execute(&self.pool)
        .await
        .map_err(|e| {
            AppError::DatabaseError(format!("Failed to increment reshare count: {}", e))
        })?;
        Ok(())
    }

    async fn decrement_reshare_count(&self, post_id: Uuid) -> Result<()> {
        sqlx::query("UPDATE posts SET reshare_count = GREATEST(reshare_count - 1, 0), updated_at = $2 WHERE id = $1")
            .bind(post_id)
            .bind(Utc::now())
        .execute(&self.pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to decrement reshare count: {}", e)))?;
        Ok(())
    }

    async fn has_user_liked(&self, user_id: Uuid, post_id: Uuid) -> Result<bool> {
        let row: (bool,) = sqlx::query_as(
            "SELECT EXISTS(SELECT 1 FROM post_likes WHERE user_id = $1 AND post_id = $2)",
        )
        .bind(user_id)
        .bind(post_id)
        .fetch_one(&self.pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to check like status: {}", e)))?;

        Ok(row.0)
    }

    async fn like_post(&self, user_id: Uuid, post_id: Uuid) -> Result<()> {
        sqlx::query(
            "INSERT INTO post_likes (user_id, post_id, created_at) VALUES ($1, $2, $3) ON CONFLICT DO NOTHING")
            .bind(user_id)
            .bind(post_id)
            .bind(Utc::now())
        .execute(&self.pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to like post: {}", e)))?;
        Ok(())
    }

    async fn unlike_post(&self, user_id: Uuid, post_id: Uuid) -> Result<()> {
        sqlx::query("DELETE FROM post_likes WHERE user_id = $1 AND post_id = $2")
            .bind(user_id)
            .bind(post_id)
            .execute(&self.pool)
            .await
            .map_err(|e| AppError::DatabaseError(format!("Failed to unlike post: {}", e)))?;
        Ok(())
    }

    async fn get_post_likes(&self, post_id: Uuid, limit: i64, offset: i64) -> Result<Vec<User>> {
        let models: Vec<UserModel> = sqlx::query_as(
            "SELECT u.* FROM users u
            INNER JOIN post_likes pl ON u.id = pl.user_id
            WHERE pl.post_id = $1
            ORDER BY pl.created_at DESC
            LIMIT $2 OFFSET $3",
        )
        .bind(post_id)
        .bind(limit)
        .bind(offset)
        .fetch_all(&self.pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to get post likes: {}", e)))?;

        models.into_iter().map(Self::user_model_to_domain).collect()
    }
}
