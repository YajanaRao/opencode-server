# OpenCode Web Server Docker Configuration
# Use official OpenCode Docker image - maintained by OpenCode team
FROM ghcr.io/anomalyco/opencode:latest

# Switch to root to create startup script
USER root

# Create startup script that uses PORT env var
RUN echo '#!/bin/sh' > /start.sh && \
    echo 'exec opencode web --hostname 0.0.0.0 --port ${PORT:-10000} --cors "*"' >> /start.sh && \
    chmod +x /start.sh

# Switch back to opencode user (if the base image has one)
USER opencode

# Set default port (Render will override with PORT env var)
ENV PORT=10000

# Expose port
EXPOSE ${PORT}

# Start OpenCode web interface using startup script
# Note: OPENCODE_SERVER_PASSWORD and OPENCODE_SERVER_USERNAME 
# are set via Render environment variables (see render.yaml)
CMD ["/start.sh"]
