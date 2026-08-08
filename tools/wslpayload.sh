#!/bin/sh
# The tree the browser will carry.
#
# Built by removing rather than by selecting, which is the opposite of how this
# started and the result of getting it wrong three times.  A hand-written list of
# "what a compile needs" missed, in order: binutils' own libbfd (so nothing
# assembled), liblto_plugin.so (so nothing linked, with an error about a flag
# nobody typed), and Scrt1.o - which `crt*.o` does not match, because it begins
# with a capital S.
#
# Each of those was cheap to carry and expensive to be without, and none of them
# were guessable from the outside.  So: take everything, then drop the few things
# that are large and provably unused, checking after each with tools/wslcheck.sh.
set -e
cd "$(dirname "$0")/.."
SRC=$PWD/build/alpine
OUT=${1:-$PWD/build/tree}

rm -rf "$OUT"
mkdir -p "$(dirname "$OUT")"
cp -a "$SRC" "$OUT"

# Documentation, locales, man pages, and the package manager's own records.
# None of it is opened by a compile; all of it is megabytes.
rm -rf "$OUT/usr/share" "$OUT/usr/lib/apk" "$OUT/etc" "$OUT/var" "$OUT/sbin" 2>/dev/null || true

# lto1 is a second whole compiler - thirty megabytes - and runs only for -flto.
# liblto_plugin.so and lto-wrapper stay: the driver uses those on every link.
find "$OUT" -name 'lto1' -delete 2>/dev/null || true
# The other front ends' drivers, for languages this does not carry.
rm -f "$OUT"/usr/bin/gfortran "$OUT"/usr/bin/gccgo "$OUT"/usr/bin/gdc 2>/dev/null || true
# Build-time helpers.
find "$OUT" -name '*.la' -delete 2>/dev/null || true
find "$OUT" -name '*.py' -delete 2>/dev/null || true
rm -rf "$OUT"/usr/libexec/gcc/*/*/install-tools "$OUT"/usr/libexec/gcc/*/*/plugin 2>/dev/null || true

# The tools in usr/bin that a compile never runs.  Removed one at a time with
# tools/wslcheck.sh after each, which is the only way this has not broken
# something: gcc's driver runs cc1, as, collect2 and ld, and nothing else.
#
# The triplet-prefixed drivers are hard links to the same gcc and g++ - the same
# file under a second name, so dropping them costs nothing and saves 3.4 MB.
for t in dwp gprof gcov gcov-dump gcov-tool objdump objcopy readelf nm size \
         strings strip addr2line c++filt elfedit gp-archive gp-collect-app \
         gp-display-html gp-display-src gp-display-text ld.gold ld.bfd \
         x86_64-alpine-linux-musl-gcc x86_64-alpine-linux-musl-g++ \
         x86_64-alpine-linux-musl-c++ x86_64-alpine-linux-musl-gcc-13.2.1 \
         x86_64-alpine-linux-musl-ld x86_64-alpine-linux-musl-as \
         x86_64-alpine-linux-musl-ar x86_64-alpine-linux-musl-ranlib \
         x86_64-alpine-linux-musl-objdump x86_64-alpine-linux-musl-nm \
         x86_64-alpine-linux-musl-strip x86_64-alpine-linux-musl-readelf \
         x86_64-alpine-linux-musl-objcopy x86_64-alpine-linux-musl-addr2line \
         x86_64-alpine-linux-musl-c++filt x86_64-alpine-linux-musl-elfedit \
         x86_64-alpine-linux-musl-gprof x86_64-alpine-linux-musl-size \
         x86_64-alpine-linux-musl-strings x86_64-alpine-linux-musl-gcc-ar \
         x86_64-alpine-linux-musl-gcc-nm x86_64-alpine-linux-musl-gcc-ranlib \
         c89 c99 cpp gcc-ar gcc-nm gcc-ranlib; do
    rm -f "$OUT/usr/bin/$t" 2>/dev/null || true
done

mkdir -p "$OUT/tmp" "$OUT/work"

echo
du -sh "$OUT"
echo "the biggest of it:"
find "$OUT" -type f -size +1M -printf '%10s  %p\n' 2>/dev/null |
    sort -rn | head -10 | awk '{printf "%8.1f MB  %s\n", $1/1048576, $2}'
echo
printf 'as one gzipped tar: '
tar --sort=name --mtime=@0 --owner=0 --group=0 --numeric-owner \
    -czf - -C "$OUT" . | wc -c | awk '{printf "%.1f MB\n", $1/1048576}'
