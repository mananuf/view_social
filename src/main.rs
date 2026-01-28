use anyhow::Result;
use view_social_backend::config::Config;
use view_social_backend::server::Server;

#[tokio::main]
async fn main() -> Result<()> {
    // Initialize tracing
    tracing_subscriber::fmt::init();

    // Load configuration from environment
    let config = Config::from_env()?;

    // Create and run server
    let server = Server::new(config).await?;
    server.run().await?;

    Ok(())
}
