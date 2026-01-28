use sqlx::PgPool;

/// Database pool wrapper for connection management
#[derive(Clone)]
pub struct DatabasePool {
    pool: PgPool,
}

impl DatabasePool {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    pub fn get_pool(&self) -> &PgPool {
        &self.pool
    }
}

impl From<PgPool> for DatabasePool {
    fn from(pool: PgPool) -> Self {
        Self::new(pool)
    }
}
