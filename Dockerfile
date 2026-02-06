# OpenCode Web Server - Simple and working
FROM node:20-slim

# Build argument for GitHub token (to clone private Notes repo)
ARG GITHUB_TOKEN

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
USER opencode
WORKDIR /home/opencode

# Clone Notes repository into opencode folder
RUN if [ -n "$GITHUB_TOKEN" ]; then \
        mkdir -p opencode && \
        git clone https://${GITHUB_TOKEN}@github.com/YajanaRao/Notes.git opencode/notes && \
        echo "Notes repository cloned successfully"; \
    else \
        echo "GITHUB_TOKEN not provided, skipping Notes clone"; \
    fi

# Set PORT (Render will override this)
ENV PORT=10000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:${PORT}/global/health || exit 1

# Start headless server
CMD sh -c "opencode serve --hostname 0.0.0.0 --port ${PORT} --cors '*'"
