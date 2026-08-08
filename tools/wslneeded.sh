#!/bin/sh
# Which of the toolchain's 204 MB a compile actually touches.
#
# The tree that comes out of the Alpine packages is a whole distribution's
# worth of compiler: three front ends, every target header, documentation, the
# static libraries for linking modes nobody here uses.  What a browser has to
# carry is the files a compile opens, and the emulator will say which those are
# - X86EMU_TRACE_OPEN prints every open() the guest makes.
#
# Compiling C and C++, at -O0 and -O2, covers what the projects will do.
set -e
cd "$(dirname "$0")/.."
ROOT=$PWD/build/alpine
[ -x ./x86emu ] || { echo "build the emulator first"; exit 1; }

mkdir -p "$ROOT/work" build
cat > "$ROOT/work/t.c" <<'EOF'
#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>
int main(void) { printf("%f %s\n", sqrt(2.0), "ok"); return 0; }
EOF
cat > "$ROOT/work/t.cc" <<'EOF'
#include <cstdio>
#include <string>
#include <vector>
#include <algorithm>
#include <cmath>
int main() {
    std::vector<int> v{3, 1, 2};
    std::sort(v.begin(), v.end());
    std::string s = "ok";
    std::printf("%zu %s %f\n", v.size(), s.c_str(), std::sqrt(2.0));
    return 0;
}
EOF

: > build/opened.txt
for cmd in "/usr/bin/gcc /work/t.c -o /work/t1 -lm" \
           "/usr/bin/gcc -O2 /work/t.c -o /work/t2 -lm" \
           "/usr/bin/g++ /work/t.cc -o /work/t3" \
           "/usr/bin/g++ -O2 /work/t.cc -o /work/t4"; do
    echo "== $cmd"
    # shellcheck disable=SC2086
    X86EMU_TRACE_OPEN=1 ./x86emu -r "$ROOT" $cmd 2>&1 |
        sed -n 's/^x86emu: open(\(.*\))$/\1/p' >> build/opened.txt || true
done
echo "== running what came out"
for p in /work/t1 /work/t2 /work/t3 /work/t4; do
    printf '%-10s ' "$p"
    X86EMU_TRACE_OPEN=1 ./x86emu -r "$ROOT" "$p" 2>> build/opened.raw |
        tail -1 || echo "(failed)"
done
sed -n 's/^x86emu: open(\(.*\))$/\1/p' build/opened.raw >> build/opened.txt 2>/dev/null || true

sort -u build/opened.txt > build/needed.txt
echo
echo "distinct files opened: $(wc -l < build/needed.txt)"
total=0
while IFS= read -r p; do
    f="$ROOT$p"
    [ -f "$f" ] || continue
    total=$((total + $(stat -c%s "$f")))
done < build/needed.txt
echo "their size: $(awk "BEGIN{printf \"%.1f MB\", $total/1048576}")"
echo "the whole tree: $(du -sh "$ROOT" | cut -f1)"
