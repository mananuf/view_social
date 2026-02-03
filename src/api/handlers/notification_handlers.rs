use crate::api::middleware::auth::AuthUser;
use crate::application::services::NotificationService;
use crate::domain::entities::{CreateDeviceTokenRequest, DevicePlatform, NotificationPreferences};
use crate::domain::errors::AppError;
use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    response::Response,
    Json,
};
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use uuid::Uuid;

/// State for notification handlers
pub type NotificationState = Arc<NotificationService>;

/// Query parameters for notification list
#[derive(Debug, Deserialize)]
pub struct NotificationQuery {
    pub limit: Option<i64>,
    pub offset: Option<i64>,
}

/// Request for registering device token
#[derive(Debug, Deserialize)]
pub struct RegisterDeviceTokenRequest {
    pub token: String,
    pub platform: String,
}

/// Request for updating notification preferences
#[derive(Debug, Deserialize)]
pub struct UpdatePreferencesRequest {
    pub push_notifications_enabled: Option<bool>,
    pub email_notifications_enabled: Option<bool>,
    pub message_notifications: Option<bool>,
    pub like_notifications: Option<bool>,
    pub comment_notifications: Option<bool>,
    pub follow_notifications: Option<bool>,
    pub payment_notifications: Option<bool>,
    pub mention_notifications: Option<bool>,
    pub system_notifications: Option<bool>,
}

/// Response for notification list
#[derive(Debug, Serialize)]
pub struct NotificationListResponse {
    pub notifications: Vec<NotificationResponse>,
    pub total_count: i64,
    pub unread_count: i64,
}

/// Response for single notification
#[derive(Debug, Serialize)]
pub struct NotificationResponse {
    pub id: Uuid,
    pub notification_type: String,
    pub title: String,
    pub body: String,
    pub data: serde_json::Value,
    pub is_read: bool,
    pub created_at: chrono::DateTime<chrono::Utc>,
    pub read_at: Option<chrono::DateTime<chrono::Utc>>,
}

impl From<crate::domain::entities::Notification> for NotificationResponse {
    fn from(notification: crate::domain::entities::Notification) -> Self {
        Self {
            id: notification.id,
            notification_type: notification.notification_type.to_string(),
            title: notification.title,
            body: notification.body,
            data: notification.data,
            is_read: notification.is_read,
            created_at: notification.created_at,
            read_at: notification.read_at,
        }
    }
}

/// GET /notifications - Get user notifications
pub async fn get_notifications(
    auth_user: AuthUser,
    Query(query): Query<NotificationQuery>,
    State(service): State<NotificationState>,
) -> Result<Response, AppError> {
    let limit = query.limit.unwrap_or(20).min(100).max(1);
    let offset = query.offset.unwrap_or(0).max(0);

    // Get notifications
    let notifications = service
        .get_user_notifications(auth_user.user_id, limit, offset)
        .await?;

    // Get stats for counts
    let stats = service.get_notification_stats(auth_user.user_id).await?;

    let response = NotificationListResponse {
        notifications: notifications
            .into_iter()
            .map(NotificationResponse::from)
            .collect(),
        total_count: stats.total_notifications,
        unread_count: stats.unread_count,
    };

    Ok(Response::builder()
        .status(StatusCode::OK)
        .header("content-type", "application/json")
        .body(serde_json::to_string(&response).unwrap().into())
        .unwrap())
}

/// GET /notifications/unread - Get unread notifications
pub async fn get_unread_notifications(
    auth_user: AuthUser,
    State(service): State<NotificationState>,
) -> Result<Response, AppError> {
    let notifications = service.get_unread_notifications(auth_user.user_id).await?;

    let response: Vec<NotificationResponse> = notifications
        .into_iter()
        .map(NotificationResponse::from)
        .collect();

    Ok(Response::builder()
        .status(StatusCode::OK)
        .header("content-type", "application/json")
        .body(serde_json::to_string(&response).unwrap().into())
        .unwrap())
}

