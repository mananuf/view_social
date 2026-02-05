use crate::domain::entities::{Message, MessageRead, MessageType};
use crate::domain::errors::{AppError, Result};
use crate::domain::repositories::MessageRepository;
use crate::infrastructure::database::models::{MessageModel, MessageReadModel};
use async_trait::async_trait;
use chrono::{DateTime, Utc};
use sqlx::PgPool;
use uuid::Uuid;

/// PostgreSQL implementation of MessageRepository
pub struct PostgresMessageRepository {
    pool: PgPool,
}

impl PostgresMessageRepository {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    /// Convert database model to domain entity
    fn to_domain(model: MessageModel) -> Result<Message> {
        let message_type = match model.message_type.as_str() {
            "text" => MessageType::Text,
            "image" => MessageType::Image,
            "video" => MessageType::Video,
            "audio" => MessageType::Audio,
            "payment" => MessageType::Payment,
            "system" => MessageType::System,
            _ => MessageType::Text,
        };

        let payment_data = if let Some(payment_json) = model.payment_data {
            Some(serde_json::from_value(payment_json).map_err(|e| {
                AppError::SerializationError(format!("Failed to deserialize payment data: {}", e))
            })?)
        } else {
            None
        };

        Ok(Message {
            id: model.id,
            conversation_id: model.conversation_id,
            sender_id: model.sender_id,
            message_type,
            content: model.content,
            media_url: model.media_url,
            payment_data,
            reply_to_id: model.reply_to_id,
            created_at: model.created_at,
        })
    }
}

