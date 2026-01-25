#!/bin/bash

# Development setup script for VIEW Social MVP

echo "🚀 Setting up VIEW Social development environment..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Start PostgreSQL and Redis
echo "📦 Starting PostgreSQL and Redis containers..."
docker-compose up -d postgres redis

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
sleep 10

# Check if services are running
if docker-compose ps | grep -q "postgres.*Up"; then
    echo "✅ PostgreSQL is running"
else
    echo "❌ PostgreSQL failed to start"
fi

if docker-compose ps | grep -q "redis.*Up"; then
    echo "✅ Redis is running"
else
    echo "❌ Redis failed to start"
fi

echo "🎉 Development environment setup complete!"
echo ""
echo "Next steps:"
echo "1. Run 'cargo run' to start the Rust backend"
echo "2. Run 'cd view_social_app && flutter run' to start the Flutter app"
echo "3. Visit http://localhost:3000/health to check backend health"