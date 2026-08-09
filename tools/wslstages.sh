#!/bin/sh
# Where the C++ compile's time actually goes.
#
# `g++ hello.cpp` is four guest programs - cc1plus, as, collect2, ld - and the
# emulator pays an ELF load and a full ld.so relocation for each one.  Knowing
# the split decides whether clang is worth trying: its integrated assembler and
# -fintegrated-cc1 would collapse four processes into two and remove the .s file
# round trip, and that is worth whatever `as` plus three startups costs, not a
# guess about frontend speed.
#
# Native emulator, not the WebAssembly one: the absolute numbers are smaller but
# the question here is the ratio between stages, and this iterates in seconds.
set -e
cd "$(dirname "$0")/.."
ROOT=$PWD/build/tree
[ -x ./x86emu ] || { echo "build the emulator first"; exit 1; }
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

secs() { date +%s.%N; }
took() { awk "BEGIN{printf \"%7.2f\", $2 - $1}"; }

echo "== the whole thing, for the total"
a=$(secs)
./x86emu -r "$ROOT" /usr/bin/g++ -O2 -Wall /work/hello.cpp -o /work/a.out -lm
b=$(secs)
whole=$(took "$a" "$b")
echo "  g++ (everything)          $whole s"

echo
echo "== what it runs"
# -### prints the sub-commands without running them, one per line, quoted.
./x86emu -r "$ROOT" /usr/bin/g++ -### -O2 -Wall /work/hello.cpp -o /work/a.out -lm \
    2>"$ROOT/work/cmds.txt" || true
grep -c . "$ROOT/work/cmds.txt" > /dev/null
sed -n 's/^ \(\/[^ ]*\).*/  \1/p' "$ROOT/work/cmds.txt" | sort -u

echo
echo "== an empty program, to price the startups"
printf 'int main(){return 0;}\n' > "$ROOT/work/empty.c"
a=$(secs)
./x86emu -r "$ROOT" /usr/bin/gcc /work/empty.c -o /work/e.out
b=$(secs)
echo "  gcc (empty .c)            $(took "$a" "$b") s"

a=$(secs)
./x86emu -r "$ROOT" /usr/bin/gcc -c /work/empty.c -o /work/e.o
b=$(secs)
echo "  gcc -c (no link)          $(took "$a" "$b") s"

a=$(secs)
./x86emu -r "$ROOT" /usr/bin/g++ -fsyntax-only /work/hello.cpp
b=$(secs)
echo "  g++ -fsyntax-only         $(took "$a" "$b") s   (cc1plus, no codegen, no as, no ld)"

a=$(secs)
./x86emu -r "$ROOT" /usr/bin/g++ -O2 -S /work/hello.cpp -o /work/hello.s
b=$(secs)
echo "  g++ -S                    $(took "$a" "$b") s   (cc1plus only, to assembly)"

a=$(secs)
./x86emu -r "$ROOT" /usr/bin/g++ -O2 -c /work/hello.cpp -o /work/hello.o
b=$(secs)
echo "  g++ -c                    $(took "$a" "$b") s   (cc1plus + as)"

a=$(secs)
./x86emu -r "$ROOT" /usr/bin/as /work/hello.s -o /work/hello2.o
b=$(secs)
echo "  as alone                  $(took "$a" "$b") s"

echo
echo "  total was $whole s"
