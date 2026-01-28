use crate::domain::errors::{AppError, Result};
use regex::Regex;
use serde::{Deserialize, Serialize};
use std::fmt;

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Username(String);

impl Username {
    pub fn new(username: String) -> Result<Self> {
        let username = username.trim().to_lowercase();

        if username.is_empty() {
            return Err(AppError::ValidationError(
                "Username cannot be empty".to_string(),
            ));
        }

        if username.len() < 3 {
            return Err(AppError::ValidationError(
                "Username must be at least 3 characters long".to_string(),
            ));
        }

        if username.len() > 30 {
            return Err(AppError::ValidationError(
                "Username cannot exceed 30 characters".to_string(),
            ));
        }

        // Username can only contain alphanumeric characters and underscores
        let username_regex = Regex::new(r"^[a-zA-Z0-9_]+$").unwrap();
        if !username_regex.is_match(&username) {
            return Err(AppError::ValidationError(
                "Username can only contain letters, numbers, and underscores".to_string(),
            ));
        }

        // Username cannot start with underscore
        if username.starts_with('_') {
            return Err(AppError::ValidationError(
                "Username cannot start with underscore".to_string(),
            ));
        }

        Ok(Username(username))
    }

    pub fn value(&self) -> &str {
        &self.0
    }
}

impl fmt::Display for Username {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.0)
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Email(String);

impl Email {
    pub fn new(email: String) -> Result<Self> {
        let email = email.trim().to_lowercase();

        if email.is_empty() {
            return Err(AppError::ValidationError(
                "Email cannot be empty".to_string(),
            ));
        }

        // Basic email validation regex
        let email_regex = Regex::new(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").unwrap();
        if !email_regex.is_match(&email) {
            return Err(AppError::ValidationError(
                "Invalid email format".to_string(),
            ));
        }

        if email.len() > 254 {
            return Err(AppError::ValidationError(
                "Email cannot exceed 254 characters".to_string(),
            ));
        }

        Ok(Email(email))
    }

    pub fn value(&self) -> &str {
        &self.0
    }
}

impl fmt::Display for Email {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.0)
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct PhoneNumber(String);

impl PhoneNumber {
    pub fn new(phone: String) -> Result<Self> {
        let phone = phone.trim().to_string();

        if phone.is_empty() {
            return Err(AppError::ValidationError(
                "Phone number cannot be empty".to_string(),
            ));
        }

        // Nigerian phone number validation (supports +234 and 0 prefixes)
        let phone_regex = Regex::new(r"^(\+234|0)[789][01]\d{8}$").unwrap();
        if !phone_regex.is_match(&phone) {
            return Err(AppError::ValidationError(
                "Invalid Nigerian phone number format".to_string(),
            ));
        }

        Ok(PhoneNumber(phone))
    }

    pub fn value(&self) -> &str {
        &self.0
    }

    pub fn normalized(&self) -> String {
        // Normalize to +234 format
        if self.0.starts_with("0") {
            format!("+234{}", &self.0[1..])
        } else {
            self.0.clone()
        }
    }
}

impl fmt::Display for PhoneNumber {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.0)
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct DisplayName(String);

impl DisplayName {
    pub fn new(name: String) -> Result<Self> {
        let name = name.trim().to_string();

        if name.is_empty() {
            return Err(AppError::ValidationError(
                "Display name cannot be empty".to_string(),
            ));
        }

        if name.len() > 100 {
            return Err(AppError::ValidationError(
                "Display name cannot exceed 100 characters".to_string(),
            ));
        }

        // Display name can contain letters, numbers, spaces, and common punctuation
        let name_regex = Regex::new(r"^[a-zA-Z0-9\s\-_.,!?']+$").unwrap();
        if !name_regex.is_match(&name) {
            return Err(AppError::ValidationError(
                "Display name contains invalid characters".to_string(),
            ));
        }

        Ok(DisplayName(name))
    }

    pub fn value(&self) -> &str {
        &self.0
    }
}

impl fmt::Display for DisplayName {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.0)
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Bio(String);

impl Bio {
    pub fn new(bio: String) -> Result<Self> {
        let bio = bio.trim().to_string();

        if bio.len() > 500 {
            return Err(AppError::ValidationError(
                "Bio cannot exceed 500 characters".to_string(),
            ));
        }

        Ok(Bio(bio))
    }

    pub fn value(&self) -> &str {
        &self.0
    }

    pub fn is_empty(&self) -> bool {
        self.0.is_empty()
    }
}

impl fmt::Display for Bio {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.0)
    }
}
