#!/bin/sh
# What interpreter each binary really names, from the program headers rather
# than from whatever string happens to come first.
cd "$(dirname "$0")/.."
ROOT=$PWD/build/alpine
for f in usr/bin/gcc usr/bin/g++ usr/bin/as usr/bin/ld \
         usr/libexec/gcc/x86_64-alpine-linux-musl/13.2.1/cc1; do
    [ -f "$ROOT/$f" ] || { echo "missing: $f"; continue; }
    printf '%-52s ' "$f"
    readelf -l "$ROOT/$f" 2>/dev/null |
        sed -n 's/.*Requesting program interpreter: \(.*\)\]/\1/p' |
        head -1 || echo '(static)'
done
echo
echo "== is the musl loader there, and is it a real file"
ls -lL "$ROOT/lib/ld-musl-x86_64.so.1" 2>&1
readelf -h "$ROOT/lib/ld-musl-x86_64.so.1" 2>&1 | sed -n 's/^  Type: */type /p;s/^  Machine: */machine /p'
