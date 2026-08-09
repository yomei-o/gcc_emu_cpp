#!/bin/sh
# Build ./x86emu.before from the *committed* emulator in the sibling checkout.
#
#   sh tools/wslbaseline.sh
#
# What it is for: an A/B needs a baseline that is one change away from what is
# being measured, and copying "whatever ./x86emu happens to be" is not that.
# The last attempt at this compared a two-changes-old binary against the
# current source and would have credited one change with both.
#
# ../x86_emu_cpp/src is the merge point, so its committed state is exactly
# "everything accepted so far" - which is the baseline any new experiment wants.
set -e
cd "$(dirname "$0")/.."
SRC=${1:-../x86_emu_cpp}
CXX=${CXX:-$HOME/gpp/bin/g++}
[ -x "$CXX" ] || { echo "no g++ at $CXX"; exit 1; }
[ -d "$SRC/src" ] || { echo "no emulator source at $SRC/src"; exit 1; }

dirty=$(cd "$SRC" && git status --porcelain src/ 2>/dev/null | head -3)
if [ -n "$dirty" ]; then
    echo "  $SRC/src has uncommitted changes - the baseline would include them:"
    printf '    %s\n' $dirty
    echo "  commit or stash there first."
    exit 1
fi

echo "== building the baseline from $SRC ($(cd "$SRC" && git rev-parse --short HEAD))"
$CXX -std=c++17 -O2 -Wall -I"$SRC/src" -o x86emu.before "$SRC"/src/*.cpp
ls -l x86emu.before | awk '{printf "   %.1f MB\n", $5/1048576}'
