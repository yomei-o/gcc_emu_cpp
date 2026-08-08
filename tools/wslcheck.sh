#!/bin/sh
# Does the trimmed tree still compile and run C and C++?
#
# Trimming is where this breaks quietly: a missing header is a clear error, but
# a missing crt object or a default library the driver names is a link failure
# a long way from the file that was dropped.  So the trimmed tree gets the same
# four compiles as the whole one, and runs what they produce.
set -e
cd "$(dirname "$0")/.."
ROOT=${1:-$PWD/build/tree}
[ -x ./x86emu ] || { echo "build the emulator first"; exit 1; }
[ -d "$ROOT/usr/bin" ] || { echo "no tree at $ROOT - run tools/wslpayload.sh"; exit 1; }

mkdir -p "$ROOT/work" "$ROOT/tmp"
cat > "$ROOT/work/t.c" <<'EOF'
#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>
int main(void) { printf("C %f %s\n", sqrt(2.0), "ok"); return 0; }
EOF
cat > "$ROOT/work/t.cc" <<'EOF'
#include <cstdio>
#include <string>
#include <vector>
#include <map>
#include <algorithm>
#include <cmath>
#include <memory>
#include <sstream>
int main() {
    std::vector<int> v{3, 1, 2};
    std::sort(v.begin(), v.end());
    std::map<std::string, int> m{{"a", 1}};
    auto p = std::make_unique<int>(7);
    std::ostringstream os;
    os << "C++ " << v.size() << " " << m["a"] << " " << *p << " " << std::sqrt(2.0);
    std::printf("%s\n", os.str().c_str());
    return 0;
}
EOF

fail=0
run() {  # run <label> <command...>
    label=$1; shift
    if out=$(./x86emu -r "$ROOT" "$@" 2>&1); then
        printf '  ok    %s\n' "$label"
    else
        printf '  FAIL  %s\n' "$label"
        printf '%s\n' "$out" | tail -6 | sed 's/^/        /'
        fail=$((fail + 1))
    fi
}

echo "compiling"
run "gcc"      /usr/bin/gcc /work/t.c -o /work/t1 -lm
run "gcc -O2"  /usr/bin/gcc -O2 /work/t.c -o /work/t2 -lm
run "g++"      /usr/bin/g++ /work/t.cc -o /work/t3
run "g++ -O2"  /usr/bin/g++ -O2 /work/t.cc -o /work/t4

echo "running"
for p in /work/t1 /work/t2 /work/t3 /work/t4; do
    if out=$(./x86emu -r "$ROOT" "$p" 2>&1); then
        printf '  ok    %-10s %s\n' "$p" "$out"
    else
        printf '  FAIL  %-10s\n' "$p"
        printf '%s\n' "$out" | tail -4 | sed 's/^/        /'
        fail=$((fail + 1))
    fi
done

echo
[ "$fail" = 0 ] && echo "the trimmed tree works" || echo "$fail failed"
[ "$fail" = 0 ]
