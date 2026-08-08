#!/bin/sh
# Can the emulator run this toolchain at all?
#
# Everything else in this project - the editor, the projects, the graphs - is
# ordinary web work that will certainly work.  This is the part that might not,
# so it goes first and it goes on its own.
set -e
cd "$(dirname "$0")/.."
ROOT=$PWD/build/alpine
[ -d "$ROOT/usr/bin" ] || { echo "no toolchain - run tools/fetch_alpine.sh"; exit 1; }

if [ ! -x ./x86emu ]; then
    echo "== building the emulator"
    CXX=${CXX:-$HOME/gpp/bin/g++} sh build.sh > build/emu.log 2>&1 ||
        { tail -20 build/emu.log; exit 1; }
fi

mkdir -p "$ROOT/tmp" "$ROOT/work"
cat > "$ROOT/work/hello.c" <<'EOF'
#include <stdio.h>
int main(void) {
    printf("hello from a compiler that is not really here\n");
    return 0;
}
EOF

echo "== gcc --version"
time ./x86emu -r "$ROOT" /usr/bin/gcc --version 2>&1 | head -3

echo
echo "== gcc /work/hello.c -o /work/hello"
time ./x86emu -r "$ROOT" /usr/bin/gcc /work/hello.c -o /work/hello 2>&1 | tail -20

echo
echo "== and running what it produced"
time ./x86emu -r "$ROOT" /work/hello 2>&1 | tail -5
