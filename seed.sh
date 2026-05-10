#!/usr/bin/env bash

svnadmin create "$(pwd)/upstream"
echo '#!/bin/sh' > hooks/pre-revprop-change
chmod +x hooks/pre-revprop-change
svnsync init "file://$(pwd)/upstream" svn://svn.code.sf.net/p/tom7misc/svn/trunk
svnsync sync "file://$(pwd)/upstream"
