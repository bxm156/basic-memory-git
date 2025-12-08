# AGENTS.md

Developer guide for AI agents working on this repository.

## Purpose

This document explains the system architecture, design decisions, and development workflow for AI developers maintaining basic-memory-git. Read this to understand **why** things are built the way they are, not just **what** exists.

## Quick Start

1. **First, read [CLAUDE.md](./CLAUDE.md)** for critical rules you must never violate
2. **Check [ROADMAP.md](./ROADMAP.md)** to understand current milestone (M1: Read-Only Sync)
3. **See [TESTING.md](./TESTING.md)** for testing strategy and requirements

## Architecture Overview

### System Components

**Three-service Docker Compose stack:**

1. **git-sync** (v4.5.0) - Periodically clones/pulls from git repository
   - Creates `/data/git/current` symlink to versioned directories
   - Runs every 60 seconds (configurable via `SYNC_PERIOD`)
   - Supports SSH keys for private repos
   - Supports sparse checkout for large repos

2. **git-crypt-unlock** - Conditionally decrypts encrypted repositories
   - Waits for git-sync to complete (health check dependency)
   - Skips if `ENABLE_GIT_CRYPT != true`
   - Validates symmetric key file before unlocking
   - Has 60s timeout with retry logic

3. **basic-memory** - Indexes markdown files and serves MCP
   - Runs as non-root `appuser` for security
   - Wraps stdio MCP server with supergateway (SSE/HTTP)
   - Validates DOCS_SUBPATH to prevent path traversal
   - Indexes only specified subdirectory (or entire repo)

### Data Flow

```text
1. git-sync pulls → /data/git/current (symlink to timestamped dir)
2. git-crypt-unlock decrypts (if enabled) → modifies files in place
3. basic-memory indexes → /data/git/current/DOCS_SUBPATH
4. supergateway wraps stdio → http://localhost:8000/sse
5. Claude Code connects → MCP tools available
```

### Current Milestone

**M1: Read-Only Sync** (Complete)

- Volume is mounted read-only (`:ro` flag in docker-compose.yml:61)
- AI can search/read through MCP, but not write
- Users contribute via normal git workflow (clone, edit, commit, PR)

See [ROADMAP.md](./ROADMAP.md) for M2 (Read-Write Mode), M3 (Auto-Commit), M4 (PR Integration).

## Key Design Principles

### 1. Simplicity

**Goal:** `docker compose up` should just work.

**Implementation:**

- Single `docker-compose.yml` with sensible defaults
- Health checks ensure correct startup order
- Clear error messages in scripts
- Minimal required configuration (just `GIT_REPO_URL`)

**Trade-off:** Limited flexibility in deployment model (runs locally, not as shared service)

### 2. Flexibility

**Goal:** Support various repository types and structures.

**Implementation:**

- Private repos: SSH key mounting
- Encrypted repos: git-crypt integration with feature flag
- Large repos: Sparse checkout support
- Subdirectories: DOCS_SUBPATH validation and indexing

**Trade-off:** More configuration options to document and test

### 3. Security

**Goal:** Prevent common vulnerabilities, especially path traversal.

**Implementation:**

- Non-root execution (appuser:1000)
- Path validation (reject `..` and absolute paths)
- Symlink resolution verification
- Pinned versions (uv, supergateway, git-sync)
- Read-only volume for basic-memory

**Trade-off:** More complex entrypoint.sh with multiple validation steps

## Development Workflow

### Making Changes

**Standard workflow:**

1. Read [CLAUDE.md](./CLAUDE.md) for critical rules
2. Make your changes (code, Dockerfile, scripts)
3. If Dockerfile or entrypoint.sh changed: `docker compose build`
4. Test: `./tests/integration-test.sh`
5. Verify: `docker compose logs` for errors
6. Commit with descriptive message

**Never:**

- Run basic-memory or supergateway directly on host (always use Docker)
- Remove path validation logic (security-critical)
- Disable health checks (breaks service orchestration)
- Use `GITSYNC_SSH_KNOWN_HOSTS=false` in production

### Critical Files

| File | Purpose | Change Impact |
|------|---------|---------------|
| `basic-memory/Dockerfile` | Installs basic-memory + supergateway | Requires rebuild |
| `basic-memory/entrypoint.sh` | Path validation + service startup | Requires rebuild + unit tests |
| `git-crypt/Dockerfile` | git-crypt unlock service | Requires rebuild |
| `git-crypt/unlock.sh` | Decryption logic | Requires rebuild + unit tests |
| `docker-compose.yml` | Service orchestration | Requires `docker compose up` restart |
| `.env` | Configuration | Requires service restart |

### Testing Requirements

See [TESTING.md](./TESTING.md) for comprehensive strategy.

**Summary:**

- **Unit tests** for bash scripts (entrypoint.sh, unlock.sh) - **Not yet implemented**
- **Integration tests** for full stack (`tests/integration-test.sh`) - ✅ Exists
- CI/CD runs tests on every PR (`.github/workflows/ci.yml`)

Before committing:

```bash
# Run integration tests
./tests/integration-test.sh

# TODO: When unit tests exist
# bats tests/unit/*.sh
```

## Common Development Tasks

### Adding Git Authentication Method

1. Add environment variable to `git-sync` service in docker-compose.yml
2. Document in README.md Configuration section
3. Test with a private repository
4. Update integration test if behavior changes

