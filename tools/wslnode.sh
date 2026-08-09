#!/bin/sh
# The WebAssembly build, under node.
set -e
cd "$(dirname "$0")/.."
NODE=$(ls "$HOME"/emsdk/node/*/bin/node 2>/dev/null | head -1)
[ -x "$NODE" ] || { echo "no node in emsdk"; exit 1; }

# Is web/x86emu.js older than the emulator it was built from?
#
# web/build.sh says at the top to rebuild whenever x86_emu_cpp/src changes, and
# saying so is not enough: a source fix landed, the native build got it, this
# one did not, and the test then reported a crash that had already been fixed -
# in a module three hours older than the fix.  The same mistake, with a
# three-day-old binary, cost an hour this morning in x86_emu_cpp/tests.
if [ -f web/x86emu.js ]; then
    newer=$(find x86_emu_cpp/src web/wasm_api.cpp -newer web/x86emu.js 2>/dev/null | head -3)
    if [ -n "$newer" ]; then
        echo "  STALE: newer than web/x86emu.js -"
        printf '    %s\n' $newer
        echo "  run tools/wslwasm.sh first."
        exit 1
    fi
fi

exec "$NODE" web/test_node.mjs "$@"
