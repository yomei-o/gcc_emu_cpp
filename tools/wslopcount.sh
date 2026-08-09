#!/bin/sh
# Which instructions the C++ compile actually executes.
#
# tools/wslstages.sh says cc1plus is 97 % of a C++ compile and parsing is 64 %.
# That is where the time is; this is what the time is made of.  The same
# question asked of voicevox turned out to have a surprising answer - the run
# everyone described as matrix arithmetic was a varint decoder - so it is worth
# asking here rather than assuming cc1plus does what a compiler "obviously"
# does.
#
# -fsyntax-only, because parsing is the 61 of the 93 seconds and mixing codegen
# in would blur the two.  Pass `all` to count the whole compile instead.
set -e
cd "$(dirname "$0")/.."
ROOT=$PWD/build/tree
[ -x ./x86emu ] || { echo "build the emulator first: sh build.sh"; exit 1; }
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

if [ "$1" = all ]; then
    set -- -O2 -Wall /work/hello.cpp -o /work/a.out -lm
    echo "== the whole compile"
else
    set -- -fsyntax-only /work/hello.cpp
    echo "== parsing only (-fsyntax-only)"
fi

X86EMU_OPCOUNT=1 ./x86emu -r "$ROOT" /usr/bin/g++ "$@" 2>&1 |
    sed -n '/opcount/p' | head -36
