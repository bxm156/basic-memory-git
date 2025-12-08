FROM alpine:3.20

# Install git and git-crypt
# Note: Versions are managed by Alpine package manager
RUN apk add --no-cache \
    git \
    git-crypt \
    bash

# Create non-root user for security
RUN adduser -D -u 1000 gitcrypt

# Copy unlock script
COPY unlock.sh /unlock.sh
RUN chmod +x /unlock.sh

# Switch to non-root user
USER gitcrypt

ENTRYPOINT ["/unlock.sh"]
