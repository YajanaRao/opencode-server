# OpenCode Web Server - Simple and working
FROM node:20-slim

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install OpenCode
RUN npm install -g opencode-ai

# Create non-root user
RUN useradd -m -s /bin/bash opencode

# Copy backup/restore scripts (as root)
COPY --chmod=755 scripts/backup-to-supabase.sh /scripts/backup-to-supabase.sh
COPY --chmod=755 scripts/restore-from-supabase.sh /scripts/restore-from-supabase.sh
COPY --chmod=755 scripts/entrypoint.sh /scripts/entrypoint.sh

# Switch to non-root user
USER opencode
WORKDIR /home/opencode

# Set PORT (Render will override this)
ENV PORT=10000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:${PORT}/global/health || exit 1

# Use entrypoint script that handles restore/backup
ENTRYPOINT ["/scripts/entrypoint.sh"]
