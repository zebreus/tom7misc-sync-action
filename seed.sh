#!/usr/bin/env bash

svnadmin create $(pwd)/svn-mirror
echo '#!/bin/sh' > hooks/pre-revprop-change
chmod +x hooks/pre-revprop-change
svnsync init file://$(pwd)/svn-mirror svn://svn.code.sf.net/p/tom7misc/svn/trunk
svnsync sync file://$(pwd)/svn-mirror