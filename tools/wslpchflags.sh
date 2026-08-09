#!/bin/sh
# Does the precompiled header still apply under each of the page's three
# option settings?
#
# GCC will not tell you when it declines a PCH.  It re-reads the headers and
# compiles correctly, just slowly, so the only way to see it is the clock: a
# build that takes as long as one with no PCH at all did not use it.
#
# The page offers -O0 -g -Wall, -O2 -Wall, and -O2 -Wall -Wextra.  The .gch is
# built with one of them, so at most one is certain to match; this says what the
# other two cost.
set -e
cd "$(dirname "$0")/.."
ROOT=$PWD/build/tree
[ -x ./x86emu ] || { echo "build the emulator first: sh build.sh"; exit 1; }
[ -f "$ROOT/pch/std.hpp.gch" ] || { echo "no .gch - run tools/wslpchnative.sh"; exit 1; }

secs() { date +%s.%N; }

try() {  # try <flags...>
    rm -rf "$ROOT/tmp"; mkdir -p "$ROOT/tmp"
    rm -f "$ROOT/work/f.out"
    a=$(secs)
    ./x86emu -r "$ROOT" /usr/bin/g++ "$@" -I/pch -include std.hpp \
        /work/hello.cpp -o /work/f.out >/dev/null 2>&1 || { echo "  FAILED: $*"; return 1; }
    b=$(secs)
    [ -f "$ROOT/work/f.out" ] || { echo "  no output: $*"; return 1; }
    awk "BEGIN{printf \"  %7.2f s   %s\n\", $b - $a, \"$*\"}"
}

echo "== with the .gch, which was built with -O2"
try -O2 -Wall
try -O2 -Wall -Wextra
try -O0 -g -Wall
