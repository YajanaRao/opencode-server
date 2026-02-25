# OpenCode Web Server - Simple and working
FROM node:20-slim

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install OpenCode and plugins
RUN npm install -g opencode-ai opencode-scheduler

# Create non-root user
RUN useradd -m -s /bin/bash opencode
USER opencode
WORKDIR /home/opencode

# Setup OpenCode configuration directory
RUN mkdir -p /home/opencode/.config/opencode

# Copy OpenCode configuration
COPY --chown=opencode:opencode opencode.json /home/opencode/.config/opencode/opencode.json

# Copy heartbeat service
COPY --chown=opencode:opencode heartbeat.js /home/opencode/heartbeat.js

# Copy entrypoint script
COPY --chown=opencode:opencode entrypoint.sh /home/opencode/entrypoint.sh
RUN chmod +x /home/opencode/entrypoint.sh

# Set PORT (Render will override this)
ENV PORT=10000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:${PORT}/global/health || exit 1

# Start with entrypoint (clones/updates Notes, then starts server)
ENTRYPOINT ["/home/opencode/entrypoint.sh"]
