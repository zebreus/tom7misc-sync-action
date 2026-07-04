#!/usr/bin/env bash
set -exo pipefail

UPSTREAM_DIR_NAME="upstream"
REPO_DIR="$(pwd)"
UPSTREAM_DIR="$REPO_DIR/$UPSTREAM_DIR_NAME"
GIT_SVN_STATE="git-svn-state"

DOWNSTREAM_URL="https://x-access-token:${DOWNSTREAM_SYNC_TOKEN}@github.com/zebreus/tom7misc.git"
DOWNSTREAM_DIR="$REPO_DIR/downstream"

# Setup git
git config user.name "github-actions"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"

# Restore svnsync lock files (excluded from git)
mkdir -p "$UPSTREAM_DIR"/db
mkdir -p "$UPSTREAM_DIR"/locks
mkdir -p "$UPSTREAM_DIR"/db/transactions
mkdir -p "$UPSTREAM_DIR"/db/txn-protorevs
touch "$UPSTREAM_DIR"/db/txn-current-lock
touch "$UPSTREAM_DIR"/db/write-lock
touch "$UPSTREAM_DIR"/locks/db.lock
touch "$UPSTREAM_DIR"/locks/db-logs.lock

# Sync upstream
svnsync sync "file://$UPSTREAM_DIR"

# Early exit if there are no changes
git add $UPSTREAM_DIR_NAME
git diff --cached --quiet && echo "No SVN changes" && exit 0

# Clone downstream repo
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
# Rebuild the git-svn index from the downstream HEAD to ensure all referenced blobs exist
# (using the stored index can fail if the downstream repo has diverged from the saved state)
if git -C "$DOWNSTREAM_DIR" rev-parse --verify HEAD &>/dev/null; then
  GIT_INDEX_FILE="$DOWNSTREAM_DIR/.git/svn/refs/remotes/origin/trunk/index" git -C "$DOWNSTREAM_DIR" read-tree HEAD
fi
cp "$REPO_DIR/$GIT_SVN_STATE/.rev_map" "$DOWNSTREAM_DIR/.git/svn/refs/remotes/origin/trunk/.rev_map.$UUID"

cd "$DOWNSTREAM_DIR" || exit 1
git config svn-remote.svn.url "file://${UPSTREAM_DIR}"
git config svn-remote.svn.fetch 'trunk:refs/remotes/origin/trunk'
git svn fetch --authors-file="$REPO_DIR/authors.txt"
git reset --hard refs/remotes/origin/trunk
git clean -fdx

cd "$REPO_DIR" || exit 1
# Store git-svn state for next sync
cp "$DOWNSTREAM_DIR/.git/svn/refs/remotes/origin/trunk/index" "$GIT_SVN_STATE/index"
cp "$DOWNSTREAM_DIR/.git/svn/refs/remotes/origin/trunk/.rev_map."* "$GIT_SVN_STATE/.rev_map"

git add $GIT_SVN_STATE

git commit -m "Sync SVN to r$(svnlook youngest "$UPSTREAM_DIR")"

# Assert that we can push to both repos
git push --dry-run
cd "$DOWNSTREAM_DIR"
git push --dry-run --force
cd "$REPO_DIR"

# Push to both repos
git push
cd "$DOWNSTREAM_DIR"
git push --force
cd "$REPO_DIR"