/// PUT /notifications/:id/read - Mark notification as read
pub async fn mark_notification_read(
    _auth_user: AuthUser,
    Path(notification_id): Path<Uuid>,
    State(service): State<NotificationState>,
) -> Result<Response, AppError> {
    service.mark_notification_as_read(notification_id).await?;

    Ok(Response::builder()
        .status(StatusCode::OK)
        .header("content-type", "application/json")
        .body(r#"{"message": "Notification marked as read"}"#.into())
        .unwrap())
}

/// PUT /notifications/read-all - Mark all notifications as read
pub async fn mark_all_notifications_read(
    auth_user: AuthUser,
    State(service): State<NotificationState>,
) -> Result<Response, AppError> {
    service
        .mark_all_notifications_as_read(auth_user.user_id)
        .await?;

    Ok(Response::builder()
        .status(StatusCode::OK)
        .header("content-type", "application/json")
        .body(r#"{"message": "All notifications marked as read"}"#.into())
        .unwrap())
}

/// GET /notifications/stats - Get notification statistics
pub async fn get_notification_stats(
    auth_user: AuthUser,
    State(service): State<NotificationState>,
) -> Result<Response, AppError> {
    let stats = service.get_notification_stats(auth_user.user_id).await?;

    Ok(Response::builder()
        .status(StatusCode::OK)
        .header("content-type", "application/json")
        .body(serde_json::to_string(&stats).unwrap().into())
        .unwrap())
}

/// POST /notifications/device-tokens - Register device token for push notifications
pub async fn register_device_token(
    auth_user: AuthUser,
    State(service): State<NotificationState>,
    Json(payload): Json<RegisterDeviceTokenRequest>,
) -> Result<Response, AppError> {
    // Parse platform
    let platform: DevicePlatform = payload.platform.parse()?;

    // Create device token request
    let request = CreateDeviceTokenRequest {
        user_id: auth_user.user_id,
        token: payload.token,
        platform,
    };

    // Create device token entity
    let device_token = crate::domain::entities::DeviceToken::new(request)?;

    // Register the token
    let registered_token = service.register_device_token(&device_token).await?;

    #[derive(Serialize)]
    struct DeviceTokenResponse {
        id: Uuid,
        platform: String,
        is_active: bool,
        created_at: chrono::DateTime<chrono::Utc>,
    }

    let response = DeviceTokenResponse {
        id: registered_token.id,
        platform: registered_token.platform.to_string(),
        is_active: registered_token.is_active,
        created_at: registered_token.created_at,
    };

    Ok(Response::builder()
        .status(StatusCode::CREATED)
        .header("content-type", "application/json")
        .body(serde_json::to_string(&response).unwrap().into())
        .unwrap())
}

/// DELETE /notifications/device-tokens/:id - Unregister device token
pub async fn unregister_device_token(
    _auth_user: AuthUser,
    Path(token_id): Path<Uuid>,
    State(service): State<NotificationState>,
) -> Result<Response, AppError> {
    service.unregister_device_token(token_id).await?;

    Ok(Response::builder()
        .status(StatusCode::OK)
        .header("content-type", "application/json")
        .body(r#"{"message": "Device token unregistered"}"#.into())
        .unwrap())
}

/// GET /notifications/preferences - Get notification preferences
pub async fn get_notification_preferences(
    auth_user: AuthUser,
    State(service): State<NotificationState>,
) -> Result<Response, AppError> {
    let preferences = service
        .get_user_preferences(auth_user.user_id)
        .await?
        .unwrap_or_else(|| NotificationPreferences::new(auth_user.user_id));

    Ok(Response::builder()
        .status(StatusCode::OK)
        .header("content-type", "application/json")
        .body(serde_json::to_string(&preferences).unwrap().into())
        .unwrap())
}

/// PUT /notifications/preferences - Update notification preferences
pub async fn update_notification_preferences(
    auth_user: AuthUser,
    State(service): State<NotificationState>,
    Json(payload): Json<UpdatePreferencesRequest>,
) -> Result<Response, AppError> {
    // Get current preferences or create default
    let mut preferences = service
        .get_user_preferences(auth_user.user_id)
        .await?
        .unwrap_or_else(|| NotificationPreferences::new(auth_user.user_id));

    // Update preferences with provided values
    if let Some(push_enabled) = payload.push_notifications_enabled {
        preferences.push_notifications_enabled = push_enabled;
    }
    if let Some(email_enabled) = payload.email_notifications_enabled {
        preferences.email_notifications_enabled = email_enabled;
    }
    if let Some(message_enabled) = payload.message_notifications {
        preferences.message_notifications = message_enabled;
    }
    if let Some(like_enabled) = payload.like_notifications {
        preferences.like_notifications = like_enabled;
    }
    if let Some(comment_enabled) = payload.comment_notifications {
        preferences.comment_notifications = comment_enabled;
    }
    if let Some(follow_enabled) = payload.follow_notifications {
        preferences.follow_notifications = follow_enabled;
    }
    if let Some(payment_enabled) = payload.payment_notifications {
        preferences.payment_notifications = payment_enabled;
    }
    if let Some(mention_enabled) = payload.mention_notifications {
        preferences.mention_notifications = mention_enabled;
    }
    if let Some(system_enabled) = payload.system_notifications {
        preferences.system_notifications = system_enabled;
    }

    // Update preferences
    let updated_preferences = service.update_user_preferences(&preferences).await?;

    Ok(Response::builder()
        .status(StatusCode::OK)
        .header("content-type", "application/json")
        .body(serde_json::to_string(&updated_preferences).unwrap().into())
        .unwrap())
}
