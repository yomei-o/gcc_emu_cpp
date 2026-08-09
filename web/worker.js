// The compiler, off the main thread.
//
// Compiling takes seconds and running a student's program can take as long as
// the student wrote it to take, so neither happens where it would freeze the
// page.  The worker holds the toolchain - 194 MB of it - and the emulator, and
// keeps them across builds: staging that again per compile would cost more than
// the compile.
importScripts('untar.js');
importScripts('x86emu.js');

const SYSROOT = '/sysroot';
const WORK = '/work';

let Module = null;
let run = null;
let ready = false;
// The gzipped toolchain, if the page had one from a previous worker.
let carried = null;

const post = (msg, transfer) => self.postMessage(msg, transfer || []);
const status = (text) => post({ type: 'status', text });

// Guest bytes, decoded here rather than in C: a multi-byte character split
// across two writes has to be held over, and TextDecoder does that with
// {stream: true}.  One decoder per stream, because they interleave.
const decoders = { 1: new TextDecoder('utf-8'), 2: new TextDecoder('utf-8') };

async function fetchBytes(url, onProgress) {
    const res = await fetch(url);
    if (!res.ok) throw new Error(url + ': ' + res.status);
    if (!res.body) return new Uint8Array(await res.arrayBuffer());
    const total = Number(res.headers.get('content-length')) || 0;
    const reader = res.body.getReader();
    const chunks = [];
    let got = 0;
    for (;;) {
        const { done, value } = await reader.read();
        if (done) break;
        chunks.push(value);
        got += value.length;
        if (onProgress) onProgress(got, total);
    }
    const all = new Uint8Array(got);
    let at = 0;
    for (const c of chunks) { all.set(c, at); at += c.length; }
    return all;
}

async function gunzip(bytes) {
    const stream = new Blob([bytes]).stream().pipeThrough(new DecompressionStream('gzip'));
    return new Uint8Array(await new Response(stream).arrayBuffer());
}

function writeInto(path, data) {
    const full = SYSROOT + path;
    const dir = full.slice(0, full.lastIndexOf('/'));
    if (dir) Module.FS.mkdirTree(dir);
    Module.FS.writeFile(full, data);
}

