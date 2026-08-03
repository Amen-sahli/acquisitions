#!/bin/sh
# Development startup script for Acquisition App with Neon Local.
# Run on the HOST (not inside the container): npm run dev:docker

set -e

echo "🚀 Starting Acquisition App in Development Mode"
echo "================================================"

# Check if .env.development exists
if [ ! -f .env.development ]; then
    echo "❌ Error: .env.development file not found!"
    echo "   Please copy .env.development.example to .env.development and update with your Neon credentials."
    exit 1
fi

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo "❌ Error: Docker is not running!"
    echo "   Please start Docker Desktop and try again."
    exit 1
fi

# Create .neon_local directory if it doesn't exist
mkdir -p .neon_local

# Add .neon_local to .gitignore if not already present
if ! grep -q ".neon_local/" .gitignore 2>/dev/null; then
    echo ".neon_local/" >> .gitignore
    echo "✅ Added .neon_local/ to .gitignore"
fi

echo ""
echo "📦 Starting Neon Local proxy (creates an ephemeral database branch)..."
docker compose -f docker-compose.dev.yml up -d neon-local

echo "📜 Applying latest schema with Drizzle against Neon Local..."
attempt=0
until DATABASE_URL=postgres://neon:npg@localhost:5432/neondb npm run db:migrate; do
    attempt=$((attempt + 1))
    if [ "$attempt" -ge 15 ]; then
        echo "❌ Database migrations failed after $attempt attempts" >&2
        exit 1
    fi
    echo "⏳ Database not ready, retrying in 2s... (attempt $attempt)"
    sleep 2
done

echo ""
echo "🚀 Starting the application with hot reload..."
docker compose -f docker-compose.dev.yml up --build

echo ""
echo "🎉 Development environment started!"
echo "   Application: http://localhost:3000"
echo "   Database: postgres://neon:npg@localhost:5432/neondb"
echo ""
echo "To stop the environment, press Ctrl+C or run: docker compose -f docker-compose.dev.yml down"
