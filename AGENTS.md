# AGENTS.md

Guidelines for AI agents working on this repository.

## Key Points

- **Always use Docker Compose** - Don't run basic-memory or supergateway directly on host
- **Rebuild after changes** - Run `docker compose build` after modifying Dockerfile or entrypoint.sh
- **Run tests** - Execute `./tests/integration-test.sh` after any modifications
- **Keep packages pinned** - uv, supergateway, and git-sync versions are pinned for reproducibility
- **Maintain non-root user** - basic-memory runs as `appuser`, not root
- **Never disable path validation** - entrypoint.sh validates DOCS_SUBPATH to prevent path traversal
- **Use health checks** - Services use `depends_on: condition: service_healthy` for proper orchestration

## Subpath vs Sparse Checkout

Two approaches for limiting what gets indexed:

| Approach | How it works | Use when |
|----------|--------------|----------|
| **DOCS_SUBPATH** | Clones entire repo, indexes only subdirectory | Small/medium repos, simple setup |
| **Sparse checkout** | Clones only specified paths via `GITSYNC_SPARSE_CHECKOUT_FILE` | Large repos, bandwidth/storage concerns |

- Both can be used together - sparse checkout limits cloning, DOCS_SUBPATH limits indexing
- Sparse checkout requires mounting a file with git sparse-checkout format

## Useful Commands

- `docker compose up -d --build` - Build and start services
- `docker compose logs -f basic-memory` - View logs
- `docker compose down -v` - Stop and remove volumes
- `./tests/integration-test.sh` - Run integration tests
