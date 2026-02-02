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
    wget

# Download and install OpenCode using official install script
RUN curl -fsSL https://opencode.ai/install | bash --no-modify-path

# Add OpenCode to PATH
ENV PATH="/root/.opencode/bin:${PATH}"

# Create a non-root user for security
RUN addgroup -g 1001 opencode && \
    adduser -D -u 1001 -G opencode opencode

# Copy OpenCode installation to non-root user
RUN cp -r /root/.opencode /home/opencode/.opencode && \
    chown -R opencode:opencode /home/opencode/.opencode

# Switch to non-root user
USER opencode

# Update PATH for non-root user
ENV PATH="/home/opencode/.opencode/bin:${PATH}"

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
