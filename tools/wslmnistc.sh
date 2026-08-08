#!/bin/sh
# The C MNIST, compiled and run under the native emulator.
#
# The C++ one takes a minute to compile before it has done any arithmetic, which
# for a student wanting to see a network learn is a minute of nothing.  This is
# the same network in C: five seconds to compile, and the run is the same work.
set -e
cd "$(dirname "$0")/.."
ROOT=$PWD/build/tree
[ -x ./x86emu ] || { echo "build the emulator first"; exit 1; }
[ -d "$ROOT/usr/bin" ] || { echo "no tree - run tools/wslpayload.sh"; exit 1; }
mkdir -p "$ROOT/work"

NODE=$(ls "$HOME"/emsdk/node/*/bin/node 2>/dev/null | head -1)
[ -x "$NODE" ] || { echo "no node in emsdk"; exit 1; }
"$NODE" --input-type=module -e "
import { MNIST_C } from 'file://$PWD/web/mnist_c.js';
import fs from 'node:fs';
for (const [n, t] of Object.entries(MNIST_C.files)) fs.writeFileSync('$ROOT/work/' + n, t);
"

# The data, unpacked once.  web/data holds it gzipped, as distributed.
for pair in train-images:train-images-idx3-ubyte test-images:t10k-images-idx3-ubyte \
            train-labels:train-labels-idx1-ubyte test-labels:t10k-labels-idx1-ubyte; do
    out=${pair%%:*}; src=${pair#*:}
    [ -f "$ROOT/work/$out.idx" ] || gzip -dc "web/data/$src.gz" > "$ROOT/work/$out.idx"
done

echo "== compile"
start=$(date +%s)
./x86emu -r "$ROOT" /usr/bin/gcc -O2 -Wall /work/main.c -o /work/mnist -lm 2>&1 | tail -6
echo "   $(( $(date +%s) - start )) s"

echo "== run"
# From inside the project directory, because the emulator has no per-guest
# working directory: a relative fopen in the guest resolves against the host
# process's cwd.  The browser sets this with FS.chdir; here it is a `cd`.
start=$(date +%s)
EMU=$PWD/x86emu
( cd "$ROOT/work" && "$EMU" -r "$ROOT" /work/mnist ) 2>&1 | tail -24
echo "   $(( $(date +%s) - start )) s"
