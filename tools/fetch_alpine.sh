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
BRANCH=${ALPINE_BRANCH:-v3.19}
ARCH=x86_64
OUT=${1:-build/alpine}

mkdir -p build/apk "$OUT"

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
                     zlib zstd-libs libc-dev gmp mpfr4 mpc1 isl26
                     libgomp libatomic jansson"}

index=build/apk/APKINDEX.tar.gz
if [ ! -f "$index" ]; then
    echo "== index"
    curl -fsSL "$MIRROR/$BRANCH/main/$ARCH/APKINDEX.tar.gz" -o "$index"
fi
tar xzOf "$index" APKINDEX > build/apk/APKINDEX.txt

# The index is stanzas of `K:value`; P is the name and V the version, and the
# file is named "$P-$V.apk".
for p in $PKGS; do
    file=$(awk -v want="$p" '
        /^P:/ { name = substr($0, 3) }
        /^V:/ { if (name == want) { print name "-" substr($0, 3) ".apk"; exit } }
    ' build/apk/APKINDEX.txt)
    if [ -z "$file" ]; then
        echo "not in the index: $p"
        continue
    fi
    if [ ! -f "build/apk/$file" ]; then
        echo "== $file"
        curl -fsSL "$MIRROR/$BRANCH/main/$ARCH/$file" -o "build/apk/$file"
    fi
    tar xzf "build/apk/$file" -C "$OUT" 2>/dev/null || true
done

rm -f "$OUT/.PKGINFO" "$OUT/.SIGN"* 2>/dev/null || true
echo
du -sh "$OUT"
ls "$OUT/usr/bin" 2>/dev/null | head -20