#[async_trait]
impl MessageRepository for PostgresMessageRepository {
    async fn create(&self, message: &Message) -> Result<Message> {
        let message_type_str = match message.message_type {
            MessageType::Text => "text",
            MessageType::Image => "image",
            MessageType::Video => "video",
            MessageType::Audio => "audio",
            MessageType::Payment => "payment",
            MessageType::System => "system",
        };

        let payment_json = if let Some(ref payment_data) = message.payment_data {
            Some(serde_json::to_value(payment_data).map_err(|e| {
                AppError::SerializationError(format!("Failed to serialize payment data: {}", e))
            })?)
        } else {
            None
        };

        let model: MessageModel = sqlx::query_as(
            "INSERT INTO messages (id, conversation_id, sender_id, message_type, content, media_url, payment_data, reply_to_id, created_at, updated_at)
            VALUES ($1, $2, $3, $4::message_type, $5, $6, $7, $8, $9, $10)
            RETURNING id, conversation_id, sender_id, message_type::text as message_type, content, media_url, payment_data, reply_to_id, created_at")
            .bind(message.id)
            .bind(message.conversation_id)
            .bind(message.sender_id)
            .bind(message_type_str)
            .bind(&message.content)
            .bind(&message.media_url)
            .bind(payment_json)
            .bind(message.reply_to_id)
            .bind(message.created_at)
            .bind(message.created_at)
        .fetch_one(&self.pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to create message: {}", e)))?;

        // Update conversation last_message_at
        sqlx::query("UPDATE conversations SET last_message_at = $2 WHERE id = $1")
            .bind(message.conversation_id)
            .bind(message.created_at)
            .execute(&self.pool)
            .await
            .map_err(|e| {
                AppError::DatabaseError(format!("Failed to update conversation: {}", e))
            })?;

        Self::to_domain(model)
    }

    async fn find_by_id(&self, id: Uuid) -> Result<Option<Message>> {
        let model: Option<MessageModel> = sqlx::query_as(
            "SELECT id, conversation_id, sender_id, message_type::text as message_type, content, media_url, payment_data, reply_to_id, created_at FROM messages WHERE id = $1")
            .bind(id)
            .fetch_optional(&self.pool)
            .await
            .map_err(|e| AppError::DatabaseError(format!("Failed to find message: {}", e)))?;

        model.map(Self::to_domain).transpose()
    }

    async fn update(&self, message: &Message) -> Result<Message> {
        let message_type_str = match message.message_type {
            MessageType::Text => "text",
            MessageType::Image => "image",
            MessageType::Video => "video",
            MessageType::Audio => "audio",
            MessageType::Payment => "payment",
            MessageType::System => "system",
        };

        let payment_json = if let Some(ref payment_data) = message.payment_data {
            Some(serde_json::to_value(payment_data).map_err(|e| {
                AppError::SerializationError(format!("Failed to serialize payment data: {}", e))
            })?)
        } else {
            None
        };

        let model: MessageModel = sqlx::query_as(
            "UPDATE messages
            SET message_type = $2::message_type, content = $3, media_url = $4, payment_data = $5, reply_to_id = $6, updated_at = $7
            WHERE id = $1
            RETURNING id, conversation_id, sender_id, message_type::text as message_type, content, media_url, payment_data, reply_to_id, created_at")
            .bind(message.id)
            .bind(message_type_str)
            .bind(&message.content)
            .bind(&message.media_url)
            .bind(payment_json)
            .bind(message.reply_to_id)
            .bind(Utc::now())
        .fetch_one(&self.pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to update message: {}", e)))?;

        Self::to_domain(model)
    }

    async fn delete(&self, id: Uuid) -> Result<()> {
        sqlx::query("DELETE FROM messages WHERE id = $1")
            .bind(id)
            .execute(&self.pool)
            .await
            .map_err(|e| AppError::DatabaseError(format!("Failed to delete message: {}", e)))?;
        Ok(())
    }

    async fn find_by_conversation(
        &self,
        conversation_id: Uuid,
        limit: i64,
        before_id: Option<Uuid>,
    ) -> Result<Vec<Message>> {
        let models: Vec<MessageModel> = if let Some(before_id) = before_id {
            let before_row: Option<(DateTime<Utc>,)> =
                sqlx::query_as("SELECT created_at FROM messages WHERE id = $1")
                    .bind(before_id)
                    .fetch_optional(&self.pool)
                    .await
                    .map_err(|e| {
                        AppError::DatabaseError(format!("Failed to find before message: {}", e))
                    })?;

            if let Some(before_row) = before_row {
                sqlx::query_as(
                    "SELECT id, conversation_id, sender_id, message_type::text as message_type, content, media_url, payment_data, reply_to_id, created_at FROM messages
                    WHERE conversation_id = $1 AND created_at < $2
                    ORDER BY created_at DESC
                    LIMIT $3")
                    .bind(conversation_id)
                    .bind(before_row.0)
                    .bind(limit)
                .fetch_all(&self.pool)
                .await
                .map_err(|e| AppError::DatabaseError(format!("Failed to fetch messages: {}", e)))?
            } else {
                Vec::new()
            }
        } else {
            sqlx::query_as(
                "SELECT id, conversation_id, sender_id, message_type::text as message_type, content, media_url, payment_data, reply_to_id, created_at FROM messages
                WHERE conversation_id = $1
                ORDER BY created_at DESC
                LIMIT $2")
                .bind(conversation_id)
                .bind(limit)
            .fetch_all(&self.pool)
            .await
            .map_err(|e| AppError::DatabaseError(format!("Failed to fetch messages: {}", e)))?
        };

        models.into_iter().map(Self::to_domain).collect()
    }

    async fn mark_as_read(&self, message_id: Uuid, user_id: Uuid) -> Result<()> {
        sqlx::query(
            "INSERT INTO message_reads (message_id, user_id, read_at)
            VALUES ($1, $2, $3)
            ON CONFLICT (message_id, user_id) DO NOTHING",
        )
        .bind(message_id)
        .bind(user_id)
        .bind(Utc::now())
        .execute(&self.pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to mark message as read: {}", e)))?;

        Ok(())
    }

    async fn get_message_reads(&self, message_id: Uuid) -> Result<Vec<MessageRead>> {
        let models: Vec<MessageReadModel> =
            sqlx::query_as("SELECT * FROM message_reads WHERE message_id = $1")
                .bind(message_id)
                .fetch_all(&self.pool)
                .await
                .map_err(|e| {
                    AppError::DatabaseError(format!("Failed to get message reads: {}", e))
                })?;

        Ok(models
            .into_iter()
            .map(|m| MessageRead {
                id: m.id,
                message_id: m.message_id,
                user_id: m.user_id,
                read_at: m.read_at,
            })
            .collect())
    }

    async fn is_read_by_user(&self, message_id: Uuid, user_id: Uuid) -> Result<bool> {
        let row: (bool,) = sqlx::query_as(
            "SELECT EXISTS(SELECT 1 FROM message_reads WHERE message_id = $1 AND user_id = $2)",
        )
        .bind(message_id)
        .bind(user_id)
        .fetch_one(&self.pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to check read status: {}", e)))?;

        Ok(row.0)
    }

    async fn get_unread_count(&self, conversation_id: Uuid, user_id: Uuid) -> Result<i64> {
        let row: (i64,) = sqlx::query_as(
            "SELECT COUNT(*)
            FROM messages m
            WHERE m.conversation_id = $1
            AND m.sender_id != $2
            AND NOT EXISTS (
                SELECT 1 FROM message_reads mr
                WHERE mr.message_id = m.id AND mr.user_id = $2
            )",
        )
        .bind(conversation_id)
        .bind(user_id)
        .fetch_one(&self.pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to get unread count: {}", e)))?;

        Ok(row.0)
    }

    async fn get_all_unread_count(&self, user_id: Uuid) -> Result<i64> {
        let row: (i64,) = sqlx::query_as(
            "SELECT COUNT(*)
            FROM messages m
            INNER JOIN conversation_participants cp ON m.conversation_id = cp.conversation_id
            WHERE cp.user_id = $1
            AND cp.left_at IS NULL
            AND m.sender_id != $1
            AND NOT EXISTS (
                SELECT 1 FROM message_reads mr
                WHERE mr.message_id = m.id AND mr.user_id = $1
            )",
        )
        .bind(user_id)
        .fetch_one(&self.pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to get all unread count: {}", e)))?;

        Ok(row.0)
    }

    async fn find_by_type(
        &self,
        conversation_id: Uuid,
        message_type: &str,
        limit: i64,
        offset: i64,
    ) -> Result<Vec<Message>> {
        let models: Vec<MessageModel> = sqlx::query_as(
            "SELECT id, conversation_id, sender_id, message_type::text as message_type, content, media_url, payment_data, reply_to_id, created_at FROM messages
            WHERE conversation_id = $1 AND message_type = $2::message_type
            ORDER BY created_at DESC
            LIMIT $3 OFFSET $4")
            .bind(conversation_id)
            .bind(message_type)
            .bind(limit)
            .bind(offset)
        .fetch_all(&self.pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to find messages by type: {}", e)))?;

        models.into_iter().map(Self::to_domain).collect()
    }

    async fn find_latest_in_conversation(&self, conversation_id: Uuid) -> Result<Option<Message>> {
        let model: Option<MessageModel> = sqlx::query_as(
            "SELECT id, conversation_id, sender_id, message_type::text as message_type, content, media_url, payment_data, reply_to_id, created_at FROM messages
            WHERE conversation_id = $1
            ORDER BY created_at DESC
            LIMIT 1")
            .bind(conversation_id)
        .fetch_optional(&self.pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to find latest message: {}", e)))?;

        model.map(Self::to_domain).transpose()
    }

    async fn search_in_conversation(
        &self,
        conversation_id: Uuid,
        query: &str,
        limit: i64,
        offset: i64,
    ) -> Result<Vec<Message>> {
        let models: Vec<MessageModel> = sqlx::query_as(
            "SELECT id, conversation_id, sender_id, message_type::text as message_type, content, media_url, payment_data, reply_to_id, created_at FROM messages
            WHERE conversation_id = $1 AND content ILIKE $2
            ORDER BY created_at DESC
            LIMIT $3 OFFSET $4")
            .bind(conversation_id)
            .bind(format!("%{}%", query))
            .bind(limit)
            .bind(offset)
        .fetch_all(&self.pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to search messages: {}", e)))?;

        models.into_iter().map(Self::to_domain).collect()
    }
}
