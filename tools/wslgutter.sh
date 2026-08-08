#!/bin/sh
# The line-count arithmetic behind the editor's gutter.
#
# The gutter itself needs a browser to check - whether it lines up is a question
# about fonts and padding.  What can be checked here is the one thing that is
# arithmetic rather than layout: how many numbers to draw.
#
# The case that motivates it is the trailing newline.  A file that ends in one
# has not started another line, and splitting on "\n" says it has.
set -e
cd "$(dirname "$0")/.."
NODE=$(ls "$HOME"/emsdk/node/*/bin/node 2>/dev/null | head -1)
[ -x "$NODE" ] || { echo "no node in emsdk"; exit 1; }

# The expression from renderGutter() in web/app.js, kept in step by hand: this
# is a check on the reasoning, not a substitute for reading the page.
"$NODE" -e '
const count = (v) => Math.max(v ? v.split("\n").length - (v.endsWith("\n") ? 1 : 0) : 1, 1);
const cases = [
    ["", 1], ["a", 1], ["a\n", 1], ["a\nb", 2], ["a\nb\n", 2],
    ["\n", 1], ["\n\n", 2], ["a\n\nb", 3],
];
let bad = 0;
for (const [v, want] of cases) {
    const got = count(v);
    if (got !== want) {
        console.log("  FAIL  " + JSON.stringify(v) + " -> " + got + ", want " + want);
        bad++;
    }
}
console.log(bad ? "  " + bad + " failed" : "  ok    line counting (" + cases.length + " cases)");
process.exit(bad ? 1 : 0);
'
