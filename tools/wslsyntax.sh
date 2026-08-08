#!/bin/sh
# Do the page scripts parse?
#
# A browser is the only place they run - node has no document - so this checks
# syntax and nothing else.  That is still worth doing: the mistakes an edit makes
# are usually a bracket, and finding one after a push costs a round trip through
# GitHub Pages.
cd "$(dirname "$0")/.."
NODE=$(ls "$HOME"/emsdk/node/*/bin/node 2>/dev/null | head -1)
[ -x "$NODE" ] || { echo "no node in emsdk"; exit 1; }
fail=0
for f in web/*.js web/*.mjs; do
    case "$f" in web/x86emu.js|web/untar.js) continue ;; esac
    if "$NODE" --check "$f" 2>/tmp/syntax.err; then
        echo "  ok    $f"
    else
        echo "  FAIL  $f"
        head -4 /tmp/syntax.err | sed 's|^|        |'
        fail=1
    fi
done
exit $fail
