# OpenCode Web Server Docker Configuration
# Base image: Node.js 20 on Alpine Linux (lightweight)
FROM node:20-alpine

# Set working directory
WORKDIR /app

# Install OpenCode globally
RUN npm install -g opencode-ai

# Create a non-root user for security
RUN addgroup -g 1001 opencode && \
    adduser -D -u 1001 -G opencode opencode

# Create directory for OpenCode data
RUN mkdir -p /home/opencode/.opencode && \
    chown -R opencode:opencode /home/opencode

# Switch to non-root user
USER opencode

# Expose port 4096 (standard OpenCode port)
EXPOSE 4096

# Health check - verify server is responding
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:4096/global/health || exit 1

# Start OpenCode web interface
# - hostname 0.0.0.0: Allow external connections
# - port 4096: Standard OpenCode port
# - cors '*': Allow all origins (can be restricted later)
CMD ["sh", "-c", "opencode web --hostname 0.0.0.0 --port 4096 --cors '*'"]
