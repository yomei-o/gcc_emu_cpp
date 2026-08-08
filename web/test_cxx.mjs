// Where the two minutes go.
//
// A C hello compiles in 6.6 s and a C++ one in 118 s, which is not a difference
// in the language.  The candidates are the size of what gets included, the size
// of cc1plus itself, and the optimiser - and they are told apart by compiling
// four things that differ in one of those at a time.
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
mod.ccall('emu_set_sysroot', null, ['string'], [SYSROOT]);

const run = mod.cwrap('emu_run', 'number', ['array', 'number', 'string', 'number']);
function time(argv) {
    const blob = new TextEncoder().encode(argv.join('\0') + '\0');
    const t = Date.now();
    const code = run(blob, blob.length - 1, '/work', 0);
    return { code, seconds: (Date.now() - t) / 1000 };
}
function write(name, text) {
    mod.FS.writeFile(SYSROOT + '/work/' + name, new TextEncoder().encode(text));
}

write('empty.c', 'int main(void) { return 0; }\n');
write('empty.cpp', 'int main() { return 0; }\n');
write('printf.cpp', '#include <cstdio>\nint main() { std::printf("x\\n"); return 0; }\n');
write('iostream.cpp',
    '#include <iostream>\nint main() { std::cout << "x" << std::endl; return 0; }\n');
write('vector.cpp',
    '#include <vector>\n#include <algorithm>\nint main() { std::vector<int> v{2,1}; std::sort(v.begin(), v.end()); return v[0]; }\n');

const cases = [
    ['C, 何も include しない',        ['/usr/bin/gcc', '-O0', '/work/empty.c', '-o', '/work/o']],
    ['C++, 何も include しない',      ['/usr/bin/g++', '-O0', '/work/empty.cpp', '-o', '/work/o']],
    ['C++, <cstdio> だけ',            ['/usr/bin/g++', '-O0', '/work/printf.cpp', '-o', '/work/o']],
    ['C++, <vector> <algorithm>',     ['/usr/bin/g++', '-O0', '/work/vector.cpp', '-o', '/work/o']],
    ['C++, <iostream>',               ['/usr/bin/g++', '-O0', '/work/iostream.cpp', '-o', '/work/o']],
    ['C++, <iostream>, -O2',          ['/usr/bin/g++', '-O2', '/work/iostream.cpp', '-o', '/work/o']],
    // -E stops after preprocessing, so this is the cost of *reading* the headers
    // with none of the compiling.
    ['C++, <iostream> を前処理だけ',  ['/usr/bin/g++', '-E', '/work/iostream.cpp', '-o', '/work/o.i']],
];

console.error('');
for (const [label, argv] of cases) {
    const r = time(argv);
    console.error(`  ${r.seconds.toFixed(1).padStart(6)} s  ${label}${r.code ? '  (失敗)' : ''}`);
}
try {
    const n = mod.FS.readFile(SYSROOT + '/work/o.i').length;
    console.error(`\n  <iostream> は前処理後 ${(n / 1024).toFixed(0)} KB になります`);
} catch (e) { /* the last case failed */ }
fs.rmSync(tmp, { recursive: true, force: true });
