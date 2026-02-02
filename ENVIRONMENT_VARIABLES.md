# Environment Variables Configuration

This document describes all environment variables used by the VIEW Social Backend application.

## Quick Setup

1. Copy the example environment file:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` and fill in the required values for your environment.

3. Ensure all required variables are set before starting the application.

## Required Variables

### Database Configuration

| Variable | Description | Example | Required |
|----------|-------------|---------|----------|
| `DATABASE_URL` | PostgreSQL connection URL | `postgresql://user:pass@localhost:5432/db` | ✅ |

### Redis Configuration

| Variable | Description | Example | Required |
|----------|-------------|---------|----------|
| `REDIS_URL` | Redis connection URL | `redis://localhost:6379` | ✅ |

### JWT Configuration

| Variable | Description | Example | Required |
|----------|-------------|---------|----------|
| `JWT_SECRET` | Secret for signing access tokens | `your-secret-key-change-in-production` | ✅ |
| `JWT_REFRESH_SECRET` | Secret for signing refresh tokens | `your-refresh-secret` | ✅ |

### Server Configuration

| Variable | Description | Example | Required |
|----------|-------------|---------|----------|
| `PORT` | HTTP server port | `3000` | ✅ |
| `BASE_URL` | Application base URL | `http://localhost:3000` | ✅ |

### Email Configuration

| Variable | Description | Example | Required |
|----------|-------------|---------|----------|
| `SMTP_SERVER` | SMTP server hostname | `smtp.gmail.com` | ✅ |
| `SMTP_PORT` | SMTP server port | `587` | ✅ |
| `SMTP_USERNAME` | SMTP username | `your-email@gmail.com` | ✅ |
| `SMTP_PASSWORD` | SMTP password | `your-app-password` | ✅ |
| `FROM_EMAIL` | Sender email address | `noreply@viewsocial.com` | ✅ |
| `FROM_NAME` | Sender display name | `VIEW Social` | ❌ |

### SMS Configuration

| Variable | Description | Example | Required |
|----------|-------------|---------|----------|
| `SMS_PROVIDER` | SMS service provider | `termii` | ❌ |
| `SMS_API_KEY` | SMS provider API key | `your-api-key` | ✅ |
| `SMS_API_SECRET` | SMS provider API secret | `your-api-secret` | ❌ |
| `SMS_SENDER_ID` | SMS sender ID | `VIEW` | ❌ |
| `SMS_BASE_URL` | SMS provider base URL | Custom URL | ❌ |

## Optional Variables

### Development

| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `RUST_LOG` | Logging level | `info` | `debug` |
| `APP_ENV` | Application environment | `development` | `production` |

### Performance

| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `DATABASE_MAX_CONNECTIONS` | Max DB connections | `10` | `20` |
| `REDIS_TIMEOUT` | Redis timeout (seconds) | `5` | `10` |
| `JWT_EXPIRATION` | JWT expiration (seconds) | `3600` | `7200` |

### Rate Limiting

| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `RATE_LIMIT_REQUESTS_PER_MINUTE` | General rate limit | `100` | `200` |
| `AUTH_RATE_LIMIT_REQUESTS_PER_MINUTE` | Auth rate limit | `10` | `20` |

### File Upload

| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `MAX_FILE_SIZE` | Max file size (bytes) | `10485760` | `20971520` |
| `UPLOAD_PATH` | Upload directory | `./uploads` | `/var/uploads` |

## SMS Providers

The application supports multiple SMS providers:

### Termii (Default)
```env
SMS_PROVIDER=termii
SMS_API_KEY=your-termii-api-key
```

### Vonage
```env
SMS_PROVIDER=vonage
SMS_API_KEY=your-vonage-api-key
SMS_API_SECRET=your-vonage-api-secret
```

### Twilio
```env
SMS_PROVIDER=twilio
SMS_API_KEY=your-twilio-account-sid
SMS_API_SECRET=your-twilio-auth-token
```

### SendChamp
```env
SMS_PROVIDER=sendchamp
SMS_API_KEY=your-sendchamp-api-key
```

## Security Considerations

### Production Environment

1. **Change default secrets**: Always use strong, unique secrets in production
2. **Use environment-specific values**: Different secrets for dev/staging/prod
3. **Secure storage**: Store secrets in secure environment variable systems
4. **Regular rotation**: Rotate secrets periodically

### Example Production Values

```env
# Use strong, unique secrets
JWT_SECRET=super-secure-random-string-256-bits-long
JWT_REFRESH_SECRET=another-super-secure-random-string

# Use production database
DATABASE_URL=postgresql://prod_user:secure_pass@prod-db:5432/view_social_prod

# Use production Redis
REDIS_URL=redis://prod-redis:6379

# Use production email service
SMTP_SERVER=smtp.sendgrid.net
SMTP_USERNAME=apikey
SMTP_PASSWORD=your-sendgrid-api-key
```

## Validation

The application validates environment variables on startup. Missing required variables will cause the application to fail with descriptive error messages.

## Docker Compose

When using Docker Compose, environment variables are automatically loaded from `.env` file. The `docker-compose.yml` file includes all necessary environment variable mappings.

## Troubleshooting

### Common Issues

1. **Database connection fails**: Check `DATABASE_URL` format and credentials
2. **Redis connection fails**: Verify `REDIS_URL` and Redis server status
3. **Email sending fails**: Verify SMTP credentials and server settings
4. **SMS sending fails**: Check SMS provider credentials and API limits

### Debug Mode

Enable debug logging to troubleshoot configuration issues:

```env
RUST_LOG=debug
```

This will provide detailed logs about configuration loading and service initialization.