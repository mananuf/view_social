use lettre::{
    message::{header::ContentType, MultiPart, SinglePart},
    transport::smtp::authentication::Credentials,
    Message, SmtpTransport, Transport,
};
use serde::{Deserialize, Serialize};
use std::env;
use thiserror::Error;
use tracing::{error, info};

#[derive(Error, Debug)]
pub enum EmailError {
    #[error("SMTP configuration error: {0}")]
    Config(String),
    #[error("Email sending failed: {0}")]
    Send(#[from] lettre::transport::smtp::Error),
    #[error("Message building failed: {0}")]
    Message(#[from] lettre::error::Error),
    #[error("Address parsing failed: {0}")]
    Address(#[from] lettre::address::AddressError),
    #[error("Template rendering failed: {0}")]
    Template(String),
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EmailTemplate {
    pub subject: String,
    pub html_body: String,
    pub text_body: Option<String>,
}

#[derive(Debug, Clone)]
pub struct EmailConfig {
    pub smtp_server: String,
    pub smtp_port: u16,
    pub username: String,
    pub password: String,
    pub from_email: String,
    pub from_name: String,
    pub base_url: String,
}

impl EmailConfig {
    pub fn from_env() -> Result<Self, EmailError> {
        Ok(Self {
            smtp_server: env::var("SMTP_SERVER")
                .map_err(|_| EmailError::Config("SMTP_SERVER not set".to_string()))?,
            smtp_port: env::var("SMTP_PORT")
                .unwrap_or_else(|_| "587".to_string())
                .parse()
                .map_err(|_| EmailError::Config("Invalid SMTP_PORT".to_string()))?,
            username: env::var("SMTP_USERNAME")
                .map_err(|_| EmailError::Config("SMTP_USERNAME not set".to_string()))?,
            password: env::var("SMTP_PASSWORD")
                .map_err(|_| EmailError::Config("SMTP_PASSWORD not set".to_string()))?,
            from_email: env::var("FROM_EMAIL")
                .map_err(|_| EmailError::Config("FROM_EMAIL not set".to_string()))?,
            from_name: env::var("FROM_NAME").unwrap_or_else(|_| "VIEW Social".to_string()),
            base_url: env::var("BASE_URL")
                .map_err(|_| EmailError::Config("BASE_URL not set".to_string()))?,
        })
    }
}

pub struct EmailService {
    mailer: SmtpTransport,
    config: EmailConfig,
}

impl EmailService {
    pub fn new() -> Result<Self, EmailError> {
        let config = EmailConfig::from_env()?;
        let creds = Credentials::new(config.username.clone(), config.password.clone());

        let mailer = SmtpTransport::starttls_relay(&config.smtp_server)
            .map_err(|e| EmailError::Config(format!("SMTP starttls relay error: {}", e)))?
            .port(config.smtp_port)
            .credentials(creds)
            .build();

        Ok(Self { mailer, config })
    }

    pub fn send_email(
        &self,
        to_email: &str,
        to_name: Option<&str>,
        template: EmailTemplate,
    ) -> Result<(), EmailError> {
        let to_address = match to_name {
            Some(name) => format!("{} <{}>", name, to_email),
            None => to_email.to_string(),
        };

        let from_address = format!("{} <{}>", self.config.from_name, self.config.from_email);

        let message = if let Some(text_body) = &template.text_body {
            Message::builder()
                .from(from_address.parse()?)
                .to(to_address.parse()?)
                .subject(&template.subject)
                .multipart(
                    MultiPart::alternative()
                        .singlepart(
                            SinglePart::builder()
                                .header(ContentType::TEXT_PLAIN)
                                .body(text_body.clone()),
                        )
                        .singlepart(
                            SinglePart::builder()
                                .header(ContentType::TEXT_HTML)
                                .body(template.html_body.clone()),
                        ),
                )?
        } else {
            Message::builder()
                .from(from_address.parse()?)
                .to(to_address.parse()?)
                .subject(&template.subject)
                .multipart(
                    MultiPart::alternative()
                        .singlepart(SinglePart::html(template.html_body.clone())),
                )?
        };

        info!("Sending email to: {}", to_email);
        match self.mailer.send(&message) {
            Ok(_) => {
                info!("Email sent successfully to: {}", to_email);
                Ok(())
            }
            Err(e) => {
                error!("Failed to send email to {}: {:?}", to_email, e);
                Err(EmailError::Send(e))
            }
        }
    }

    pub fn generate_verification_template(
        &self,
        user_name: &str,
        verification_code: &str,
    ) -> EmailTemplate {
        let verification_link = format!(
            "{}/auth/verify?code={}",
            self.config.base_url, verification_code
        );

        let html_body = format!(
            r#"<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Email Verification</title>
    <style>
        body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif; 
               line-height: 1.6; color: #333; margin: 0; padding: 0; background-color: #f5f5f5; }}
        .container {{ max-width: 600px; margin: 20px auto; background-color: #ffffff;
                     border-radius: 8px; overflow: hidden; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }}
        .header {{ background: linear-gradient(135deg, #a667d0 0%, #764ba2 100%);
                  color: white; padding: 30px 20px; text-align: center; }}
        .header h1 {{ margin: 0; font-size: 24px; font-weight: 600; }}
        .content {{ padding: 30px 20px; background-color: #ffffff; }}
        .content h2 {{ color: #333; margin-top: 0; font-size: 20px; }}
        .button {{ display: inline-block; background: linear-gradient(135deg, #a667d0 0%, #764ba2 100%);
                  color: white !important; padding: 14px 28px; text-decoration: none; border-radius: 6px; 
                  margin: 20px 0; font-weight: 600; font-size: 16px; }}
        .code {{ background-color: #f8f9fa; padding: 15px; border-radius: 6px; margin: 20px 0;
                font-family: monospace; font-size: 24px; text-align: center; letter-spacing: 2px;
                border: 2px dashed #a667d0; }}
        .footer {{ padding: 20px; text-align: center; color: #666; font-size: 14px; background-color: #f8f9fa; }}
        .warning {{ background-color: #fff3cd; border: 1px solid #ffeaa7; color: #856404;
                   padding: 12px; border-radius: 6px; margin: 20px 0; font-size: 14px; }}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Welcome to VIEW Social!</h1>
        </div>
        <div class="content">
            <h2>Hi {}!</h2>
            <p>Thank you for joining VIEW Social. To complete your registration and secure your account, 
               please verify your email address using the code below:</p>
            
            <div class="code">{}</div>
            
            <div style="text-align: center;">
                <a href="{}" class="button">Verify Email Address</a>
            </div>
            
            <div class="warning">
                <strong>⚠️ Security Notice:</strong> This verification code will expire in 10 minutes for your security.
            </div>
            
            <p>If you didn't create an account with VIEW Social, please ignore this email.</p>
        </div>
        <div class="footer">
            <p>&copy; 2026 VIEW Social. All rights reserved.</p>
            <p>This is an automated message, please do not reply to this email.</p>
        </div>
    </div>
</body>
</html>"#,
            user_name, verification_code, verification_link
        );

        let text_body = format!(
            r#"Welcome to VIEW Social!

Hi {}!

Thank you for joining VIEW Social. To complete your registration, please verify your email address using this code:

{}

Or visit: {}

⚠️ SECURITY NOTICE: This verification code will expire in 10 minutes for your security.

If you didn't create an account with VIEW Social, please ignore this email.

---
© 2026 VIEW Social. All rights reserved.
This is an automated message, please do not reply to this email."#,
            user_name, verification_code, verification_link
        );

        EmailTemplate {
            subject: "Verify your VIEW Social account".to_string(),
            html_body,
            text_body: Some(text_body),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_email_template_generation() {
        let config = EmailConfig {
            smtp_server: "sandbox.smtp.mailtrap.io".to_string(),
            smtp_port: 587,
            username: "test_user".to_string(),
            password: "test_pass".to_string(),
            from_email: "test@example.com".to_string(),
            from_name: "VIEW Social".to_string(),
            base_url: "https://viewsocial.com".to_string(),
        };

        let service = EmailService {
            mailer: SmtpTransport::starttls_relay(&config.smtp_server)
                .unwrap()
                .credentials(Credentials::new(
                    config.username.clone(),
                    config.password.clone(),
                ))
                .build(),
            config,
        };

        let template = service.generate_verification_template("John Doe", "123456");
        assert!(template.subject.contains("VIEW Social"));
        assert!(template.html_body.contains("John Doe"));
        assert!(template.html_body.contains("123456"));
        assert!(template.text_body.is_some());
    }
}
