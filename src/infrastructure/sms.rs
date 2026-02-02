use reqwest::Client;
use serde::{Deserialize, Serialize};
use std::env;
use thiserror::Error;
use tracing::{error, info};

#[derive(Error, Debug)]
pub enum SmsError {
    #[error("SMS configuration error: {0}")]
    Config(String),
    #[error("HTTP request failed: {0}")]
    Http(#[from] reqwest::Error),
    #[error("SMS sending failed: {0}")]
    Send(String),
    #[error("Invalid phone number: {0}")]
    InvalidPhone(String),
}

#[derive(Debug, Clone)]
pub enum SmsProvider {
    Vonage,
    Termii,
    Twilio,
    SendChamp,
}

#[derive(Debug, Clone)]
pub struct SmsConfig {
    pub provider: SmsProvider,
    pub api_key: String,
    pub api_secret: Option<String>,
    pub sender_id: String,
    pub base_url: Option<String>,
}

impl SmsConfig {
    pub fn from_env() -> Result<Self, SmsError> {
        let provider_str = env::var("SMS_PROVIDER")
            .unwrap_or_else(|_| "termii".to_string())
            .to_lowercase();

        let provider = match provider_str.as_str() {
            "vonage" => SmsProvider::Vonage,
            "termii" => SmsProvider::Termii,
            "twilio" => SmsProvider::Twilio,
            "sendchamp" => SmsProvider::SendChamp,
            _ => return Err(SmsError::Config("Invalid SMS_PROVIDER".to_string())),
        };

        Ok(Self {
            provider,
            api_key: env::var("SMS_API_KEY")
                .map_err(|_| SmsError::Config("SMS_API_KEY not set".to_string()))?,
            api_secret: env::var("SMS_API_SECRET").ok(),
            sender_id: env::var("SMS_SENDER_ID").unwrap_or_else(|_| "VIEW".to_string()),
            base_url: env::var("SMS_BASE_URL").ok(),
        })
    }
}

#[derive(Debug, Serialize)]
struct TermiiSmsRequest {
    to: String,
    from: String,
    sms: String,
    #[serde(rename = "type")]
    message_type: String,
    api_key: String,
    channel: String,
}

#[derive(Debug, Deserialize)]
struct TermiiSmsResponse {
    message_id: Option<String>,
    message: String,
    balance: Option<f64>,
    user: Option<String>,
}

#[derive(Debug, Serialize)]
struct VonageSmsRequest {
    from: String,
    to: String,
    text: String,
}

#[derive(Debug, Deserialize)]
struct VonageSmsResponse {
    #[serde(rename = "message-count")]
    message_count: String,
    messages: Vec<VonageMessage>,
}

#[derive(Debug, Deserialize)]
struct VonageMessage {
    #[serde(rename = "message-id")]
    message_id: String,
    status: String,
}

pub struct SmsService {
    client: Client,
    config: SmsConfig,
}

impl SmsService {
    pub fn new() -> Result<Self, SmsError> {
        let config = SmsConfig::from_env()?;
        let client = Client::new();

        Ok(Self { client, config })
    }

    pub async fn send_sms(&self, to: &str, message: &str) -> Result<String, SmsError> {
        // Validate phone number format
        let phone = self.normalize_phone_number(to)?;

        match self.config.provider {
            SmsProvider::Termii => self.send_termii_sms(&phone, message).await,
            SmsProvider::Vonage => self.send_vonage_sms(&phone, message).await,
            SmsProvider::Twilio => self.send_twilio_sms(&phone, message).await,
            SmsProvider::SendChamp => self.send_sendchamp_sms(&phone, message).await,
        }
    }

    pub async fn send_verification_code(&self, to: &str, code: &str) -> Result<String, SmsError> {
        let message = format!(
            "Your VIEW Social verification code is: {}. This code expires in 10 minutes. Do not share this code with anyone.",
            code
        );

        self.send_sms(to, &message).await
    }

