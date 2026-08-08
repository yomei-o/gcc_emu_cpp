#!/bin/sh
# The emulator, natively, for trying things without a browser in the way.
#
# The web build is web/build.sh; this one is what tools/wsltry.sh uses.
set -e
cd "$(dirname "$0")"
CXX=${CXX:-g++}
CXXFLAGS=${CXXFLAGS:--std=c++17 -O2 -Wall -Wextra}

echo "== x86emu"
mkdir -p build
$CXX $CXXFLAGS -Ix86_emu_cpp/src -o x86emu x86_emu_cpp/src/*.cpp
echo "done"
