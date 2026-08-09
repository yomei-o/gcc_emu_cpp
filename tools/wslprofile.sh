#!/bin/sh
# Where the interpreter's time goes while cc1plus parses C++.
#
# The opcode census says what the guest executes; this says what the emulator
# spends its own time on running it.  Both are needed: 20 % of the guest's
# instructions setting flags only matters if setting flags is where the host
# time goes, and the two questions have different answers.
#
# gprof, following x86_emu_cpp/tools/profile.sh, and with the same caveat: -pg
# suppresses inlining, so the small hot helpers are pushed upward.  Treat the
# ordering as the answer and the percentages as a sketch.
#
# -fsyntax-only: parsing is 61 of the C++ compile's 93 seconds, and mixing in
# code generation would blur two different workloads together.
set -e
cd "$(dirname "$0")/.."
ROOT=$PWD/build/tree
CXX=${CXX:-$HOME/gpp/bin/g++}
[ -x "$CXX" ] || { echo "no g++ at $CXX"; exit 1; }
[ -d "$ROOT/usr/bin" ] || { echo "no tree - run tools/wslpayload.sh"; exit 1; }
mkdir -p build/prof "$ROOT/work" "$ROOT/tmp"

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

echo "== building with -pg"
"$CXX" -std=c++17 -O2 -pg -Ix86_emu_cpp/src -o build/prof/x86emu x86_emu_cpp/src/*.cpp 2>&1 | tail -2

echo "== running (cc1plus, parse only)"
cd build/prof
./x86emu -r "$ROOT" /usr/bin/g++ -fsyntax-only /work/hello.cpp > /dev/null 2>&1 || true
[ -f gmon.out ] || { echo "no gmon.out - not instrumented?"; exit 1; }

echo
echo "== flat profile, the top of it"
gprof ./x86emu gmon.out 2>/dev/null | sed -n '1,28p'
