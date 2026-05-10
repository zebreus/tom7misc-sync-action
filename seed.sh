#!/usr/bin/env bash
set -exo pipefail

svnadmin create "$(pwd)/upstream"
echo '#!/bin/sh' > hooks/pre-revprop-change
chmod +x hooks/pre-revprop-change
svnsync init "file://$(pwd)/upstream" svn://svn.code.sf.net/p/tom7misc/svn/trunk
svnsync sync "file://$(pwd)/upstream"

git svn clone "file://$(pwd)/upstream" -r 1:100 downstream --authors-file=./authors.txt --trunk=trunk --no-metadata

mkdir -p git-svn-state
cp "downstream/.git/svn/refs/remotes/origin/trunk/index" "git-svn-state/index"
cp downstream/.git/svn/refs/remotes/origin/trunk/.rev_map.* "git-svn-state/.rev_map"
