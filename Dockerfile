# OpenCode Web Server Docker Configuration
# Use official OpenCode Docker image - maintained by OpenCode team
FROM ghcr.io/anomalyco/opencode:latest

# Set environment variable for port (Render uses PORT env var)
ENV PORT=10000

# Expose port 10000 (Render's default port)
EXPOSE 10000

# Start OpenCode web interface
# - hostname 0.0.0.0: Allow external connections
# - port from PORT env var (defaults to 10000)
# - cors '*': Allow all origins (can be restricted later)
CMD ["sh", "-c", "opencode web --hostname 0.0.0.0 --port ${PORT} --cors '*'"]
