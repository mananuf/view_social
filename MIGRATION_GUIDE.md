# Database Refactoring Migration Guide

## For Developers

### What Changed?

The monolithic `src/infrastructure/database.rs` file has been refactored into a modular structure:

**Old Structure:**
```rust
// Everything in one file
src/infrastructure/database.rs (2633 lines)
```

**New Structure:**
```rust
src/infrastructure/database/
├── models/          # Database row structs
├── repositories/    # Repository implementations
├── pool.rs         # Connection pool
└── mod.rs          # Exports
```

### Import Changes

#### ✅ No Changes Required (Re-exported)

These imports continue to work as before:
```rust
use crate::infrastructure::database::{
    PostgresUserRepository,
    PostgresPostRepository,
    PostgresMessageRepository,
    PostgresConversationRepository,
    PostgresWalletRepository,
};
```

#### 📦 New Imports Available

You can now import models directly if needed:
```rust
use crate::infrastructure::database::models::{
    UserModel,
    PostModel,
    MessageModel,
    // etc.
};
```

### Code Examples

#### Creating Repositories (No Change)

```rust
// Before and After - Same code!
let user_repo = PostgresUserRepository::new(pool.clone());
let post_repo = PostgresPostRepository::new(pool.clone());
```

#### Using Repositories (No Change)

```rust
// Before and After - Same code!
let user = user_repo.find_by_id(user_id).await?;
let posts = post_repo.find_by_user_id(user_id, 10, 0).await?;
```

### Testing

#### Unit Tests

You can now test repositories independently:

```rust
#[cfg(test)]
mod tests {
    use super::*;
    
    #[tokio::test]
    async fn test_user_repository() {
        // Test just the user repository
        let pool = setup_test_pool().await;
        let repo = PostgresUserRepository::new(pool);
        // ... test code
    }
}
```

#### Integration Tests

Existing integration tests should work without modification.

### Benefits for Your Workflow

1. **Easier Navigation**
   - Find user-related code in `repositories/user.rs`
   - Find post-related code in `repositories/post.rs`
   - No more scrolling through 2600+ lines

2. **Better Git Diffs**
   - Changes to user repository don't affect post repository
   - Cleaner pull requests
   - Easier code reviews

3. **Faster Development**
   - Smaller files load faster in IDE
   - Better autocomplete performance
   - Clearer error messages

### Common Tasks

#### Adding a New Repository Method

**Before:** Edit massive `database.rs` file
**After:** Edit specific repository file

```rust
// Edit src/infrastructure/database/repositories/user.rs
impl PostgresUserRepository {
    pub async fn my_new_method(&self) -> Result<()> {
        // Implementation
    }
}
```

#### Adding a New Model Field

**Before:** Find struct in 2600+ line file
**After:** Edit specific model file

```rust
// Edit src/infrastructure/database/models/user.rs
#[derive(FromRow)]
pub struct UserModel {
    // Add new field here
    pub new_field: String,
}
```

### Troubleshooting

#### "Cannot find type `UserModel`"

**Solution:** Import from models module
```rust
use crate::infrastructure::database::models::UserModel;
```

#### "Cannot find `PostgresUserRepository`"

**Solution:** Import from database module (re-exported)
```rust
use crate::infrastructure::database::PostgresUserRepository;
```

### File Locations Quick Reference

| What You Need | Where To Find It |
|--------------|------------------|
| User repository | `repositories/user.rs` |
| Post repository | `repositories/post.rs` |
| Message repository | `repositories/message.rs` |
| Conversation repository | `repositories/conversation.rs` |
| Wallet repository | `repositories/wallet.rs` |
| User database model | `models/user.rs` |
| Post database model | `models/post.rs` |
| Connection pool | `pool.rs` |

### Questions?

If you encounter any issues:
1. Check that imports are correct
2. Verify the old `database.rs.backup` file exists
3. Run `cargo check` to see specific errors
4. The public API hasn't changed - same methods, same signatures

### Rollback (If Needed)

If you need to rollback temporarily:
```bash
# Backup new structure
mv src/infrastructure/database src/infrastructure/database_new

# Restore old file
mv src/infrastructure/database.rs.backup src/infrastructure/database.rs

# Rebuild
cargo build
```

Then restore when ready:
```bash
rm src/infrastructure/database.rs
mv src/infrastructure/database_new src/infrastructure/database
```

## Summary

✅ **No breaking changes**
✅ **All existing code works**
✅ **Better organization**
✅ **Easier maintenance**
✅ **Faster development**

The refactoring is complete and production-ready!
