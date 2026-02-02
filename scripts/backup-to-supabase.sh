#!/bin/bash
set -e

# OpenCode to Supabase Backup Script
# Backs up OpenCode data directories to Supabase Storage

echo "🔄 Starting OpenCode backup to Supabase..."

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
BACKUP_DIR="/tmp/opencode-backup-$(date +%Y%m%d-%H%M%S)"
BACKUP_ARCHIVE="/tmp/opencode-backup.tar.gz"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Copy data to backup directory
echo "📦 Collecting data..."
if [ -d "$OPENCODE_DATA_DIR" ]; then
    mkdir -p "$BACKUP_DIR/share"
    cp -r "$OPENCODE_DATA_DIR"/* "$BACKUP_DIR/share/" 2>/dev/null || true
fi

if [ -d "$OPENCODE_STATE_DIR" ]; then
    mkdir -p "$BACKUP_DIR/state"
    cp -r "$OPENCODE_STATE_DIR"/* "$BACKUP_DIR/state/" 2>/dev/null || true
fi

if [ -d "$OPENCODE_CONFIG_DIR" ]; then
    mkdir -p "$BACKUP_DIR/config"
    cp -r "$OPENCODE_CONFIG_DIR"/* "$BACKUP_DIR/config/" 2>/dev/null || true
fi

# Create archive
echo "🗜️  Creating archive..."
tar -czf "$BACKUP_ARCHIVE" -C "$BACKUP_DIR" .

# Get archive size
ARCHIVE_SIZE=$(du -h "$BACKUP_ARCHIVE" | cut -f1)
echo "📊 Archive size: $ARCHIVE_SIZE"

# Upload to Supabase Storage
echo "☁️  Uploading to Supabase..."
UPLOAD_RESPONSE=$(curl -s -X POST \
    "${SUPABASE_URL}/storage/v1/object/${SUPABASE_BUCKET}/opencode-backup.tar.gz" \
    -H "Authorization: Bearer ${SUPABASE_SERVICE_KEY}" \
    -H "Content-Type: application/gzip" \
    --data-binary "@${BACKUP_ARCHIVE}")

# Check for errors in response
if echo "$UPLOAD_RESPONSE" | grep -q "error"; then
    echo "❌ Upload failed: $UPLOAD_RESPONSE"
    
    # If file exists, try updating instead
    echo "🔄 Attempting to update existing file..."
    UPDATE_RESPONSE=$(curl -s -X PUT \
        "${SUPABASE_URL}/storage/v1/object/${SUPABASE_BUCKET}/opencode-backup.tar.gz" \
        -H "Authorization: Bearer ${SUPABASE_SERVICE_KEY}" \
        -H "Content-Type: application/gzip" \
        --data-binary "@${BACKUP_ARCHIVE}")
    
    if echo "$UPDATE_RESPONSE" | grep -q "error"; then
        echo "❌ Update also failed: $UPDATE_RESPONSE"
        exit 1
    else
        echo "✅ Backup updated successfully!"
    fi
else
    echo "✅ Backup uploaded successfully!"
fi

# Cleanup
rm -rf "$BACKUP_DIR" "$BACKUP_ARCHIVE"

echo "🎉 Backup completed at $(date)"
