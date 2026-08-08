// Does MNIST work, and how big should it be?
//
// It has never been run.  The numbers in web/mnist.js - 4000 images, 3 epochs -
// were chosen before anything was timed, which is a guess wearing a constant's
// clothes.  This compiles it, runs it, and reports what it cost, so the guess
// can be replaced.
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import { execFileSync } from 'node:child_process';
import { gunzipSync } from 'node:zlib';
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
globalThis.emuOutput = (fd, b) => process.stdout.write(dec[fd].decode(b, { stream: true }));
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
mod.FS.chdir(SYSROOT + '/work');

// The project, out of the same file the page reads.
const { MNIST } = await import('./mnist.js');
for (const [name, text] of Object.entries(MNIST.files)) {
    mod.FS.writeFile(SYSROOT + '/work/' + name, new TextEncoder().encode(text));
}
for (const [name, url] of MNIST.data) {
    const host = path.join(here, url);
    if (!fs.existsSync(host)) {
        console.error(`no ${host} - run tools/fetch_mnist.sh`);
        process.exit(1);
    }
    mod.FS.writeFile(SYSROOT + '/work/' + name,
                     new Uint8Array(gunzipSync(fs.readFileSync(host))));
}

const run = mod.cwrap('emu_run', 'number', ['array', 'number', 'string', 'number']);
function time(label, argv) {
    const blob = new TextEncoder().encode(argv.join('\0') + '\0');
    const t = Date.now();
    const code = run(blob, blob.length - 1, '/work', 0);
    const seconds = (Date.now() - t) / 1000;
    console.error(`\n[${label}: ${seconds.toFixed(1)} s, exit ${code},` +
                  ` heap ${(mod.HEAPU8.length / 1048576).toFixed(0)} MB]`);
    return { code, seconds };
}

const built = time('compile', ['/usr/bin/g++', '-O2', '/work/main.cpp', '-o', '/work/mnist']);
if (built.code === 0) time('train', ['/work/mnist']);

fs.rmSync(tmp, { recursive: true, force: true });
