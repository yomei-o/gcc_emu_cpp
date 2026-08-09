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

echo "== without it"
a=$(secs)
./x86emu -r "$ROOT" /usr/bin/g++ -O2 /work/hello.cpp -o /work/a.out
b=$(secs)
echo "  $(took "$a" "$b") s"

echo "== with it"
a=$(secs)
./x86emu -r "$ROOT" /usr/bin/g++ -O2 -I/pch -include std.hpp /work/hello.cpp -o /work/b.out || echo "  (failed)"
b=$(secs)
echo "  $(took "$a" "$b") s"
