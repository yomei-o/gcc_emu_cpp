#!/bin/sh
# Two emulator builds on the same compile, interleaved.
#
#   sh tools/wslab.sh [rounds]
#
# ./x86emu.before against ./x86emu, A then B then A then B, because this
# machine's wall clock moves ten per cent on its own and three runs of one
# followed by three of the other measures the machine as much as the change.
#
# The workload is `g++ -fsyntax-only`: parsing is 61 of a C++ compile's 93
# seconds, it is the part every student pays on every build, and leaving code
# generation out keeps one number from hiding inside another.
set -e
cd "$(dirname "$0")/.."
ROOT=$PWD/build/tree
ROUNDS=${1:-3}
[ -x ./x86emu.before ] || { echo "no ./x86emu.before to compare against"; exit 1; }
[ -x ./x86emu ] || { echo "no ./x86emu"; exit 1; }
mkdir -p "$ROOT/work" "$ROOT/tmp"

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
    a=$(date +%s.%N)
    "$2" -r "$ROOT" /usr/bin/g++ -fsyntax-only /work/hello.cpp > /dev/null 2>&1 || {
        echo "  $1: FAILED"; return 1; }
    b=$(date +%s.%N)
    awk "BEGIN{printf \"  %-8s %7.2f s\n\", \"$1\", $b - $a}"
}

r=1
while [ "$r" -le "$ROUNDS" ]; do
    echo "round $r"
    one before ./x86emu.before
    one after  ./x86emu
    r=$((r + 1))
done
