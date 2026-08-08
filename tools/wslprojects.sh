#!/bin/sh
# The example projects, timed: how long to compile, and how long to run.
#
# "C feels slow too" needs those two apart before anything is done about it.
# Compiling is a fixed cost - starting cc1, reading stdio.h, linking - that a
# longer program barely moves.  Running is the program's own arithmetic, and
# bubble sort recomputes its inversion count on every pass, which is O(n^3) by
# construction.  Those want different fixes.
set -e
cd "$(dirname "$0")/.."
ROOT=${VVTREE:-$PWD/build/tree}
[ -x ./x86emu ] || { echo "build the emulator first"; exit 1; }
mkdir -p "$ROOT/work" "$ROOT/tmp" build

# The sources, pulled out of web/projects.js so this measures what the page
# actually ships rather than something written again here.
node_bin=$(ls "$HOME"/emsdk/node/*/bin/node 2>/dev/null | head -1)
[ -x "$node_bin" ] || { echo "no node in emsdk"; exit 1; }
"$node_bin" --input-type=module -e "
import { PROJECTS } from 'file://$PWD/web/projects.js';
import fs from 'node:fs';
for (const [key, p] of Object.entries(PROJECTS)) {
    for (const [name, text] of Object.entries(p.files)) {
        fs.mkdirSync('$ROOT/work/' + key, { recursive: true });
        fs.writeFileSync('$ROOT/work/' + key + '/' + name, text);
    }
}
console.error(Object.keys(PROJECTS).join(' '));
" > /dev/null

ms() { date +%s%N; }
took() { awk "BEGIN{printf \"%6.1f\", ($2 - $1)/1000000000}"; }

printf '\n%-22s %8s %8s\n' 'project' 'compile' 'run'
for dir in "$ROOT"/work/*/; do
    key=$(basename "$dir")
    src=$(ls "$dir"*.c "$dir"*.cpp 2>/dev/null | head -1) || continue
    [ -n "$src" ] || continue
    guest=/work/$key/$(basename "$src")
    case "$src" in *.cpp) cc=/usr/bin/g++ ;; *) cc=/usr/bin/gcc ;; esac

    a=$(ms)
    if ! ./x86emu -r "$ROOT" "$cc" -O2 -Wall "$guest" -o "/work/$key/a" -lm > /dev/null 2>&1; then
        printf '%-22s %8s\n' "$key" 'failed'
        continue
    fi
    b=$(ms)
    # The program runs where its files are, the way the page runs it.
    (cd "$dir" && cd - > /dev/null) 2>/dev/null || true
    c=$(ms)
    ./x86emu -r "$ROOT" "/work/$key/a" > "build/$key.out" 2>&1 || true
    d=$(ms)
    printf '%-22s %8s %8s\n' "$key" "$(took "$a" "$b")" "$(took "$c" "$d")"
done
