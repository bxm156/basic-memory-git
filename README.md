# Basic Memory Git Sync

A Docker-based solution for sharing organizational knowledge via markdown files with AI assistants through the Model Context Protocol (MCP).

## Overview

This project provides:
- **Automated git sync**: Periodically pulls markdown files from your GitHub repository
- **MCP server**: Exposes the content via basic-memory's semantic graph
- **Two deployment modes**:
  - Local: Mount directly to filesystem for individual use
  - Shared: Connect via HTTP SSE to litellm proxy for team access

## Architecture

```
┌──────────────────────────────────────────────────┐
│             Docker Compose Stack                 │
├──────────────────────────────────────────────────┤
│  ┌───────────┐      ┌────────────────┐           │
│  │ git-sync  │─────▶│ shared volume  │           │
│  └───────────┘      └───────┬────────┘           │
│                             │                    │
│                    ┌────────▼────────┐           │
│                    │  basic-memory   │           │
│                    │    (stdio)      │           │
│                    └────────┬────────┘           │
│                             │                    │
│                    ┌────────▼────────┐           │
│                    │  supergateway   │           │
│                    │  (SSE :8000)    │           │
│                    └────────┬────────┘           │
└─────────────────────────────┼────────────────────┘
                              │
                    ┌─────────┴─────────┐
                    ▼                   ▼
              Claude Code          litellm proxy
               (local)              (shared)
```

**Note**: basic-memory uses stdio transport. Supergateway wraps it to expose an SSE/HTTP endpoint for remote access.

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` with your repository details:

```bash
GIT_REPO_URL=https://github.com/your-org/knowledge-base.git
GIT_REF=main
DOCS_SUBPATH=docs
```

### 2. Start Services

```bash
docker-compose up -d
```

### 3. Connect Claude Code

Add to your Claude Code MCP configuration:

```json
{
  "mcpServers": {
    "org-knowledge": {
      "url": "http://localhost:8000/sse"
    }
  }
}
```

Or if connecting through litellm proxy, configure your proxy to forward to `http://basic-memory:8000`.

## Usage

### Reading Content

Once connected, your AI assistant can:
- Search across all markdown documents
- Retrieve specific documents by topic
- Follow links between related content
- Access the semantic graph of your knowledge base

### Contributing Content

Contributors add/update markdown files through the standard git workflow:

1. **Clone the knowledge base repository**
   ```bash
   git clone https://github.com/your-org/knowledge-base.git
   cd knowledge-base
   ```

2. **Create a branch for your changes**
   ```bash
   git checkout -b add/my-new-topic
   ```

3. **Add or edit markdown files**
   ```bash
   # Create new document
   echo "# My Topic\n\nContent here..." > docs/my-topic.md
   ```

4. **Commit and push**
   ```bash
   git add .
   git commit -m "Add documentation for my topic"
   git push -u origin add/my-new-topic
   ```

5. **Create a Pull Request** on GitHub for review

Once merged to main, git-sync will automatically pull the changes (within the configured sync period).

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `GIT_REPO_URL` | required | Repository URL to sync |
| `GIT_REF` | `main` | Git ref (branch/tag/hash) to sync |
| `DOCS_SUBPATH` | `.` | Subdirectory containing docs |
| `SYNC_PERIOD` | `60s` | Git sync interval |
| `MCP_PORT` | `8000` | SSE server port (supergateway) |

### Private Repositories

For private repos, uncomment the SSH configuration in `docker-compose.yml` and set:

```bash
SSH_KEY_PATH=/path/to/your/private/key
```

Ensure the key has read access to the repository.

### Encrypted Repositories (git-crypt)

For repositories encrypted with [git-crypt](https://github.com/AGWA/git-crypt):

1. **Export your symmetric key**:

   ```bash
   git-crypt export-key /path/to/git-crypt-key
   ```

2. **Secure the key file**:

   ```bash
   chmod 600 /path/to/git-crypt-key
   ```

3. **Configure in `.env`**:

   ```bash
   ENABLE_GIT_CRYPT=true
   GIT_CRYPT_KEY_PATH=/path/to/git-crypt-key
   ```

4. **Start services**:

   ```bash
   docker compose up -d --build
   ```

The `git-crypt-unlock` service will automatically decrypt files after git-sync clones the repository and before basic-memory indexes them.

**Security**: Never commit the key file to git. It's already excluded via `.dockerignore`. Store the key file securely and share it only with authorized team members.

### Sparse Checkout (Large Repos)

For large repositories, use sparse checkout to clone only specific paths:

1. Create a `sparse-checkout` file:
   ```
   docs/
   knowledge-base/
   ```

2. Uncomment the sparse checkout lines in `docker-compose.yml`:
   ```yaml
   environment:
     - GITSYNC_SPARSE_CHECKOUT_FILE=/etc/git-sync/sparse-checkout
   volumes:
     - ./sparse-checkout:/etc/git-sync/sparse-checkout:ro
   ```

This downloads only the specified paths instead of the entire repository.

## Local Development Mode

For local development without Docker, you can run basic-memory directly:

```bash
# Install basic-memory (requires Python 3.12+)
uv tool install basic-memory

# Create a project pointing to your docs directory
basic-memory project add my-docs /path/to/your/docs
basic-memory project default my-docs

# Sync your local docs
basic-memory sync

# Start the MCP server (stdio transport)
basic-memory mcp
```

To expose it over SSE for remote access, use supergateway:

```bash
npx -y supergateway --stdio "basic-memory mcp" --port 8000
```

For Claude Desktop (local), configure stdio directly in `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "basic-memory": {
      "command": "uvx",
      "args": ["basic-memory", "mcp"]
    }
  }
}
```

## Troubleshooting

### Check service status
```bash
docker-compose ps
docker-compose logs git-sync
docker-compose logs basic-memory
```

### Force re-sync
```bash
docker-compose restart basic-memory
```

### Verify content is accessible
```bash
curl http://localhost:8000/sse
```

## Roadmap

- [ ] **Milestone 2**: Multiple projects support (personal + org knowledge bases)
- [ ] Authentication for shared server deployments
- [ ] Webhook-triggered sync for real-time updates
- [ ] Web UI for browsing indexed content

## License

MIT