**Example:** SSH key support (already implemented)

- Mounts `${SSH_KEY_PATH}` to `/etc/git-secret/ssh:ro`
- Sets `GITSYNC_SSH_KEY_FILE` environment variable
- Documented in README.md lines 137-143

### Adding New Environment Variable

1. Add with default to docker-compose.yml (use `${VAR:-default}` syntax)
2. Add to `.env.example` with description
3. Document in README.md table (around line 126)
4. Add validation if security-critical (in entrypoint.sh)
5. Test with various values

### Modifying Path Validation

**⚠️ SECURITY-CRITICAL - Extra care required**

Path validation (entrypoint.sh:7-30) prevents path traversal attacks. If modifying:

1. Understand all 4 validation layers:
   - Check for `..` substring (line 7)
   - Check for absolute paths starting with `/` (line 12)
   - Verify directory exists (line 20)
   - Resolve symlinks and verify under `/data/git` (line 26)

2. Write unit tests FIRST (see TESTING.md for BATS examples)
3. Test with malicious inputs: `../../etc/passwd`, `/etc/passwd`, symlinks
4. Get review from security-conscious developer
5. Document why change is necessary in commit message

### Changing Service Dependencies

Docker Compose orchestration relies on `depends_on` with health checks:

- git-sync must be `service_healthy` before git-crypt-unlock starts
- git-crypt-unlock must be `service_completed_successfully` before basic-memory starts

**If adding a new service:**

1. Define health check (test command, intervals, retries)
2. Set appropriate `depends_on` conditions
3. Test startup order with `docker compose up`
4. Test failure scenarios (what if health check never passes?)

## Error Patterns and Debugging

### Common Issues

**Service won't start:**

```bash
# Check logs for all services
docker compose logs

# Check specific service
docker compose logs git-sync
docker compose logs basic-memory

# Check health status
docker compose ps
```

**Path validation errors:**

```text
ERROR: DOCS_PATH does not exist: /data/git/current/docs
```

- Verify DOCS_SUBPATH matches repository structure
- Check git-sync successfully cloned repo: `docker compose logs git-sync`
- Ensure path doesn't contain `..` or start with `/`

**git-crypt unlock failures:**

```text
ERROR: Failed to unlock git-crypt repository
```

- Verify `GIT_CRYPT_KEY_PATH` points to valid key file
- Check key file is not empty: `ls -lh /path/to/key`
- Ensure repository actually uses git-crypt (check for `.git-crypt` dir)
- Verify key matches repository: re-export key from original repo

### Health Check Failures

**git-sync health check:**

- Tests: `test -d /data/git/current`
- Common cause: Repository URL invalid or network issues
- Debug: `docker compose exec git-sync ls -la /data/git/`

**basic-memory health check:**

- Tests: `curl -f http://localhost:8000/sse`
- Common cause: entrypoint.sh path validation failed
- Debug: `docker compose logs basic-memory` for error messages

### git-crypt Issues

**Repository uses git-crypt but unlock is disabled:**

- Files appear encrypted in basic-memory index
- Enable: Set `ENABLE_GIT_CRYPT=true` in `.env`
- Mount key: Set `GIT_CRYPT_KEY_PATH=/path/to/key` in `.env`

**Unlock times out waiting for repository:**

- git-sync may be slow to clone large repos
- Increase `MAX_WAIT` in unlock.sh (default 60s)
- Or use sparse checkout to reduce clone size

## Architecture Decisions

### Why git-sync Instead of Regular Git Clone?

**Chosen:** git-sync creates versioned directories with symlinks

**Pros:**

- Atomic updates (symlink swap)
- No git working directory pollution
- Designed for this exact use case

**Cons:**

- Can't commit from container (read-only sync only)
- Requires switching to regular git clone for M2 (Read-Write Mode)

**Decision:** Perfect for M1 (read-only), will replace in M2.

### Why supergateway Wrapper?

**Chosen:** Wrap basic-memory's stdio MCP with HTTP/SSE via supergateway

**Pros:**

- basic-memory only supports stdio transport
- SSE enables remote/shared access (future: team deployments)
- Minimal overhead

**Cons:**

- Extra dependency (pinned to avoid breaking changes)
- One more layer to debug

**Alternative considered:** Direct stdio connection

- Would require local basic-memory installation
- Wouldn't support shared/remote deployments

**Decision:** supergateway enables both local and future shared use cases.

### Why Non-Root User?

**Chosen:** Run basic-memory as `appuser` (UID 1000)

**Pros:**

- Security best practice (principle of least privilege)
- Matches host UID 1000 for volume permissions
- Prevents accidental system modification

**Cons:**

- More complex Dockerfile (user creation, permissions)
- Harder to debug (can't `apt install` as appuser)

**Decision:** Security benefit outweighs complexity cost.

## What's Next

See [ROADMAP.md](./ROADMAP.md) for upcoming milestones:

- **M2: Read-Write Mode** - AI can edit files through MCP
- **M3: Auto-Commit** - Automatic git commits for changes
- **M4: PR Integration** - AI creates PRs directly

Current focus: Completing unit tests (see TESTING.md) and documentation improvements.

---

**Questions or suggestions?** Open an issue or see [README.md](./README.md) for contribution guidelines.