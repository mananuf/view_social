use crate::domain::errors::{AppError, Result};
use crate::domain::repositories::ConversationRepository;
use crate::infrastructure::database::models::{ConversationModel, ParticipantModel};
use async_trait::async_trait;
use chrono::{DateTime, Utc};
use sqlx::PgPool;
use uuid::Uuid;

/// PostgreSQL implementation of ConversationRepository
pub struct PostgresConversationRepository {
    pool: PgPool,
}

impl PostgresConversationRepository {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }
}

#[async_trait]
impl ConversationRepository for PostgresConversationRepository {
    async fn create(
        &self,
        conversation_id: Uuid,
        participant_ids: Vec<Uuid>,
        is_group: bool,
        group_name: Option<String>,
        created_by: Uuid,
    ) -> Result<Uuid> {
        let mut tx =
            self.pool.begin().await.map_err(|e| {
                AppError::DatabaseError(format!("Failed to start transaction: {}", e))
            })?;

        let conversation_type = if is_group { "group" } else { "direct" };

        sqlx::query(
            "INSERT INTO conversations (id, conversation_type, title, created_by, created_at, updated_at, last_message_at)
            VALUES ($1, $2, $3, $4, $5, $6, $7)")
            .bind(conversation_id)
            .bind(conversation_type)
            .bind(group_name)
            .bind(created_by)
            .bind(Utc::now())
            .bind(Utc::now())
            .bind(Utc::now())
        .execute(&mut *tx)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to create conversation: {}", e)))?;

        for participant_id in participant_ids {
            sqlx::query(
                "INSERT INTO conversation_participants (conversation_id, user_id, joined_at, is_admin)
                VALUES ($1, $2, $3, $4)")
                .bind(conversation_id)
                .bind(participant_id)
                .bind(Utc::now())
                .bind(participant_id == created_by)
            .execute(&mut *tx)
            .await
            .map_err(|e| AppError::DatabaseError(format!("Failed to add participant: {}", e)))?;
        }

        tx.commit().await.map_err(|e| {
            AppError::DatabaseError(format!("Failed to commit conversation creation: {}", e))
        })?;

        Ok(conversation_id)
    }

    async fn find_by_id(
        &self,
        id: Uuid,
    ) -> Result<Option<(Uuid, Vec<Uuid>, bool, Option<String>, DateTime<Utc>)>> {
        let model: Option<ConversationModel> = sqlx::query_as(
            "SELECT id, conversation_type, title, created_at FROM conversations WHERE id = $1",
        )
        .bind(id)
        .fetch_optional(&self.pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to find conversation: {}", e)))?;

        match model {
            Some(model) => {
                let participants: Vec<ParticipantModel> = sqlx::query_as(
                    "SELECT user_id FROM conversation_participants WHERE conversation_id = $1 AND left_at IS NULL")
                    .bind(id)
                .fetch_all(&self.pool)
                .await
                .map_err(|e| AppError::DatabaseError(format!("Failed to get participants: {}", e)))?;

                let participant_ids: Vec<Uuid> = participants.iter().map(|p| p.user_id).collect();
                let is_group = model.conversation_type == "group";

                Ok(Some((
                    model.id,
                    participant_ids,
                    is_group,
                    model.title,
                    model.created_at,
                )))
            }
            None => Ok(None),
        }
    }

    async fn find_by_user(
        &self,
        user_id: Uuid,
        limit: i64,
        offset: i64,
    ) -> Result<Vec<(Uuid, Vec<Uuid>, bool, Option<String>, DateTime<Utc>)>> {
        let models: Vec<ConversationModel> = sqlx::query_as(
            "SELECT DISTINCT c.id, c.conversation_type, c.title, c.created_at
            FROM conversations c
            INNER JOIN conversation_participants cp ON c.id = cp.conversation_id
            WHERE cp.user_id = $1 AND cp.left_at IS NULL
            ORDER BY c.last_message_at DESC
            LIMIT $2 OFFSET $3",
        )
        .bind(user_id)
        .bind(limit)
        .bind(offset)
        .fetch_all(&self.pool)
        .await
        .map_err(|e| {
            AppError::DatabaseError(format!("Failed to find user conversations: {}", e))
        })?;

        let mut conversations = Vec::new();
        for model in models {
            let participants: Vec<ParticipantModel> = sqlx::query_as(
                "SELECT user_id FROM conversation_participants WHERE conversation_id = $1 AND left_at IS NULL")
                .bind(model.id)
            .fetch_all(&self.pool)
            .await
            .map_err(|e| AppError::DatabaseError(format!("Failed to get participants: {}", e)))?;

            let participant_ids: Vec<Uuid> = participants.iter().map(|p| p.user_id).collect();
            let is_group = model.conversation_type == "group";

            conversations.push((
                model.id,
                participant_ids,
                is_group,
                model.title,
                model.created_at,
            ));
        }

        Ok(conversations)
    }

    async fn is_participant(&self, conversation_id: Uuid, user_id: Uuid) -> Result<bool> {
        let row: (bool,) = sqlx::query_as(
            "SELECT EXISTS(SELECT 1 FROM conversation_participants WHERE conversation_id = $1 AND user_id = $2 AND left_at IS NULL)")
            .bind(conversation_id)
            .bind(user_id)
        .fetch_one(&self.pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to check participant status: {}", e)))?;

        Ok(row.0)
    }

    async fn add_participant(&self, conversation_id: Uuid, user_id: Uuid) -> Result<()> {
        sqlx::query(
            "INSERT INTO conversation_participants (conversation_id, user_id, joined_at, is_admin)
            VALUES ($1, $2, $3, false)
            ON CONFLICT (conversation_id, user_id) DO UPDATE SET left_at = NULL",
        )
        .bind(conversation_id)
        .bind(user_id)
        .bind(Utc::now())
        .execute(&self.pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to add participant: {}", e)))?;

        Ok(())
    }

    async fn remove_participant(&self, conversation_id: Uuid, user_id: Uuid) -> Result<()> {
        sqlx::query(
            "UPDATE conversation_participants SET left_at = $3 WHERE conversation_id = $1 AND user_id = $2")
            .bind(conversation_id)
            .bind(user_id)
            .bind(Utc::now())
        .execute(&self.pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to remove participant: {}", e)))?;

        Ok(())
    }

    async fn get_participants(&self, conversation_id: Uuid) -> Result<Vec<Uuid>> {
        let models: Vec<ParticipantModel> = sqlx::query_as(
            "SELECT user_id FROM conversation_participants WHERE conversation_id = $1 AND left_at IS NULL")
            .bind(conversation_id)
        .fetch_all(&self.pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to get participants: {}", e)))?;

        Ok(models.iter().map(|r| r.user_id).collect())
    }

    async fn find_direct_conversation(
        &self,
        user1_id: Uuid,
        user2_id: Uuid,
    ) -> Result<Option<Uuid>> {
        let row: Option<(Uuid,)> = sqlx::query_as(
            "SELECT c.id FROM conversations c
            WHERE c.conversation_type = 'direct'
            AND EXISTS (SELECT 1 FROM conversation_participants cp1 WHERE cp1.conversation_id = c.id AND cp1.user_id = $1 AND cp1.left_at IS NULL)
            AND EXISTS (SELECT 1 FROM conversation_participants cp2 WHERE cp2.conversation_id = c.id AND cp2.user_id = $2 AND cp2.left_at IS NULL)
            AND (SELECT COUNT(*) FROM conversation_participants cp WHERE cp.conversation_id = c.id AND cp.left_at IS NULL) = 2
            LIMIT 1")
            .bind(user1_id)
            .bind(user2_id)
        .fetch_optional(&self.pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to find direct conversation: {}", e)))?;

        Ok(row.map(|r| r.0))
    }
}
