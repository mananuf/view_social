#!/bin/bash

# Script to commit all modified and untracked files individually with meaningful commit messages
# Following Conventional Commits specification

set -e

echo "🚀 Starting individual commits for all changes..."
echo ""

# Configuration & Documentation
# Skip .env as it's in .gitignore (use .env.example instead)

git add Cargo.toml
git commit -m "build(deps): update Rust dependencies

- Add rust_decimal feature for PostgreSQL
- Update sqlx with required features
- Add async-trait for repository pattern
- Configure workspace dependencies"

git add Dockerfile
git commit -m "build(docker): optimize Docker configuration

- Multi-stage build for smaller image size
- Add health check endpoint
- Configure production environment
- Optimize layer caching"

git add docker-compose.yml
git commit -m "build(docker): configure docker-compose services

- Add PostgreSQL database service
- Add Redis cache service
- Configure service networking
- Set up volume persistence"

# Database & Migrations
git add migrations/001_init.sql
git commit -m "feat(database): create comprehensive database schema

- Add users table with profile fields
- Create posts, comments, and engagement tables
- Add conversations and messages tables
- Create wallets and transactions tables
- Add indexes for query optimization
- Implement database triggers for counters"

# Documentation
git add REFACTORING_SUMMARY.md
git commit -m "docs(refactoring): document database refactoring process

- Explain modular architecture structure
- Document separation of concerns
- List all created files and their purposes
- Provide migration guide for developers"

git add MIGRATION_GUIDE.md
git commit -m "docs(migration): create developer migration guide

- Document import changes
- Provide code examples for new structure
- Explain benefits of modular architecture
- Add troubleshooting section"

git add COMMIT_STRATEGY.md
git commit -m "docs(git): document commit strategy and conventions

- Explain conventional commit format
- Document 25 commit phases
- Provide commit message best practices
- Add examples of good vs poor commits"

git add TASK_7.3_IMPLEMENTATION_SUMMARY.md
git commit -m "docs(api): document social media endpoints implementation

- Document POST /posts endpoint
- Document GET /posts/feed endpoint
- Document engagement endpoints (like, comment)
- Add request/response examples"

git add TASK_7.4_IMPLEMENTATION_SUMMARY.md
git commit -m "docs(api): document messaging endpoints implementation

- Document conversation management endpoints
- Document message sending and retrieval
- Add pagination and cursor support
- Provide API usage examples"

git add WEBSOCKET_IMPLEMENTATION.md
git commit -m "docs(websocket): document WebSocket implementation

- Explain connection manager architecture
- Document event types and broadcasting
- Add presence tracking documentation
- Provide usage examples"

git add generate_commits.sh
git commit -m "chore(git): add script for generating 100+ atomic commits

- Create 25-phase commit strategy
- Follow conventional commit standards
- Generate meaningful commit messages
- Enable atomic refactoring history"

# Domain Layer
git add src/domain/entities.rs
git commit -m "feat(domain): enhance domain entities

- Add validation to User entity
- Enhance Post entity with engagement tracking
- Add Message entity with payment support
- Implement Wallet and Transaction entities
- Add value object validations"

git add src/domain/password.rs
git commit -m "feat(domain): implement secure password handling

- Add bcrypt password hashing with cost factor 12
- Implement password verification
- Add password strength validation
- Follow security best practices"

git add src/domain/repositories.rs
git commit -m "feat(domain): define repository trait interfaces

- Create UserRepository trait
- Create PostRepository trait
- Create MessageRepository trait
- Create ConversationRepository trait
- Create WalletRepository trait
- Use async-trait for async methods"

# Infrastructure Layer - Database Refactoring
git add src/infrastructure/database.rs.backup
git commit -m "chore(database): backup original monolithic database file

- Preserve original 2633-line implementation
- Enable rollback if needed
- Maintain historical reference"

git add src/infrastructure/database/mod.rs
git commit -m "refactor(database): create modular database structure

- Export all models and repositories
- Create DatabasePool abstraction
- Organize imports and exports
- Enable clean architecture"

git add src/infrastructure/database/pool.rs
git commit -m "feat(database): implement DatabasePool abstraction

- Create connection pool wrapper
- Add pool configuration
- Implement connection management
- Enable dependency injection"

# Database Models
git add src/infrastructure/database/models/mod.rs
git commit -m "refactor(models): create models module structure

- Export all database models
- Organize model imports
- Enable clean separation"

git add src/infrastructure/database/models/user.rs
git commit -m "refactor(models): extract UserModel from monolithic file

- Create UserModel with FromRow derive
- Add 12 user profile fields
- Implement database row mapping
- Separate from domain entity"

git add src/infrastructure/database/models/post.rs
git commit -m "refactor(models): extract PostModel from monolithic file

- Create PostModel with FromRow derive
- Add content and engagement fields
- Support media attachments
- Enable post type differentiation"

