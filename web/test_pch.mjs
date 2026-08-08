// Does a precompiled header buy back the minute?
//
// The measurement said where the time goes: preprocessing <iostream> costs 17
// seconds and the other sixty are spent parsing the 808 KB that comes out.  A
// precompiled header is exactly a saved copy of that parse, so it should remove
// the sixty and leave the rest.
//
// Whether it does is a question about gcc's PCH machinery under an emulator,
// which is not obviously going to behave - the file is a memory image with
// addresses in it, and gcc is fussy about the flags matching.
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
globalThis.emuOutput = (fd, bytes) => process.stderr.write(dec[fd].decode(bytes, { stream: true }));
globalThis.emuLog = () => {};

const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'gccemu-'));
execFileSync('tar', ['xzf', path.join(root, 'guest/tree.tar.gz'), '-C', tmp]);
function put(dir, base) {
    for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
        const host = path.join(dir, e.name), guest = base + '/' + e.name;
        if (e.isDirectory()) { mod.FS.mkdirTree(SYSROOT + guest); put(host, guest); }
        else if (e.isSymbolicLink()) {
            try { mod.FS.symlink(fs.readlinkSync(host), SYSROOT + guest); } catch (x) {}
        } else mod.FS.writeFile(SYSROOT + guest, new Uint8Array(fs.readFileSync(host)));
    }
}
mod.FS.mkdirTree(SYSROOT);
put(tmp, '');
mod.FS.mkdirTree(SYSROOT + '/tmp');
mod.FS.mkdirTree(SYSROOT + '/work');
mod.FS.mkdirTree(SYSROOT + '/pch');
mod.ccall('emu_set_sysroot', null, ['string'], [SYSROOT]);

const run = mod.cwrap('emu_run', 'number', ['array', 'number', 'string', 'number']);
function time(label, argv) {
    const blob = new TextEncoder().encode(argv.join('\0') + '\0');
    const t = Date.now();
    const code = run(blob, blob.length - 1, '/work', 0);
    const seconds = (Date.now() - t) / 1000;
    console.error(`  ${seconds.toFixed(1).padStart(6)} s  ${label}${code ? '  (失敗)' : ''}`);
    return { code, seconds };
}
const write = (p, text) => mod.FS.writeFile(SYSROOT + p, new TextEncoder().encode(text));

// What a student is likely to include.  One header that includes the others, so
// a program says `#include "std.hpp"` - or says nothing, because -include puts
// it in without being asked.
write('/pch/std.hpp', `#pragma once
#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <iostream>
#include <map>
#include <memory>
#include <numeric>
#include <set>
#include <sstream>
#include <string>
#include <vector>
`);
write('/work/hello.cpp', `#include <iostream>
#include <vector>
#include <algorithm>
int main() {
    std::vector<int> v{3, 1, 2};
    std::sort(v.begin(), v.end());
    std::cout << "C++ " << v[0] << v[1] << v[2] << std::endl;
    return 0;
}
`);

console.error('\n== いまの姿');
time('g++ -O2, PCH なし', ['/usr/bin/g++', '-O2', '/work/hello.cpp', '-o', '/work/a']);

console.error('\n== PCH を作る (一度きり、ツールチェーンに同梱できる)');
// gcc finds `std.hpp.gch` beside `std.hpp` on its own.  The flags have to match
// the ones the student's compile uses, or it is silently ignored - which is the
// failure mode to watch for.
const made = time('g++ -O2 -x c++-header std.hpp',
    ['/usr/bin/g++', '-O2', '-x', 'c++-header', '/pch/std.hpp', '-o', '/pch/std.hpp.gch']);

if (made.code === 0) {
    const n = mod.FS.readFile(SYSROOT + '/pch/std.hpp.gch').length;
    console.error(`  できた .gch は ${(n / 1048576).toFixed(1)} MB`);

    console.error('\n== それを使う');
    // -Winvalid-pch says so out loud when the header is there but unusable,
    // which otherwise looks exactly like it working and being no faster.
    time('g++ -O2 -include std.hpp',
        ['/usr/bin/g++', '-O2', '-Winvalid-pch', '-I/pch', '-include', 'std.hpp',
         '/work/hello.cpp', '-o', '/work/b']);
}

fs.rmSync(tmp, { recursive: true, force: true });
