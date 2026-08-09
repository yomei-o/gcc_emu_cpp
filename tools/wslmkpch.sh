#!/bin/sh
# Build the precompiled header that ships with the toolchain.
#
# Parsing the standard library is 61 of a C++ compile's 93 seconds, and it is
# the same 61 seconds for every student and every program.  This does it once,
# here, and the result rides along in guest/tree.
#
#   28 MB on disk, 4.4 MB in the gzipped tarball - which is the number that
#   matters, and is 8 % on top of the 54 MB download for a compile that goes
#   from 81 s to 24 s.  An earlier look at this compared the 28 MB against the
#   *compressed* download and dismissed it.
#
# Built with -O2 because that is what the page compiles with.  GCC declines a
# PCH whose options do not match and says nothing when it does - see
# tools/wslpchflags.sh, which times each of the page's three settings so that a
# decline shows up as a clock rather than as silence.
set -e
cd "$(dirname "$0")/.."
ROOT=${1:-$PWD/build/tree}
[ -x ./x86emu ] || { echo "build the emulator first: sh build.sh"; exit 1; }
[ -d "$ROOT/usr/bin" ] || { echo "no tree at $ROOT - run tools/wslpayload.sh"; exit 1; }
mkdir -p "$ROOT/pch" "$ROOT/tmp"

# What a student is likely to include, and nothing exotic: every header here
# costs build time once and download size forever.
cat > "$ROOT/pch/std.hpp" <<'EOF'
// Precompiled and shipped: see tools/wslmkpch.sh.
//
// The page passes -include std.hpp to every C++ build, so a program gets these
// whether it asks or not.  Its own #include <vector> then costs nothing - the
// include guard is already defined.
#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <iostream>
#include <map>
#include <memory>
#include <numeric>
#include <set>
#include <sstream>
#include <string>
#include <vector>
EOF

rm -rf "$ROOT/tmp"; mkdir -p "$ROOT/tmp"
rm -f "$ROOT/pch/std.hpp.gch"
echo "== building (a few minutes, once)"
start=$(date +%s)
./x86emu -r "$ROOT" /usr/bin/g++ -O2 -x c++-header /pch/std.hpp -o /pch/std.hpp.gch
echo "   $(( $(date +%s) - start )) s"
ls -l "$ROOT/pch/std.hpp.gch" | awk '{printf "   %.1f MB on disk\n", $5/1048576}'
gzip -9 -c "$ROOT/pch/std.hpp.gch" | wc -c | awk '{printf "   %.1f MB gzipped\n", $1/1048576}'
