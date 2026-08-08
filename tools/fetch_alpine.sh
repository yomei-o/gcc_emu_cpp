#!/bin/sh
# Build a musl/Alpine C and C++ toolchain tree for the guest to run.
#
# Alpine rather than a glibc distribution: musl is one library instead of a
# dozen, its dynamic loader is one file, and the whole toolchain unpacks to a
# fraction of the size - which matters when the destination is a browser tab.
#
# The packages are ordinary .apk files, which are gzipped tars with a signature
# tacked on the front, so tar reads them directly and ignores what it does not
# understand.
set -e
cd "$(dirname "$0")/.."
MIRROR=${ALPINE_MIRROR:-https://dl-cdn.alpinelinux.org/alpine}
# gcc 6.4 rather than 13.2, because this is a teaching site and speed is the
# feature.  Measured, on a quiet machine, compiling the same two programs:
#
#     gcc 13.2   cc1plus 34.8 MB   C 6.8 s   C++ 79.4 s
#     gcc  9.3   cc1plus 21.8 MB   C 6.3 s   C++ 67.8 s
#     gcc  6.4   cc1plus 17.7 MB   C 5.4 s   C++ 59.0 s
#
# Twenty-six per cent for free, and C++14 instead of C++17 - which for an
# introduction is no loss at all.
#
# Note what the numbers also say: cc1plus is half the size and the compile is a
# quarter faster, so this is not where the time goes.  The emulator decoding
# every instruction afresh is, and that is the fix that matters (see resume.md).
BRANCH=${ALPINE_BRANCH:-v3.8}
ARCH=x86_64
OUT=${1:-build/alpine}

# Cached per branch, which is the whole point of naming a branch.  Sharing one
# cache made `sh tools/wslcompare.sh v3.8 v3.12 v3.19` download v3.19 once and
# then measure it three times, reporting gcc 13.2.1 for all three - a comparison
# that agreed with itself perfectly and said nothing.
APK=build/apk/$BRANCH
mkdir -p "$APK" "$OUT"

# What a compile needs, and nothing else.  gcc pulls in cc1; g++ pulls in
# cc1plus and the C++ headers; binutils is as and ld; musl-dev is the C headers
# and crt*.o; libgcc and libstdc++ are what the linked program will need.
# cc1 links against the arbitrary-precision libraries gcc does its constant
# folding with (gmp, mpfr, mpc) and against isl for the loop optimiser.  Leaving
# them out gets as far as running cc1 and no further: the loader reports several
# hundred missing symbols, which is what a real musl would do.
# ...and ld wants jansson, because Alpine's binutils is built with the JSON
# report option.  Each of these was found by running the thing and reading what
# the loader said was missing, which is faster than reading a dependency graph.
PKGS=${ALPINE_PKGS:-"gcc g++ binutils musl musl-dev libgcc libstdc++ libstdc++-dev
                     zlib zstd-libs libc-dev gmp mpc1
                     libgomp libatomic jansson"}

# isl is versioned in its package name and the version follows the branch: 3.19
# has isl26, 3.12 has isl22, 3.8 has isl.  Naming one of them works until the
# branch changes and then reports a missing libisl.so.15, which is a long way
# from "the package list is for a different Alpine".  So: whichever the index
# has.
ISL_CANDIDATES="isl26 isl25 isl24 isl23 isl22 isl21 isl"
# mpfr is versioned in its package name too, and the version follows the branch
# the same way isl's does.
MPFR_CANDIDATES="mpfr4 mpfr3 mpfr"

index=$APK/APKINDEX.tar.gz
if [ ! -f "$index" ]; then
    echo "== index"
    curl -fsSL "$MIRROR/$BRANCH/main/$ARCH/APKINDEX.tar.gz" -o "$index"
fi
tar xzOf "$index" APKINDEX > "$APK/APKINDEX.txt"

# Whichever isl this branch has.  Only the first that the index knows about,
# because taking them all puts two copies of the same library in the tree.
for isl in $ISL_CANDIDATES; do
    if grep -qx "P:$isl" "$APK/APKINDEX.txt"; then
        PKGS="$PKGS $isl"
        break
    fi
done
for mpfr in $MPFR_CANDIDATES; do
    if grep -qx "P:$mpfr" "$APK/APKINDEX.txt"; then
        PKGS="$PKGS $mpfr"
        break
    fi
done

# The index is stanzas of `K:value`; P is the name and V the version, and the
# file is named "$P-$V.apk".
for p in $PKGS; do
    file=$(awk -v want="$p" '
        /^P:/ { name = substr($0, 3) }
        /^V:/ { if (name == want) { print name "-" substr($0, 3) ".apk"; exit } }
    ' "$APK/APKINDEX.txt")
    if [ -z "$file" ]; then
        echo "not in the index: $p"
        continue
    fi
    if [ ! -f "$APK/$file" ]; then
        echo "== $file"
        curl -fsSL "$MIRROR/$BRANCH/main/$ARCH/$file" -o "$APK/$file"
    fi
    tar xzf "$APK/$file" -C "$OUT" 2>/dev/null || true
done

rm -f "$OUT/.PKGINFO" "$OUT/.SIGN"* 2>/dev/null || true
echo
du -sh "$OUT"
ls "$OUT/usr/bin" 2>/dev/null | head -20
