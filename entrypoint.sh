#!/bin/bash
set -e

# Validate DOCS_SUBPATH to prevent path traversal
DOCS_SUBPATH="${DOCS_SUBPATH:-.}"

if [[ "$DOCS_SUBPATH" == *".."* ]]; then
    echo "ERROR: DOCS_SUBPATH cannot contain '..'" >&2
    exit 1
fi

if [[ "$DOCS_SUBPATH" == /* ]]; then
    echo "ERROR: DOCS_SUBPATH cannot be an absolute path" >&2
    exit 1
fi

DOCS_PATH="/data/git/current/${DOCS_SUBPATH}"

# Verify the path exists and is within expected directory
if [ ! -d "$DOCS_PATH" ]; then
    echo "ERROR: DOCS_PATH does not exist: $DOCS_PATH" >&2
    exit 1
fi

# Resolve to absolute path and verify it's under /data/git
RESOLVED_PATH=$(cd "$DOCS_PATH" && pwd)
if [[ "$RESOLVED_PATH" != /data/git/* ]]; then
    echo "ERROR: DOCS_PATH must be under /data/git" >&2
    exit 1
fi

echo "Setting up basic-memory project..."
basic-memory project add org-docs "$DOCS_PATH"
basic-memory project default org-docs

echo "Running initial sync..."
basic-memory sync

# Start MCP server based on transport mode
MCP_TRANSPORT="${MCP_TRANSPORT:-stdio}"

if [ "$MCP_TRANSPORT" = "sse" ]; then
    echo "Starting MCP server via supergateway (SSE mode) on port 8000..."
    exec supergateway --stdio "basic-memory mcp" --port 8000 --baseUrl "http://localhost:8000" "$@"
else
    echo "Starting MCP server (stdio mode)..."
    exec basic-memory mcp "$@"
fi
