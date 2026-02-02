#!/bin/bash
set -e

# OpenCode from Supabase Restore Script
# Restores OpenCode data directories from Supabase Storage

echo "🔄 Starting OpenCode restore from Supabase..."

# Check required environment variables
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_SERVICE_KEY" ] || [ -z "$SUPABASE_BUCKET" ]; then
    echo "❌ Error: Missing required environment variables"
    echo "   Required: SUPABASE_URL, SUPABASE_SERVICE_KEY, SUPABASE_BUCKET"
    exit 1
fi

# Set paths
OPENCODE_DATA_DIR="$HOME/.local/share/opencode"
OPENCODE_STATE_DIR="$HOME/.local/state/opencode"
OPENCODE_CONFIG_DIR="$HOME/.config/opencode"
BACKUP_ARCHIVE="/tmp/opencode-backup.tar.gz"
RESTORE_DIR="/tmp/opencode-restore"

# Check if backup exists
echo "🔍 Checking for existing backup..."
CHECK_RESPONSE=$(curl -s -I \
    "${SUPABASE_URL}/storage/v1/object/${SUPABASE_BUCKET}/opencode-backup.tar.gz" \
    -H "Authorization: Bearer ${SUPABASE_SERVICE_KEY}")

if echo "$CHECK_RESPONSE" | grep -q "404"; then
    echo "ℹ️  No backup found. Starting fresh..."
    exit 0
fi

# Download backup from Supabase
echo "⬇️  Downloading backup from Supabase..."
HTTP_CODE=$(curl -s -w "%{http_code}" -o "$BACKUP_ARCHIVE" \
    "${SUPABASE_URL}/storage/v1/object/${SUPABASE_BUCKET}/opencode-backup.tar.gz" \
    -H "Authorization: Bearer ${SUPABASE_SERVICE_KEY}")

if [ "$HTTP_CODE" != "200" ]; then
    echo "❌ Download failed with HTTP code: $HTTP_CODE"
    exit 1
fi

# Check if downloaded file is valid
if [ ! -s "$BACKUP_ARCHIVE" ]; then
    echo "❌ Downloaded file is empty"
    exit 1
fi

ARCHIVE_SIZE=$(du -h "$BACKUP_ARCHIVE" | cut -f1)
echo "📊 Downloaded archive size: $ARCHIVE_SIZE"

# Create restore directory
mkdir -p "$RESTORE_DIR"

# Extract archive
echo "📦 Extracting archive..."
tar -xzf "$BACKUP_ARCHIVE" -C "$RESTORE_DIR"

# Restore data directories
echo "♻️  Restoring data..."

if [ -d "$RESTORE_DIR/share" ]; then
    mkdir -p "$OPENCODE_DATA_DIR"
    cp -r "$RESTORE_DIR/share"/* "$OPENCODE_DATA_DIR/" 2>/dev/null || true
    echo "✅ Restored data directory"
fi

if [ -d "$RESTORE_DIR/state" ]; then
    mkdir -p "$OPENCODE_STATE_DIR"
    cp -r "$RESTORE_DIR/state"/* "$OPENCODE_STATE_DIR/" 2>/dev/null || true
    echo "✅ Restored state directory"
fi

if [ -d "$RESTORE_DIR/config" ]; then
    mkdir -p "$OPENCODE_CONFIG_DIR"
    cp -r "$RESTORE_DIR/config"/* "$OPENCODE_CONFIG_DIR/" 2>/dev/null || true
    echo "✅ Restored config directory"
fi

# Set proper permissions
chmod -R u+rw "$OPENCODE_DATA_DIR" 2>/dev/null || true
chmod -R u+rw "$OPENCODE_STATE_DIR" 2>/dev/null || true
chmod -R u+rw "$OPENCODE_CONFIG_DIR" 2>/dev/null || true

# Cleanup
rm -rf "$RESTORE_DIR" "$BACKUP_ARCHIVE"

echo "🎉 Restore completed at $(date)"
echo "📂 Restored directories:"
echo "   - $OPENCODE_DATA_DIR"
echo "   - $OPENCODE_STATE_DIR"
echo "   - $OPENCODE_CONFIG_DIR"
