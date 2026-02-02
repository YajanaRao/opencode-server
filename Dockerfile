# OpenCode Web Server Docker Configuration
# Base image: Bun on Alpine Linux (faster than Node.js)
FROM oven/bun:1-alpine

# Set working directory
WORKDIR /app

# Install required dependencies for OpenCode
RUN apk add --no-cache \
    git \
    openssh-client \
    ca-certificates \
    wget

# Install OpenCode globally using bun
RUN bun install -g opencode-ai

# Create a non-root user for security
RUN addgroup -g 1001 opencode && \
    adduser -D -u 1001 -G opencode opencode

# Create directory for OpenCode data
RUN mkdir -p /home/opencode/.opencode && \
    chown -R opencode:opencode /home/opencode

# Switch to non-root user
USER opencode

# Set environment variable for port (Render uses PORT env var)
ENV PORT=10000

# Expose port 10000 (Render's default port)
EXPOSE 10000

# Health check - verify server is responding
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:${PORT}/global/health || exit 1

# Start OpenCode web interface
# - hostname 0.0.0.0: Allow external connections
# - port from PORT env var (defaults to 10000)
# - cors '*': Allow all origins (can be restricted later)
CMD ["sh", "-c", "opencode web --hostname 0.0.0.0 --port ${PORT} --cors '*'"]