    async fn send_termii_sms(&self, to: &str, message: &str) -> Result<String, SmsError> {
        let url = "https://api.ng.termii.com/api/sms/send";

        let request = TermiiSmsRequest {
            to: to.to_string(),
            from: self.config.sender_id.clone(),
            sms: message.to_string(),
            message_type: "plain".to_string(),
            api_key: self.config.api_key.clone(),
            channel: "generic".to_string(),
        };

        info!("Sending SMS via Termii to: {}", to);

        let response = self.client.post(url).json(&request).send().await?;

        if response.status().is_success() {
            let result: TermiiSmsResponse = response.json().await?;
            info!("SMS sent successfully via Termii to: {}", to);
            Ok(result.message_id.unwrap_or_else(|| "success".to_string()))
        } else {
            let error_text = response.text().await?;
            error!("Failed to send SMS via Termii: {}", error_text);
            Err(SmsError::Send(error_text))
        }
    }

    async fn send_vonage_sms(&self, to: &str, message: &str) -> Result<String, SmsError> {
        let url = "https://rest.nexmo.com/sms/json";

        let mut params = vec![
            ("from", self.config.sender_id.as_str()),
            ("to", to),
            ("text", message),
            ("api_key", &self.config.api_key),
        ];

        if let Some(secret) = &self.config.api_secret {
            params.push(("api_secret", secret));
        }

        info!("Sending SMS via Vonage to: {}", to);

        let response = self.client.post(url).form(&params).send().await?;

        if response.status().is_success() {
            let result: VonageSmsResponse = response.json().await?;
            if let Some(message) = result.messages.first() {
                if message.status == "0" {
                    info!("SMS sent successfully via Vonage to: {}", to);
                    return Ok(message.message_id.clone());
                }
            }
            Err(SmsError::Send("Failed to send SMS".to_string()))
        } else {
            let error_text = response.text().await?;
            error!("Failed to send SMS via Vonage: {}", error_text);
            Err(SmsError::Send(error_text))
        }
    }

    async fn send_twilio_sms(&self, _to: &str, _message: &str) -> Result<String, SmsError> {
        // Twilio implementation would go here
        // For now, return a placeholder
        info!("Twilio SMS sending not implemented yet");
        Err(SmsError::Send("Twilio not implemented".to_string()))
    }

    async fn send_sendchamp_sms(&self, _to: &str, _message: &str) -> Result<String, SmsError> {
        // SendChamp implementation would go here
        // For now, return a placeholder
        info!("SendChamp SMS sending not implemented yet");
        Err(SmsError::Send("SendChamp not implemented".to_string()))
    }

    fn normalize_phone_number(&self, phone: &str) -> Result<String, SmsError> {
        // Remove all non-digit characters
        let digits: String = phone.chars().filter(|c| c.is_ascii_digit()).collect();

        // Basic validation
        if digits.len() < 10 || digits.len() > 15 {
            return Err(SmsError::InvalidPhone(
                "Phone number must be between 10 and 15 digits".to_string(),
            ));
        }

        // Add country code if missing (assuming Nigeria +234)
        let normalized = if digits.starts_with("234") {
            format!("+{}", digits)
        } else if digits.starts_with("0") {
            format!("+234{}", &digits[1..])
        } else if digits.len() == 10 {
            format!("+234{}", digits)
        } else {
            format!("+{}", digits)
        };

        Ok(normalized)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_phone_number_normalization() {
        let service = SmsService {
            client: Client::new(),
            config: SmsConfig {
                provider: SmsProvider::Termii,
                api_key: "test".to_string(),
                api_secret: None,
                sender_id: "TEST".to_string(),
                base_url: None,
            },
        };

        // Test Nigerian numbers
        assert_eq!(
            service.normalize_phone_number("08012345678").unwrap(),
            "+2348012345678"
        );
        assert_eq!(
            service.normalize_phone_number("2348012345678").unwrap(),
            "+2348012345678"
        );
        assert_eq!(
            service.normalize_phone_number("+2348012345678").unwrap(),
            "+2348012345678"
        );

        // Test invalid numbers
        assert!(service.normalize_phone_number("123").is_err());
        assert!(service
            .normalize_phone_number("12345678901234567890")
            .is_err());
    }
}
