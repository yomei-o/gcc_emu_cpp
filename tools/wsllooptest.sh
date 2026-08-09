#!/bin/sh
# The run loop's per-instruction checks, hoisted or not.
#
# run_slice tests four things around every single step(): halted, reschedule_,
# the deadline, an instruction limit that is almost always off, and a
# save-state path that is almost always empty.  The last two cannot change
# while the loop runs.
#
# ./x86emu.before is whatever was built before the change; this builds the
# current source beside it and runs the pair interleaved.
set -e
cd "$(dirname "$0")/.."
ROOT=$PWD/build/tree
ROUNDS=${1:-3}
CXX=${CXX:-$HOME/gpp/bin/g++}
[ -x "$CXX" ] || { echo "no g++ at $CXX"; exit 1; }
[ -x ./x86emu.before ] || { echo "no ./x86emu.before to compare against"; exit 1; }
mkdir -p build/size "$ROOT/work" "$ROOT/tmp"

echo "== building the current source"
$CXX -std=c++17 -O2 -Wall -Ix86_emu_cpp/src -o build/size/loop_after x86_emu_cpp/src/*.cpp

cat > "$ROOT/work/hello.cpp" <<'EOF'
#include <cstdio>
#include <string>
#include <vector>
#include <map>
#include <algorithm>
#include <memory>
#include <sstream>
int main() {
    std::vector<int> v{3, 1, 2};
    std::sort(v.begin(), v.end());
    std::map<std::string, int> m{{"a", 1}};
    auto p = std::make_unique<int>(7);
    std::ostringstream os;
    os << "C++ " << v.size() << " " << m["a"] << " " << *p;
    std::printf("%s\n", os.str().c_str());
    return 0;
}
EOF

one() {  # one <label> <binary>
    rm -rf "$ROOT/tmp"; mkdir -p "$ROOT/tmp"
    a=$(date +%s.%N)
    "$2" -r "$ROOT" /usr/bin/g++ -fsyntax-only /work/hello.cpp >/dev/null 2>&1 ||
        { echo "  $1: FAILED"; return 1; }
    b=$(date +%s.%N)
    awk "BEGIN{printf \"  %-7s %7.2f s\n\", \"$1\", $b - $a}"
}

echo "== measuring"
r=1
while [ "$r" -le "$ROUNDS" ]; do
    echo "round $r"
    one before ./x86emu.before
    one after  build/size/loop_after
    r=$((r + 1))
done
