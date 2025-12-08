# Roadmap

Progressive enhancement strategy for basic-memory-git, from read-only sync to full AI-assisted knowledge contribution workflow.

## Milestone 1: Read-Only Sync (MVP) ✅ CURRENT

**Goal:** Personal knowledge base access for AI assistants

**Deliverables:**

- ✅ Docker Compose setup with git-sync + basic-memory + supergateway
- ✅ Support for private repos (SSH keys)
- ✅ Support for encrypted repos (git-crypt)
- ✅ Support for sparse checkout (large repos)
- ✅ DOCS_SUBPATH for indexing subdirectories
- ✅ MCP SSE endpoint for Claude Code
- ✅ Integration tests verifying end-to-end functionality
- ✅ Security hardening (non-root, path validation, pinned versions)

**Success Criteria:**

- ✅ User runs `docker compose up -d` and connects Claude Code
- ✅ AI can search/read markdown files from shared repo
- ✅ Changes to git repo sync within configured period (default: 60s)
- ✅ All integration tests pass
- ✅ Works with public, private, and encrypted repositories

**Status:** ✅ **Complete**

**Architecture:**

```text
git-sync (pulls) → git-crypt-unlock (decrypts) → basic-memory (indexes)
                                                        ↓
                                        supergateway (serves MCP/SSE)
                                                        ↓
                                                 Claude Code connects
```

---

## Milestone 2: Read-Write Mode

**Goal:** AI can edit knowledge base through MCP tools

**Deliverables:**

- Switch Docker volume from read-only to read-write
- Replace git-sync with proper git working directory
- Verify basic-memory write operations work through MCP
- Unit tests for write operations
- Document write workflow in README

**Success Criteria:**

- AI can create/update/delete markdown files via MCP
- Changes persist in Docker volume
- User can manually commit/push from container (`docker exec`)
- Write operations don't break read functionality

**Technical Changes:**

- Remove `:ro` flag from docs-data volume in docker-compose.yml
- Replace git-sync service with init container that clones repo
- Maintain `.git` directory for commit operations
- Add git config (user.name, user.email) to container

**Estimated Complexity:** Medium - requires replacing git-sync approach

---

## Milestone 3: Auto-Commit

**Goal:** Automatic git commits for AI changes

**Deliverables:**

- File watcher monitoring knowledge base directory
- Auto-commit service with descriptive commit messages
- Git credentials configuration (SSH or token-based)
- User review workflow before push (manual or automated)
- Documentation for git authentication setup

**Success Criteria:**

- File changes automatically create git commits
- Commit messages include timestamp and change context
- User can review staged changes before pushing
- Commits include proper authorship

**Technical Approach:**

- Use `inotifywait` or similar for file watching
- Create commit-service container
- Generate commit messages from file diffs
- Support both manual `git push` and automated push modes

**Estimated Complexity:** Medium - new service, credential management

---

## Milestone 4: GitHub PR Integration

**Goal:** AI can create PRs directly from conversation

**Deliverables:**

- GitHub CLI integration in container
- Custom MCP tools: `create_pr`, `update_pr`, `list_prs`
- OAuth authentication workflow for GitHub
- PR template support
- Branch management (create feature branches automatically)

**Success Criteria:**

- AI can create PR with changes made during conversation
- PR includes description and context from conversation
- Follows organization PR guidelines (templates)
- User can approve/modify PR before submission

**Technical Approach:**

- Add `gh` CLI to container
- Create MCP wrapper tools for `gh pr` commands
- Implement OAuth flow for GitHub authentication
- Auto-create feature branches for changes

**Estimated Complexity:** High - requires authentication, MCP tool development

---

## Future Considerations

**M5: Multi-Project Support**

- Support multiple knowledge bases in single instance
- Project switching via MCP tools
- Separate git repos for personal vs team knowledge

**M6: Real-Time Sync**

- Webhook-triggered sync instead of periodic polling
- Near-instant updates when team members push changes
- Conflict resolution for concurrent edits

**M7: Web UI**

- Browse indexed content via web interface
- Visualize knowledge graph
- Markdown preview and editing
- Search interface

**M8: Advanced Search**

- Semantic search improvements
- Tag-based filtering
- Date range queries
- Author-based search

---

## Migration Path

Each milestone builds on the previous:

1. **M1 → M2:** Add write capability (backward compatible - read-only still works)
2. **M2 → M3:** Add auto-commit (optional feature - manual commit still works)
3. **M3 → M4:** Add PR integration (optional feature - manual PR still works)

Users can stay at any milestone that meets their needs. Later milestones are optional enhancements, not breaking changes.

---

## Contributing to Roadmap

Have ideas for additional features? Open an issue with:

- Use case description
- Proposed milestone (or new milestone)
- Technical approach (if known)
- Trade-offs and alternatives

See [AGENTS.md](./AGENTS.md) for developer guide and [TESTING.md](./TESTING.md) for testing strategy.