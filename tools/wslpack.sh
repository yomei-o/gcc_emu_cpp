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

# Symlinks become copies.
#
# Two reasons, either of which would be enough: git on Windows cannot index one
# (`invalid argument`, on musl's libc.musl-x86_64.so.1), and untar.js cannot
# create one in MEMFS - so the browser would end up with the name and no file.
# The cost is a second copy of ld-musl (645 KB) and a few small ones, which gzip
# takes back.
# A link whose target is gone goes with it: tools/wslpayload.sh removes drivers
# this does not need, and `x86_64-alpine-linux-musl-cc` pointed at one of them.
# Left in place it is a name with nothing behind it, which git refuses to index
# and a guest would fail to execute.
find guest/tree -type l | while IFS= read -r link; do
    target=$(readlink -f "$link") || target=
    if [ -n "$target" ] && [ -f "$target" ]; then
        rm -f "$link"
        cp "$target" "$link"
    else
        rm -f "$link"
    fi
done
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
