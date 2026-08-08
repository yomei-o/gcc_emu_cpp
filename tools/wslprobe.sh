#!/bin/sh
# Which gcc is the emulator actually loading?
#
# The suspicion: the program is opened as a host path while everything the guest
# opens goes through the sysroot, so `/usr/bin/gcc` found *this machine's* gcc -
# a glibc binary, whose ld-linux was then looked for inside the Alpine tree.
cd "$(dirname "$0")/.."
ROOT=$PWD/build/alpine
echo "== as a guest path (what a guest would say)"
./x86emu -r "$ROOT" /usr/bin/gcc --version 2>&1 | head -3
echo
echo "== as a host path (what the emulator seems to want)"
./x86emu -r "$ROOT" "$ROOT/usr/bin/gcc" --version 2>&1 | head -5
echo
echo "== and this machine's own gcc, for comparison"
readelf -l /usr/bin/gcc 2>/dev/null |
    sed -n 's/.*Requesting program interpreter: \(.*\)\]/this host: \1/p' | head -1
