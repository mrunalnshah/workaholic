#!/bin/sh
set -e

# Ensure working directory is clean
if [ -n "$(git status -s)" ]; then
    echo "❌ The working directory is dirty. Please commit any pending changes."
    exit 1
fi

echo "🧹 Cleaning old build"
rm -rf public

echo "🗂️ Pruning old worktrees"
git worktree prune

# Remove stale worktree reference if it exists (safe fallback)
if [ -d ".git/worktrees/public" ]; then
    rm -rf .git/worktrees/public
fi

echo "🌿 Setting up gh-pages worktree"

# Ensure gh-pages branch exists locally
if git show-ref --verify --quiet refs/heads/gh-pages; then
    git worktree add public gh-pages
else
    git worktree add -B gh-pages public origin/gh-pages || git worktree add -B gh-pages public
fi

echo "🗑️ Clearing old files"
rm -rf public/*

echo "⚙️ Building site with Hugo"
HUGO_ENV="production" hugo -t github-style

echo "📦 Committing changes"
cd public

git add --all

if git diff --cached --quiet; then
    echo "ℹ️ No changes to commit"
else
    git commit -m "Publish site ($(date))"
fi

echo "🚀 Pushing to GitHub"
git push origin gh-pages

cd ..

echo "✅ Deployment complete"
