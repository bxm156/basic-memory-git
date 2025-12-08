#!/bin/bash
set -e

echo "git-crypt-unlock: Starting..."

# Check if git-crypt is enabled
if [ "$ENABLE_GIT_CRYPT" != "true" ]; then
    echo "git-crypt-unlock: Feature disabled (ENABLE_GIT_CRYPT != true), skipping unlock"
    exit 0
fi

echo "git-crypt-unlock: Feature enabled, proceeding with unlock"

# Wait for repository to exist (git-sync must complete first)
MAX_WAIT=60
WAITED=0
while [ ! -d "/data/git/current/.git" ]; do
    if [ $WAITED -ge $MAX_WAIT ]; then
        echo "git-crypt-unlock: ERROR - Repository not found at /data/git/current after ${MAX_WAIT}s"
        echo "git-crypt-unlock: Ensure git-sync service is healthy and has cloned the repository"
        exit 1
    fi
    echo "git-crypt-unlock: Waiting for git-sync to clone repository... (${WAITED}s/${MAX_WAIT}s)"
    sleep 2
    WAITED=$((WAITED + 2))
done

echo "git-crypt-unlock: Repository found at /data/git/current"

# Change to repository directory
cd /data/git/current

# Check if repository uses git-crypt
if [ ! -d ".git-crypt" ]; then
    echo "git-crypt-unlock: Repository does not use git-crypt (no .git-crypt directory), skipping unlock"
    exit 0
fi

echo "git-crypt-unlock: Repository uses git-crypt, proceeding with unlock"

# Validate key file exists
if [ ! -f "$GIT_CRYPT_KEY_PATH" ]; then
    echo "git-crypt-unlock: ERROR - Key file not found at: $GIT_CRYPT_KEY_PATH"
    echo "git-crypt-unlock: Please ensure GIT_CRYPT_KEY_PATH is set correctly and the key file is mounted"
    exit 1
fi

# Validate key file is not empty
if [ ! -s "$GIT_CRYPT_KEY_PATH" ]; then
    echo "git-crypt-unlock: ERROR - Key file is empty: $GIT_CRYPT_KEY_PATH"
    echo "git-crypt-unlock: Please ensure the key file contains a valid git-crypt key"
    exit 1
fi

echo "git-crypt-unlock: Key file validated, unlocking repository..."

# Unlock the repository
if git-crypt unlock "$GIT_CRYPT_KEY_PATH"; then
    echo "git-crypt-unlock: Successfully unlocked git-crypt repository"
    echo "git-crypt-unlock: Encrypted files are now decrypted and ready for use"
    exit 0
else
    UNLOCK_EXIT_CODE=$?
    echo "git-crypt-unlock: ERROR - Failed to unlock git-crypt repository (exit code: $UNLOCK_EXIT_CODE)"
    echo "git-crypt-unlock: This may indicate an invalid key or corrupted repository"
    echo "git-crypt-unlock: Please verify the key file matches the repository encryption"
    exit 1
fi
