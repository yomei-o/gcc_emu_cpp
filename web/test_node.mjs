// The WebAssembly build, compiling and running C and C++, under node.
//
//   node web/test_node.mjs
//
// This goes through the same entry point the worker uses and stages the
// toolchain the same way the worker does - out of guest/tree.tar.gz, through
// web/untar.js, into MEMFS.  Copying the unpacked tree would be easier and
// would test a path the page does not take; that shortcut has cost this author
// a day before.
//
// It used to unpack with node's `tar` here, which is the same shortcut wearing
// a different hat: `tar` is not what the browser runs.  untar.js was reading a
// hard link's target from the wrong offset and writing an empty file, and this
// test could not have seen it - it passed, twice, while the page it stands for
// could not execute g++.
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import fs from 'node:fs';
import path from 'node:path';
import zlib from 'node:zlib';

const require = createRequire(import.meta.url);
const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.join(here, '..');
const createEmu = require(path.join(here, 'x86emu.js'));

const SYSROOT = '/sysroot';
const mod = await createEmu();

const dec = { 1: new TextDecoder('utf-8'), 2: new TextDecoder('utf-8') };
let captured = '';
globalThis.emuOutput = (fd, bytes) => {
    const text = dec[fd].decode(bytes, { stream: true });
    captured += text;
    process.stdout.write(text);
};
globalThis.emuLog = (line) => console.error('[emu]', line);

// The tarball, unpacked into MEMFS - the worker's own untar.js, the worker's
// own hard-link handling.
const untarBytes = require(path.join(here, 'untar.js'));
const tarball = path.join(root, 'guest/tree.tar.gz');
if (!fs.existsSync(tarball)) {
    console.error(`no ${tarball} - run tools/wslpack.sh first`);
    process.exit(1);
}
console.error(`staging ${(fs.statSync(tarball).size / 1048576).toFixed(1)} MB`);

function writeInto(p, data) {
    const full = SYSROOT + p;
    const dir = full.slice(0, full.lastIndexOf('/'));
    if (dir) mod.FS.mkdirTree(dir);
    mod.FS.writeFile(full, data);
}

mod.FS.mkdirTree(SYSROOT);
untarBytes(zlib.gunzipSync(fs.readFileSync(tarball)), (name, data, linkTo) => {
    if (!linkTo) { writeInto('/' + name, data); return; }
    const from = SYSROOT + '/' + linkTo.replace(/^\.\//, '');
    writeInto('/' + name, mod.FS.readFile(from));
});
mod.FS.mkdirTree(SYSROOT + '/tmp');
mod.FS.mkdirTree(SYSROOT + '/work');
mod.ccall('emu_set_sysroot', null, ['string'], [SYSROOT]);

const run = mod.cwrap('emu_run', 'number', ['array', 'number', 'string', 'number']);
function exec(argv) {
    const blob = new TextEncoder().encode(argv.join('\0') + '\0');
    const started = Date.now();
    const code = run(blob, blob.length - 1, '/work', 0);
    return {
        code,
        seconds: (Date.now() - started) / 1000,
        error: code < 0 ? mod.ccall('emu_error', 'string', [], []) : '',
    };
}

function write(name, text) {
    mod.FS.writeFile(SYSROOT + '/work/' + name, new TextEncoder().encode(text));
}

let failed = 0;
function check(label, argv, want) {
    captured = '';
    const r = exec(argv);
    if (r.code !== 0) {
        console.error(`  FAIL  ${label}: exit ${r.code} ${r.error}`);
        failed++;
        return false;
    }
    if (want && !captured.includes(want)) {
        console.error(`  FAIL  ${label}: expected ${JSON.stringify(want)}`);
        failed++;
        return false;
    }
    // How far the heap grew.  A browser will refuse to grow a wasm32 memory
    // somewhere between one and four gigabytes depending on which browser it is,
    // and the failure is an abort with nothing readable in it - so the number
    // matters as much as the seconds.
    console.error(`  ok    ${label} (${r.seconds.toFixed(1)} s,` +
                  ` heap ${(mod.HEAPU8.length / 1048576).toFixed(0)} MB)`);
    return true;
}

write('hello.c', `#include <stdio.h>
#include <math.h>
int main(void) { printf("C %.4f\\n", sqrt(2.0)); return 0; }
`);
write('hello.cpp', `#include <iostream>
#include <vector>
#include <algorithm>
int main() {
    std::vector<int> v{3, 1, 2};
    std::sort(v.begin(), v.end());
    std::cout << "C++ " << v[0] << v[1] << v[2] << std::endl;
    return 0;
}
`);

console.error('compiling');
check('gcc', ['/usr/bin/gcc', '-O2', '-Wall', '/work/hello.c', '-o', '/work/a.out', '-lm']);
console.error('running');
check('a.out', ['/work/a.out'], 'C 1.4142');
console.error('compiling C++');
check('g++', ['/usr/bin/g++', '-O2', '-Wall', '/work/hello.cpp', '-o', '/work/b.out']);
console.error('running');
check('b.out', ['/work/b.out'], 'C++ 123');

// And again with the precompiled header the toolchain now carries, which is
// what web/worker.js passes for a -O2 C++ build.  Both times, because the
// number worth having is the pair: the header is 4.6 MB of everyone's download
// and it has to earn that here, in WebAssembly, not only under the native
// emulator where it was first measured.
//
// The same program, so the answer must not change - a faster compile that
// produces something different is not a faster compile.
console.error('compiling C++ with the precompiled header');
check('g++ +pch', ['/usr/bin/g++', '-O2', '-Wall', '-I/pch', '-include', 'std.hpp',
                   '/work/hello.cpp', '-o', '/work/c.out']);
console.error('running');
check('c.out', ['/work/c.out'], 'C++ 123');

// Nothing to clean up: the archive goes straight from memory into MEMFS, and
// MEMFS goes away with the process.
console.error(failed ? `\n${failed} failed` : '\nthe WebAssembly build compiles and runs both');
process.exit(failed ? 1 : 0);
