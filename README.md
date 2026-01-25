# VIEW Social MVP

A comprehensive social media platform combining social networking, messaging, and payments in a unified mobile experience.

## Architecture

- **Backend**: Rust with Axum framework
- **Frontend**: Flutter mobile application
- **Database**: PostgreSQL with Redis caching
- **Architecture**: Clean Architecture with Domain-Driven Design

## Development Setup

### Prerequisites

- Rust (latest stable)
- Flutter SDK
- Docker and Docker Compose
- PostgreSQL (if running locally)
- Redis (if running locally)

### Quick Start with Docker

1. Clone the repository
2. Copy environment variables:
   ```bash
   cp .env.example .env
   ```
3. Start the development environment:
   ```bash
   docker-compose up -d
   ```

### Local Development

1. Start PostgreSQL and Redis:
   ```bash
   docker-compose up postgres redis -d
   ```

2. Run the Rust backend:
   ```bash
   cargo run
   ```

3. Run the Flutter app:
   ```bash
   cd view_social_app
   flutter pub get
   flutter run
   ```

## Project Structure

### Backend (Rust)
```
src/
├── domain/          # Business entities and rules
├── application/     # Use cases and services
├── infrastructure/  # Database, cache, external services
├── api/            # HTTP handlers and WebSocket
└── config.rs       # Configuration management
```

### Frontend (Flutter)
```
lib/
├── core/           # Shared utilities and theme
├── features/       # Feature-based modules
│   ├── auth/       # Authentication
│   ├── social/     # Social media features
│   ├── messaging/  # Real-time messaging
│   └── payments/   # Payment system
```

## Environment Variables

See `.env.example` for required environment variables.

## Development Status

This project is currently in development. See the implementation tasks in `.kiro/specs/view-social-mvp/tasks.md` for current progress.