git add src/infrastructure/database/models/conversation.rs
git commit -m "refactor(models): extract conversation models

- Create ConversationModel with FromRow
- Create ParticipantModel for group chats
- Add conversation metadata
- Support multi-user conversations"

git add src/infrastructure/database/models/message.rs
git commit -m "refactor(models): extract message models

- Create MessageModel with FromRow
- Create MessageReadModel for read receipts
- Support different message types
- Add payment data support"

git add src/infrastructure/database/models/wallet.rs
git commit -m "refactor(models): extract WalletModel

- Create WalletModel with FromRow
- Add balance and currency fields
- Support wallet status tracking
- Add PIN hash for security"

git add src/infrastructure/database/models/transaction.rs
git commit -m "refactor(models): extract TransactionModel

- Create TransactionModel with FromRow
- Track sender and receiver
- Add transaction status
- Support transaction metadata"

# Database Repositories
git add src/infrastructure/database/repositories/mod.rs
git commit -m "refactor(repositories): create repositories module structure

- Export all repository implementations
- Organize repository imports
- Enable modular repository access"

git add src/infrastructure/database/repositories/user.rs
git commit -m "refactor(repositories): extract PostgresUserRepository

- Implement UserRepository trait
- Add CRUD operations
- Implement follow/unfollow with transactions
- Add search and pagination
- Use to_domain helper for entity mapping"

git add src/infrastructure/database/repositories/post.rs
git commit -m "refactor(repositories): extract PostgresPostRepository

- Implement PostRepository trait
- Add feed generation with optimization
- Implement engagement tracking (like, comment)
- Add search and discovery queries
- Prevent N+1 query patterns"

git add src/infrastructure/database/repositories/conversation.rs
git commit -m "refactor(repositories): extract PostgresConversationRepository

- Implement ConversationRepository trait
- Add conversation creation with transactions
- Implement participant management
- Add direct conversation lookup
- Support group conversations"

git add src/infrastructure/database/repositories/message.rs
git commit -m "refactor(repositories): extract PostgresMessageRepository

- Implement MessageRepository trait
- Add message CRUD operations
- Implement cursor-based pagination
- Add read receipt tracking
- Support message search"

git add src/infrastructure/database/repositories/wallet.rs
git commit -m "refactor(repositories): extract PostgresWalletRepository

- Implement WalletRepository trait
- Add wallet CRUD operations
- Implement atomic transfers with locking
- Add transaction history
- Ensure balance consistency"

git rm src/infrastructure/database.rs
git commit -m "refactor(database): remove monolithic database file

- Complete migration to modular structure
- All functionality preserved in new modules
- Backup file retained for reference"

# Infrastructure - Cache
git add src/infrastructure/cache.rs
git commit -m "feat(cache): implement Redis caching layer

- Create RedisCache struct
- Implement cache-aside pattern
- Add session caching
- Support feed caching
- Add cache invalidation strategies"

# API Layer - Handlers
git add src/api/dto.rs
git commit -m "feat(api): create data transfer objects

- Define request/response DTOs
- Add serialization/deserialization
- Implement validation
- Support all API endpoints"

git add src/api/auth_handlers.rs
git commit -m "feat(api): implement authentication handlers

- Add POST /auth/register endpoint
- Add POST /auth/login endpoint
- Add POST /auth/refresh endpoint
- Add POST /auth/logout endpoint
- Implement JWT token generation"

git add src/api/user_handlers.rs
git commit -m "feat(api): implement user management handlers

- Add GET /users/me endpoint
- Add PUT /users/me endpoint
- Add GET /users/:id endpoint
- Add POST /users/:id/follow endpoint
- Add DELETE /users/:id/follow endpoint"

git add src/api/post_handlers.rs
git commit -m "feat(api): implement social media handlers

- Add GET /posts/feed endpoint
- Add POST /posts endpoint
- Add POST /posts/:id/like endpoint
- Add GET /posts/:id/comments endpoint
- Add POST /posts/:id/comments endpoint
- Implement pagination support"

git add src/api/message_handlers.rs
git commit -m "feat(api): implement messaging handlers

- Add GET /conversations endpoint
- Add POST /conversations endpoint
- Add GET /conversations/:id/messages endpoint
- Add POST /conversations/:id/messages endpoint
- Implement cursor-based pagination"

git add src/api/payment_handlers.rs
git commit -m "feat(api): implement payment handlers

- Add GET /wallet endpoint
- Add POST /wallet/pin endpoint
- Add POST /transfers endpoint
- Add GET /transactions endpoint
- Implement payment validation"

git add src/api/middleware.rs
git commit -m "feat(api): enhance authentication middleware

- Add JWT token validation
- Implement user extraction
- Add error handling
- Support protected routes"

