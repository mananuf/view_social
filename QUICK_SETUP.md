# Quick Setup Guide

This guide will help you get the VIEW Social Backend up and running quickly.

## Prerequisites

- Rust (latest stable version)
- PostgreSQL 16+
- Redis 7+
- Git

## 1. Clone and Setup

```bash
# Clone the repository
git clone <repository-url>
cd view-social-backend

# Copy environment configuration
cp .env.example .env
```

## 2. Configure Environment Variables

Edit the `.env` file and fill in the required values:

### Database (Required)
```env
DATABASE_URL=postgresql://username:password@localhost:5432/view_social
```

### Email Service (Required)
Choose one of these email providers:

#### Gmail
```env
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password
FROM_EMAIL=your-email@gmail.com
```

#### SendGrid
```env
SMTP_SERVER=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USERNAME=apikey
SMTP_PASSWORD=your-sendgrid-api-key
FROM_EMAIL=noreply@yourdomain.com
```

### SMS Service (Required)
Choose one of these SMS providers:

#### Termii (Recommended for Nigeria)
```env
SMS_PROVIDER=termii
SMS_API_KEY=your-termii-api-key
```

#### Twilio
```env
SMS_PROVIDER=twilio
SMS_API_KEY=your-twilio-account-sid
SMS_API_SECRET=your-twilio-auth-token
```

### Security (Required)
```env
JWT_SECRET=your-super-secure-secret-key-change-in-production
JWT_REFRESH_SECRET=your-super-secure-refresh-secret-key
BASE_URL=http://localhost:3000
```

## 3. Validate Configuration

Run the validation script to check your configuration:

```bash
./validate_env.sh
```

This will tell you if any required variables are missing.

## 4. Setup Database

### Option A: Using Docker (Recommended)
```bash
# Start PostgreSQL and Redis
docker-compose up -d postgres redis

# Wait for services to be ready
docker-compose logs postgres
```

### Option B: Local Installation
```bash
# Install PostgreSQL and Redis locally
# Then create the database
createdb view_social

# Run migrations
sqlx migrate run
```

## 5. Build and Run

```bash
# Build the application
cargo build --release

# Run the application
cargo run --release
```

Or for development:

```bash
# Run in development mode with hot reload
cargo watch -x run
```

## 6. Test the Setup

The application should start on `http://localhost:3000`. You can test it with:

```bash
# Health check
curl http://localhost:3000/api/v1/health

# Should return: {"status":"OK","version":"v1"}
```

## Quick Development Setup

For rapid development setup:

```bash
# 1. Copy and configure environment
cp .env.example .env
# Edit .env with your values

# 2. Start services with Docker
docker-compose up -d

# 3. Run the application
cargo run
```

## Troubleshooting

### Common Issues

1. **Database connection failed**
   - Check if PostgreSQL is running
   - Verify DATABASE_URL credentials
   - Ensure database exists

2. **Redis connection failed**
   - Check if Redis is running
   - Verify REDIS_URL

3. **Email sending failed**
   - Verify SMTP credentials
   - Check if less secure apps are enabled (Gmail)
   - Try using app passwords instead of regular passwords

4. **SMS sending failed**
   - Verify SMS provider credentials
   - Check API key permissions
   - Ensure sufficient balance (for paid providers)

### Getting Help

1. Run `./validate_env.sh` to check configuration
2. Check logs with `RUST_LOG=debug cargo run`
3. Refer to `ENVIRONMENT_VARIABLES.md` for detailed configuration
4. Check the application logs for specific error messages

## Production Deployment

For production deployment:

1. Use strong, unique secrets for JWT tokens
2. Use production database and Redis instances
3. Configure proper SMTP service (not Gmail)
4. Set up proper logging and monitoring
5. Use environment variables instead of .env file
6. Enable HTTPS and proper security headers

See `ENVIRONMENT_VARIABLES.md` for production configuration guidelines.