#!/bin/bash
set -e

DOCS_PATH="/data/git/current/${DOCS_SUBPATH:-.}"

echo "Setting up basic-memory project..."
basic-memory project add org-docs "$DOCS_PATH"
basic-memory project default org-docs

echo "Running initial sync..."
basic-memory sync

echo "Starting MCP server via supergateway on port 8000..."
exec supergateway --stdio "basic-memory mcp" --port 8000 --baseUrl "http://localhost:8000"
