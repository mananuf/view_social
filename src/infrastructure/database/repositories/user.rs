use crate::domain::entities::User;
use crate::domain::errors::{AppError, Result};
use crate::domain::repositories::UserRepository;
use crate::domain::value_objects::{Bio, DisplayName, Email, PhoneNumber, Username};
use crate::infrastructure::database::models::UserModel;
use async_trait::async_trait;
use chrono::Utc;
use sqlx::PgPool;
use uuid::Uuid;

/// PostgreSQL implementation of UserRepository
pub struct PostgresUserRepository {
    pool: PgPool,
}

impl PostgresUserRepository {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    /// Convert database model to domain entity
    fn to_domain(model: UserModel) -> Result<User> {
        Ok(User {
            id: model.id,
            username: Username::new(model.username)?,
            email: Email::new(model.email)?,
            phone_number: model.phone_number.map(PhoneNumber::new).transpose()?,
            display_name: model.display_name.map(DisplayName::new).transpose()?,
            bio: model.bio.map(Bio::new).transpose()?,
            avatar_url: model.avatar_url,
            is_verified: model.is_verified,
            follower_count: model.follower_count,
            following_count: model.following_count,
            created_at: model.created_at,
            updated_at: model.updated_at,
        })
    }
}

#[async_trait]
impl UserRepository for PostgresUserRepository {
    async fn create(&self, user: &User) -> Result<User> {
        sqlx::query(
            "INSERT INTO users (id, username, email, phone_number, display_name, bio, avatar_url, is_verified, follower_count, following_count, created_at, updated_at)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)")
            .bind(user.id)
            .bind(user.username.value())
            .bind(user.email.value())
            .bind(user.phone_number.as_ref().map(|p| p.value()))
            .bind(user.display_name.as_ref().map(|d| d.value()))
            .bind(user.bio.as_ref().map(|b| b.value()))
            .bind(user.avatar_url.clone())
            .bind(user.is_verified)
            .bind(user.follower_count)
            .bind(user.following_count)
            .bind(user.created_at)
            .bind(user.updated_at)
            .execute(&self.pool)
            .await
            .map_err(|e| AppError::DatabaseError(format!("Failed to create user: {}", e)))?;

        Ok(user.clone())
    }

    async fn find_by_id(&self, id: Uuid) -> Result<Option<User>> {
        let model: Option<UserModel> = sqlx::query_as("SELECT * FROM users WHERE id = $1")
            .bind(id)
            .fetch_optional(&self.pool)
            .await
            .map_err(|e| AppError::DatabaseError(format!("Failed to find user by id: {}", e)))?;

        model.map(Self::to_domain).transpose()
    }

    async fn find_by_username(&self, username: &str) -> Result<Option<User>> {
        let model: Option<UserModel> = sqlx::query_as("SELECT * FROM users WHERE username = $1")
            .bind(username)
            .fetch_optional(&self.pool)
            .await
            .map_err(|e| {
                AppError::DatabaseError(format!("Failed to find user by username: {}", e))
            })?;

        model.map(Self::to_domain).transpose()
    }

    async fn find_by_email(&self, email: &str) -> Result<Option<User>> {
        let model: Option<UserModel> = sqlx::query_as("SELECT * FROM users WHERE email = $1")
            .bind(email)
            .fetch_optional(&self.pool)
            .await
            .map_err(|e| AppError::DatabaseError(format!("Failed to find user by email: {}", e)))?;

        model.map(Self::to_domain).transpose()
    }

    async fn find_by_phone_number(&self, phone_number: &str) -> Result<Option<User>> {
        let model: Option<UserModel> =
            sqlx::query_as("SELECT * FROM users WHERE phone_number = $1")
                .bind(phone_number)
                .fetch_optional(&self.pool)
                .await
                .map_err(|e| {
                    AppError::DatabaseError(format!("Failed to find user by phone: {}", e))
                })?;

        model.map(Self::to_domain).transpose()
    }

