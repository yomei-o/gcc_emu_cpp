#!/bin/sh
# The precompiled header, under the native emulator, so it can be iterated on.
#
# web/test_pch.mjs runs the same thing through WebAssembly, which is the path
# the page takes and four times slower to try anything in.  This one is for
# finding out why it breaks.
#
#   sh tools/wslpchnative.sh          build the .gch if missing, then use it
#   X86EMU_MMAP_TRACE=1 sh ...        with every mmap printed
set -e
cd "$(dirname "$0")/.."
ROOT=$PWD/build/tree
[ -x ./x86emu ] || { echo "build the emulator first: sh build.sh"; exit 1; }
mkdir -p "$ROOT/pch" "$ROOT/work" "$ROOT/tmp"

cat > "$ROOT/pch/std.hpp" <<'EOF'
#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <iostream>
#include <map>
#include <memory>
#include <numeric>
#include <set>
#include <sstream>
#include <string>
#include <vector>
EOF

cat > "$ROOT/work/hello.cpp" <<'EOF'
#include <iostream>
#include <vector>
#include <algorithm>
int main() {
    std::vector<int> v{3, 1, 2};
    std::sort(v.begin(), v.end());
    std::cout << "C++ " << v.size() << "\n";
    return 0;
}
EOF

secs() { date +%s.%N; }
took() { awk "BEGIN{printf \"%7.2f\", $2 - $1}"; }

if [ ! -f "$ROOT/pch/std.hpp.gch" ]; then
    echo "== building the .gch (once)"
    a=$(secs)
    ./x86emu -r "$ROOT" /usr/bin/g++ -O2 -x c++-header /pch/std.hpp -o /pch/std.hpp.gch
    b=$(secs)
    echo "  $(took "$a" "$b") s   $(du -h "$ROOT/pch/std.hpp.gch" | cut -f1)"
fi

# cc1plus names its temporary files from the pid, the emulator hands out the
# same pids every run, and a previous run's leavings make the next one fail with
# `Cannot create temporary file in /tmp/: File exists`.  That failure takes half
# a second and looks exactly like a very fast compile.
rm -rf "$ROOT/tmp"; mkdir -p "$ROOT/tmp"

# And each timing is only worth reading if something ran: a compile that failed
# is faster than one that worked, every time.
run() {  # run <label> <output> <flags...>
    label=$1; out=$2; shift 2
    rm -f "$ROOT$out"
    a=$(secs)
    ./x86emu -r "$ROOT" /usr/bin/g++ "$@" -o "$out" || { echo "  $label: FAILED"; return 1; }
    b=$(secs)
    [ -f "$ROOT$out" ] || { echo "  $label: no output produced"; return 1; }
    got=$(cd "$ROOT" && "$OLDPWD/x86emu" -r "$ROOT" "$out" 2>&1) ||
        { echo "  $label: the program it built does not run"; return 1; }
    echo "  $(took "$a" "$b") s   ($label, ran and printed: $got)"
}

echo "== without it"
run "no pch" /work/a.out -O2 /work/hello.cpp

rm -rf "$ROOT/tmp"; mkdir -p "$ROOT/tmp"
echo "== with it"
run "pch" /work/b.out -O2 -I/pch -include std.hpp /work/hello.cpp
