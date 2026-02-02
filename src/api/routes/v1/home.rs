use crate::{api::dto::SuccessResponse, server::AppState};
use axum::{http::StatusCode, response::IntoResponse, Json, Router};
use serde::Serialize;

#[derive(Serialize)]
struct WelcomeMessage {
    message: String,
    version: &'static str,
    description: &'static str,
}

async fn home_handler() -> impl IntoResponse {
    let welcome = WelcomeMessage {
        message: "Welcome to View Social".to_string(),
        version: "1.0.0",
        description: "Social media platform with integrated payments",
    };

    (
        StatusCode::OK,
        Json(SuccessResponse::new(
            "Welcome to View Social API".to_string(),
            Some(serde_json::to_value(welcome).unwrap()),
        )),
    )
}

///
/// - GET /- test api to return a welcome string
pub fn create_router(state: AppState) -> Router {
    Router::new()
        .route("/", axum::routing::get(home_handler))
        .with_state(state.message_state)
}
