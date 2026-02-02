// Common DTOs used across the application
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize)]
pub struct SuccessResponse {
    pub message: String,
    pub data: Option<serde_json::Value>,
}

impl SuccessResponse {
    pub fn new(message: String, data: Option<serde_json::Value>) -> Self {
        Self { message, data }
    }
}

#[derive(Debug, Serialize)]
pub struct ErrorResponse {
    pub success: bool,
    pub error: ErrorDetail,
}

#[derive(Debug, Serialize)]
pub struct ErrorDetail {
    pub code: String,
    pub message: String,
}

impl ErrorResponse {
    pub fn new(code: String, message: String) -> Self {
        Self {
            success: false,
            error: ErrorDetail { code, message },
        }
    }
}

#[derive(Debug, Serialize)]
pub struct PaginatedResponse<T> {
    pub success: bool,
    pub data: Vec<T>,
    pub pagination: PaginationMeta,
}

#[derive(Debug, Serialize)]
pub struct PaginationMeta {
    pub total: i64,
    pub limit: i64,
    pub offset: i64,
    pub has_more: bool,
}

impl<T> PaginatedResponse<T> {
    pub fn new(data: Vec<T>, total: i64, limit: i64, offset: i64) -> Self {
        let has_more = offset + (data.len() as i64) < total;
        Self {
            success: true,
            data,
            pagination: PaginationMeta {
                total,
                limit,
                offset,
                has_more,
            },
        }
    }
}
