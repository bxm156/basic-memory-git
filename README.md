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
┌─────────────────────────────────────────────┐
│           Docker Compose Stack              │
├─────────────────────────────────────────────┤
│  ┌───────────┐      ┌────────────────┐      │
│  │ git-sync  │─────▶│ shared volume  │      │
│  └───────────┘      └───────┬────────┘      │
│                             │               │
│                    ┌────────▼────────┐      │
│                    │  basic-memory   │      │
│                    │  (SSE :8765)    │      │
│                    └────────┬────────┘      │
└─────────────────────────────┼───────────────┘
                              │
                    ┌─────────┴─────────┐
                    ▼                   ▼
              Claude Code          litellm proxy
               (local)              (shared)
```

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` with your repository details:

```bash
GIT_REPO_URL=https://github.com/your-org/knowledge-base.git
GIT_BRANCH=main
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
      "url": "http://localhost:8765/sse"
    }
  }
}
```

Or if connecting through litellm proxy, configure your proxy to forward to `http://basic-memory:8765`.

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
| `GIT_BRANCH` | `main` | Branch to track |
| `DOCS_SUBPATH` | `.` | Subdirectory containing docs |
| `SYNC_PERIOD` | `60s` | Git sync interval |
| `MEMORY_SYNC_PERIOD` | `300` | Re-index interval (seconds) |
| `MCP_PORT` | `8765` | SSE server port |

### Private Repositories

For private repos, uncomment the SSH configuration in `docker-compose.yml` and set:

```bash
SSH_KEY_PATH=/path/to/your/private/key
```

Ensure the key has read access to the repository.

## Local Development Mode

For local development without Docker, mount your local docs directory directly:

```bash
# Install basic-memory
pip install basic-memory

# Sync your local docs
basic-memory sync /path/to/your/docs

# Start the MCP server
basic-memory mcp --transport sse --port 8765
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
docker-compose restart memory-sync
```

### Verify content is accessible
```bash
curl http://localhost:8765/health
```

## Roadmap

- [ ] **Milestone 2**: Multiple projects support (personal + org knowledge bases)
- [ ] Authentication for shared server deployments
- [ ] Webhook-triggered sync for real-time updates
- [ ] Web UI for browsing indexed content

## License

MIT
