# VIEW Social MVP Development Commands

.PHONY: help setup dev-db backend frontend test clean

help: ## Show this help message
	@echo "VIEW Social MVP Development Commands"
	@echo "=================================="
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

setup: ## Set up the development environment
	@echo "🚀 Setting up VIEW Social development environment..."
	@echo "📦 Starting PostgreSQL and Redis containers..."
	docker-compose up -d postgres redis
	@echo "⏳ Waiting for services to be ready..."
	sleep 10
	@echo "✅ Development environment ready!"

dev-db: ## Start development databases (PostgreSQL and Redis)
	docker-compose up -d postgres redis

backend: ## Run the Rust backend server
	cargo run

frontend: ## Run the Flutter mobile app
	cd view_social_app && flutter run

test-backend: ## Run Rust backend tests
	cargo test

test-frontend: ## Run Flutter tests
	cd view_social_app && flutter test

check: ## Check code quality (Rust + Flutter)
	cargo check
	cd view_social_app && flutter analyze

clean: ## Clean up development environment
	docker-compose down
	cargo clean
	cd view_social_app && flutter clean

build-docker: ## Build the Docker image
	docker-compose build

logs: ## Show logs from all services
	docker-compose logs -f

status: ## Show status of all services
	docker-compose ps