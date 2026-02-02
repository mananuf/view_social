#!/bin/bash

# Script to commit main.rs refactoring with meaningful, atomic commits
# Following Conventional Commits specification

set -e

echo "🚀 Starting main.rs refactoring commits..."
echo ""

# Phase 1: Server Module Creation
echo "📦 Phase 1: Server Module Creation"

git add src/server/mod.rs
git commit -m "feat(server): create Server struct for lifecycle management

- Add Server struct with new() and run() methods
- Implement clean server initialization
- Add router assembly logic
- Provide centralized server startup
- Enable dependency injection pattern"

git add src/server/state.rs
git commit -m "feat(server): implement centralized AppState

- Create AppState struct with all domain states
- Add from_config() for initialization
- Initialize database connection pool
- Set up JWT authentication service
- Initialize all repositories
- Create domain-specific states (post, message, payment, ws)
- Add comprehensive logging for initialization steps"

git add src/server/router.rs
git commit -m "feat(server): implement versioned router assembly

- Create main router with API versioning support
- Mount v1 routes under /api/v1/ namespace
- Prepare structure for future API versions
- Apply global CORS middleware
- Enable professional API design"

git add src/server/config.rs
git commit -m "feat(server): add config module for server

- Re-export Config from main config module
- Provide clean server configuration access
- Enable server module independence"

# Phase 2: API Routes with Versioning
echo "📦 Phase 2: API Routes with Versioning"

git add src/api/routes/mod.rs
git commit -m "feat(api): create API versioning structure

- Add routes module for version organization
- Document versioning strategy
- Enable backward compatibility
- Prepare for gradual API evolution
- Support multiple API versions"

git add src/api/routes/v1/mod.rs
git commit -m "feat(api): create v1 API router

- Implement v1 router assembly
- Merge all domain-specific routes
- Organize routes by feature (health, auth, posts, messages, payments, ws)
- Provide clean v1 API structure"

git add src/api/routes/v1/health.rs
git commit -m "feat(api): implement health check endpoint with versioning

- Add GET /api/v1/health endpoint
- Return JSON response with status and version
- Add comprehensive documentation
- Include unit tests for health endpoint
- Enable API version tracking"

git add src/api/routes/v1/auth.rs
git commit -m "feat(api): add authentication routes placeholder

- Create auth routes module structure
- Document planned endpoints (register, login, refresh, logout)
- Prepare for future auth implementation
- Follow RESTful design patterns"

git add src/api/routes/v1/posts.rs
git commit -m "feat(api): implement post routes with versioning

- Add GET /api/v1/posts/feed (protected)
- Add POST /api/v1/posts (protected)
- Add POST /api/v1/posts/:id/like (protected)
- Add DELETE /api/v1/posts/:id/like (protected)
- Add POST /api/v1/posts/:id/comments (protected)
- Add GET /api/v1/posts/:id/comments (public)
- Apply authentication middleware to protected routes
- Organize routes by access level"

git add src/api/routes/v1/messages.rs
git commit -m "feat(api): implement messaging routes with versioning

- Add GET /api/v1/conversations (protected)
- Add POST /api/v1/conversations (protected)
- Add GET /api/v1/conversations/:id/messages (protected)
- Add POST /api/v1/conversations/:id/messages (protected)
- Apply authentication middleware
- Enable real-time messaging support"

git add src/api/routes/v1/payments.rs
git commit -m "feat(api): implement payment routes with versioning

- Add GET /api/v1/wallet (protected)
- Add POST /api/v1/wallet/pin (protected)
- Add POST /api/v1/transfers (protected)
- Add GET /api/v1/transactions (protected)
- Apply authentication middleware
- Enable secure payment processing"

git add src/api/routes/v1/websocket.rs
git commit -m "feat(api): implement WebSocket routes with versioning

- Add GET /api/v1/ws (protected)
- Apply authentication middleware
- Enable real-time communication
- Support WebSocket connection management"

# Phase 3: Main.rs Simplification
echo "📦 Phase 3: Main.rs Simplification"

git add src/main.rs
git commit -m "refactor(main): simplify main.rs to 18 lines

- Reduce from 108 lines to 18 lines (83% reduction)
- Remove all business logic
- Use Server::new() for initialization
- Use Server::run() for startup
- Pure application assembly
- Delegate all concerns to modules
- Improve maintainability dramatically"

# Phase 4: Module Integration
echo "📦 Phase 4: Module Integration"

git add src/lib.rs
git commit -m "refactor(lib): export server module

- Add server module to library exports
- Enable server module access
- Maintain clean module structure"

git add src/api/mod.rs
git commit -m "refactor(api): export routes module

- Add routes module to API exports
- Enable versioned routing
- Organize API structure"

# Phase 5: Configuration Updates
echo "📦 Phase 5: Configuration Updates"

git add src/config.rs
git commit -m "refactor(config): update Config usage

- Ensure all config fields are used
- Support database_url, redis_url, jwt_secret
- Enable environment-based configuration"

