#!/bin/sh
# Shrink Cpu::step() and nothing else, then measure.
#
# The first attempt at this compiled all of cpu.cpp at -Os and came out 77 %
# slower - which says -Os is bad for that file and cannot say whether step()'s
# size mattered, because alu(), shift(), the flag helpers and the memory paths
# all got worse in the same build.  A confounded experiment answers a question
# nobody asked.
#
# X86EMU_SMALL_STEP puts __attribute__((optimize("Os"))) on step() alone.
set -e
cd "$(dirname "$0")/.."
ROOT=$PWD/build/tree
ROUNDS=${1:-3}
CXX=${CXX:-$HOME/gpp/bin/g++}
[ -x "$CXX" ] || { echo "no g++ at $CXX"; exit 1; }
mkdir -p build/size "$ROOT/work" "$ROOT/tmp"

build() {  # build <output> [extra flags]
    out=$1; shift
    $CXX -std=c++17 -O2 -Wall -Ix86_emu_cpp/src "$@" \
        -o "$out" x86_emu_cpp/src/*.cpp
    nm -C --size-sort -S "$out" 2>/dev/null |
        awk -v o="$out" '/Cpu::step\(\)$/ {printf "   %-28s step() %d bytes\n", o, strtonum("0x" $2)}'
}

echo "== building"
build build/size/step_big
build build/size/step_small -DX86EMU_SMALL_STEP

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
    awk "BEGIN{printf \"  %-6s %7.2f s\n\", \"$1\", $b - $a}"
}

echo "== measuring"
r=1
while [ "$r" -le "$ROUNDS" ]; do
    echo "round $r"
    one big   build/size/step_big
    one small build/size/step_small
    r=$((r + 1))
done
