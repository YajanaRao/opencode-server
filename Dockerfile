# OpenCode Web Server Docker Configuration
# Base image: Alpine Linux (minimal and secure)
FROM alpine:3.19

# Set working directory
WORKDIR /app

# Install required dependencies
RUN apk add --no-cache \
    bash \
    curl \
    git \
    openssh-client \
    ca-certificates \
    wget \
    jq

# Download OpenCode binary - fetch latest version from GitHub
# Automatically gets the latest release every time you build
RUN echo "Fetching latest OpenCode version..." && \
    LATEST_VERSION=$(curl -fsSL https://api.github.com/repos/anomalyco/opencode/releases/latest | jq -r '.tag_name') && \
    echo "Latest version: ${LATEST_VERSION}" && \
    ARCH="$(uname -m)" && \
    if [ "$ARCH" = "x86_64" ]; then ARCH="x64"; fi && \
    if [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; fi && \
    echo "Downloading OpenCode for linux-${ARCH}..." && \
    curl -fsSL "https://github.com/anomalyco/opencode/releases/download/${LATEST_VERSION}/opencode-linux-${ARCH}" -o /usr/local/bin/opencode && \
    chmod +x /usr/local/bin/opencode && \
    echo "OpenCode installed successfully"

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
