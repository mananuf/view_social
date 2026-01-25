use crate::domain::entities::{User, Post, Message, MessageRead, Wallet, Transaction, MessageType, PostVisibility, WalletStatus, TransactionStatus, TransactionType};
use crate::domain::repositories::{UserRepository, PostRepository, MessageRepository, WalletRepository};
use crate::domain::errors::{AppError, Result};
use crate::domain::value_objects::{Username, Email, PhoneNumber, DisplayName, Bio};
use async_trait::async_trait;
use sqlx::PgPool;
use uuid::Uuid;
use rust_decimal::Decimal;
use chrono::{DateTime, Utc};

/// PostgreSQL implementation of UserRepository
pub struct PostgresUserRepository {
    pool: PgPool,
}

impl PostgresUserRepository {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }
}

/// PostgreSQL implementation of PostRepository
pub struct PostgresPostRepository {
    pool: PgPool,
}

impl PostgresPostRepository {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }
}

/// PostgreSQL implementation of MessageRepository
pub struct PostgresMessageRepository {
    pool: PgPool,
}

impl PostgresMessageRepository {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }
}

/// PostgreSQL implementation of WalletRepository
pub struct PostgresWalletRepository {
    pool: PgPool,
}

impl PostgresWalletRepository {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }
}

#[async_trait]
impl UserRepository for PostgresUserRepository {
    async fn create(&self, user: &User) -> Result<User> {
        let row = sqlx::query!(
            r#"
            INSERT INTO users (id, username, email, phone_number, display_name, bio, avatar_url, is_verified, follower_count, following_count, created_at, updated_at)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
            RETURNING *
            "#,
            user.id,
            user.username.value(),
            user.email.value(),
            user.phone_number.as_ref().map(|p| p.value()),
            user.display_name.as_ref().map(|d| d.value()),
            user.bio.as_ref().map(|b| b.value()),
            user.avatar_url,
            user.is_verified,
            user.follower_count,
            user.following_count,
            user.created_at,
            user.updated_at
        )
        .fetch_one(&self.pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to create user: {}", e)))?;

        Ok(User {
            id: row.id,
            username: Username::new(row.username)?,
            email: Email::new(row.email)?,
            phone_number: row.phone_number.map(PhoneNumber::new).transpose()?,
            display_name: row.display_name.map(DisplayName::new).transpose()?,
            bio: row.bio.map(Bio::new).transpose()?,
            avatar_url: row.avatar_url,
            is_verified: row.is_verified,
            follower_count: row.follower_count,
            following_count: row.following_count,
            created_at: row.created_at,
            updated_at: row.updated_at,
        })
    }

    async fn find_by_id(&self, id: Uuid) -> Result<Option<User>> {
        let row = sqlx::query!(
            "SELECT * FROM users WHERE id = $1",
            id
        )
        .fetch_optional(&self.pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to find user by id: {}", e)))?;

        match row {
            Some(row) => Ok(Some(User {
                id: row.id,
                username: Username::new(row.username)?,
                email: Email::new(row.email)?,
                phone_number: row.phone_number.map(PhoneNumber::new).transpose()?,
                display_name: row.display_name.map(DisplayName::new).transpose()?,
                bio: row.bio.map(Bio::new).transpose()?,
                avatar_url: row.avatar_url,
                is_verified: row.is_verified,
                follower_count: row.follower_count,
                following_count: row.following_count,
                created_at: row.created_at,
                updated_at: row.updated_at,
            })),
            None => Ok(None),
        }
    }

    async fn find_by_username(&self, username: &str) -> Result<Option<User>> {
        let row = sqlx::query!(
            "SELECT * FROM users WHERE username = $1",
            username
        )
        .fetch_optional(&self.pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to find user by username: {}", e)))?;

        match row {
            Some(row) => Ok(Some(User {
                id: row.id,
                username: Username::new(row.username)?,
                email: Email::new(row.email)?,
                phone_number: row.phone_number.map(PhoneNumber::new).transpose()?,
                display_name: row.display_name.map(DisplayName::new).transpose()?,
                bio: row.bio.map(Bio::new).transpose()?,
                avatar_url: row.avatar_url,
                is_verified: row.is_verified,
                follower_count: row.follower_count,
                following_count: row.following_count,
                created_at: row.created_at,
                updated_at: row.updated_at,
            })),
            None => Ok(None),
        }
    }

    async fn find_by_email(&self, email: &str) -> Result<Option<User>> {
        let row = sqlx::query!(
            "SELECT * FROM users WHERE email = $1",
            email
        )
        .fetch_optional(&self.pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to find user by email: {}", e)))?;

        match row {
            Some(row) => Ok(Some(User {
                id: row.id,
                username: Username::new(row.username)?,
                email: Email::new(row.email)?,
                phone_number: row.phone_number.map(PhoneNumber::new).transpose()?,
                display_name: row.display_name.map(DisplayName::new).transpose()?,
                bio: row.bio.map(Bio::new).transpose()?,
                avatar_url: row.avatar_url,
                is_verified: row.is_verified,
                follower_count: row.follower_count,
                following_count: row.following_count,
                created_at: row.created_at,
                updated_at: row.updated_at,
            })),
            None => Ok(None),
        }
    }

    async fn find_by_phone_number(&self, phone_number: &str) -> Result<Option<User>> {
        let row = sqlx::query!(
            "SELECT * FROM users WHERE phone_number = $1",
            phone_number
        )
        .fetch_optional(&self.pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to find user by phone: {}", e)))?;

        match row {
            Some(row) => Ok(Some(User {
                id: row.id,
                username: Username::new(row.username)?,
                email: Email::new(row.email)?,
                phone_number: row.phone_number.map(PhoneNumber::new).transpose()?,
                display_name: row.display_name.map(DisplayName::new).transpose()?,
                bio: row.bio.map(Bio::new).transpose()?,
                avatar_url: row.avatar_url,
                is_verified: row.is_verified,
                follower_count: row.follower_count,
                following_count: row.following_count,
                created_at: row.created_at,
                updated_at: row.updated_at,
            })),
            None => Ok(None),
        }
    }

    async fn update(&self, user: &User) -> Result<User> {
        let row = sqlx::query!(
            r#"
            UPDATE users 
            SET username = $2, email = $3, phone_number = $4, display_name = $5, bio = $6, 
                avatar_url = $7, is_verified = $8, follower_count = $9, following_count = $10, updated_at = $11
            WHERE id = $1
            RETURNING *
            "#,
            user.id,
            user.username.value(),
            user.email.value(),
            user.phone_number.as_ref().map(|p| p.value()),
            user.display_name.as_ref().map(|d| d.value()),
            user.bio.as_ref().map(|b| b.value()),
            user.avatar_url,
            user.is_verified,
            user.follower_count,
            user.following_count,
            user.updated_at
        )
        .fetch_one(&self.pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to update user: {}", e)))?;

        Ok(User {
            id: row.id,
            username: Username::new(row.username)?,
            email: Email::new(row.email)?,
            phone_number: row.phone_number.map(PhoneNumber::new).transpose()?,
            display_name: row.display_name.map(DisplayName::new).transpose()?,
            bio: row.bio.map(Bio::new).transpose()?,
            avatar_url: row.avatar_url,
            is_verified: row.is_verified,
            follower_count: row.follower_count,
            following_count: row.following_count,
            created_at: row.created_at,
            updated_at: row.updated_at,
        })
    }

    async fn delete(&self, id: Uuid) -> Result<()> {
        sqlx::query!("DELETE FROM users WHERE id = $1", id)
            .execute(&self.pool)
            .await
            .map_err(|e| AppError::DatabaseError(format!("Failed to delete user: {}", e)))?;
        Ok(())
    }

    async fn username_exists(&self, username: &str) -> Result<bool> {
        let row = sqlx::query!(
            "SELECT EXISTS(SELECT 1 FROM users WHERE username = $1)",
            username
        )
        .fetch_one(&self.pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to check username existence: {}", e)))?;

        Ok(row.exists.unwrap_or(false))
    }

    async fn email_exists(&self, email: &str) -> Result<bool> {
        let row = sqlx::query!(
            "SELECT EXISTS(SELECT 1 FROM users WHERE email = $1)",
            email
        )
        .fetch_one(&self.pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to check email existence: {}", e)))?;

        Ok(row.exists.unwrap_or(false))
    }

    async fn search(&self, query: &str, limit: i64, offset: i64) -> Result<Vec<User>> {
        let rows = sqlx::query!(
            r#"
            SELECT * FROM users 
            WHERE username ILIKE $1 OR display_name ILIKE $1
            ORDER BY follower_count DESC, created_at DESC
            LIMIT $2 OFFSET $3
            "#,
            format!("%{}%", query),
            limit,
            offset
        )
        .fetch_all(&self.pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to search users: {}", e)))?;

        let mut users = Vec::new();
        for row in rows {
            users.push(User {
                id: row.id,
                username: Username::new(row.username)?,
                email: Email::new(row.email)?,
                phone_number: row.phone_number.map(PhoneNumber::new).transpose()?,
                display_name: row.display_name.map(DisplayName::new).transpose()?,
                bio: row.bio.map(Bio::new).transpose()?,
                avatar_url: row.avatar_url,
                is_verified: row.is_verified,
                follower_count: row.follower_count,
                following_count: row.following_count,
                created_at: row.created_at,
                updated_at: row.updated_at,
            });
        }
        Ok(users)
    }

    async fn get_followers(&self, user_id: Uuid, limit: i64, offset: i64) -> Result<Vec<User>> {
        let rows = sqlx::query!(
            r#"
            SELECT u.* FROM users u
            INNER JOIN follows f ON u.id = f.follower_id
            WHERE f.following_id = $1
            ORDER BY f.created_at DESC
            LIMIT $2 OFFSET $3
            "#,
            user_id,
            limit,
            offset
        )
        .fetch_all(&self.pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to get followers: {}", e)))?;

        let mut users = Vec::new();
        for row in rows {
            users.push(User {
                id: row.id,
                username: Username::new(row.username)?,
                email: Email::new(row.email)?,
                phone_number: row.phone_number.map(PhoneNumber::new).transpose()?,
                display_name: row.display_name.map(DisplayName::new).transpose()?,
                bio: row.bio.map(Bio::new).transpose()?,
                avatar_url: row.avatar_url,
                is_verified: row.is_verified,
                follower_count: row.follower_count,
                following_count: row.following_count,
                created_at: row.created_at,
                updated_at: row.updated_at,
            });
        }
        Ok(users)
    }

    async fn get_following(&self, user_id: Uuid, limit: i64, offset: i64) -> Result<Vec<User>> {
        let rows = sqlx::query!(
            r#"
            SELECT u.* FROM users u
            INNER JOIN follows f ON u.id = f.following_id
            WHERE f.follower_id = $1
            ORDER BY f.created_at DESC
            LIMIT $2 OFFSET $3
            "#,
            user_id,
            limit,
            offset
        )
        .fetch_all(&self.pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to get following: {}", e)))?;

        let mut users = Vec::new();
        for row in rows {
            users.push(User {
                id: row.id,
                username: Username::new(row.username)?,
                email: Email::new(row.email)?,
                phone_number: row.phone_number.map(PhoneNumber::new).transpose()?,
                display_name: row.display_name.map(DisplayName::new).transpose()?,
                bio: row.bio.map(Bio::new).transpose()?,
                avatar_url: row.avatar_url,
                is_verified: row.is_verified,
                follower_count: row.follower_count,
                following_count: row.following_count,
                created_at: row.created_at,
                updated_at: row.updated_at,
            });
        }
        Ok(users)
    }

    async fn is_following(&self, follower_id: Uuid, following_id: Uuid) -> Result<bool> {
        let row = sqlx::query!(
            "SELECT EXISTS(SELECT 1 FROM follows WHERE follower_id = $1 AND following_id = $2)",
            follower_id,
            following_id
        )
        .fetch_one(&self.pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to check follow status: {}", e)))?;

        Ok(row.exists.unwrap_or(false))
    }

    async fn follow(&self, follower_id: Uuid, following_id: Uuid) -> Result<()> {
        let mut tx = self.pool.begin().await
            .map_err(|e| AppError::DatabaseError(format!("Failed to start transaction: {}", e)))?;

        // Insert follow relationship
        sqlx::query!(
            "INSERT INTO follows (follower_id, following_id, created_at) VALUES ($1, $2, $3) ON CONFLICT DO NOTHING",
            follower_id,
            following_id,
            Utc::now()
        )
        .execute(&mut *tx)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to create follow: {}", e)))?;

        // Update follower count
        sqlx::query!(
            "UPDATE users SET following_count = following_count + 1 WHERE id = $1",
            follower_id
        )
        .execute(&mut *tx)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to update following count: {}", e)))?;

        // Update following count
        sqlx::query!(
            "UPDATE users SET follower_count = follower_count + 1 WHERE id = $1",
            following_id
        )
        .execute(&mut *tx)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to update follower count: {}", e)))?;

        tx.commit().await
            .map_err(|e| AppError::DatabaseError(format!("Failed to commit follow transaction: {}", e)))?;

        Ok(())
    }

    async fn unfollow(&self, follower_id: Uuid, following_id: Uuid) -> Result<()> {
        let mut tx = self.pool.begin().await
            .map_err(|e| AppError::DatabaseError(format!("Failed to start transaction: {}", e)))?;

        // Delete follow relationship
        let result = sqlx::query!(
            "DELETE FROM follows WHERE follower_id = $1 AND following_id = $2",
            follower_id,
            following_id
        )
        .execute(&mut *tx)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to delete follow: {}", e)))?;

        if result.rows_affected() > 0 {
            // Update follower count
            sqlx::query!(
                "UPDATE users SET following_count = GREATEST(following_count - 1, 0) WHERE id = $1",
                follower_id
            )
            .execute(&mut *tx)
            .await
            .map_err(|e| AppError::DatabaseError(format!("Failed to update following count: {}", e)))?;

            // Update following count
            sqlx::query!(
                "UPDATE users SET follower_count = GREATEST(follower_count - 1, 0) WHERE id = $1",
                following_id
            )
            .execute(&mut *tx)
            .await
            .map_err(|e| AppError::DatabaseError(format!("Failed to update follower count: {}", e)))?;
        }

        tx.commit().await
            .map_err(|e| AppError::DatabaseError(format!("Failed to commit unfollow transaction: {}", e)))?;

        Ok(())
    }
}