git add src/api/rate_limit.rs
git commit -m "feat(api): implement rate limiting middleware

- Add Redis-backed rate limiter
- Set 100 requests per minute limit
- Implement exponential backoff
- Add rate limit headers"

git add src/api/websocket.rs
git commit -m "feat(api): implement WebSocket connection manager

- Create ConnectionManager for lifecycle management
- Add user presence tracking
- Implement event broadcasting
- Add automatic cleanup of stale connections
- Support multiple connections per user
- Add comprehensive unit tests"

git add src/api/mod.rs
git commit -m "refactor(api): update API module exports

- Export all handler modules
- Export middleware and rate limiting
- Export WebSocket functionality
- Organize API structure"

# Main Application
git add src/main.rs
git commit -m "feat(app): update main application with new architecture

- Initialize modular database repositories
- Configure WebSocket connection manager
- Set up all API routes
- Add middleware stack
- Configure CORS and rate limiting"

# Tests - Backend
git add tests/auth_tests.rs
git commit -m "test(auth): add authentication integration tests

- Test user registration
- Test login flow
- Test JWT token generation
- Test token refresh
- Test protected routes"

git add tests/password_tests.rs
git commit -m "test(auth): add password security tests

- Test bcrypt hashing
- Test password verification
- Test cost factor 12
- Verify security properties"

git add tests/post_endpoints_test.rs
git commit -m "test(api): add post endpoints integration tests

- Test post creation
- Test feed retrieval
- Test engagement (like, comment)
- Test pagination
- Verify response formats"

git add tests/message_endpoints_test.rs
git commit -m "test(api): add messaging endpoints integration tests

- Test conversation creation
- Test message sending
- Test message retrieval
- Test pagination
- Verify read receipts"

git add tests/websocket_connection_test.rs
git commit -m "test(websocket): add WebSocket connection tests

- Test connection lifecycle
- Test presence tracking
- Test event broadcasting
- Test multiple connections
- Verify cleanup behavior"

# Benchmarks
git add benches/benchmarks.rs
git commit -m "perf(bench): add performance benchmarks

- Benchmark database queries
- Benchmark feed generation
- Benchmark message delivery
- Measure WebSocket throughput"

# Flutter App - BLoC State Management
git add view_social_app/lib/features/auth/presentation/bloc/
git commit -m "feat(flutter): implement authentication BLoC

- Create AuthBloc for state management
- Add login/logout events
- Implement token refresh handling
- Add user session persistence"

git add view_social_app/lib/features/social/presentation/bloc/
git commit -m "feat(flutter): implement social media BLoCs

- Create FeedBloc with pagination
- Create PostCreationBloc
- Create EngagementBloc for likes/comments
- Add infinite scroll support"

git add view_social_app/lib/features/messaging/presentation/bloc/
git commit -m "feat(flutter): implement messaging BLoCs

- Create ConversationBloc
- Create ChatBloc with real-time updates
- Create TypingBloc for indicators
- Add WebSocket integration"

git add view_social_app/lib/features/payment/presentation/bloc/
git commit -m "feat(flutter): implement payment BLoCs

- Create WalletBloc with balance tracking
- Create TransferBloc with validation
- Create TransactionBloc for history
- Add PIN authentication"

# Flutter App - Theme
git add view_social_app/lib/core/theme/app_theme.dart
git commit -m "feat(flutter): enhance app theme

- Update color scheme with primary #a667d0
- Add light/dark mode support
- Define text styles
- Add responsive design utilities"

# Flutter App - iOS Configuration
git add view_social_app/ios/Podfile.lock
git commit -m "build(ios): update iOS dependencies

- Lock CocoaPods dependencies
- Update plugin versions
- Ensure compatibility"

git add view_social_app/ios/Runner.xcodeproj/project.pbxproj
git commit -m "build(ios): update Xcode project configuration

- Configure build settings
- Add required capabilities
- Update deployment target"

git add view_social_app/ios/Runner.xcworkspace/contents.xcworkspacedata
git commit -m "build(ios): update Xcode workspace

- Configure workspace structure
- Add plugin references
- Update workspace settings"

# iOS Build Artifacts (add to .gitignore instead)
echo "view_social_app/ios/build/" >> .gitignore
git add .gitignore
git commit -m "chore(git): ignore iOS build artifacts

- Add iOS build directory to gitignore
- Prevent committing generated files
- Keep repository clean"

# Spec Updates
git add .kiro/specs/view-social-mvp/tasks.md
git commit -m "docs(spec): update task completion status

- Mark completed tasks as done
- Update task 7 and 8 status
- Track implementation progress
- Document remaining work"

echo ""
echo "✅ All changes committed successfully!"
echo ""
echo "📊 Commit Summary:"
git log --oneline -30
echo ""
echo "🎉 Total commits created: $(git rev-list --count HEAD ^HEAD~30)"
