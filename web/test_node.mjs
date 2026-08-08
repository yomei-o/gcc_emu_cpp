// The WebAssembly build, compiling and running C and C++, under node.
//
//   node web/test_node.mjs
//
// This goes through the same entry point the worker uses and stages the
// toolchain the same way the worker does - out of guest/tree.tar.gz rather than
// from the unpacked directory beside it.  Copying the unpacked tree would be
// easier and would test a path the page does not take; that shortcut has cost
// this author a day before.
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

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

// The tarball, unpacked into MEMFS - what the worker does, with node's tar
// standing in for untar.js.
const tarball = path.join(root, 'guest/tree.tar.gz');
if (!fs.existsSync(tarball)) {
    console.error(`no ${tarball} - run tools/wslpack.sh first`);
    process.exit(1);
}
console.error(`staging ${(fs.statSync(tarball).size / 1048576).toFixed(1)} MB`);
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'gccemu-'));
execFileSync('tar', ['xzf', tarball, '-C', tmp]);

function put(dir, base) {
    for (const name of fs.readdirSync(dir, { withFileTypes: true })) {
        const host = path.join(dir, name.name);
        const guest = base + '/' + name.name;
        if (name.isDirectory()) {
            mod.FS.mkdirTree(SYSROOT + guest);
            put(host, guest);
        } else if (name.isSymbolicLink()) {
            // MEMFS has symlinks, and musl's libc.so is one.
            try { mod.FS.symlink(fs.readlinkSync(host), SYSROOT + guest); } catch (e) { /* exists */ }
        } else {
            mod.FS.writeFile(SYSROOT + guest, new Uint8Array(fs.readFileSync(host)));
        }
    }
}
mod.FS.mkdirTree(SYSROOT);
put(tmp, '');
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
    console.error(`  ok    ${label} (${r.seconds.toFixed(1)} s)`);
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

fs.rmSync(tmp, { recursive: true, force: true });
console.error(failed ? `\n${failed} failed` : '\nthe WebAssembly build compiles and runs both');
process.exit(failed ? 1 : 0);
