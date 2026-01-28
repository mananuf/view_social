# VIEW Social Backend Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         Client Applications                      │
│  (Flutter Mobile App, Web Clients, Third-party Integrations)    │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ HTTP/WebSocket
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                      API Gateway (Axum)                          │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                    CORS Middleware                          │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                  API Version Router                         │ │
│  │                                                              │ │
│  │  /api/v1/*  ──────────────────────────────────────────────┐ │ │
│  │  /api/v2/*  (future)                                       │ │ │
│  └────────────────────────────────────────────────────────────┘ │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                      API v1 Routes                               │
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   Health     │  │    Auth      │  │    Posts     │          │
│  │   /health    │  │   /auth/*    │  │   /posts/*   │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │  Messages    │  │  Payments    │  │  WebSocket   │          │
│  │/conversations│  │   /wallet    │  │     /ws      │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │            Authentication Middleware                        │ │
│  │         (JWT Token Validation & User Extraction)           │ │
│  └────────────────────────────────────────────────────────────┘ │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                      API Handlers Layer                          │
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │    Post      │  │   Message    │  │   Payment    │          │
│  │   Handlers   │  │   Handlers   │  │   Handlers   │          │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
│         │                  │                  │                  │
│         └──────────────────┼──────────────────┘                  │
│                            │                                     │
└────────────────────────────┼─────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Application State                           │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                     AppState                                │ │
│  │                                                              │ │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  │ │
│  │  │   Auth   │  │   Post   │  │ Message  │  │ Payment  │  │ │
│  │  │  State   │  │  State   │  │  State   │  │  State   │  │ │
│  │  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘  │ │
│  │       │             │              │             │         │ │
│  │  ┌────┴─────────────┴──────────────┴─────────────┴──────┐ │ │
│  │  │              WebSocket State                          │ │ │
│  │  │        (Connection Manager & Presence)                │ │ │
│  │  └───────────────────────────────────────────────────────┘ │ │
│  └────────────────────────────────────────────────────────────┘ │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Domain Layer (Business Logic)                 │
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   Entities   │  │    Value     │  │   Domain     │          │
│  │              │  │   Objects    │  │   Services   │          │
│  │ • User       │  │ • Email      │  │ • Auth       │          │
│  │ • Post       │  │ • Username   │  │ • Password   │          │
│  │ • Message    │  │ • PhoneNum   │  │              │          │
│  │ • Wallet     │  │ • Bio        │  │              │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │              Repository Trait Interfaces                    │ │
│  │  (UserRepo, PostRepo, MessageRepo, WalletRepo, etc.)      │ │
│  └────────────────────────────────────────────────────────────┘ │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Infrastructure Layer                           │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                Database Repositories                        │ │
│  │                                                              │ │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  │ │
│  │  │   User   │  │   Post   │  │ Message  │  │  Wallet  │  │ │
│  │  │   Repo   │  │   Repo   │  │   Repo   │  │   Repo   │  │ │
│  │  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘  │ │
│  │       │             │              │             │         │ │
│  │  ┌────┴─────────────┴──────────────┴─────────────┴──────┐ │ │
│  │  │              Database Models (FromRow)                │ │ │
│  │  │  (UserModel, PostModel, MessageModel, etc.)          │ │ │
│  │  └───────────────────────────────────────────────────────┘ │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                  Connection Pool                            │ │
│  │                   (PostgreSQL)                              │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                   Redis Cache                               │ │
│  │            (Sessions, Feed Cache, etc.)                     │ │
│  └────────────────────────────────────────────────────────────┘ │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Data Storage                                │
│                                                                   │
│  ┌──────────────────────┐         ┌──────────────────────┐      │
│  │     PostgreSQL       │         │        Redis         │      │
│  │                      │         │                      │      │
│  │  • users             │         │  • sessions          │      │
│  │  • posts             │         │  • feed_cache        │      │
│  │  • messages          │         │  • rate_limits       │      │
│  │  • wallets           │         │  • presence          │      │
│  │  • transactions      │         │                      │      │
│  └──────────────────────┘         └──────────────────────┘      │
└─────────────────────────────────────────────────────────────────┘
```

## Module Structure

```
src/
├── main.rs (17 lines)
│   └── Application Entry Point
│       ├── Initialize tracing
│       ├── Load configuration
│       ├── Create server
│       └── Run server
│
├── lib.rs
│   └── Module Exports
│
├── config.rs
│   └── Configuration Management
│       ├── Environment variables
│       ├── Database URL
│       ├── Redis URL
│       └── JWT secret
│
├── server/
│   ├── mod.rs
│   │   └── Server Struct
│   │       ├── new() - Initialize server
│   │       ├── run() - Start server
│   │       └── build_router() - Assemble routes
│   │
│   ├── state.rs
│   │   └── AppState
│   │       ├── auth_state
│   │       ├── post_state
│   │       ├── message_state
│   │       ├── payment_state
│   │       └── ws_state
│   │
│   ├── router.rs
│   │   └── Main Router Assembly
│   │       └── /api/v1/* → v1 routes
│   │
│   └── config.rs
│       └── Re-export Config
│
├── api/
│   ├── routes/
│   │   ├── mod.rs (Versioning structure)
│   │   └── v1/
│   │       ├── mod.rs (v1 router)
│   │       ├── health.rs
│   │       │   └── GET /health
│   │       ├── auth.rs (placeholder)
│   │       │   ├── POST /auth/register
│   │       │   ├── POST /auth/login
│   │       │   ├── POST /auth/refresh
│   │       │   └── POST /auth/logout
│   │       ├── posts.rs
│   │       │   ├── GET /posts/feed
│   │       │   ├── POST /posts
│   │       │   ├── POST /posts/:id/like
│   │       │   ├── DELETE /posts/:id/like
│   │       │   ├── POST /posts/:id/comments
│   │       │   └── GET /posts/:id/comments
│   │       ├── messages.rs
│   │       │   ├── GET /conversations
│   │       │   ├── POST /conversations
│   │       │   ├── GET /conversations/:id/messages
│   │       │   └── POST /conversations/:id/messages
│   │       ├── payments.rs
│   │       │   ├── GET /wallet
│   │       │   ├── POST /wallet/pin
│   │       │   ├── POST /transfers
│   │       │   └── GET /transactions
│   │       └── websocket.rs
│   │           └── GET /ws
│   │
│   ├── handlers/ (existing)
│   │   ├── auth_handlers.rs
│   │   ├── user_handlers.rs
│   │   ├── post_handlers.rs
│   │   ├── message_handlers.rs
│   │   └── payment_handlers.rs
│   │
│   ├── middleware/ (existing)
│   │   └── auth.rs (JWT validation)
│   │
│   ├── websocket.rs (existing)
│   │   └── Connection Manager
│   │
│   └── dto.rs (existing)
│       └── Data Transfer Objects
│
├── domain/ (existing)
│   ├── entities.rs
│   │   ├── User
│   │   ├── Post
│   │   ├── Message
│   │   └── Wallet
│   ├── value_objects.rs
│   │   ├── Email
│   │   ├── Username
│   │   ├── PhoneNumber
│   │   └── Bio
│   ├── repositories.rs
│   │   └── Trait Interfaces
│   ├── services.rs
│   │   └── Domain Services
│   └── auth.rs
│       └── JWT Service
│
├── infrastructure/ (existing)
│   ├── database/
│   │   ├── mod.rs
│   │   ├── pool.rs
│   │   ├── models/
│   │   │   ├── user.rs
│   │   │   ├── post.rs
│   │   │   ├── message.rs
│   │   │   └── wallet.rs
│   │   └── repositories/
│   │       ├── user.rs
│   │       ├── post.rs
│   │       ├── message.rs
│   │       └── wallet.rs
│   └── cache.rs
│       └── Redis Cache
│
└── application/ (existing)
    ├── commands.rs
    ├── queries.rs
    └── services.rs
```

## Request Flow

### Example: Create Post Request

```
1. Client Request
   POST /api/v1/posts
   Authorization: Bearer <jwt_token>
   Body: { "content": "Hello World!" }
   
   ↓

2. API Gateway (Axum)
   - CORS middleware
   - Route to /api/v1/*
   
   ↓

3. API Version Router
   - Match /api/v1/posts
   - Route to v1::posts module
   
   ↓

4. Posts Router
   - Match POST /posts
   - Apply auth middleware
   
   ↓

5. Auth Middleware
   - Extract JWT token
   - Validate token
   - Extract user_id
   - Inject AuthUser into request
   
   ↓

6. Post Handler
   - Extract PostState from app state
   - Extract request body
   - Call repository
   
   ↓

7. Post Repository
   - Map domain entity to database model
   - Execute SQL query
   - Map result back to domain entity
   
   ↓

8. Database (PostgreSQL)
   - Insert post record
   - Return created post
   
   ↓

9. Response
   - Map domain entity to DTO
   - Serialize to JSON
   - Return 201 Created
```

## WebSocket Flow

```
1. Client Connection
   WS /api/v1/ws
   Authorization: Bearer <jwt_token>
   
   ↓

2. WebSocket Router
   - Apply auth middleware
   - Upgrade to WebSocket
   
   ↓

3. Connection Manager
   - Register connection
   - Track user presence
   - Set up event channels
   
   ↓

4. Event Broadcasting
   - Message sent → Broadcast to conversation participants
   - Typing indicator → Send to other participants
   - Payment received → Notify recipient
   - User online/offline → Broadcast presence
   
   ↓

5. Connection Cleanup
   - On disconnect: Unregister connection
   - Update presence status
   - Clean up resources
```

## Key Design Patterns

### 1. Clean Architecture
- **Domain Layer**: Business logic and entities
- **Application Layer**: Use cases and services
- **Infrastructure Layer**: Database and external services
- **API Layer**: HTTP handlers and routes

### 2. Repository Pattern
- Abstract data access behind interfaces
- Domain layer defines traits
- Infrastructure layer implements traits
- Easy to swap implementations (e.g., PostgreSQL → MongoDB)

### 3. Dependency Injection
- AppState contains all dependencies
- Injected into routes via Axum state
- Easy to test with mock implementations

### 4. API Versioning
- Routes organized by version
- Easy to add new versions
- Backward compatibility maintained

### 5. Middleware Chain
- CORS → Version Router → Auth → Handler
- Composable and reusable
- Clear separation of concerns

## Scalability Considerations

### Horizontal Scaling
```
┌─────────────┐
│   Client    │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│Load Balancer│
└──────┬──────┘
       │
       ├──────────┬──────────┬──────────┐
       ▼          ▼          ▼          ▼
   ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐
   │ App  │  │ App  │  │ App  │  │ App  │
   │ v1   │  │ v2   │  │ v3   │  │ v4   │
   └───┬──┘  └───┬──┘  └───┬──┘  └───┬──┘
       │         │         │         │
       └─────────┴─────────┴─────────┘
                 │
                 ▼
         ┌──────────────┐
         │  PostgreSQL  │
         │   (Primary)  │
         └──────┬───────┘
                │
         ┌──────┴───────┐
         │              │
         ▼              ▼
    ┌────────┐    ┌────────┐
    │Replica │    │Replica │
    │   1    │    │   2    │
    └────────┘    └────────┘
```

### Caching Strategy
- Redis for session storage
- Feed caching for hot users
- Rate limit tracking
- Presence information

### Database Optimization
- Connection pooling (5 connections per instance)
- Prepared statements
- Indexed queries
- Materialized views for feeds

## Security Layers

```
┌─────────────────────────────────────┐
│         HTTPS/TLS Layer             │
│    (Transport Layer Security)       │
└─────────────────┬───────────────────┘
                  │
┌─────────────────▼───────────────────┐
│         CORS Middleware             │
│   (Cross-Origin Protection)         │
└─────────────────┬───────────────────┘
                  │
┌─────────────────▼───────────────────┐
│      Rate Limiting Middleware       │
│   (DDoS Protection, 100 req/min)    │
└─────────────────┬───────────────────┘
                  │
┌─────────────────▼───────────────────┐
│    Authentication Middleware        │
│   (JWT Token Validation)            │
└─────────────────┬───────────────────┘
                  │
┌─────────────────▼───────────────────┐
│      Authorization Checks           │
│   (Resource Access Control)         │
└─────────────────┬───────────────────┘
                  │
┌─────────────────▼───────────────────┐
│      Input Validation               │
│   (SQL Injection Prevention)        │
└─────────────────┬───────────────────┘
                  │
┌─────────────────▼───────────────────┐
│      Business Logic                 │
│   (Domain Rules Enforcement)        │
└─────────────────────────────────────┘
```

## Monitoring & Observability

```
┌─────────────────────────────────────┐
│         Application Logs            │
│      (tracing_subscriber)           │
└─────────────────┬───────────────────┘
                  │
┌─────────────────▼───────────────────┐
│         Metrics Collection          │
│   (Request count, latency, errors)  │
└─────────────────┬───────────────────┘
                  │
┌─────────────────▼───────────────────┐
│         Health Checks               │
│   GET /api/v1/health                │
└─────────────────┬───────────────────┘
                  │
┌─────────────────▼───────────────────┐
│      Error Tracking                 │
│   (Structured error responses)      │
└─────────────────────────────────────┘
```

## Summary

This architecture provides:
- ✅ **Modularity**: Clear separation of concerns
- ✅ **Scalability**: Easy to scale horizontally
- ✅ **Maintainability**: Each module has single responsibility
- ✅ **Testability**: Components can be tested independently
- ✅ **Versioning**: Professional API versioning support
- ✅ **Security**: Multiple security layers
- ✅ **Performance**: Optimized database access and caching
- ✅ **Observability**: Comprehensive logging and monitoring
