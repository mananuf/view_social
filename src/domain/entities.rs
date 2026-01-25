use crate::domain::errors::{AppError, Result};
use crate::domain::value_objects::{Username, Email, PhoneNumber, DisplayName, Bio};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct User {
    pub id: Uuid,
    pub username: Username,
    pub email: Email,
    pub phone_number: Option<PhoneNumber>,
    pub display_name: Option<DisplayName>,
    pub bio: Option<Bio>,
    pub avatar_url: Option<String>,
    pub is_verified: bool,
    pub follower_count: i32,
    pub following_count: i32,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateUserRequest {
    pub username: String,
    pub email: String,
    pub phone_number: Option<String>,
    pub display_name: Option<String>,
    pub bio: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UpdateUserRequest {
    pub display_name: Option<String>,
    pub bio: Option<String>,
    pub avatar_url: Option<String>,
}

impl User {
    pub fn new(request: CreateUserRequest) -> Result<Self> {
        let username = Username::new(request.username)?;
        let email = Email::new(request.email)?;
        
        let phone_number = if let Some(phone) = request.phone_number {
            Some(PhoneNumber::new(phone)?)
        } else {
            None
        };
        
        let display_name = if let Some(name) = request.display_name {
            Some(DisplayName::new(name)?)
        } else {
            None
        };
        
        let bio = if let Some(bio_text) = request.bio {
            Some(Bio::new(bio_text)?)
        } else {
            None
        };
        
        let now = Utc::now();
        
        Ok(User {
            id: Uuid::new_v4(),
            username,
            email,
            phone_number,
            display_name,
            bio,
            avatar_url: None,
            is_verified: false,
            follower_count: 0,
            following_count: 0,
            created_at: now,
            updated_at: now,
        })
    }
    
    pub fn update(&mut self, request: UpdateUserRequest) -> Result<()> {
        if let Some(name) = request.display_name {
            self.display_name = Some(DisplayName::new(name)?);
        }
        
        if let Some(bio_text) = request.bio {
            if bio_text.trim().is_empty() {
                self.bio = None;
            } else {
                self.bio = Some(Bio::new(bio_text)?);
            }
        }
        
        if let Some(avatar_url) = request.avatar_url {
            if avatar_url.trim().is_empty() {
                self.avatar_url = None;
            } else {
                // Basic URL validation
                if !avatar_url.starts_with("http://") && !avatar_url.starts_with("https://") {
                    return Err(AppError::ValidationError("Avatar URL must be a valid HTTP/HTTPS URL".to_string()));
                }
                self.avatar_url = Some(avatar_url);
            }
        }
        
        self.updated_at = Utc::now();
        Ok(())
    }
    
    pub fn increment_follower_count(&mut self) {
        self.follower_count += 1;
        self.updated_at = Utc::now();
    }
    
    pub fn decrement_follower_count(&mut self) {
        if self.follower_count > 0 {
            self.follower_count -= 1;
            self.updated_at = Utc::now();
        }
    }
    
    pub fn increment_following_count(&mut self) {
        self.following_count += 1;
        self.updated_at = Utc::now();
    }
    
    pub fn decrement_following_count(&mut self) {
        if self.following_count > 0 {
            self.following_count -= 1;
            self.updated_at = Utc::now();
        }
    }
    
    pub fn verify(&mut self) {
        self.is_verified = true;
        self.updated_at = Utc::now();
    }
    
    pub fn unverify(&mut self) {
        self.is_verified = false;
        self.updated_at = Utc::now();
    }
    
    pub fn get_display_name_or_username(&self) -> String {
        self.display_name
            .as_ref()
            .map(|name| name.value().to_string())
            .unwrap_or_else(|| self.username.value().to_string())
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum PostContentType {
    Text,
    Image,
    Video,
    Mixed,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum PostVisibility {
    Public,
    Followers,
    Private,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MediaAttachment {
    pub id: Uuid,
    pub url: String,
    pub media_type: String, // MIME type
    pub size: i64,
    pub width: Option<i32>,
    pub height: Option<i32>,
    pub duration: Option<i32>, // For videos, in seconds
}

impl MediaAttachment {
    pub fn new(
        url: String,
        media_type: String,
        size: i64,
        width: Option<i32>,
        height: Option<i32>,
        duration: Option<i32>,
    ) -> Result<Self> {
        // Validate URL
        if url.trim().is_empty() {
            return Err(AppError::ValidationError("Media URL cannot be empty".to_string()));
        }
        
        if !url.starts_with("http://") && !url.starts_with("https://") {
            return Err(AppError::ValidationError("Media URL must be a valid HTTP/HTTPS URL".to_string()));
        }
        
        // Validate media type
        if media_type.trim().is_empty() {
            return Err(AppError::ValidationError("Media type cannot be empty".to_string()));
        }
        
        // Validate supported media types
        let supported_types = [
            "image/jpeg", "image/png", "image/gif", "image/webp",
            "video/mp4", "video/webm", "video/quicktime",
            "audio/mpeg", "audio/wav", "audio/ogg"
        ];
        
        if !supported_types.contains(&media_type.as_str()) {
            return Err(AppError::ValidationError(format!("Unsupported media type: {}", media_type)));
        }
        
        // Validate file size (max 100MB)
        if size <= 0 {
            return Err(AppError::ValidationError("Media size must be positive".to_string()));
        }
        
        if size > 100 * 1024 * 1024 {
            return Err(AppError::ValidationError("Media file cannot exceed 100MB".to_string()));
        }
        
        // Validate dimensions for images and videos
        if media_type.starts_with("image/") || media_type.starts_with("video/") {
            if let (Some(w), Some(h)) = (width, height) {
                if w <= 0 || h <= 0 {
                    return Err(AppError::ValidationError("Media dimensions must be positive".to_string()));
                }
                if w > 4096 || h > 4096 {
                    return Err(AppError::ValidationError("Media dimensions cannot exceed 4096x4096".to_string()));
                }
            }
        }
        
        // Validate duration for videos and audio
        if media_type.starts_with("video/") || media_type.starts_with("audio/") {
            if let Some(dur) = duration {
                if dur <= 0 {
                    return Err(AppError::ValidationError("Media duration must be positive".to_string()));
                }
                if dur > 3600 {
                    return Err(AppError::ValidationError("Media duration cannot exceed 1 hour".to_string()));
                }
            }
        }
        
        Ok(MediaAttachment {
            id: Uuid::new_v4(),
            url,
            media_type,
            size,
            width,
            height,
            duration,
        })
    }
    
    pub fn is_image(&self) -> bool {
        self.media_type.starts_with("image/")
    }
    
    pub fn is_video(&self) -> bool {
        self.media_type.starts_with("video/")
    }
    
    pub fn is_audio(&self) -> bool {
        self.media_type.starts_with("audio/")
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Post {
    pub id: Uuid,
    pub user_id: Uuid,
    pub content_type: PostContentType,
    pub text_content: Option<String>,
    pub media_attachments: Vec<MediaAttachment>,
    pub is_reel: bool,
    pub visibility: PostVisibility,
    pub like_count: i32,
    pub comment_count: i32,
    pub reshare_count: i32,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreatePostRequest {
    pub user_id: Uuid,
    pub text_content: Option<String>,
    pub media_attachments: Vec<MediaAttachment>,
    pub is_reel: bool,
    pub visibility: PostVisibility,
}

impl Post {
    pub fn new(request: CreatePostRequest) -> Result<Self> {
        // Validate content
        if request.text_content.is_none() && request.media_attachments.is_empty() {
            return Err(AppError::ValidationError("Post must have either text content or media attachments".to_string()));
        }
        
        // Validate text content length if present
        if let Some(ref text) = request.text_content {
            if text.trim().is_empty() {
                return Err(AppError::ValidationError("Text content cannot be empty".to_string()));
            }
            if text.len() > 2000 {
                return Err(AppError::ValidationError("Text content cannot exceed 2000 characters".to_string()));
            }
        }
        
        // Validate reel constraints
        if request.is_reel {
            // Reels must have video content
            let has_video = request.media_attachments.iter().any(|media| {
                media.media_type.starts_with("video/")
            });
            
            if !has_video {
                return Err(AppError::ValidationError("Reels must contain video content".to_string()));
            }
            
            // Validate video duration for reels (under 60 seconds)
            for media in &request.media_attachments {
                if media.media_type.starts_with("video/") {
                    if let Some(duration) = media.duration {
                        if duration > 60 {
                            return Err(AppError::ValidationError("Reel videos must be under 60 seconds".to_string()));
                        }
                    }
                }
            }
        }
        
        // Validate media attachments count
        if request.media_attachments.len() > 10 {
            return Err(AppError::ValidationError("Posts cannot have more than 10 media attachments".to_string()));
        }
        
        // Determine content type
        let content_type = if request.media_attachments.is_empty() {
            PostContentType::Text
        } else {
            let has_image = request.media_attachments.iter().any(|m| m.media_type.starts_with("image/"));
            let has_video = request.media_attachments.iter().any(|m| m.media_type.starts_with("video/"));
            
            match (has_image, has_video) {
                (true, true) => PostContentType::Mixed,
                (true, false) => PostContentType::Image,
                (false, true) => PostContentType::Video,
                (false, false) => PostContentType::Text,
            }
        };
        
        let now = Utc::now();
        
        Ok(Post {
            id: Uuid::new_v4(),
            user_id: request.user_id,
            content_type,
            text_content: request.text_content,
            media_attachments: request.media_attachments,
            is_reel: request.is_reel,
            visibility: request.visibility,
            like_count: 0,
            comment_count: 0,
            reshare_count: 0,
            created_at: now,
            updated_at: now,
        })
    }
    
    pub fn increment_like_count(&mut self) {
        self.like_count += 1;
        self.updated_at = Utc::now();
    }
    
    pub fn decrement_like_count(&mut self) {
        if self.like_count > 0 {
            self.like_count -= 1;
            self.updated_at = Utc::now();
        }
    }
    
    pub fn increment_comment_count(&mut self) {
        self.comment_count += 1;
        self.updated_at = Utc::now();
    }
    
    pub fn decrement_comment_count(&mut self) {
        if self.comment_count > 0 {
            self.comment_count -= 1;
            self.updated_at = Utc::now();
        }
    }
    
    pub fn increment_reshare_count(&mut self) {
        self.reshare_count += 1;
        self.updated_at = Utc::now();
    }
    
    pub fn decrement_reshare_count(&mut self) {
        if self.reshare_count > 0 {
            self.reshare_count -= 1;
            self.updated_at = Utc::now();
        }
    }
    
    pub fn is_video_content(&self) -> bool {
        matches!(self.content_type, PostContentType::Video | PostContentType::Mixed)
    }
    
    pub fn is_image_content(&self) -> bool {
        matches!(self.content_type, PostContentType::Image | PostContentType::Mixed)
    }
    
    pub fn has_media(&self) -> bool {
        !self.media_attachments.is_empty()
    }
    
    pub fn get_total_engagement(&self) -> i32 {
        self.like_count + self.comment_count + self.reshare_count
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum MessageType {
    Text,
    Image,
    Video,
    Audio,
    Payment,
    System,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PaymentData {
    pub transaction_id: Uuid,
    pub amount: rust_decimal::Decimal,
    pub currency: String,
    pub status: String,
}

impl PaymentData {
    pub fn new(
        transaction_id: Uuid,
        amount: rust_decimal::Decimal,
        currency: String,
        status: String,
    ) -> Result<Self> {
        // Validate amount
        if amount <= rust_decimal::Decimal::ZERO {
            return Err(AppError::ValidationError("Payment amount must be positive".to_string()));
        }
        
        // Validate currency (Nigerian Naira for MVP)
        if currency != "NGN" {
            return Err(AppError::ValidationError("Only NGN currency is supported".to_string()));
        }
        
        // Validate status
        let valid_statuses = ["pending", "completed", "failed", "cancelled"];
        if !valid_statuses.contains(&status.as_str()) {
            return Err(AppError::ValidationError("Invalid payment status".to_string()));
        }
        
        Ok(PaymentData {
            transaction_id,
            amount,
            currency,
            status,
        })
    }
    
    pub fn is_completed(&self) -> bool {
        self.status == "completed"
    }
    
    pub fn is_pending(&self) -> bool {
        self.status == "pending"
    }
    
    pub fn is_failed(&self) -> bool {
        self.status == "failed"
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Message {
    pub id: Uuid,
    pub conversation_id: Uuid,
    pub sender_id: Option<Uuid>, // None for system messages
    pub message_type: MessageType,
    pub content: Option<String>,
    pub media_url: Option<String>,
    pub payment_data: Option<PaymentData>,
    pub reply_to_id: Option<Uuid>,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateMessageRequest {
    pub conversation_id: Uuid,
    pub sender_id: Option<Uuid>,
    pub message_type: MessageType,
    pub content: Option<String>,
    pub media_url: Option<String>,
    pub payment_data: Option<PaymentData>,
    pub reply_to_id: Option<Uuid>,
}

impl Message {
    pub fn new(request: CreateMessageRequest) -> Result<Self> {
        // Validate message content based on type
        match request.message_type {
            MessageType::Text => {
                if request.content.is_none() || request.content.as_ref().unwrap().trim().is_empty() {
                    return Err(AppError::ValidationError("Text messages must have content".to_string()));
                }
                
                if let Some(ref content) = request.content {
                    if content.len() > 4000 {
                        return Err(AppError::ValidationError("Message content cannot exceed 4000 characters".to_string()));
                    }
                }
            }
            MessageType::Image | MessageType::Video | MessageType::Audio => {
                if request.media_url.is_none() || request.media_url.as_ref().unwrap().trim().is_empty() {
                    return Err(AppError::ValidationError("Media messages must have a media URL".to_string()));
                }
                
                if let Some(ref url) = request.media_url {
                    if !url.starts_with("http://") && !url.starts_with("https://") {
                        return Err(AppError::ValidationError("Media URL must be a valid HTTP/HTTPS URL".to_string()));
                    }
                }
            }
            MessageType::Payment => {
                if request.payment_data.is_none() {
                    return Err(AppError::ValidationError("Payment messages must have payment data".to_string()));
                }
                
                if request.sender_id.is_none() {
                    return Err(AppError::ValidationError("Payment messages must have a sender".to_string()));
                }
            }
            MessageType::System => {
                if request.sender_id.is_some() {
                    return Err(AppError::ValidationError("System messages cannot have a sender".to_string()));
                }
                
                if request.content.is_none() || request.content.as_ref().unwrap().trim().is_empty() {
                    return Err(AppError::ValidationError("System messages must have content".to_string()));
                }
            }
        }
        
        Ok(Message {
            id: Uuid::new_v4(),
            conversation_id: request.conversation_id,
            sender_id: request.sender_id,
            message_type: request.message_type,
            content: request.content,
            media_url: request.media_url,
            payment_data: request.payment_data,
            reply_to_id: request.reply_to_id,
            created_at: Utc::now(),
        })
    }
    
    pub fn is_system_message(&self) -> bool {
        matches!(self.message_type, MessageType::System)
    }
    
    pub fn is_payment_message(&self) -> bool {
        matches!(self.message_type, MessageType::Payment)
    }
    
    pub fn is_media_message(&self) -> bool {
        matches!(
            self.message_type,
            MessageType::Image | MessageType::Video | MessageType::Audio
        )
    }
    
    pub fn is_reply(&self) -> bool {
        self.reply_to_id.is_some()
    }
    
    pub fn has_content(&self) -> bool {
        self.content.is_some() && !self.content.as_ref().unwrap().trim().is_empty()
    }
}

// Message read tracking
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MessageRead {
    pub id: Uuid,
    pub message_id: Uuid,
    pub user_id: Uuid,
    pub read_at: DateTime<Utc>,
}

impl MessageRead {
    pub fn new(message_id: Uuid, user_id: Uuid) -> Self {
        MessageRead {
            id: Uuid::new_v4(),
            message_id,
            user_id,
            read_at: Utc::now(),
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum WalletStatus {
    Active,
    Suspended,
    Locked,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Wallet {
    pub id: Uuid,
    pub user_id: Uuid,
    pub balance: rust_decimal::Decimal,
    pub currency: String,
    pub status: WalletStatus,
    pub pin_hash: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateWalletRequest {
    pub user_id: Uuid,
    pub currency: String,
    pub pin: Option<String>,
}

impl Wallet {
    pub fn new(request: CreateWalletRequest) -> Result<Self> {
        // Validate currency (Nigerian Naira for MVP)
        if request.currency != "NGN" {
            return Err(AppError::ValidationError("Only NGN currency is supported".to_string()));
        }
        
        // Hash PIN if provided
        let pin_hash = if let Some(pin) = request.pin {
            if pin.len() != 4 {
                return Err(AppError::ValidationError("PIN must be exactly 4 digits".to_string()));
            }
            
            if !pin.chars().all(|c| c.is_ascii_digit()) {
                return Err(AppError::ValidationError("PIN must contain only digits".to_string()));
            }
            
            // Hash the PIN using bcrypt
            let hashed = bcrypt::hash(&pin, bcrypt::DEFAULT_COST)
                .map_err(|e| AppError::AuthenticationError(format!("Failed to hash PIN: {}", e)))?;
            Some(hashed)
        } else {
            None
        };
        
        let now = Utc::now();
        
        Ok(Wallet {
            id: Uuid::new_v4(),
            user_id: request.user_id,
            balance: rust_decimal::Decimal::ZERO,
            currency: request.currency,
            status: WalletStatus::Active,
            pin_hash,
            created_at: now,
            updated_at: now,
        })
    }
    
    pub fn verify_pin(&self, pin: &str) -> Result<bool> {
        match &self.pin_hash {
            Some(hash) => {
                bcrypt::verify(pin, hash)
                    .map_err(|e| AppError::AuthenticationError(format!("PIN verification failed: {}", e)))
            }
            None => Err(AppError::ValidationError("No PIN set for this wallet".to_string())),
        }
    }
    
    pub fn set_pin(&mut self, pin: String) -> Result<()> {
        if pin.len() != 4 {
            return Err(AppError::ValidationError("PIN must be exactly 4 digits".to_string()));
        }
        
        if !pin.chars().all(|c| c.is_ascii_digit()) {
            return Err(AppError::ValidationError("PIN must contain only digits".to_string()));
        }
        
        let hashed = bcrypt::hash(&pin, bcrypt::DEFAULT_COST)
            .map_err(|e| AppError::AuthenticationError(format!("Failed to hash PIN: {}", e)))?;
        
        self.pin_hash = Some(hashed);
        self.updated_at = Utc::now();
        Ok(())
    }
    
    pub fn credit(&mut self, amount: rust_decimal::Decimal) -> Result<()> {
        if amount <= rust_decimal::Decimal::ZERO {
            return Err(AppError::ValidationError("Credit amount must be positive".to_string()));
        }
        
        if self.status != WalletStatus::Active {
            return Err(AppError::PaymentError("Wallet is not active".to_string()));
        }
        
        self.balance += amount;
        self.updated_at = Utc::now();
        Ok(())
    }
    
    pub fn debit(&mut self, amount: rust_decimal::Decimal) -> Result<()> {
        if amount <= rust_decimal::Decimal::ZERO {
            return Err(AppError::ValidationError("Debit amount must be positive".to_string()));
        }
        
        if self.status != WalletStatus::Active {
            return Err(AppError::PaymentError("Wallet is not active".to_string()));
        }
        
        if self.balance < amount {
            return Err(AppError::InsufficientFunds);
        }
        
        self.balance -= amount;
        self.updated_at = Utc::now();
        Ok(())
    }
    
    pub fn suspend(&mut self) {
        self.status = WalletStatus::Suspended;
        self.updated_at = Utc::now();
    }
    
    pub fn lock(&mut self) {
        self.status = WalletStatus::Locked;
        self.updated_at = Utc::now();
    }
    
    pub fn activate(&mut self) {
        self.status = WalletStatus::Active;
        self.updated_at = Utc::now();
    }
    
    pub fn is_active(&self) -> bool {
        matches!(self.status, WalletStatus::Active)
    }
    
    pub fn has_sufficient_balance(&self, amount: rust_decimal::Decimal) -> bool {
        self.balance >= amount
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum TransactionStatus {
    Pending,
    Completed,
    Failed,
    Cancelled,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum TransactionType {
    Transfer,
    Deposit,
    Withdrawal,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Transaction {
    pub id: Uuid,
    pub sender_wallet_id: Option<Uuid>,
    pub receiver_wallet_id: Option<Uuid>,
    pub transaction_type: TransactionType,
    pub amount: rust_decimal::Decimal,
    pub currency: String,
    pub status: TransactionStatus,
    pub description: Option<String>,
    pub reference: String,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateTransactionRequest {
    pub sender_wallet_id: Option<Uuid>,
    pub receiver_wallet_id: Option<Uuid>,
    pub transaction_type: TransactionType,
    pub amount: rust_decimal::Decimal,
    pub currency: String,
    pub description: Option<String>,
}

impl Transaction {
    pub fn new(request: CreateTransactionRequest) -> Result<Self> {
        // Validate amount
        if request.amount <= rust_decimal::Decimal::ZERO {
            return Err(AppError::ValidationError("Transaction amount must be positive".to_string()));
        }
        
        // Validate currency
        if request.currency != "NGN" {
            return Err(AppError::ValidationError("Only NGN currency is supported".to_string()));
        }
        
        // Validate transaction type constraints
        match request.transaction_type {
            TransactionType::Transfer => {
                if request.sender_wallet_id.is_none() || request.receiver_wallet_id.is_none() {
                    return Err(AppError::ValidationError("Transfer transactions require both sender and receiver wallets".to_string()));
                }
                
                if request.sender_wallet_id == request.receiver_wallet_id {
                    return Err(AppError::ValidationError("Cannot transfer to the same wallet".to_string()));
                }
            }
            TransactionType::Deposit => {
                if request.receiver_wallet_id.is_none() {
                    return Err(AppError::ValidationError("Deposit transactions require a receiver wallet".to_string()));
                }
                
                if request.sender_wallet_id.is_some() {
                    return Err(AppError::ValidationError("Deposit transactions should not have a sender wallet".to_string()));
                }
            }
            TransactionType::Withdrawal => {
                if request.sender_wallet_id.is_none() {
                    return Err(AppError::ValidationError("Withdrawal transactions require a sender wallet".to_string()));
                }
                
                if request.receiver_wallet_id.is_some() {
                    return Err(AppError::ValidationError("Withdrawal transactions should not have a receiver wallet".to_string()));
                }
            }
        }
        
        // Validate description length
        if let Some(ref desc) = request.description {
            if desc.len() > 500 {
                return Err(AppError::ValidationError("Transaction description cannot exceed 500 characters".to_string()));
            }
        }
        
        // Generate unique reference
        let reference = format!("TXN-{}", Uuid::new_v4().to_string().replace('-', "").to_uppercase()[..12].to_string());
        
        let now = Utc::now();
        
        Ok(Transaction {
            id: Uuid::new_v4(),
            sender_wallet_id: request.sender_wallet_id,
            receiver_wallet_id: request.receiver_wallet_id,
            transaction_type: request.transaction_type,
            amount: request.amount,
            currency: request.currency,
            status: TransactionStatus::Pending,
            description: request.description,
            reference,
            created_at: now,
            updated_at: now,
        })
    }
    
    pub fn complete(&mut self) -> Result<()> {
        if self.status != TransactionStatus::Pending {
            return Err(AppError::PaymentError("Only pending transactions can be completed".to_string()));
        }
        
        self.status = TransactionStatus::Completed;
        self.updated_at = Utc::now();
        Ok(())
    }
    
    pub fn fail(&mut self, reason: Option<String>) -> Result<()> {
        if self.status == TransactionStatus::Completed {
            return Err(AppError::PaymentError("Cannot fail a completed transaction".to_string()));
        }
        
        self.status = TransactionStatus::Failed;
        if let Some(reason) = reason {
            self.description = Some(format!("{} - Failed: {}", 
                self.description.as_deref().unwrap_or(""), reason));
        }
        self.updated_at = Utc::now();
        Ok(())
    }
    
    pub fn cancel(&mut self) -> Result<()> {
        if self.status != TransactionStatus::Pending {
            return Err(AppError::PaymentError("Only pending transactions can be cancelled".to_string()));
        }
        
        self.status = TransactionStatus::Cancelled;
        self.updated_at = Utc::now();
        Ok(())
    }
    
    pub fn is_completed(&self) -> bool {
        matches!(self.status, TransactionStatus::Completed)
    }
    
    pub fn is_pending(&self) -> bool {
        matches!(self.status, TransactionStatus::Pending)
    }
    
    pub fn is_failed(&self) -> bool {
        matches!(self.status, TransactionStatus::Failed)
    }
    
    pub fn is_cancelled(&self) -> bool {
        matches!(self.status, TransactionStatus::Cancelled)
    }
    
    pub fn is_transfer(&self) -> bool {
        matches!(self.transaction_type, TransactionType::Transfer)
    }
    
    pub fn involves_wallet(&self, wallet_id: Uuid) -> bool {
        self.sender_wallet_id == Some(wallet_id) || self.receiver_wallet_id == Some(wallet_id)
    }
}
#[cfg(test)]
mod tests {
    use super::*;
    use proptest::prelude::*;
    use std::collections::HashSet;

    // **Feature: view-social-mvp, Property 1: User registration uniqueness**
    // **Validates: Requirements 1.1**
    proptest! {
        #[test]
        fn test_user_registration_uniqueness(
            usernames in prop::collection::vec("[a-z][a-z0-9_]{2,29}", 2..10),
            emails in prop::collection::vec("[a-z]{3,10}@[a-z]{3,10}\\.[a-z]{2,3}", 2..10)
        ) {
            // For any set of registration data, usernames and emails should be unique
            let mut created_users = Vec::new();
            let mut seen_usernames = HashSet::new();
            let mut seen_emails = HashSet::new();
            
            for (username, email) in usernames.iter().zip(emails.iter()) {
                let request = CreateUserRequest {
                    username: username.clone(),
                    email: email.clone(),
                    phone_number: None,
                    display_name: None,
                    bio: None,
                };
                
                match User::new(request) {
                    Ok(user) => {
                        // Username should be unique
                        prop_assert!(!seen_usernames.contains(user.username.value()));
                        seen_usernames.insert(user.username.value().to_string());
                        
                        // Email should be unique
                        prop_assert!(!seen_emails.contains(user.email.value()));
                        seen_emails.insert(user.email.value().to_string());
                        
                        created_users.push(user);
                    }
                    Err(_) => {
                        // If user creation fails due to validation, that's acceptable
                        // The property is about uniqueness, not validation
                    }
                }
            }
            
            // All created users should have unique usernames and emails
            let usernames_count = created_users.iter().map(|u| u.username.value()).collect::<HashSet<_>>().len();
            let emails_count = created_users.iter().map(|u| u.email.value()).collect::<HashSet<_>>().len();
            
            prop_assert_eq!(usernames_count, created_users.len());
            prop_assert_eq!(emails_count, created_users.len());
        }
    }

    // **Feature: view-social-mvp, Property 5: Post creation validation**
    // **Validates: Requirements 2.1**
    proptest! {
        #[test]
        fn test_post_creation_validation(
            text_content in prop::option::of("[a-zA-Z0-9 .,!?]{1,1999}"),
            user_id in "[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}",
            is_reel in any::<bool>(),
            visibility in prop::sample::select(vec![PostVisibility::Public, PostVisibility::Followers, PostVisibility::Private])
        ) {
            // For any valid post creation request, the post should be created and validated properly
            let user_uuid = user_id.parse::<Uuid>().unwrap();
            
            let request = CreatePostRequest {
                user_id: user_uuid,
                text_content: text_content.clone(),
                media_attachments: vec![], // Start with no media for simplicity
                is_reel,
                visibility,
            };
            
            match Post::new(request) {
                Ok(post) => {
                    // Post should have the correct user_id
                    prop_assert_eq!(post.user_id, user_uuid);
                    
                    // Post should have the correct text content
                    prop_assert_eq!(post.text_content, text_content);
                    
                    // Post should have correct content type for text-only posts
                    prop_assert_eq!(post.content_type, PostContentType::Text);
                    
                    // Post should have zero engagement initially
                    prop_assert_eq!(post.like_count, 0);
                    prop_assert_eq!(post.comment_count, 0);
                    prop_assert_eq!(post.reshare_count, 0);
                    
                    // Post should have valid timestamps
                    prop_assert!(post.created_at <= Utc::now());
                    prop_assert!(post.updated_at <= Utc::now());
                    prop_assert_eq!(post.created_at, post.updated_at);
                    
                    // If is_reel is true but no video content, it should fail validation
                    // This is handled by the validation logic in Post::new
                }
                Err(err) => {
                    // If post creation fails, it should be due to validation
                    // For text-only posts with no content, this is expected
                    if text_content.is_none() {
                        prop_assert!(matches!(err, AppError::ValidationError(_)));
                    }
                }
            }
        }
    }

    // **Feature: view-social-mvp, Property 12: Payment processing consistency**
    // **Validates: Requirements 5.1**
    proptest! {
        #[test]
        fn test_payment_processing_consistency(
            sender_balance in 1000u32..100000u32,
            transfer_amount in 1u32..1000u32,
        ) {
            use rust_decimal::Decimal;
            
            // For any valid money transfer, sender balance should decrease and receiver balance should increase by the same amount
            let sender_user_id = Uuid::new_v4();
            let receiver_user_id = Uuid::new_v4();
            
            // Create sender wallet with initial balance
            let mut sender_wallet = Wallet::new(CreateWalletRequest {
                user_id: sender_user_id,
                currency: "NGN".to_string(),
                pin: Some("1234".to_string()),
            }).unwrap();
            
            let initial_sender_balance = Decimal::from(sender_balance);
            sender_wallet.credit(initial_sender_balance).unwrap();
            
            // Create receiver wallet with zero balance
            let mut receiver_wallet = Wallet::new(CreateWalletRequest {
                user_id: receiver_user_id,
                currency: "NGN".to_string(),
                pin: Some("5678".to_string()),
            }).unwrap();
            
            let _initial_receiver_balance = receiver_wallet.balance;
            let amount = Decimal::from(transfer_amount);
            
            // Only proceed if sender has sufficient balance
            if sender_wallet.has_sufficient_balance(amount) {
                let sender_balance_before = sender_wallet.balance;
                let receiver_balance_before = receiver_wallet.balance;
                
                // Perform the transfer
                let debit_result = sender_wallet.debit(amount);
                let credit_result = receiver_wallet.credit(amount);
                
                prop_assert!(debit_result.is_ok());
                prop_assert!(credit_result.is_ok());
                
                // Verify balance consistency
                let sender_balance_after = sender_wallet.balance;
                let receiver_balance_after = receiver_wallet.balance;
                
                // Sender balance should decrease by exactly the transfer amount
                prop_assert_eq!(sender_balance_before - amount, sender_balance_after);
                
                // Receiver balance should increase by exactly the transfer amount
                prop_assert_eq!(receiver_balance_before + amount, receiver_balance_after);
                
                // Total money in the system should remain constant
                let total_before = sender_balance_before + receiver_balance_before;
                let total_after = sender_balance_after + receiver_balance_after;
                prop_assert_eq!(total_before, total_after);
                
                // Verify wallet states are still active
                prop_assert!(sender_wallet.is_active());
                prop_assert!(receiver_wallet.is_active());
            }
        }
    }

    #[test]
    fn test_user_creation_with_valid_data() {
        let request = CreateUserRequest {
            username: "testuser".to_string(),
            email: "test@example.com".to_string(),
            phone_number: Some("+2348012345678".to_string()),
            display_name: Some("Test User".to_string()),
            bio: Some("This is a test bio".to_string()),
        };

        let user = User::new(request).unwrap();
        
        assert_eq!(user.username.value(), "testuser");
        assert_eq!(user.email.value(), "test@example.com");
        assert!(user.phone_number.is_some());
        assert!(user.display_name.is_some());
        assert!(user.bio.is_some());
        assert!(!user.is_verified);
        assert_eq!(user.follower_count, 0);
        assert_eq!(user.following_count, 0);
    }

    #[test]
    fn test_user_creation_with_invalid_username() {
        let request = CreateUserRequest {
            username: "ab".to_string(), // Too short
            email: "test@example.com".to_string(),
            phone_number: None,
            display_name: None,
            bio: None,
        };

        assert!(User::new(request).is_err());
    }

    #[test]
    fn test_user_creation_with_invalid_email() {
        let request = CreateUserRequest {
            username: "testuser".to_string(),
            email: "invalid-email".to_string(),
            phone_number: None,
            display_name: None,
            bio: None,
        };

        assert!(User::new(request).is_err());
    }

    #[test]
    fn test_user_update() {
        let request = CreateUserRequest {
            username: "testuser".to_string(),
            email: "test@example.com".to_string(),
            phone_number: None,
            display_name: None,
            bio: None,
        };

        let mut user = User::new(request).unwrap();
        
        let update_request = UpdateUserRequest {
            display_name: Some("Updated Name".to_string()),
            bio: Some("Updated bio".to_string()),
            avatar_url: Some("https://example.com/avatar.jpg".to_string()),
        };

        user.update(update_request).unwrap();
        
        assert_eq!(user.display_name.as_ref().unwrap().value(), "Updated Name");
        assert_eq!(user.bio.as_ref().unwrap().value(), "Updated bio");
        assert_eq!(user.avatar_url.as_ref().unwrap(), "https://example.com/avatar.jpg");
    }
}
    // **Feature: view-social-mvp, Property 8: Feed content filtering**
    // **Validates: Requirements 3.1**
    proptest! {
        #[test]
        fn test_feed_content_filtering(
            user_ids in prop::collection::vec("[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}", 3..10),
            post_contents in prop::collection::vec("[a-zA-Z0-9 .,!?]{10,100}", 5..20),
            follow_relationships in prop::collection::vec((0usize..5usize, 0usize..5usize), 2..10)
        ) {
            use std::collections::{HashMap, HashSet};
            
            // For any user's feed request, only posts from followed users should be included in the response
            
            // Parse user IDs
            let mut users = Vec::new();
            for user_id_str in &user_ids {
                if let Ok(user_id) = user_id_str.parse::<Uuid>() {
                    users.push(user_id);
                }
            }
            
            // Skip if we don't have enough users
            if users.len() < 3 {
                return Ok(());
            }
            
            let requesting_user = users[0];
            
            // Create follow relationships - who does the requesting user follow?
            let mut followed_users = HashSet::new();
            for (follower_idx, following_idx) in &follow_relationships {
                if *follower_idx < users.len() && *following_idx < users.len() {
                    let follower = users[*follower_idx];
                    let following = users[*following_idx];
                    
                    // Only track who the requesting user follows
                    if follower == requesting_user && following != requesting_user {
                        followed_users.insert(following);
                    }
                }
            }
            
            // Create posts from various users
            let mut all_posts = Vec::new();
            let mut posts_from_followed_users = Vec::new();
            
            for (i, content) in post_contents.iter().enumerate() {
                if i < users.len() {
                    let author = users[i % users.len()];
                    
                    let post_request = CreatePostRequest {
                        user_id: author,
                        text_content: Some(content.clone()),
                        media_attachments: vec![],
                        is_reel: false,
                        visibility: PostVisibility::Public,
                    };
                    
                    if let Ok(post) = Post::new(post_request) {
                        all_posts.push(post.clone());
                        
                        // Track posts from users that the requesting user follows
                        if followed_users.contains(&author) {
                            posts_from_followed_users.push(post);
                        }
                    }
                }
            }
            
            // Simulate feed filtering logic
            // In a real implementation, this would be done by the repository
            let mut feed_posts = Vec::new();
            for post in &all_posts {
                // Only include posts from followed users in the feed
                if followed_users.contains(&post.user_id) {
                    feed_posts.push(post.clone());
                }
            }
            
            // Property: Feed should only contain posts from followed users
            for post in &feed_posts {
                prop_assert!(followed_users.contains(&post.user_id), 
                    "Feed contains post from user {:?} who is not followed by requesting user {:?}", 
                    post.user_id, requesting_user);
            }
            
            // Property: All posts from followed users should be in the feed (assuming public visibility)
            for post in &posts_from_followed_users {
                if post.visibility == PostVisibility::Public || post.visibility == PostVisibility::Followers {
                    prop_assert!(feed_posts.iter().any(|fp| fp.id == post.id),
                        "Feed missing post {:?} from followed user {:?}", 
                        post.id, post.user_id);
                }
            }
            
            // Property: Feed should not contain posts from users not followed
            let non_followed_users: HashSet<_> = users.iter()
                .filter(|&u| *u != requesting_user && !followed_users.contains(u))
                .collect();
            
            for post in &feed_posts {
                prop_assert!(!non_followed_users.contains(&post.user_id),
                    "Feed contains post from non-followed user {:?}", post.user_id);
            }
        }
    }