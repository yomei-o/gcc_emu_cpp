#!/bin/sh
# Is an older gcc lighter?
#
# The measurement said the cost is parsing the standard library, not the size of
# the compiler - and an older libstdc++ is a smaller library.  C++11's <vector>
# is not C++20's.  So the question is worth an afternoon of downloads.
#
# Alpine keeps its old branches on the same mirror, so each one is a whole
# toolchain of that vintage:
#
#   v3.8   gcc 6.4     v3.12  gcc 9.3     v3.16  gcc 11.2   v3.19  gcc 13.2
#
#   sh tools/wslcompare.sh v3.8 v3.12 v3.19
set -e
cd "$(dirname "$0")/.."
[ -x ./x86emu ] || { echo "build the emulator first (sh build.sh)"; exit 1; }
BRANCHES=${*:-"v3.8 v3.12 v3.16 v3.19"}

for b in $BRANCHES; do
    root=build/cmp/$b
    if [ ! -d "$root/usr/bin" ]; then
        echo "== fetching $b"
        ALPINE_BRANCH=$b sh tools/fetch_alpine.sh "$root" > "build/cmp-$b.log" 2>&1 || {
            echo "  could not fetch $b - see build/cmp-$b.log"
            continue
        }
    fi
    mkdir -p "$root/work" "$root/tmp"

    # The unpacked packages are not a working toolchain on their own - the same
    # holes that cost this project an afternoon are in every branch.  Rather than
    # rediscover them per version, ask the loader: run gcc once and print what it
    # says is missing, so a failure here reads as "this branch needs X" instead
    # of "failed".
    if ! ./x86emu -r "$PWD/$root" /usr/bin/gcc --version > /dev/null 2>&1; then
        echo "  $b: gcc will not start:"
        ./x86emu -r "$PWD/$root" /usr/bin/gcc --version 2>&1 | head -4 | sed 's/^/    /'
        continue
    fi

    # The same two programs every time.  <iostream> and <vector> because those
    # are what the measurement pointed at.
    cat > "$root/work/t.c" <<'EOF'
#include <stdio.h>
#include <math.h>
int main(void) { printf("%f\n", sqrt(2.0)); return 0; }
EOF
    cat > "$root/work/t.cpp" <<'EOF'
#include <iostream>
#include <vector>
#include <algorithm>
int main() {
    std::vector<int> v{3, 1, 2};
    std::sort(v.begin(), v.end());
    std::cout << v[0] << v[1] << v[2] << std::endl;
    return 0;
}
EOF

    version=$(./x86emu -r "$PWD/$root" /usr/bin/gcc --version 2>/dev/null | head -1)
    cc1=$(find "$root/usr/libexec/gcc" -name cc1 2>/dev/null | head -1)
    cc1plus=$(find "$root/usr/libexec/gcc" -name cc1plus 2>/dev/null | head -1)
    printf '\n== %s  %s\n' "$b" "${version:-(gcc did not run)}"
    [ -n "$cc1" ] && printf '   cc1     %5.1f MB\n' "$(awk "BEGIN{print $(stat -c%s "$cc1")/1048576}")"
    [ -n "$cc1plus" ] && printf '   cc1plus %5.1f MB\n' "$(awk "BEGIN{print $(stat -c%s "$cc1plus")/1048576}")"

    for what in "C  gcc -O2:/usr/bin/gcc:-O2:/work/t.c:-lm" \
                "C++ g++ -O2:/usr/bin/g++:-O2:/work/t.cpp:"; do
        label=${what%%:*}; rest=${what#*:}
        prog=${rest%%:*}; rest=${rest#*:}
        opt=${rest%%:*}; rest=${rest#*:}
        src=${rest%%:*}; extra=${rest#*:}
        start=$(date +%s%N)
        # shellcheck disable=SC2086
        # shellcheck disable=SC2086
        if out=$(./x86emu -r "$PWD/$root" "$prog" "$opt" "$src" -o /work/a $extra 2>&1); then
            end=$(date +%s%N)
            printf '   %-14s %6.1f s\n' "$label" \
                "$(awk "BEGIN{print ($end - $start)/1000000000}")"
        else
            # Say why.  "failed" is what the first version of this printed, and
            # it turned a missing library into a mystery about old compilers.
            printf '   %-14s failed: %s\n' "$label" \
                "$(printf '%s' "$out" | grep -m1 -iE 'error|cannot|not found' | cut -c1-90)"
        fi
    done
done
