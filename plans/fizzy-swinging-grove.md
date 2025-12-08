# Repository Reorganization Plan

## Overview

Reorganize the repository to improve structure and maintainability by moving Docker build contexts into dedicated subdirectories.

## Current Structure

```text
/workspaces/basic-memory-git/
├── Dockerfile                    # basic-memory build
├── entrypoint.sh                 # basic-memory entrypoint
├── Dockerfile.git-crypt          # git-crypt-unlock build
├── git-crypt-unlock.sh           # git-crypt-unlock entrypoint
├── docker-compose.yml
├── README.md
├── CLAUDE.md
├── AGENTS.md
├── .env.example
├── .dockerignore
├── mise.toml
├── tests/
└── reports/
```

## Target Structure

```text
/workspaces/basic-memory-git/
├── basic-memory/
│   ├── Dockerfile
│   └── entrypoint.sh
├── git-crypt/
│   ├── Dockerfile
│   └── unlock.sh
├── tests/
├── reports/
├── docker-compose.yml
├── README.md
├── CLAUDE.md
├── AGENTS.md
├── .env.example
├── .dockerignore
└── mise.toml
```

## Changes Required

### 1. Create Directory Structure

**Actions:**

- Create `basic-memory/` directory
- Create `git-crypt/` directory

### 2. Move and Rename Files

**basic-memory service:**

- Move `Dockerfile` → `basic-memory/Dockerfile`
- Move `entrypoint.sh` → `basic-memory/entrypoint.sh`

**git-crypt-unlock service:**

- Move `Dockerfile.git-crypt` → `git-crypt/Dockerfile`
- Move `git-crypt-unlock.sh` → `git-crypt/unlock.sh`

### 3. Update docker-compose.yml

**File:** `/workspaces/basic-memory-git/docker-compose.yml`

**Changes:**

1. Update git-crypt-unlock service build context:

   ```yaml
   # OLD:
   git-crypt-unlock:
     build:
       context: .
       dockerfile: Dockerfile.git-crypt

   # NEW:
   git-crypt-unlock:
     build: ./git-crypt
   ```

2. Update basic-memory service build context:

   ```yaml
   # OLD:
   basic-memory:
     build: .

   # NEW:
   basic-memory:
     build: ./basic-memory
   ```

### 4. Update git-crypt/Dockerfile

**File:** `/workspaces/basic-memory-git/git-crypt/Dockerfile`

**Changes:**

- Update COPY statement to reference new script name:

  ```dockerfile
  # OLD:
  COPY git-crypt-unlock.sh /git-crypt-unlock.sh

  # NEW:
  COPY unlock.sh /unlock.sh
  ```

- Update ENTRYPOINT:

  ```dockerfile
  # OLD:
  ENTRYPOINT ["/git-crypt-unlock.sh"]

  # NEW:
  ENTRYPOINT ["/unlock.sh"]
  ```

### 5. Update .dockerignore

**File:** `/workspaces/basic-memory-git/.dockerignore`

**Changes:**

- Keep as is (applies to all build contexts)
- Note: Both build contexts will use the same .dockerignore from root

### 6. Update CLAUDE.md

**File:** `/workspaces/basic-memory-git/CLAUDE.md`

**Changes to "Key Files" section:**

```markdown
## Key Files

- `basic-memory/Dockerfile` - Runs as non-root `appuser`, installs basic-memory with uv
- `basic-memory/entrypoint.sh` - Validates DOCS_SUBPATH, starts MCP server
- `git-crypt/Dockerfile` - Alpine-based image with git-crypt for encrypted repos
- `git-crypt/unlock.sh` - Unlock script with error handling for git-crypt repositories
- `docker-compose.yml` - git-sync (v4.5.0) + git-crypt-unlock + basic-memory with health checks
```

### 7. Update Documentation References

**Files to check for references:**

- README.md (minimal impact, mostly references docker-compose)
- AGENTS.md (may reference file paths)

## Implementation Steps

1. **Create directories:**

   ```bash
   mkdir -p basic-memory git-crypt
   ```

2. **Move basic-memory files:**

   ```bash
   mv Dockerfile basic-memory/
   mv entrypoint.sh basic-memory/
   ```

3. **Move and rename git-crypt files:**

   ```bash
   mv Dockerfile.git-crypt git-crypt/Dockerfile
   mv git-crypt-unlock.sh git-crypt/unlock.sh
   ```

4. **Update docker-compose.yml:**
   - Change basic-memory build context to `./basic-memory`
   - Change git-crypt-unlock build context to `./git-crypt`

5. **Update git-crypt/Dockerfile:**
   - Change COPY path from `git-crypt-unlock.sh` to `unlock.sh`
   - Change ENTRYPOINT from `/git-crypt-unlock.sh` to `/unlock.sh`

6. **Update CLAUDE.md:**
   - Update Key Files section with new paths

7. **Test:**
   - Run `docker compose build` to verify both images build successfully
   - Run integration tests to verify functionality

## Critical Files to Modify

1. **docker-compose.yml** - Update build contexts for both services
2. **git-crypt/Dockerfile** - Update COPY and ENTRYPOINT paths (after move)
3. **CLAUDE.md** - Update file path references in Key Files section

## Files to Move

- `Dockerfile` → `basic-memory/Dockerfile`
- `entrypoint.sh` → `basic-memory/entrypoint.sh`
- `Dockerfile.git-crypt` → `git-crypt/Dockerfile`
- `git-crypt-unlock.sh` → `git-crypt/unlock.sh`

## Verification Steps

After reorganization:

- [ ] Directory structure matches target layout
- [ ] `docker compose build` succeeds for both services
- [ ] `docker compose up -d` starts all services successfully
- [ ] Health checks pass for all services
- [ ] Integration tests pass
- [ ] No broken references in documentation

## Benefits

- **Clearer organization**: Related files grouped together
- **Easier navigation**: Build contexts are self-contained
- **Better maintainability**: Each service's files are isolated
- **Scalability**: Easy to add more services in the future
- **Professional structure**: Standard Docker multi-service project layout

## Backward Compatibility

- No impact on runtime behavior
- No changes to environment variables or configuration
- No changes to service names or endpoints
- Only affects build-time file locations