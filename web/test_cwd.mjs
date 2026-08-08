// Where does a program's fopen("x.csv", "w") actually put the file?
//
// The graph tab found nothing to plot after the Newton example ran, and that
// example writes its CSV with a relative path.  The page collects what appeared
// in /work; if the guest's idea of "here" is somewhere else, the file exists and
// nobody can see it.
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
globalThis.emuOutput = (fd, b) => process.stderr.write(dec[fd].decode(b, { stream: true }));
globalThis.emuLog = () => {};

const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'gccemu-'));
execFileSync('tar', ['xzf', path.join(root, 'guest/tree.tar.gz'), '-C', tmp]);
function put(dir, base) {
    for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
        const host = path.join(dir, e.name), guest = base + '/' + e.name;
        if (e.isDirectory()) { mod.FS.mkdirTree(SYSROOT + guest); put(host, guest); }
        else mod.FS.writeFile(SYSROOT + guest, new Uint8Array(fs.readFileSync(host)));
    }
}
mod.FS.mkdirTree(SYSROOT);
put(tmp, '');
mod.FS.mkdirTree(SYSROOT + '/tmp');
mod.FS.mkdirTree(SYSROOT + '/work');
mod.ccall('emu_set_sysroot', null, ['string'], [SYSROOT]);

const run = mod.cwrap('emu_run', 'number', ['array', 'number', 'string', 'number']);
const exec = (argv) => {
    const blob = new TextEncoder().encode(argv.join('\0') + '\0');
    return run(blob, blob.length - 1, '/work', 0);
};

mod.FS.writeFile(SYSROOT + '/work/w.c', new TextEncoder().encode(`#include <stdio.h>
int main(void) {
    FILE* f = fopen("out.csv", "w");
    if (!f) { printf("fopen に失敗\\n"); return 1; }
    fprintf(f, "a,b\\n1,2\\n");
    fclose(f);
    printf("書きました\\n");
    return 0;
}
`));

console.error('\n== compile');
exec(['/usr/bin/gcc', '-O0', '/work/w.c', '-o', '/work/w']);

// Where the emscripten filesystem thinks "here" is when the guest runs.
console.error('== the module cwd is', mod.FS.cwd());
console.error('== run');
exec(['/work/w']);

const look = (dir) => {
    try {
        return mod.FS.readdir(dir).filter((n) => n !== '.' && n !== '..').join(' ');
    } catch (e) { return '(none)'; }
};
console.error('\nafter, with the cwd left alone:');
console.error('  /sysroot/work :', look(SYSROOT + '/work'));
console.error('  /sysroot      :', look(SYSROOT));
console.error('  /             :', look('/'));

// And again, having told the filesystem where the program is running.
console.error('\n== again, after FS.chdir to the project directory');
mod.FS.chdir(SYSROOT + '/work');
try { mod.FS.unlink(SYSROOT + '/work/out.csv'); } catch (e) {}
exec(['/work/w']);
console.error('  /sysroot/work :', look(SYSROOT + '/work'));

fs.rmSync(tmp, { recursive: true, force: true });
