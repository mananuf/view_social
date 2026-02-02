//! API Handlers Module
//!
//! This module contains all HTTP request handlers organized by domain.
//! Each handler is responsible for:
//! - HTTP request/response handling
//! - Input validation
//! - Calling appropriate services
//! - Error handling and response formatting

pub mod auth_handlers;
pub mod message_handlers;
pub mod payment_handlers;
pub mod post_handlers;
pub mod user_handlers;

// Re-export commonly used types
pub use auth_handlers::*;
pub use message_handlers::*;
pub use payment_handlers::*;
pub use post_handlers::*;
pub use user_handlers::*;
