#!/bin/sh
# Build web/x86emu.js from WSL, with emsdk's emcc.
#
# A script file because `wsl.exe -- bash -c 'EMCC=$HOME/... sh web/build.sh'`
# loses the expansion and the build reports "emcc not found".
set -e
cd "$(dirname "$0")/.."
EMCC=$HOME/emsdk/upstream/emscripten/emcc
EMXX=$HOME/emsdk/upstream/emscripten/em++
[ -x "$EMCC" ] || { echo "no emcc at $EMCC"; exit 1; }
EMCC=$EMCC EMXX=$EMXX sh web/build.sh
