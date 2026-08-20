#!/bin/bash
set -e

NOTES_DIR="/home/opencode/opencode/notes"

# Refuse to start without a password. opencode's only auth is HTTP basic auth,
# and with none set the server is fully open — that means arbitrary code
# execution plus access to OPENCODE_API_KEY and GITHUB_TOKEN.
if [ -z "$OPENCODE_SERVER_PASSWORD" ]; then
    echo "ERROR: OPENCODE_SERVER_PASSWORD is not set - refusing to start." >&2
    echo "An unauthenticated opencode server grants shell access to anyone who can reach it." >&2
    exit 1
fi

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

# Start the opencode web UI. `web` serves the browser interface; `serve` is
# API-only. It tries to open a local browser on startup and fails harmlessly
# when headless, so it is safe in a container.
#
# --cors is deliberately omitted: it takes specific origins, and a wildcard
# gains nothing here since the UI is served from the same origin.
exec opencode web --hostname 0.0.0.0 --port ${PORT}
