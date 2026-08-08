#!/bin/sh
# The WebAssembly build, under node.
set -e
cd "$(dirname "$0")/.."
NODE=$(ls "$HOME"/emsdk/node/*/bin/node 2>/dev/null | head -1)
[ -x "$NODE" ] || { echo "no node in emsdk"; exit 1; }
exec "$NODE" web/test_mnist.mjs "$@"
