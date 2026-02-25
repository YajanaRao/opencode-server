#!/bin/bash
set -e

NOTES_DIR="/home/opencode/opencode/notes"

# Clone or update Notes repository on startup
if [ -n "$GITHUB_TOKEN" ]; then
    mkdir -p /home/opencode/opencode
    
    if [ -d "$NOTES_DIR/.git" ]; then
        echo "Updating Notes repository..."
        cd "$NOTES_DIR"
        git pull origin main || git pull origin master || echo "Pull failed, using existing version"
        cd /home/opencode
    else
        echo "Cloning Notes repository..."
        rm -rf "$NOTES_DIR"
        git clone "https://${GITHUB_TOKEN}@github.com/YajanaRao/Notes.git" "$NOTES_DIR"
    fi
    echo "Notes repository ready"
else
    echo "GITHUB_TOKEN not provided, skipping Notes sync"
fi

# Start heartbeat service in background
node /home/opencode/heartbeat.js &

# Start opencode server in foreground
exec opencode serve --hostname 0.0.0.0 --port ${PORT} --cors '*'
