#!/bin/sh
# Is the precompiled header used at -O0 -g, or silently declined?
#
# tools/wslpchflags.sh timed all three of the page's settings and -O0 -g came
# out at 67 s against 32 and 18 for the two -O2 ones.  That is not evidence on
# its own: -O0 compiles faster than -O2 anyway, so the only way to know is to
# run -O0 -g both with and against the same header.
#
# A script file, not a command line.  `wsl.exe -- bash -c '...$VAR...'` loses
# the expansions: the last attempt at this became `rm -rf /tmp` on the WSL side,
# because $R had arrived empty.
set -e
cd "$(dirname "$0")/.."
ROOT=$PWD/build/tree
[ -x ./x86emu ] || { echo "build the emulator first: sh build.sh"; exit 1; }
[ -f "$ROOT/pch/std.hpp.gch" ] || { echo "no .gch - run tools/wslpchnative.sh"; exit 1; }
[ -d "$ROOT/usr/bin" ] || { echo "no tree at $ROOT"; exit 1; }

one() {  # one <label> <extra flags...>
    label=$1; shift
    rm -rf "$ROOT/tmp"; mkdir -p "$ROOT/tmp"
    rm -f "$ROOT/work/g.out"
    a=$(date +%s.%N)
    ./x86emu -r "$ROOT" /usr/bin/g++ -O0 -g -Wall "$@" \
        /work/hello.cpp -o /work/g.out >/dev/null 2>&1 || { echo "  $label: FAILED"; return 1; }
    b=$(date +%s.%N)
    [ -f "$ROOT/work/g.out" ] || { echo "  $label: no output"; return 1; }
    awk "BEGIN{printf \"  %-10s %7.2f s\n\", \"$label\", $b - $a}"
}

echo "== -O0 -g -Wall"
one "with pch" -I/pch -include std.hpp
one "without"
