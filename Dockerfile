# OpenCode Web Server Docker Configuration
# Base image: Alpine Linux (minimal and secure)
FROM alpine:3.19

# OpenCode version to install
ARG OPENCODE_VERSION=1.1.48

# Set working directory
WORKDIR /app

# Install required dependencies
RUN apk add --no-cache \
    bash \
    curl \
    git \
    openssh-client \
    ca-certificates \
    wget

# Download OpenCode binary directly from GitHub releases
# This avoids the install script's version fetch issues
RUN ARCH="$(uname -m)" && \
    if [ "$ARCH" = "x86_64" ]; then ARCH="x64"; fi && \
    if [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; fi && \
    curl -fsSL "https://github.com/anomalyco/opencode/releases/download/v${OPENCODE_VERSION}/opencode-linux-${ARCH}" -o /usr/local/bin/opencode && \
    chmod +x /usr/local/bin/opencode

# Verify installation
RUN opencode --version

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
