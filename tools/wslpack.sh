#!/bin/sh
# Put the toolchain into the repository, twice, on purpose.
#
#   guest/tree/       the files themselves - what to edit, what to add a .so to,
#                     what a diff can show
#   guest/tree.tar.gz what the page fetches - one request instead of 3172
#
# Individual files because the tree will grow: another library, another header
# set, and git stores only what changed.  A tarball as well because 3172 requests
# is not how a page loads, and GitHub Pages serves what is committed - so it has
# to be committed rather than built on the way out.
#
# Regenerating the tarball writes a new 37 MB blob into history, so do it when
# the tree actually changes and not as a habit.
set -e
cd "$(dirname "$0")/.."
SRC=${1:-$PWD/build/tree}
[ -d "$SRC/usr/bin" ] || { echo "no tree at $SRC - run tools/wslpayload.sh"; exit 1; }

rm -rf guest/tree
mkdir -p guest
cp -a "$SRC" guest/tree
# The empty directories a guest expects to be able to write into.  git does not
# carry a directory, so the page makes them; these are here for the native runs.
mkdir -p guest/tree/tmp guest/tree/work

echo "== guest/tree"
find guest/tree -type f | wc -l | sed 's/^/  files: /'
du -sh guest/tree | sed 's/^/  size:  /'

echo "== guest/tree.tar.gz"
# Sorted and with a fixed timestamp, so that regenerating an unchanged tree
# produces an identical file and adds nothing to history.
tar --sort=name --mtime=@0 --owner=0 --group=0 --numeric-owner \
    -czf guest/tree.tar.gz -C guest/tree .
ls -l guest/tree.tar.gz | awk '{printf "  %.1f MB\n", $5/1048576}'