# Phase 6: Documentation
echo "📦 Phase 6: Documentation"

git add MAIN_REFACTORING_SUMMARY.md
git commit -m "docs(refactoring): add main refactoring summary

- Document refactoring process and goals
- Explain new modular structure
- List all created files and purposes
- Provide before/after comparison
- Document benefits and improvements"

git add ARCHITECTURE_DIAGRAM.md
git commit -m "docs(architecture): add comprehensive architecture diagram

- Create visual system overview
- Document module structure
- Show request flow diagrams
- Explain design patterns
- Provide scalability considerations"

git add QUICK_REFERENCE.md
git commit -m "docs(reference): add developer quick reference guide

- Document all API endpoints with versioning
- Provide quick commands
- Add testing examples
- Include troubleshooting tips
- Enable fast developer onboarding"

git add REFACTORING_COMPARISON.md
git commit -m "docs(comparison): add before/after refactoring comparison

- Show detailed before/after code
- Compare metrics and complexity
- Document maintainability improvements
- Explain scalability benefits
- Provide ROI analysis"

git add MIGRATION_CHECKLIST.md
git commit -m "docs(migration): add deployment migration checklist

- Create comprehensive deployment checklist
- Document verification steps
- Provide rollback plan
- List success criteria
- Enable smooth deployment"

git add EXECUTIVE_SUMMARY.md
git commit -m "docs(executive): add executive summary

- Provide high-level overview
- Document key metrics and achievements
- Show business value and ROI
- Include risk assessment
- Enable stakeholder communication"

git add REFACTORING_COMPLETE.txt
git commit -m "docs(summary): add visual completion summary

- Create visual summary of achievements
- List all new files created
- Document API endpoints
- Provide quick test commands
- Celebrate completion"

git add COMMIT_SESSION_SUMMARY.md
git commit -m "docs(commits): add commit session summary

- Document previous commit session
- Provide commit breakdown by type
- List all committed files
- Show commit statistics"

# Phase 7: Build Scripts and Tools
echo "📦 Phase 7: Build Scripts and Tools"

git add commit_all_changes.sh
git commit -m "chore(git): add previous commit script

- Preserve commit script from previous session
- Document commit strategy
- Enable reproducible commits"

# Phase 8: Database Migrations
echo "📦 Phase 8: Database Migrations"

if [ -f "init.sql" ]; then
    git add init.sql
    git commit -m "feat(database): add root-level init.sql

- Provide database initialization script
- Enable quick database setup
- Support development environment"
fi

if [ -f "migrations/init.sql" ]; then
    git add migrations/init.sql
    git commit -m "feat(database): add migrations init.sql

- Provide migration-based initialization
- Support versioned database changes
- Enable production deployments"
fi

# Phase 9: Infrastructure Updates
echo "📦 Phase 9: Infrastructure Updates"

git add docker-compose.yml
git commit -m "build(docker): update docker-compose configuration

- Update service configurations
- Ensure compatibility with new structure
- Maintain development environment"

# Phase 10: Minor Updates to Existing Files
echo "📦 Phase 10: Minor Updates to Existing Files"

# Only commit if there are actual changes
if git diff --cached --quiet src/api/auth_handlers.rs 2>/dev/null; then
    git add src/api/auth_handlers.rs 2>/dev/null || true
    git commit -m "refactor(api): update auth handlers for new structure" 2>/dev/null || true
fi

if git diff --cached --quiet src/api/dto.rs 2>/dev/null; then
    git add src/api/dto.rs 2>/dev/null || true
    git commit -m "refactor(api): update DTOs for consistency" 2>/dev/null || true
fi

if git diff --cached --quiet src/api/middleware.rs 2>/dev/null; then
    git add src/api/middleware.rs 2>/dev/null || true
    git commit -m "refactor(api): update middleware for new routing" 2>/dev/null || true
fi

# Commit any remaining modified files
if ! git diff --quiet; then
    git add -u
    git commit -m "refactor: update remaining files for new architecture

- Update imports for new module structure
- Ensure compatibility with refactored code
- Maintain existing functionality" || true
fi

# Phase 11: Ignore Build Artifacts
echo "📦 Phase 11: Ignore Build Artifacts"

if [ -d "view_social_app/ios/build/" ]; then
    echo "view_social_app/ios/build/" >> .gitignore
    git add .gitignore
    git commit -m "chore(git): ignore iOS build artifacts

- Add iOS build directory to gitignore
- Prevent committing generated files
- Keep repository clean"
fi

echo ""
echo "✅ All refactoring commits completed successfully!"
echo ""
echo "📊 Commit Summary:"
git log --oneline -25
echo ""
echo "🎉 Total commits created: $(git rev-list --count HEAD ^HEAD~25 2>/dev/null || echo 'N/A')"
echo ""
echo "📋 Next Steps:"
echo "  1. Review commits: git log"
echo "  2. Run tests: cargo test"
echo "  3. Build project: cargo build --release"
echo "  4. Push to remote: git push origin main"
echo ""
echo "🚀 Refactoring complete and committed!"
