# CLAUDE.md

Critical rules for Claude Code working on this repository.

**First:** Read [AGENTS.md](./AGENTS.md) for comprehensive developer context before making changes.

## Critical Rules

- **Always use Docker Compose** - Never run basic-memory or supergateway directly on host
- **Never remove path validation** in entrypoint.sh - Prevents path traversal attacks
- **Always run tests** after changes: `./tests/integration-test.sh` (see [TESTING.md](./TESTING.md))
- **Rebuild after changes**: `docker compose build` for Dockerfile/entrypoint.sh modifications

## Security (Never Compromise)

- DOCS_SUBPATH validated against `..` and absolute paths (entrypoint.sh:7-14)
- basic-memory runs as `appuser`, not root (security principle of least privilege)
- All package versions pinned: uv, supergateway, git-sync (reproducibility)

## Don't

- Don't modify PATH to include `/root/.local/bin`
- Don't disable health checks or `depends_on: condition: service_healthy`
- Don't use `GITSYNC_SSH_KNOWN_HOSTS=false` in production
- Don't commit git-crypt key files to repository (already in .dockerignore)
- Don't disable git-crypt-unlock service for encrypted repos

## Quick Commands

```bash
# Build and start all services
docker compose up -d --build

# View logs from basic-memory service
docker compose logs -f basic-memory

# Stop and remove all containers and volumes
docker compose down -v

# Run integration tests
./tests/integration-test.sh
```

## Current Milestone

**M1: Read-Only Sync** (Complete) - See [ROADMAP.md](./ROADMAP.md) for future milestones.

Volume is read-only (docker-compose.yml:61 has `:ro` flag). For write support, see M2 in roadmap.