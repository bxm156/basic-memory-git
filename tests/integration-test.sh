#!/bin/bash
set -e

echo "=== Basic Memory Git Integration Test ==="

# Cleanup function
cleanup() {
    echo "Cleaning up..."
    docker compose down -v 2>/dev/null || true
    rm -rf "$TEST_REPO_DIR" 2>/dev/null || true
    rm -f .env 2>/dev/null || true
}
trap cleanup EXIT

# Create a temporary git repository with test fixtures
TEST_REPO_DIR=$(mktemp -d)
echo "Creating test git repository at $TEST_REPO_DIR"

cp -r tests/fixtures/* "$TEST_REPO_DIR/"
cd "$TEST_REPO_DIR"
git init
git config user.email "test@test.com"
git config user.name "Test"
git add .
git commit -m "Initial test content"
cd - > /dev/null

# Create .env file for testing
cat > .env << EOF
GIT_REPO_URL=file://$TEST_REPO_DIR
GIT_REF=main
DOCS_SUBPATH=.
SYNC_PERIOD=10s
ONE_TIME_SYNC=false
MCP_PORT=8000
EOF

echo "Starting docker compose..."
docker compose up -d --build

# Wait for services to be healthy
echo "Waiting for services to be healthy..."
MAX_WAIT=120
WAITED=0

while [ $WAITED -lt $MAX_WAIT ]; do
    if docker compose ps | grep -q "healthy"; then
        BASIC_MEMORY_HEALTH=$(docker inspect --format='{{.State.Health.Status}}' basic-memory 2>/dev/null || echo "unknown")
        if [ "$BASIC_MEMORY_HEALTH" = "healthy" ]; then
            echo "Services are healthy!"
            break
        fi
    fi
    echo "Waiting... ($WAITED/$MAX_WAIT seconds)"
    sleep 5
    WAITED=$((WAITED + 5))
done

if [ $WAITED -ge $MAX_WAIT ]; then
    echo "ERROR: Services did not become healthy in time"
    echo "=== Docker Compose Logs ==="
    docker compose logs
    exit 1
fi

# Test 1: Check SSE endpoint responds
echo "Test 1: Checking SSE endpoint..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/sse --max-time 10 || echo "000")

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "000" ]; then
    # SSE connections may not return immediately, check if server is listening
    if curl -s http://localhost:8000/sse --max-time 2 > /dev/null 2>&1; then
        echo "✓ SSE endpoint is responding"
    else
        # Try alternative check - see if port is open
        if nc -z localhost 8000 2>/dev/null; then
            echo "✓ MCP server is listening on port 8000"
        else
            echo "✗ MCP server not responding"
            docker compose logs basic-memory
            exit 1
        fi
    fi
else
    echo "✗ SSE endpoint returned unexpected code: $HTTP_CODE"
    docker compose logs basic-memory
    exit 1
fi

# Test 2: Check container logs for successful sync
echo "Test 2: Checking for successful sync..."
if docker compose logs basic-memory 2>&1 | grep -q "sync\|Starting MCP server"; then
    echo "✓ Basic-memory initialized successfully"
else
    echo "✗ Could not confirm basic-memory initialization"
    docker compose logs basic-memory
    exit 1
fi

# Test 3: Verify git-sync pulled the content
echo "Test 3: Verifying git-sync pulled content..."
if docker compose exec -T git-sync test -f /data/git/current/test-doc.md; then
    echo "✓ Test document synced successfully"
else
    echo "✗ Test document not found in synced volume"
    docker compose logs git-sync
    exit 1
fi

echo ""
echo "=== All tests passed! ==="
