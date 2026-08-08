// The compiler, off the main thread.
//
// Compiling takes seconds and running a student's program can take as long as
// the student wrote it to take, so neither happens where it would freeze the
// page.  The worker holds the toolchain - 105 MB of it - and the emulator, and
// keeps them across builds: staging that again per compile would cost more than
// the compile.
importScripts('untar.js');
importScripts('x86emu.js');

const SYSROOT = '/sysroot';
const WORK = '/work';

let Module = null;
let run = null;
let ready = false;

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

    status('ツールチェーンを取得しています (57 MB)');
    // Beside the tree it was made from, not in web/: the payload is not part of
    // the page, and tools/wslpack.sh puts both there together.
    const gz = await fetchBytes('../guest/tree.tar.gz', (got, total) =>
        post({ type: 'progress', done: got, total: total || 58 * 1024 * 1024 }));
    status('展開しています (105 MB)');
    // Straight into the sysroot: every path in the archive is already the path
    // the guest will use.
    untarBytes(await gunzip(gz), (name, data) => writeInto('/' + name, data));
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
    argv.push(...(opts && opts.flags ? opts.flags : ['-O2', '-Wall']));
    argv.push(...sources.map((f) => WORK + '/' + f));
    argv.push('-o', WORK + '/a.out');
    // -lm is free to name even when unused, and forgetting it is the most
    // common first error a student meets.
    argv.push('-lm');
    return { result: execute(argv), sources, compiler: argv[0] };
}

self.onmessage = async (e) => {
    const m = e.data;
    try {
        if (m.type === 'build' || m.type === 'run') {
            await start();
            stageProject(m.files);
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
            await start();
            post({ type: 'done' });
        }
    } catch (err) {
        post({ type: 'error', text: String(err && err.message ? err.message : err) });
        post({ type: 'done' });
    }
};
