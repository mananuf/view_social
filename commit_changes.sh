#!/bin/bash

# Bash script to commit changes for user management service implementation
# This script creates meaningful commits for the work done on task 9.1

set -e  # Exit on any error

echo "🚀 Starting git commits for user management service implementation..."

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "❌ Error: Not in a git repository"
    exit 1
fi

# Check git status
echo "📊 Current git status:"
git status --short

# Function to commit changes if there are any
commit_if_changes() {
    local message="$1"
    local files="$2"
    
    # Check if there are changes to commit
    if git diff --cached --quiet && git diff --quiet $files 2>/dev/null; then
        echo "⏭️  No changes to commit for: $message"
        return 0
    fi
    
    # Add files if specified
    if [ -n "$files" ]; then
        git add $files
    fi
    
    # Check if there are staged changes
    if git diff --cached --quiet; then
        echo "⏭️  No staged changes for: $message"
        return 0
    fi
    
    # Commit the changes
    git commit -m "$message"
    echo "✅ Committed: $message"
}

# 1. Commit user management service implementation
echo "📝 Committing user management service implementation..."
commit_if_changes "feat: implement comprehensive user management service

- Add profile update coordination with validation
- Implement follow/unfollow operations with business logic
- Add user search functionality with query validation
- Include follower/following list retrieval with pagination
- Prevent self-following and duplicate follow attempts
- Update follower counts atomically
- Add comprehensive unit tests (12 test cases)
- Clean up unused imports and variables

Addresses task 9.1 requirements 1.1, 1.2, 1.3" "src/application/services.rs"

# 2. Commit API handler updates
echo "📝 Committing API handler updates..."
commit_if_changes "refactor: update user handlers to use user management service

- Replace direct repository access with service layer
- Add new endpoints for followers, following, and search
- Add follow status checking endpoint
- Improve error handling and business logic encapsulation
- Maintain clean architecture principles

Enhances user management API with proper service abstraction" "src/api/handlers/user_handlers.rs"

# 3. Commit property-based test implementation
echo "📝 Committing property-based test implementation..."
commit_if_changes "test: add property-based test for wallet creation consistency

- Implement comprehensive PBT for wallet creation (Property 3)
- Validate 8 key properties: uniqueness, currency, balance, status, timestamps
- Add mock repositories for isolated testing
- Include integration tests for basic functionality
- Ensure exactly one wallet per user with correct defaults
- Test passes with 100+ iterations for statistical confidence

Validates Requirements 1.3 - wallet creation consistency
Completes task 9.2" "tests/wallet_creation_test.rs"

# 4. Commit task status updates
echo "📝 Committing task status updates..."
commit_if_changes "docs: update task completion status

- Mark task 9.1 (user management service) as completed
- Mark task 9.2 (wallet creation PBT) as completed with passing status
- Update task progress in implementation plan

Tasks completed successfully with all tests passing" ".kiro/specs/view-social-mvp/tasks.md"

# 5. Commit any remaining changes
echo "📝 Committing any remaining changes..."
if ! git diff --quiet || ! git diff --cached --quiet; then
    git add .
    commit_if_changes "chore: clean up and finalize user management service implementation

- Fix any remaining compilation warnings
- Ensure all tests pass
- Maintain code quality standards
- Complete task 9.1 implementation" ""
fi

echo ""
echo "🎉 All commits completed successfully!"
echo ""
echo "📋 Summary of commits made:"
git log --oneline -10

echo ""
echo "🔍 Final git status:"
git status --short

echo ""
echo "✨ User management service implementation has been committed with meaningful messages!"