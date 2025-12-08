# Testing Strategy

Comprehensive testing approach for basic-memory-git, covering unit and integration testing.

## Overview

Two complementary testing levels:

1. **Unit Tests** - Fast, isolated tests for bash script logic (entrypoint.sh, unlock.sh)
2. **Integration Tests** - Full Docker stack validation (end-to-end functionality)

## Unit Testing

### Framework: BATS (Bash Automated Testing System)

**Why BATS:**

- Lightweight, TAP-compatible test framework for bash
- Simple syntax similar to other testing frameworks
- Good isolation and mocking support
- Active community and maintenance

**Installation:**

```bash
# Clone BATS repository
git clone https://github.com/bats-core/bats-core.git
cd bats-core

# Install to /usr/local
sudo ./install.sh /usr/local

# Verify installation
bats --version
```

### Test Structure

```text
tests/
├── integration-test.sh          # Existing: E2E via Docker Compose
├── unit/
│   ├── test-entrypoint.sh       # Path validation tests
│   ├── test-unlock.sh           # git-crypt unlock logic tests
│   └── helpers.sh               # Shared test utilities
└── fixtures/
    ├── test-doc.md              # Existing: Sample markdown
    └── test-paths/              # Path validation test directories
```

### Running Unit Tests

```bash
# Run all unit tests
bats tests/unit/*.sh

# Run specific test file
bats tests/unit/test-entrypoint.sh

# Verbose output with timing
bats -t tests/unit/test-entrypoint.sh

# Pretty formatting
bats -p tests/unit/*.sh
```

### What to Unit Test

#### entrypoint.sh (Priority: HIGH)

**Path Validation Logic (Lines 7-30):**

| Test Case | Expected Result | Security Impact |
|-----------|----------------|-----------------|
| Path with `..` substring | Reject with error | Prevents path traversal |
| Absolute path (starts with `/`) | Reject with error | Prevents arbitrary file access |
| Valid relative path (`docs`, `kb/docs`) | Accept and process | Normal operation |
| Non-existent directory | Reject with error | Prevents indexing failures |
| Symlink to outside `/data/git` | Reject with error | Prevents symlink attacks |
| Symlink to inside `/data/git` | Accept if valid | Allow legitimate symlinks |

**Example Test:**

```bash
#!/usr/bin/env bats

@test "entrypoint rejects paths with .." {
  export DOCS_SUBPATH="../etc/passwd"
  run ./basic-memory/entrypoint.sh
  [ "$status" -eq 1 ]
  [[ "$output" =~ "cannot contain" ]]
}

@test "entrypoint rejects absolute paths" {
  export DOCS_SUBPATH="/etc/passwd"
  run ./basic-memory/entrypoint.sh
  [ "$status" -eq 1 ]
  [[ "$output" =~ "cannot be an absolute path" ]]
}

@test "entrypoint accepts valid relative paths" {
  # Setup: Create temp directory structure
  export DOCS_SUBPATH="docs"
  mkdir -p /tmp/test-git/current/docs

  # Mock the git repo location
  export GIT_ROOT="/tmp/test-git"

  run ./basic-memory/entrypoint.sh
  [ "$status" -eq 0 ]
}
```

**Service Startup:**

- Test basic-memory project setup
- Test supergateway launch (mock or check process)

#### unlock.sh (Priority: MEDIUM-HIGH)

**Feature Flag Logic (Lines 7-10):**

| Test Case | Expected Result |
|-----------|----------------|
| `ENABLE_GIT_CRYPT=false` | Exit 0 immediately (skip unlock) |
| `ENABLE_GIT_CRYPT=true` | Proceed to unlock logic |
| Variable unset/empty | Default to false behavior |

**Timeout/Retry Logic (Lines 15-26):**

| Test Case | Expected Result |
|-----------|----------------|
| Repository appears within 10s | Success, proceed to unlock |
| Repository never appears (60s) | Exit 1 with timeout error |
| Repository appears after 30s | Success after waiting |

**File Validation (Lines 42-53):**

| Test Case | Expected Result |
|-----------|----------------|
| Key file missing | Exit 1 with descriptive error |
| Key file empty (0 bytes) | Exit 1 with descriptive error |
| Key file valid | Proceed to git-crypt unlock |

**Example Test:**

