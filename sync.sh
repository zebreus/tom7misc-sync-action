#!/usr/bin/env bash
set -exo pipefail

UPSTREAM_DIR_NAME="upstream"
REPO_DIR="$(pwd)"
UPSTREAM_DIR="$REPO_DIR/$UPSTREAM_DIR_NAME"
GIT_SVN_STATE="git-svn-state"

DOWNSTREAM_URL="https://${DOWNSTREAM_SYNC_TOKEN}@github.com/zebreus/tom7misc.git"
DOWNSTREAM_DIR="$REPO_DIR/downstream"

# Setup git
git config user.name "github-actions"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"

# Restore svnsync lock files (excluded from git)
touch $UPSTREAM_DIR_NAME/db/txn-current-lock
touch $UPSTREAM_DIR_NAME/db/write-lock
touch $UPSTREAM_DIR_NAME/locks/db.lock
touch $UPSTREAM_DIR_NAME/locks/db-logs.lock

# Sync upstream
svnsync sync "file://$UPSTREAM_DIR"

git add $UPSTREAM_DIR_NAME
git diff --cached --quiet && echo "No SVN changes" && exit 0

# Clone downstream URL
git clone "$DOWNSTREAM_URL" "$DOWNSTREAM_DIR"

# Prepare downstream for git-svn
UUID=$(svnlook uuid "$UPSTREAM_DIR")
mkdir -p "$DOWNSTREAM_DIR/.git/svn"
cat > "$DOWNSTREAM_DIR/.git/svn/.metadata" << EOF
; This file is used internally by git-svn.
; You should not have to edit it
[svn-remote "svn"]
	reposRoot = file://${UPSTREAM_DIR}
	uuid = $UUID
EOF
mkdir -p "$DOWNSTREAM_DIR/.git/svn/refs/remotes/origin/trunk"
cp "$REPO_DIR/$GIT_SVN_STATE/index" "$DOWNSTREAM_DIR/.git/svn/refs/remotes/origin/trunk/index"
cp "$REPO_DIR/$GIT_SVN_STATE/.rev_map" "$DOWNSTREAM_DIR/.git/svn/refs/remotes/origin/trunk/.rev_map.$UUID"

cd "$DOWNSTREAM_DIR" || exit 1
git config svn-remote.svn.url "file://$REPO_DIR/$UPSTREAM_DIR_NAME"
git config svn-remote.svn.fetch 'trunk:refs/remotes/origin/trunk'
git svn fetch --authors-file="$REPO_DIR/authors.txt"
git rebase refs/remotes/origin/trunk

cd "$REPO_DIR" || exit 1
# Store git-svn state for next sync
cp "$DOWNSTREAM_DIR/.git/svn/refs/remotes/origin/trunk/index" "$GIT_SVN_STATE/index"
cp "$DOWNSTREAM_DIR/.git/svn/refs/remotes/origin/trunk/.rev_map."* "$GIT_SVN_STATE/.rev_map"

git add $GIT_SVN_STATE

git commit -m "Sync SVN to r$(svnlook youngest $UPSTREAM_DIR_NAME)"

# Assert that we can push to both repos
git push origin main --dry-run
cd "$DOWNSTREAM_DIR"
git push origin main --dry-run 
cd "$REPO_DIR"

# Push to both repos
git push origin main
cd "$DOWNSTREAM_DIR"
git push origin main
cd "$REPO_DIR"
