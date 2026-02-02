#!/bin/bash

# Environment Variables Validation Script
# This script checks if all required environment variables are set

set -e

echo "🔍 Validating environment variables..."

# Load .env file if it exists
if [ -f .env ]; then
    source .env
    echo "✅ Loaded .env file"
else
    echo "❌ .env file not found. Please copy .env.example to .env and configure it."
    exit 1
fi

# Required variables
REQUIRED_VARS=(
    "DATABASE_URL"
    "REDIS_URL"
    "JWT_SECRET"
    "JWT_REFRESH_SECRET"
    "PORT"
    "BASE_URL"
    "SMTP_SERVER"
    "SMTP_PORT"
    "SMTP_USERNAME"
    "SMTP_PASSWORD"
    "FROM_EMAIL"
    "SMS_API_KEY"
)

# Optional variables with defaults
OPTIONAL_VARS=(
    "FROM_NAME"
    "SMS_PROVIDER"
    "SMS_API_SECRET"
    "SMS_SENDER_ID"
    "SMS_BASE_URL"
    "RUST_LOG"
)

echo ""
echo "📋 Checking required variables..."

missing_vars=()
for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        missing_vars+=("$var")
        echo "❌ $var is not set"
    else
        echo "✅ $var is set"
    fi
done

echo ""
echo "📋 Checking optional variables..."

for var in "${OPTIONAL_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        echo "⚠️  $var is not set (optional)"
    else
        echo "✅ $var is set"
    fi
done

echo ""

if [ ${#missing_vars[@]} -eq 0 ]; then
    echo "🎉 All required environment variables are set!"
    echo ""
    echo "📊 Configuration Summary:"
    echo "- Database: ${DATABASE_URL}"
    echo "- Redis: ${REDIS_URL}"
    echo "- Server Port: ${PORT}"
    echo "- Base URL: ${BASE_URL}"
    echo "- Email Provider: ${SMTP_SERVER}:${SMTP_PORT}"
    echo "- SMS Provider: ${SMS_PROVIDER:-termii}"
    echo "- Log Level: ${RUST_LOG:-info}"
    echo ""
    echo "✅ Ready to start the application!"
else
    echo "❌ Missing required environment variables:"
    for var in "${missing_vars[@]}"; do
        echo "   - $var"
    done
    echo ""
    echo "Please set these variables in your .env file before starting the application."
    echo "Refer to .env.example for example values."
    exit 1
fi