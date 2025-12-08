FROM python:3.12-slim

# Install uv from official image (pinned version)
COPY --from=ghcr.io/astral-sh/uv:0.5.11 /uv /uvx /bin/

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

# Install supergateway (pinned version)
RUN npm install -g supergateway@3.4.3

# Create non-root user
RUN useradd -m -u 1000 appuser

# Set up directories
RUN mkdir -p /data/git /data/memory \
    && chown -R appuser:appuser /data

# Copy entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Switch to non-root user before installing basic-memory
USER appuser

# Install basic-memory as appuser (installs to ~/.local/bin)
ENV UV_COMPILE_BYTECODE=1
RUN uv tool install basic-memory

# Add uv tools to PATH (appuser's directory only)
ENV PATH="/home/appuser/.local/bin:$PATH"

EXPOSE 8000

ENTRYPOINT ["/entrypoint.sh"]
