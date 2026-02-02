#!/bin/bash
set -e

echo "🚀 OpenCode Entrypoint Starting..."

# Restore data from Supabase on startup
if [ -n "$SUPABASE_URL" ] && [ -n "$SUPABASE_SERVICE_KEY" ] && [ -n "$SUPABASE_BUCKET" ]; then
    echo "📥 Supabase configured, attempting restore..."
    /scripts/restore-from-supabase.sh || echo "⚠️  Restore failed, continuing with fresh state..."
else
    echo "ℹ️  Supabase not configured, skipping restore..."
fi

# Setup graceful shutdown backup
if [ -n "$SUPABASE_URL" ] && [ -n "$SUPABASE_SERVICE_KEY" ] && [ -n "$SUPABASE_BUCKET" ]; then
    trap 'echo "🛑 Shutdown signal received, backing up..."; /scripts/backup-to-supabase.sh || echo "⚠️  Shutdown backup failed"; exit 0' SIGTERM SIGINT
    echo "✅ Shutdown backup handler configured"
fi

# Start OpenCode web server
echo "🌐 Starting OpenCode web server..."
exec opencode web --hostname 0.0.0.0 --port ${PORT:-10000} --cors '*'