```bash
#!/usr/bin/env bats

setup() {
  # Create temporary test environment
  export TEST_DIR=$(mktemp -d)
  export GIT_CRYPT_KEY_PATH="$TEST_DIR/key"
}

teardown() {
  # Clean up test environment
  rm -rf "$TEST_DIR"
}

@test "unlock skips when ENABLE_GIT_CRYPT is false" {
  export ENABLE_GIT_CRYPT=false
  run ./git-crypt/unlock.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Feature disabled" ]]
}

@test "unlock detects missing key file" {
  export ENABLE_GIT_CRYPT=true
  export GIT_CRYPT_KEY_PATH="/nonexistent/key"

  # Mock repository directory
  mkdir -p "$TEST_DIR/current/.git"
  mkdir -p "$TEST_DIR/current/.git-crypt"

  run ./git-crypt/unlock.sh
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Key file not found" ]]
}

@test "unlock detects empty key file" {
  export ENABLE_GIT_CRYPT=true
  touch "$GIT_CRYPT_KEY_PATH"  # Create empty file

  # Mock repository directory
  mkdir -p "$TEST_DIR/current/.git"
  mkdir -p "$TEST_DIR/current/.git-crypt"

  run ./git-crypt/unlock.sh
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Key file is empty" ]]
}
```

### Test Isolation Best Practices

**Use temporary directories:**

```bash
setup() {
  export TEST_DIR=$(mktemp -d)
}

teardown() {
  rm -rf "$TEST_DIR"
}
```

**Mock external commands:**

```bash
# Create mock for basic-memory command
basic-memory() {
  echo "mock: basic-memory $@"
}
export -f basic-memory
```

**Don't require actual services:**

- No Docker required for unit tests
- No git repositories needed
- No network access required
- Fast execution (< 1 second per test)

### Writing New Unit Tests

**Guidelines:**

1. One behavior per test case (use descriptive names)
2. Use `setup()` and `teardown()` for test isolation
3. Always check exit code: `[ "$status" -eq 0 ]`
4. Use regex for output validation: `[[ "$output" =~ "expected text" ]]`
5. Test both success and failure paths
6. Test edge cases (empty strings, special characters, etc.)

**File naming convention:**

- `test-*.sh` for test files
- Match source file name: `test-entrypoint.sh` tests `entrypoint.sh`

## Integration Testing

### Current Implementation

**File:** `tests/integration-test.sh`

**What it tests:**

1. **Docker Compose Build** - All services build successfully
2. **Service Orchestration** - Services start in correct order (health checks)
3. **git-sync** - Successfully clones test repository
4. **git-crypt-unlock** - Processes encrypted files (if enabled)
5. **basic-memory** - Indexes content from repository
6. **supergateway** - Serves MCP endpoint on port 8000
7. **End-to-end connectivity** - HTTP request to `/sse` succeeds

**Execution flow:**

```bash
# 1. Build images
docker compose build

# 2. Start services
docker compose up -d

# 3. Wait for health checks
while ! healthy; do sleep 2; done

# 4. Test MCP endpoint
curl -f http://localhost:8000/sse

# 5. Check logs for errors
docker compose logs | grep ERROR

# 6. Cleanup
docker compose down -v
```

### Running Integration Tests

```bash
# Run from repository root
./tests/integration-test.sh

# Expected output:
# ✓ Docker Compose build succeeded
# ✓ Services started successfully
# ✓ Health checks passed
# ✓ MCP endpoint responding
# ✓ No errors in logs
```

### Integration Test Duration

- **Target:** < 5 minutes (CI timeout)
- **Typical:** 2-3 minutes for full stack startup
- **Includes:** Build (60s) + Start (90s) + Health checks (30s)

### What Integration Tests Cover

| Component | Test Coverage |
|-----------|---------------|
| Service dependencies | `depends_on` with health checks work |
| git-sync | Clones repository to `/data/git/current` |
| git-crypt-unlock | Decrypts files when enabled |
| basic-memory | Indexes markdown files successfully |
| supergateway | Wraps stdio and serves HTTP/SSE |
| Volume mounts | Shared volumes work correctly |
| Network | Services can communicate |
| Health checks | All health checks eventually pass |

### Adding New Integration Tests

**When to add:**

- New service added to docker-compose.yml
- New health check added
- New volume mount configuration
- New environment variable affecting startup

**How to add:**

1. Open `tests/integration-test.sh`
2. Add new check after services are healthy
3. Use `docker compose exec` to run commands in containers
4. Check exit codes and output
5. Add descriptive error messages

**Example:**

```bash
# Test that basic-memory indexed test document
echo "Testing basic-memory index..."
docker compose exec basic-memory \
  basic-memory search "test" | grep -q "test-doc"

if [ $? -eq 0 ]; then
  echo "✓ basic-memory indexed test document"
else
  echo "✗ basic-memory failed to index test document"
  exit 1
fi
```

