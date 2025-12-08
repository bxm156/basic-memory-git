# CLAUDE.md

Critical rules and information for Claude Code working on this repository.

## Critical Rules

- **Always use Docker Compose** - Never run basic-memory or supergateway directly on host
- **Never remove path validation** in entrypoint.sh - Prevents path traversal attacks
- **Always run tests** after changes: `./tests/integration-test.sh`
- **Rebuild after changes**: `docker compose build` for Dockerfile/entrypoint.sh changes

## Key Files

- `basic-memory/Dockerfile` - Runs as non-root `appuser`, installs basic-memory with uv
- `basic-memory/entrypoint.sh` - Validates DOCS_SUBPATH, starts MCP server
- `git-crypt/Dockerfile` - Alpine-based image with git-crypt for encrypted repos
- `git-crypt/unlock.sh` - Unlock script with error handling for git-crypt repositories
- `docker-compose.yml` - git-sync (v4.5.0) + git-crypt-unlock + basic-memory with health checks

## Security

- DOCS_SUBPATH validated against `..` and absolute paths
- basic-memory installs and runs as `appuser`, not root
- All package versions pinned (uv, supergateway, git-sync)

## Don't

- Don't modify PATH to include `/root/.local/bin`
- Don't disable health checks or `depends_on: condition: service_healthy`
- Don't use `GITSYNC_SSH_KNOWN_HOSTS=false` in production
- Don't commit git-crypt key files to repository
- Don't disable git-crypt-unlock service for encrypted repos

## Commands

- `docker compose up -d --build` - Build and start
- `docker compose logs -f basic-memory` - View logs
- `docker compose down -v` - Stop and clean up
- `./tests/integration-test.sh` - Run tests
