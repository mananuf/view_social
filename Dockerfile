# Build stage - Use Rust 1.82 (stable and compatible)
FROM rust:1.91 AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy manifests
# COPY Cargo.toml ./

# Copy source code
COPY . .

# Build for release
RUN cargo build --release

# Runtime stage
FROM debian:bookworm-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the compiled binary
COPY --from=builder /app/target/release/view-social-backend /app/view-social-backend

# Expose port
EXPOSE 3000

# Run the binary
CMD ["./view-social-backend"]