## CI/CD Integration

### GitHub Actions Workflow

**File:** `.github/workflows/ci.yml`

**Workflow steps:**

1. **Lint Phase** - Dockerfile linting with hadolint
2. **Unit Test Phase** - BATS tests (< 30s)
3. **Integration Test Phase** - Full Docker stack (5min timeout)

**Configuration:**

```yaml
name: CI

on: [push, pull_request]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Lint Dockerfiles
        run: |
          docker run --rm -i hadolint/hadolint < basic-memory/Dockerfile
          docker run --rm -i hadolint/hadolint < git-crypt/Dockerfile

  unit-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install BATS
        run: |
          git clone https://github.com/bats-core/bats-core.git
          cd bats-core
          sudo ./install.sh /usr/local
      - name: Run unit tests
        run: bats tests/unit/*.sh

  integration-tests:
    runs-on: ubuntu-latest
    timeout-minutes: 5
    steps:
      - uses: actions/checkout@v3
      - name: Run integration tests
        run: ./tests/integration-test.sh
```

### Test Requirements for PRs

**Before merging, all PRs must:**

- ✅ Pass Dockerfile linting (hadolint)
- ✅ Pass all unit tests (when implemented)
- ✅ Pass integration test
- ✅ Have no new security vulnerabilities
- ✅ Include tests for new features

## Testing Checklist

Before committing code changes:

- [ ] **Unit tests written** for new bash logic (if applicable)
- [ ] **Unit tests pass** - `bats tests/unit/*.sh` (when implemented)
- [ ] **Integration test passes** - `./tests/integration-test.sh`
- [ ] **Services start successfully** - `docker compose up -d && docker compose ps`
- [ ] **Health checks pass** - All services show "healthy" status
- [ ] **Logs are clean** - `docker compose logs | grep -i error` shows no unexpected errors
- [ ] **Manual testing done** - Connect Claude Code and verify MCP tools work
- [ ] **Documentation updated** - README, AGENTS, TESTING docs reflect changes

## Common Testing Scenarios

### Testing Path Validation Changes

```bash
# Create test cases in tests/unit/test-entrypoint.sh
@test "new path validation rule" {
  export DOCS_SUBPATH="<test-input>"
  run ./basic-memory/entrypoint.sh
  [ "$status" -eq <expected-code> ]
}

# Run unit test
bats tests/unit/test-entrypoint.sh

# Run integration test to ensure no regression
./tests/integration-test.sh
```

### Testing New Environment Variables

```bash
# Add to .env.example
NEW_VAR=default_value

# Update docker-compose.yml
environment:
  - NEW_VAR=${NEW_VAR:-default}

# Test with various values
NEW_VAR=value1 ./tests/integration-test.sh
NEW_VAR=value2 ./tests/integration-test.sh
```

### Testing git-crypt Changes

```bash
# Test with git-crypt disabled
ENABLE_GIT_CRYPT=false ./tests/integration-test.sh

# Test with git-crypt enabled (requires test key)
ENABLE_GIT_CRYPT=true \
GIT_CRYPT_KEY_PATH=/path/to/test-key \
./tests/integration-test.sh
```

## Debugging Test Failures

### Unit Test Failures

```bash
# Run with verbose output
bats -t tests/unit/test-entrypoint.sh

# Debug specific test
bats -f "test name pattern" tests/unit/test-entrypoint.sh

# Add debug output to test
@test "my test" {
  echo "DEBUG: variable=$VARIABLE" >&3  # Visible with -t flag
  run command
}
```

### Integration Test Failures

```bash
# Keep containers running after failure
# (comment out cleanup in integration-test.sh)

# Inspect service logs
docker compose logs git-sync
docker compose logs git-crypt-unlock
docker compose logs basic-memory

# Check service health
docker compose ps

# Exec into container for debugging
docker compose exec basic-memory /bin/bash

# Check volume contents
docker compose exec basic-memory ls -la /data/git/current
```

## Future Testing Enhancements

**Planned improvements:**

1. **Unit tests for entrypoint.sh** - Comprehensive path validation coverage
2. **Unit tests for unlock.sh** - All error paths and timeout scenarios
3. **Performance tests** - Measure sync time for various repo sizes
4. **Security tests** - Automated vulnerability scanning
5. **Load tests** - Multiple concurrent MCP connections

See [ROADMAP.md](./ROADMAP.md) for testing requirements in future milestones.

---

**Questions about testing?** See [AGENTS.md](./AGENTS.md) for development workflow or open an issue.