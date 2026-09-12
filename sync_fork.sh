#!/usr/bin/env bash
set -e

UPSTREAM_URL="https://github.com/diku-dk/pmph-e2026-pub.git"

# Make sure we're inside a git repository
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    echo "Error: not inside a Git repository."
    exit 1
}

# Refuse to run with uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo "Error: You have uncommitted changes."
    echo "Commit or stash them first."
    exit 1
fi

BRANCH=$(git branch --show-current)

if [ -z "$BRANCH" ]; then
    echo "Error: detached HEAD state."
    exit 1
fi

echo "Current branch: $BRANCH"

# Add upstream if missing
if git remote get-url upstream >/dev/null 2>&1; then
    echo "Upstream already configured:"
    git remote get-url upstream
else
    echo "Adding upstream:"
    git remote add upstream "$UPSTREAM_URL"
fi

echo
echo "Fetching upstream..."
git fetch upstream

# Make sure this branch exists upstream
if ! git show-ref --verify --quiet "refs/remotes/upstream/$BRANCH"; then
    echo "Error: upstream/$BRANCH does not exist."
    echo
    echo "Available upstream branches:"
    git branch -r | grep "upstream/"
    exit 1
fi

echo
echo "New upstream commits:"
git log --oneline "HEAD..upstream/$BRANCH" || true

echo
echo "Your commits:"
git log --oneline "upstream/$BRANCH..HEAD" || true

echo
echo "Rebasing onto upstream/$BRANCH..."
git rebase "upstream/$BRANCH"

echo
echo "Pushing updated branch to your fork..."
git push --force-with-lease origin "$BRANCH"

echo
echo "Done."
echo "Your fork is now updated with:"
echo "  upstream: $UPSTREAM_URL"
echo "  branch:   $BRANCH"