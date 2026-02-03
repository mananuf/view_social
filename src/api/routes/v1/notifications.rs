use crate::api::handlers::notification_handlers::{
    get_notification_preferences, get_notification_stats, get_notifications,
    get_unread_notifications, mark_all_notifications_read, mark_notification_read,
    register_device_token, unregister_device_token, update_notification_preferences,
    NotificationState,
};
use axum::{
    routing::{delete, get, post, put},
    Router,
};

/// Create notification routes
///
/// Routes:
/// - GET /notifications - Get user notifications with pagination
/// - GET /notifications/unread - Get unread notifications
/// - PUT /notifications/:id/read - Mark specific notification as read
/// - PUT /notifications/read-all - Mark all notifications as read
/// - GET /notifications/stats - Get notification statistics
/// - POST /notifications/device-tokens - Register device token for push notifications
/// - DELETE /notifications/device-tokens/:id - Unregister device token
/// - GET /notifications/preferences - Get notification preferences
/// - PUT /notifications/preferences - Update notification preferences
pub fn create_router(state: NotificationState) -> Router {
    Router::new()
        .route("/", get(get_notifications))
        .route("/unread", get(get_unread_notifications))
        .route("/:id/read", put(mark_notification_read))
        .route("/read-all", put(mark_all_notifications_read))
        .route("/stats", get(get_notification_stats))
        .route("/device-tokens", post(register_device_token))
        .route("/device-tokens/:id", delete(unregister_device_token))
        .route("/preferences", get(get_notification_preferences))
        .route("/preferences", put(update_notification_preferences))
        .with_state(state)
}