    async fn update(&self, user: &User) -> Result<User> {
        let model: UserModel = sqlx::query_as(
            "UPDATE users 
            SET username = $2, email = $3, phone_number = $4, display_name = $5, bio = $6, 
                avatar_url = $7, is_verified = $8, follower_count = $9, following_count = $10, updated_at = $11
            WHERE id = $1
            RETURNING *")
            .bind(user.id)
            .bind(user.username.value())
            .bind(user.email.value())
            .bind(user.phone_number.as_ref().map(|p| p.value()))
            .bind(user.display_name.as_ref().map(|d| d.value()))
            .bind(user.bio.as_ref().map(|b| b.value()))
            .bind(user.avatar_url.clone())
            .bind(user.is_verified)
            .bind(user.follower_count)
            .bind(user.following_count)
            .bind(user.updated_at)
        .fetch_one(&self.pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to update user: {}", e)))?;

        Self::to_domain(model)
    }

    async fn delete(&self, id: Uuid) -> Result<()> {
        sqlx::query("DELETE FROM users WHERE id = $1")
            .bind(id)
            .execute(&self.pool)
            .await
            .map_err(|e| AppError::DatabaseError(format!("Failed to delete user: {}", e)))?;
        Ok(())
    }

    async fn username_exists(&self, username: &str) -> Result<bool> {
        let row: (bool,) = sqlx::query_as("SELECT EXISTS(SELECT 1 FROM users WHERE username = $1)")
            .bind(username)
            .fetch_one(&self.pool)
            .await
            .map_err(|e| {
                AppError::DatabaseError(format!("Failed to check username existence: {}", e))
            })?;

        Ok(row.0)
    }

    async fn email_exists(&self, email: &str) -> Result<bool> {
        let row: (bool,) = sqlx::query_as("SELECT EXISTS(SELECT 1 FROM users WHERE email = $1)")
            .bind(email)
            .fetch_one(&self.pool)
            .await
            .map_err(|e| {
                AppError::DatabaseError(format!("Failed to check email existence: {}", e))
            })?;

        Ok(row.0)
    }

    async fn search(&self, query: &str, limit: i64, offset: i64) -> Result<Vec<User>> {
        let models: Vec<UserModel> = sqlx::query_as(
            "SELECT * FROM users 
            WHERE username ILIKE $1 OR display_name ILIKE $1
            ORDER BY follower_count DESC, created_at DESC
            LIMIT $2 OFFSET $3",
        )
        .bind(format!("%{}%", query))
        .bind(limit)
        .bind(offset)
        .fetch_all(&self.pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to search users: {}", e)))?;

        models.into_iter().map(Self::to_domain).collect()
    }

    async fn get_followers(&self, user_id: Uuid, limit: i64, offset: i64) -> Result<Vec<User>> {
        let models: Vec<UserModel> = sqlx::query_as(
            "SELECT u.* FROM users u
            INNER JOIN follows f ON u.id = f.follower_id
            WHERE f.following_id = $1
            ORDER BY f.created_at DESC
            LIMIT $2 OFFSET $3",
        )
        .bind(user_id)
        .bind(limit)
        .bind(offset)
        .fetch_all(&self.pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to get followers: {}", e)))?;

        models.into_iter().map(Self::to_domain).collect()
    }

    async fn get_following(&self, user_id: Uuid, limit: i64, offset: i64) -> Result<Vec<User>> {
        let models: Vec<UserModel> = sqlx::query_as(
            "SELECT u.* FROM users u
            INNER JOIN follows f ON u.id = f.following_id
            WHERE f.follower_id = $1
            ORDER BY f.created_at DESC
            LIMIT $2 OFFSET $3",
        )
        .bind(user_id)
        .bind(limit)
        .bind(offset)
        .fetch_all(&self.pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to get following: {}", e)))?;

        models.into_iter().map(Self::to_domain).collect()
    }

    async fn is_following(&self, follower_id: Uuid, following_id: Uuid) -> Result<bool> {
        let row: (bool,) = sqlx::query_as(
            "SELECT EXISTS(SELECT 1 FROM follows WHERE follower_id = $1 AND following_id = $2)",
        )
        .bind(follower_id)
        .bind(following_id)
        .fetch_one(&self.pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to check follow status: {}", e)))?;

        Ok(row.0)
    }

    async fn follow(&self, follower_id: Uuid, following_id: Uuid) -> Result<()> {
        let mut tx =
            self.pool.begin().await.map_err(|e| {
                AppError::DatabaseError(format!("Failed to start transaction: {}", e))
            })?;

        sqlx::query(
            "INSERT INTO follows (follower_id, following_id, created_at) VALUES ($1, $2, $3) ON CONFLICT DO NOTHING")
            .bind(follower_id)
            .bind(following_id)
            .bind(Utc::now())
        .execute(&mut *tx)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to create follow: {}", e)))?;

        sqlx::query("UPDATE users SET following_count = following_count + 1 WHERE id = $1")
            .bind(follower_id)
            .execute(&mut *tx)
            .await
            .map_err(|e| {
                AppError::DatabaseError(format!("Failed to update following count: {}", e))
            })?;

        sqlx::query("UPDATE users SET follower_count = follower_count + 1 WHERE id = $1")
            .bind(following_id)
            .execute(&mut *tx)
            .await
            .map_err(|e| {
                AppError::DatabaseError(format!("Failed to update follower count: {}", e))
            })?;

        tx.commit().await.map_err(|e| {
            AppError::DatabaseError(format!("Failed to commit follow transaction: {}", e))
        })?;

        Ok(())
    }

    async fn unfollow(&self, follower_id: Uuid, following_id: Uuid) -> Result<()> {
        let mut tx =
            self.pool.begin().await.map_err(|e| {
                AppError::DatabaseError(format!("Failed to start transaction: {}", e))
            })?;

        let result =
            sqlx::query("DELETE FROM follows WHERE follower_id = $1 AND following_id = $2")
                .bind(follower_id)
                .bind(following_id)
                .execute(&mut *tx)
                .await
                .map_err(|e| AppError::DatabaseError(format!("Failed to delete follow: {}", e)))?;

        if result.rows_affected() > 0 {
            sqlx::query(
                "UPDATE users SET following_count = GREATEST(following_count - 1, 0) WHERE id = $1",
            )
            .bind(follower_id)
            .execute(&mut *tx)
            .await
            .map_err(|e| {
                AppError::DatabaseError(format!("Failed to update following count: {}", e))
            })?;

            sqlx::query(
                "UPDATE users SET follower_count = GREATEST(follower_count - 1, 0) WHERE id = $1",
            )
            .bind(following_id)
            .execute(&mut *tx)
            .await
            .map_err(|e| {
                AppError::DatabaseError(format!("Failed to update follower count: {}", e))
            })?;
        }

        tx.commit().await.map_err(|e| {
            AppError::DatabaseError(format!("Failed to commit unfollow transaction: {}", e))
        })?;

        Ok(())
    }
}