async function start() {
    if (ready) return;
    if (!Module) {
        status('エミュレータを起動しています');
        Module = await createEmu();
        run = Module.cwrap('emu_run', 'number', ['array', 'number', 'string', 'number']);
        globalThis.emuOutput = (fd, bytes) => {
            const d = decoders[fd] || decoders[1];
            post({ type: 'out', fd, text: d.decode(bytes, { stream: true }) });
        };
        globalThis.emuLog = (line) => post({ type: 'out', fd: 2, text: '[emu] ' + line + '\n' });
        Module.ccall('emu_set_sysroot', null, ['string'], [SYSROOT]);
    }

    let gz = carried;
    if (gz) {
        // Handed over by the page, which kept it from the worker before this
        // one.  Stopping a run kills the worker, and re-downloading sixty
        // megabytes to punish someone for stopping an infinite loop is not a
        // design.
        status('ツールチェーンを用意しています');
    } else {
        status('ツールチェーンを取得しています (54 MB)');
        // Beside the tree it was made from, not in web/: the payload is not part
        // of the page, and tools/wslpack.sh puts both there together.
        gz = await fetchBytes('../guest/tree.tar.gz', (got, total) =>
            post({ type: 'progress', done: got, total: total || 54 * 1024 * 1024 }));
        // A copy for the page to keep.  postMessage would neuter the original if
        // it were transferred, and this one is about to be gunzipped.
        post({ type: 'carry', bytes: gz.slice().buffer });
    }
    status('展開しています (194 MB)');
    // Straight into the sysroot: every path in the archive is already the path
    // the guest will use.
    untarBytes(await gunzip(gz), (name, data, linkTo) => {
        if (!linkTo) { writeInto('/' + name, data); return; }
        // A hard link: the same bytes under another name.  gcc, g++ and c++ are
        // one file, and MEMFS has no way to share it - so it is copied from the
        // one already unpacked.
        const from = SYSROOT + '/' + linkTo.replace(/^\.\//, '');
        try {
            writeInto('/' + name, Module.FS.readFile(from));
        } catch (e) {
            post({ type: 'out', fd: 2,
                   text: `[emu] ${name}: ${linkTo} が見つかりません\n` });
        }
    });
    Module.FS.mkdirTree(SYSROOT + '/tmp');
    Module.FS.mkdirTree(SYSROOT + WORK);
    ready = true;
    status('準備完了');
}

// The project's files, as the guest will see them.  The whole directory is
// replaced rather than updated, so a file the student deleted is really gone.
function stageProject(files) {
    const dir = SYSROOT + WORK;
    // And "here" is that directory.
    //
    // A program that writes fopen("out.csv", "w") means "beside me", and without
    // this it meant "/" - the file was created, nothing failed, and the page,
    // which collects what appeared in /work, found nothing to plot.  Passing
    // /work to emu_run only ever set PWD in the guest's environment, which is
    // what a shell reads and not what the C library resolves against.
    try { Module.FS.mkdirTree(dir); } catch (e) { /* already there */ }
    Module.FS.chdir(dir);
    try {
        for (const name of Module.FS.readdir(dir)) {
            if (name === '.' || name === '..') continue;
            try { Module.FS.unlink(dir + '/' + name); } catch (e) { /* a directory */ }
        }
    } catch (e) { Module.FS.mkdirTree(dir); }
    const enc = new TextEncoder();
    for (const [name, content] of Object.entries(files)) {
        const data = typeof content === 'string' ? enc.encode(content)
                                                 : new Uint8Array(content);
        writeInto(WORK + '/' + name, data);
    }
}

// Data a project needs but does not carry: MNIST's twelve megabytes, which have
// no business in localStorage or in a project's own file list.
//
// Kept once and re-staged from here, so switching away and back does not fetch
// them again.  They are gzipped as distributed and unpacked on the way in.
const datasets = new Map();

async function stageData(list) {
    for (const [name, url] of list || []) {
        if (!datasets.has(url)) {
            status(`データを取得しています: ${name}`);
            const gz = await fetchBytes(url, (got, total) =>
                post({ type: 'progress', done: got, total: total || 12 * 1024 * 1024 }));
            datasets.set(url, await gunzip(gz));
        }
        writeInto(WORK + '/' + name, datasets.get(url));
    }
}

function execute(argv, cwd) {
    const blob = new TextEncoder().encode(argv.join('\0') + '\0');
    const started = Date.now();
    const code = run(blob, blob.length - 1, cwd || WORK, 0);
    return {
        code,
        seconds: (Date.now() - started) / 1000,
        instructions: Module.ccall('emu_instructions', 'number', [], []),
        error: code < 0 ? Module.ccall('emu_error', 'string', [], []) : '',
    };
}

// Compile every source in the project into one program.
//
// One command rather than compile-then-link: gcc drives the whole thing, and a
// student who has split their program into three files should not have to say
// so twice.
function build(files, opts) {
    const sources = Object.keys(files).filter((f) => /\.(c|cc|cpp|cxx)$/.test(f));
    if (!sources.length) throw new Error('コンパイルする .c / .cpp ファイルがありません');
    const cpp = sources.some((f) => /\.(cc|cpp|cxx)$/.test(f));
    const argv = [cpp ? '/usr/bin/g++' : '/usr/bin/gcc'];
    const flags = (opts && opts.flags) ? opts.flags : ['-O2', '-Wall'];
    argv.push(...flags);
    // The precompiled standard library, if these flags can use it.
    //
    // Parsing <vector>, <map>, <sstream> and the rest is 61 of a C++ compile's
    // 93 seconds and is identical for every program, so the toolchain carries
    // the answer: 81 s becomes 24 s.  -include puts it in front of the
    // student's first line, and their own #include <vector> then costs nothing.
    //
    // Only for -O2, and this is not a detail.  GCC declines a header whose
    // options do not match, says nothing about it, and re-reads the real ones -
    // having first read the 28 MB file it is about to reject.  Measured at
    // -O0 -g that is 72 s against 57 s without: passing it where it does not
    // apply is worse than not having it.
    if (cpp && flags.includes('-O2')) argv.push('-I/pch', '-include', 'std.hpp');
    argv.push(...sources.map((f) => WORK + '/' + f));
    argv.push('-o', WORK + '/a.out');
    // -lm is free to name even when unused, and forgetting it is the most
    // common first error a student meets.
    argv.push('-lm');
    echo(argv);
    return { result: execute(argv), sources, compiler: argv[0] };
}

// The command, the way it would be typed.
//
// A student should be able to see what the button does and, eventually, type it
// themselves somewhere else.  Paths are shown relative to the project, because
// /work is this page's arrangement and not something to learn.
function echo(argv) {
    const said = argv.map((a) => (a.startsWith(WORK + '/') ? a.slice(WORK.length + 1) : a))
                     .map((a) => (a.startsWith('/usr/bin/') ? a.slice('/usr/bin/'.length) : a));
    post({ type: 'out', fd: 1, text: '$ ' + said.join(' ') + '\n' });
}

self.onmessage = async (e) => {
    const m = e.data;
    try {
        if (m.type === 'build' || m.type === 'run') {
            if (m.carried && !carried) carried = new Uint8Array(m.carried);
            await start();
            stageProject(m.files);
            await stageData(m.data);
            if (m.type === 'build' || m.rebuild !== false) {
                // C++ is minutes rather than seconds, and a student who does not
                // know that assumes it has hung.  Saying so costs nothing and is
                // the difference between waiting and giving up.  See resume.md:
                // sixty of those seconds are cc1plus parsing the standard
                // library's templates, and the fix is in the emulator.
                const cpp = Object.keys(m.files).some((f) => /\.(cc|cpp|cxx)$/.test(f));
                status(cpp ? 'コンパイルしています - C++ は 1〜2 分かかります'
                           : 'コンパイルしています - 10 秒ほど');
                const { result, compiler } = build(m.files, m.opts);
                post({ type: 'built', ...result, compiler });
                if (result.code !== 0) { post({ type: 'done' }); return; }
            }
            if (m.type === 'run') {
                status('実行しています');
                echo(['./a.out', ...(m.args || [])]);
                const result = execute([WORK + '/a.out', ...(m.args || [])]);
                post({ type: 'ran', ...result });
                // Whatever the program wrote, so the page can offer it back -
                // a CSV to plot, for instance.
                const out = {};
                for (const name of Module.FS.readdir(SYSROOT + WORK)) {
                    if (name === '.' || name === '..' || name === 'a.out') continue;
                    if (name in m.files) continue;   // the student's own source
                    try {
                        const data = Module.FS.readFile(SYSROOT + WORK + '/' + name);
                        out[name] = data;
                    } catch (err) { /* a directory */ }
                }
                if (Object.keys(out).length) post({ type: 'produced', files: out });
            }
            post({ type: 'done' });
        } else if (m.type === 'prepare') {
            if (m.carried) carried = new Uint8Array(m.carried);
            await start();
            post({ type: 'done' });
        }
    } catch (err) {
        post({ type: 'error', text: String(err && err.message ? err.message : err) });
        post({ type: 'done' });
    }
};
