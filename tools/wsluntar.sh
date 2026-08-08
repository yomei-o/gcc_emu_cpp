#!/bin/sh
# Unpack guest/tree.tar.gz the way the browser does, and check what came out.
#
# The browser test compiles a program, which is the right end-to-end check and
# takes four minutes.  This is the cheap one that would have caught the bug that
# got past it: every member of the archive is unpacked through web/untar.js and
# compared against the tree the archive was made from.
#
# What it looks for, in order of what has actually gone wrong:
#   - a file that came out empty when the original is not
#   - a file whose bytes differ from the original
#   - a name in the tree that never appeared at all
#
# The empty-file case is first because that is the shape the failures take.  A
# hard link read with a bad offset comes back with no target, is written as a
# zero-length regular file, and every later symptom is about something else:
# `unrecognised executable format`, or an assembler that does not know `--64`.
set -e
cd "$(dirname "$0")/.."
[ -f guest/tree.tar.gz ] || { echo "no guest/tree.tar.gz - run tools/wslpack.sh"; exit 1; }
NODE=$(ls "$HOME"/emsdk/node/*/bin/node 2>/dev/null | head -1)
[ -x "$NODE" ] || { echo "no node in emsdk"; exit 1; }

"$NODE" -e '
const fs = require("fs"), zlib = require("zlib"), path = require("path");
const untar = require("./web/untar.js");
const bytes = zlib.gunzipSync(fs.readFileSync("guest/tree.tar.gz"));

// The unpacked filesystem, as the browser would hold it.
const out = new Map();
let links = 0;
untar(bytes, (name, data, linkTo) => {
    const clean = name.replace(/^\.\//, "");
    if (!linkTo) { out.set(clean, Buffer.from(data)); return; }
    links++;
    const from = linkTo.replace(/^\.\//, "");
    const target = out.get(from);
    if (!target) throw new Error(clean + ": link to " + from + ", which is not unpacked yet");
    out.set(clean, target);
});

let empty = 0, differ = 0, missing = 0, checked = 0;
const walk = (dir) => {
    for (const e of fs.readdirSync(dir, {withFileTypes: true})) {
        const p = path.join(dir, e.name);
        if (e.isDirectory()) { walk(p); continue; }
        if (!e.isFile()) continue;
        const rel = path.relative("guest/tree", p).split(path.sep).join("/");
        const got = out.get(rel);
        const want = fs.readFileSync(p);
        checked++;
        if (got === undefined) {
            if (missing++ < 5) console.log("  MISSING  " + rel);
        } else if (got.length === 0 && want.length !== 0) {
            if (empty++ < 5) console.log("  EMPTY    " + rel + " (should be " + want.length + " bytes)");
        } else if (!got.equals(want)) {
            if (differ++ < 5) console.log("  DIFFERS  " + rel);
        }
    }
};
walk("guest/tree");

console.log("  " + checked + " files, " + links + " of them hard links");
const bad = empty + differ + missing;
if (bad) {
    console.log("  " + empty + " empty, " + differ + " different, " + missing + " missing");
    process.exit(1);
}
console.log("  ok    every file unpacks to its original bytes");
'
