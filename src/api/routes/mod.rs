//! API versioning module
//!
//! This module organizes API routes by version, allowing for:
//! - Backward compatibility when introducing breaking changes
//! - Gradual migration of clients to new API versions
//! - Clear deprecation paths for old endpoints
//!
//! Current versions: v1 (Initial API version - stable)

pub mod v1;
