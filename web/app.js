// The page: files on the left, an editor in the middle, output and a graph on
// the right.  Everything slow happens in the worker; this only moves text
// around and decides what to show.
import { PROJECTS } from './projects.js';
import { MNIST } from './mnist.js';
import { MNIST_C } from './mnist_c.js';
import * as store from './store.js';
import { parseCsv, chartCode, draw, CHART_TYPES } from './chart.js';
import { makeZip, readZip } from './zip.js';

const $ = (id) => document.getElementById(id);
const TEMPLATES = { ...PROJECTS, 'mnist-c': MNIST_C, mnist: MNIST };

let worker = null;
let project = null;      // { name, template, files, produced }
let current = null;      // the file being edited
let busy = false;
let saveTimer = null;
// The gzipped toolchain, kept by the page so that stopping a run - which kills
// the worker - does not also throw away sixty megabytes that were already
// downloaded.
let carried = null;

// ---------------------------------------------------------------- the worker

function ensureWorker() {
    if (worker) return worker;
    worker = new Worker('worker.js');

    worker.onerror = (e) => {
        say('ワーカーが停止しました: ' + (e.message || 'メモリ不足かもしれません'), true);
        worker = null;
        setBusy(false);
    };
    worker.onmessage = (e) => {
        const m = e.data;
        if (m.type === 'status') $('statustext').textContent = m.text;
        else if (m.type === 'progress') {
            $('bar').hidden = false;
            $('bar').max = m.total || 1;
            $('bar').value = m.done || 0;
        } else if (m.type === 'out') say(m.text, m.fd === 2);
        else if (m.type === 'error') say(m.text + '\n', true);
        else if (m.type === 'built') {
            $('bar').hidden = true;
            if (m.code === 0) {
                say(`— コンパイル成功 (${m.seconds.toFixed(1)} 秒)\n`);
            } else if (m.code < 0) {
                say(`— コンパイルできませんでした: ${m.error}\n`, true);
            } else {
                say(`— コンパイル失敗 (終了コード ${m.code})\n`, true);
            }
        } else if (m.type === 'ran') {
            say(`— 終了コード ${m.code} (${m.seconds.toFixed(1)} 秒)\n`);
        } else if (m.type === 'produced') {
            project.produced = m.files;
            renderOutputs();
            refreshCsvChoices();
        } else if (m.type === 'carry') {
            carried = m.bytes;
        } else if (m.type === 'done') {
            setBusy(false);
            $('statustext').textContent = '';
            $('bar').hidden = true;
        }
    };
    // Handed over once, when the worker is created: postMessage copies rather
    // than moves, and copying sixty megabytes before every compile would cost
    // more than the download it saves.
    worker.postMessage({ type: 'prepare', carried });
    return worker;
}

// The same thing, said out loud at start-up: the toolchain is what the student
// is about to want, and fetching it now rather than when they press the button
// is most of the wait gone.
function prepareWorker() { ensureWorker(); }

// The spinner, and a clock beside it.
//
// A C++ compile is two minutes during which nothing at all happens on screen,
// and a page that shows nothing is indistinguishable from a page that has died.
// The spinner says something is running; the seconds say how long, which is what
// tells a student whether to keep waiting.
let ticking = null;

function setBusy(on) {
    busy = on;
    $('run').disabled = on;
    $('run').textContent = on ? '実行中…' : 'ビルドして実行';
    $('stop').hidden = !on;
    $('spin').hidden = !on;

    clearInterval(ticking);
    if (on) {
        const started = Date.now();
        const tick = () => {
            const s = (Date.now() - started) / 1000;
            $('elapsed').textContent = s < 60
                ? `${s.toFixed(0)} 秒`
                : `${Math.floor(s / 60)} 分 ${(s % 60).toFixed(0).padStart(2, '0')} 秒`;
        };
        tick();
        ticking = setInterval(tick, 1000);
    } else {
        $('elapsed').textContent = '';
    }
}

// Stopping means killing the worker.
//
// There is no gentler way here.  emu_run is one synchronous call into
// WebAssembly, so a message asking it to stop would not be read until it had
// already finished; a shared flag would need SharedArrayBuffer, which needs
// COOP/COEP headers, which GitHub Pages does not send.  So: terminate.
//
// The cost is real and is stated rather than hidden - the next run stages the
// 105 MB toolchain again, which is ten to twenty seconds.  An infinite loop that
// cannot be stopped is worse.
function stopEverything() {
    if (!worker) return;
    worker.terminate();
    worker = null;
    say('\n— 中断しました。次の実行はツールチェーンの用意からやり直します\n', true);
    setBusy(false);
    $('statustext').textContent = '';
    $('bar').hidden = true;
}

function say(text, isError) {
    const el = $('console');
    if (isError) {
        const span = document.createElement('span');
        span.className = 'err';
        span.textContent = text;
        el.appendChild(span);
    } else if (text.startsWith('$ ')) {
        // The command being run, marked out from what it prints.
        const span = document.createElement('span');
        span.className = 'cmd';
        span.textContent = text;
        el.appendChild(span);
    } else {
        el.appendChild(document.createTextNode(text));
    }
    el.parentElement.scrollTop = el.parentElement.scrollHeight;
}

// ---------------------------------------------------------------- projects

function templateFiles(name) {
    const t = TEMPLATES[name];
    return t ? { ...t.files } : {};
}

function openTemplate(key) {
    const t = TEMPLATES[key];
    project = { name: t.title, template: key, files: { ...t.files }, produced: {} };
    afterOpen();
}

function openSaved(name) {
    const template = store.templateOf(name);
    const loaded = store.load(name, templateFiles(template));
    project = { name, template, files: loaded.files, produced: {} };
    afterOpen();
}

function afterOpen() {
    current = Object.keys(project.files).find((f) => /\.(c|cc|cpp|cxx)$/.test(f)) ||
              Object.keys(project.files)[0] || null;
    $('console').textContent = '';
    outputSaved = null;
    $('viewing').hidden = true;
    renderFiles();
    renderOutputs();
    showFile(current);
    refreshCsvChoices();
    localStorage.setItem('gccemu.last', project.name);
}

// The list of projects, rebuilt only when it has actually changed.
//
// Saving happens on a timer after every keystroke, and saving used to rebuild
// this - so the dropdown was being replaced underneath whoever had just opened
// it, and switching projects was impossible.  The signature is what the list
// would look like; if that has not moved, only the number below it is updated.
let projectsShown = '';

function renderProjects() {
    const sel = $('project');
    const saved = store.listSaved();

    const u = store.usage();
    $('usage').textContent =
        `${(u.bytes / 1024).toFixed(0)} KB / ${(u.limit / 1048576).toFixed(0)} MB`;

    const want = project
        ? (saved.some((s) => s.name === project.name) ? 'saved:' + project.name
                                                      : 'tpl:' + project.template)
        : '';
    const signature = Object.keys(TEMPLATES).join('|') + '//' +
                      saved.map((s) => s.name).join('|') + '//' + want;
    if (signature === projectsShown) return;
    projectsShown = signature;

    sel.innerHTML = '';
    const g1 = document.createElement('optgroup');
    g1.label = 'お手本';
    for (const [key, t] of Object.entries(TEMPLATES)) {
        const o = document.createElement('option');
        o.value = 'tpl:' + key;
        o.textContent = t.title;
        g1.appendChild(o);
    }
    sel.appendChild(g1);
    if (saved.length) {
        const g2 = document.createElement('optgroup');
        g2.label = '保存したもの';
        for (const s of saved) {
            const o = document.createElement('option');
            o.value = 'saved:' + s.name;
            o.textContent = s.name;
            g2.appendChild(o);
        }
        sel.appendChild(g2);
    }
    if ([...sel.options].some((o) => o.value === want)) sel.value = want;
}

// ---------------------------------------------------------------- files

function renderFiles() {
    const box = $('files');
    box.innerHTML = '';
    for (const name of Object.keys(project.files).sort()) {
        const row = document.createElement('div');
        row.className = 'file' + (name === current ? ' on' : '');
        const label = document.createElement('span');
        label.textContent = name;
        row.appendChild(label);
        const x = document.createElement('span');
        x.className = 'x';
        x.textContent = '×';
        x.title = '削除';
        x.onclick = (e) => {
            e.stopPropagation();
            if (!confirm(name + ' を削除しますか')) return;
            delete project.files[name];
            if (current === name) current = Object.keys(project.files)[0] || null;
            renderFiles();
            showFile(current);
            scheduleSave();
        };
        row.appendChild(x);
        row.onclick = () => { stash(); current = name; renderFiles(); showFile(name); };
        box.appendChild(row);
    }
}

function renderOutputs() {
    const box = $('outputs');
    box.innerHTML = '';
    const produced = project.produced || {};
    if (!Object.keys(produced).length) {
        const p = document.createElement('div');
        p.className = 'note';
        p.style.padding = '.2rem .7rem';
        p.textContent = 'まだありません';
        box.appendChild(p);
        return;
    }
    for (const name of Object.keys(produced).sort()) {
        const row = document.createElement('div');
        row.className = 'file';
        const label = document.createElement('span');
        label.textContent = name;
        row.appendChild(label);
        const d = document.createElement('span');
        d.className = 'x';
        d.textContent = '⤓';
        d.title = 'ダウンロード';
        d.onclick = (e) => {
            e.stopPropagation();
            saveAs(name, new Blob([produced[name]]));
        };
        row.appendChild(d);
        row.onclick = () => {
            // Text is worth showing; anything else is only worth downloading.
            const bytes = produced[name];
            const text = new TextDecoder('utf-8', { fatal: false }).decode(bytes);
            if (/[\x00-\x08\x0e-\x1f]/.test(text.slice(0, 400))) {
                say(`${name}: ${bytes.length} バイトのバイナリです\n`);
            } else {
                showFileInConsole(name, text);
            }
            showPane('out');
        };
        box.appendChild(row);
    }
}

// Showing a produced file where the output was, and being able to go back.
//
// It used to overwrite the console, and the run's output - the compiler's
// diagnostics, whatever the program printed - was gone until it was run again.
// The nodes are kept rather than the text, because errors and command lines are
// coloured spans and re-rendering them from a string would lose that.
let outputSaved = null;

function showFileInConsole(name, text) {
    const el = $('console');
    if (!outputSaved) outputSaved = [...el.childNodes];
    el.textContent = text;
    $('viewing').hidden = false;
    $('viewing-name').textContent = name;
}

function backToOutput() {
    const el = $('console');
    if (outputSaved) {
        el.textContent = '';
        for (const node of outputSaved) el.appendChild(node);
        outputSaved = null;
    }
    $('viewing').hidden = true;
}

function showFile(name) {
    const ed = $('editor');
    if (!name) { ed.value = ''; ed.disabled = true; renderGutter(); return; }
    ed.disabled = false;
    const v = project.files[name];
    ed.value = typeof v === 'string' ? v : '(バイナリファイル)';
    ed.readOnly = typeof v !== 'string';
    // Setting .value does not fire `input`, so the numbers would still be the
    // last file's.
    renderGutter();
}

// The editor's text back into the project.  Called before anything that reads
// the file list, because the textarea is the only place a keystroke has been.
function stash() {
    if (!current || $('editor').readOnly) return;
    project.files[current] = $('editor').value;
}

// ---------------------------------------------------------------- saving

// Is there anything to save?
//
// An example that has not been touched is the example, and saving it made a copy
// under the same name in "保存したもの" - so opening three examples to look at
// them left three saved projects that were identical to the originals.  A
// project that has been saved before stays saved even if the last edit was
// undone; what this stops is creating one for nothing.
function worthSaving() {
    if (!project) return false;
    if (store.listSaved().some((s) => s.name === project.name)) return true;
    const base = templateFiles(project.template);
    const names = Object.keys(project.files);
    if (names.length !== Object.keys(base).length) return true;
    return names.some((f) => base[f] !== project.files[f]);
}

function scheduleSave() {
    if (!$('autosave').checked) return;
    clearTimeout(saveTimer);
    saveTimer = setTimeout(doSave, 800);
}

function doSave() {
    stash();
    if (!worthSaving()) return;
    try {
        const { skipped } = store.save(project.name, {
            template: project.template,
            files: project.files,
            templateFiles: templateFiles(project.template),
        });
        if (skipped.length) {
            say(`保存しませんでした (大きすぎます): ${skipped.join(', ')}\n`, true);
        }
        renderProjects();
    } catch (e) {
        say(e.message + '\n', true);
        $('autosave').checked = false;
    }
}

// ---------------------------------------------------------------- transfers

function saveAs(name, blob) {
    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = name;
    a.click();
    setTimeout(() => URL.revokeObjectURL(a.href), 30000);
}

// A project as one file.  A zip, because a student on Windows double-clicks one
// and gets a folder - and double-clicks a tar.gz and gets a dialog about which
// program to use.
async function downloadProject() {
    stash();
    const files = { ...project.files };
    for (const [n, b] of Object.entries(project.produced || {})) files[n] = b;
    saveAs(project.name.replace(/[^\w.-]+/g, '_') + '.zip', await makeZip(files));
}

// A file the student picked.  A zip is unpacked into the project; anything else
// becomes a file in it.
async function uploadFiles(list) {
    for (const file of list) {
        const buf = await file.arrayBuffer();
        const name = file.name.split(/[\\/]/).pop();

        if (/\.zip$/i.test(name)) {
            try {
                const inside = await readZip(buf);
                for (const [n, bytes] of Object.entries(inside)) {
                    // Flat, as the rest of this is: a zip made elsewhere may
                    // have directories, and the last component is the name.
                    addFile(n.split('/').pop(), bytes);
                }
                say(`${name}: ${Object.keys(inside).length} 個のファイルを取り込みました\n`);
            } catch (e) {
                say(`${name}: ${e.message}\n`, true);
            }
            continue;
        }
        addFile(name, new Uint8Array(buf));
    }
    renderFiles();
    scheduleSave();
}

// Text stays text so it can be edited; everything else is kept as bytes and
// said out loud, because bytes are what will not be saved.
function addFile(name, bytes) {
    if (/\.(c|cc|cpp|cxx|h|hpp|hh|inc|txt|csv|md|json)$/i.test(name)) {
        project.files[name] = new TextDecoder('utf-8', { fatal: false }).decode(bytes);
    } else {
        project.files[name] = bytes;
        say(`${name}: ${(bytes.length / 1024).toFixed(0)} KB` +
            ` (テキストではないので保存はされません)\n`);
    }
}

// ---------------------------------------------------------------- the graph

function csvFiles() {
    const out = {};
    for (const [n, v] of Object.entries(project.files)) {
        if (typeof v === 'string' && /\.csv$/i.test(n)) out[n] = v;
    }
    for (const [n, b] of Object.entries(project.produced || {})) {
        if (!/\.csv$/i.test(n)) continue;
        out[n] = new TextDecoder('utf-8', { fatal: false }).decode(b);
    }
    return out;
}

function refreshCsvChoices() {
    const files = csvFiles();
    const sel = $('csv');
    const had = sel.value;
    sel.innerHTML = '';
    for (const n of Object.keys(files).sort()) {
        const o = document.createElement('option');
        o.value = o.textContent = n;
        sel.appendChild(o);
    }
    if ([...sel.options].some((o) => o.value === had)) sel.value = had;
    refreshColumns();
}

function refreshColumns() {
    const files = csvFiles();
    const name = $('csv').value;
    const cx = $('cx');
    cx.innerHTML = '';
    if (!name) { $('code').value = ''; return; }
    const { columns } = parseCsv(files[name]);
    for (const c of columns) {
        const o = document.createElement('option');
        o.value = o.textContent = c;
        cx.appendChild(o);
    }
    writeCode();
}

function writeCode() {
    const file = $('csv').value;
    if (!file) return;
    const files = csvFiles();
    const { columns } = parseCsv(files[file]);
    const x = $('cx').value || columns[0];
    const ys = columns.filter((c) => c !== x);
    $('code').value = chartCode({ file, type: $('ctype').value, x, ys });
}

function plot() {
    const files = csvFiles();
    const canvas = $('canvas');
    try {
        // The code shown is the code run: a Function over the same helpers the
        // generated text names, so editing it does what it looks like it does.
        const fn = new Function('files', 'canvas', 'parseCsv', 'draw', $('code').value);
        fn(files, canvas, parseCsv, draw);
    } catch (e) {
        say('グラフ: ' + e.message + '\n', true);
    }
}

// ---------------------------------------------------------------- wiring

for (const t of CHART_TYPES) {
    const o = document.createElement('option');
    o.value = t.id;
    o.textContent = t.label;
    $('ctype').appendChild(o);
}

$('project').onchange = () => {
    stash();
    // Save what is being left, now rather than in eight hundred milliseconds:
    // the timer that would have done it is about to be looking at a different
    // project.  Including one that has never been saved - a student who edits an
    // example and switches away should find their edit when they come back.
    clearTimeout(saveTimer);
    if ($('autosave').checked && worthSaving()) doSave();
    const v = $('project').value;
    if (v.startsWith('tpl:')) openTemplate(v.slice(4));
    else openSaved(v.slice(6));
    renderProjects();
};

$('new').onclick = () => {
    const name = prompt('新しいプロジェクトの名前', 'my-project');
    if (!name) return;
    project = {
        name,
        template: null,
        files: {
            'main.c': '#include <stdio.h>\n\nint main(void) {\n    printf("hello\\n");\n    return 0;\n}\n',
        },
        produced: {},
    };
    afterOpen();
    doSave();
    renderProjects();
};

$('rename').onclick = () => {
    const name = prompt('新しい名前', project.name);
    if (!name || name === project.name) return;
    const old = project.name;
    project.name = name;
    doSave();
    if (store.listSaved().some((s) => s.name === old)) store.remove(old);
    renderProjects();
};

$('delete').onclick = () => {
    if (!store.listSaved().some((s) => s.name === project.name)) {
        alert('お手本は削除できません。');
        return;
    }
    if (!confirm(project.name + ' を削除しますか')) return;
    store.remove(project.name);
    openTemplate(Object.keys(TEMPLATES)[0]);
    renderProjects();
};

$('add').onclick = () => {
    const name = prompt('ファイル名', 'util.c');
    if (!name) return;
    stash();
    project.files[name] = '';
    current = name;
    renderFiles();
    showFile(name);
    scheduleSave();
};

$('upload').onclick = () => $('picker').click();
$('picker').onchange = async (e) => {
    await uploadFiles([...e.target.files]);
    e.target.value = '';
};
$('download').onclick = downloadProject;

// The numbers down the left of the editor.
//
// gcc reports a mistake as `main.c:12:5: error`, and without these a student
// counts rows with a finger to find line 12.
//
// Drawn rather than styled: a textarea cannot decorate its own lines, so this is
// a second element holding one number per line, scrolled to match.  It stays
// aligned because neither side wraps - see the CSS.
function renderGutter() {
    const ed = $('editor');
    const g = $('gutter');
    // A trailing newline ends the last line rather than starting a new one, so
    // an empty document is one line and "a\n" is one line, not two.
    const lines = ed.value ? ed.value.split('\n').length - (ed.value.endsWith('\n') ? 1 : 0)
                           : 1;
    const want = Math.max(lines, 1);
    if (g.dataset.n !== String(want)) {   // typing inside a line changes nothing
        g.dataset.n = String(want);
        let text = '';
        for (let i = 1; i <= want; i++) text += i + '\n';
        g.textContent = text;
    }
    // Always, not only when the count changed: opening another file leaves the
    // textarea at the top and the gutter wherever the last one was scrolled to.
    g.scrollTop = ed.scrollTop;
}

$('editor').addEventListener('scroll', () => {
    $('gutter').scrollTop = $('editor').scrollTop;
});

$('editor').oninput = () => { stash(); renderGutter(); scheduleSave(); };
$('editor').onkeydown = (e) => {
    // Tab inserts a tab rather than leaving the editor, which is what a text
    // area does by default and never what someone writing code wants.
    if (e.key !== 'Tab') return;
    e.preventDefault();
    const ed = e.target;
    const at = ed.selectionStart;
    ed.value = ed.value.slice(0, at) + '    ' + ed.value.slice(ed.selectionEnd);
    ed.selectionStart = ed.selectionEnd = at + 4;
    // Assigning .value does not fire `input`, so the indentation would sit in
    // the textarea and never reach the project - typed, then compiled away.
    stash();
    scheduleSave();
};

$('run').onclick = () => {
    if (busy) return;
    stash();
    setBusy(true);
    outputSaved = null;
    $('viewing').hidden = true;
    $('console').textContent = '';
    showPane('out');
    ensureWorker().postMessage({
        type: 'run',
        files: project.files,
        // Data the project needs but does not carry - MNIST's twelve megabytes.
        // The worker keeps them; the project does not, so they never reach
        // localStorage and never appear in a download.
        data: (TEMPLATES[project.template] || {}).data || null,
        opts: { flags: $('opt').value.split(/\s+/) },
    });
};

for (const b of document.querySelectorAll('.tabs button')) {
    b.onclick = () => showPane(b.dataset.pane);
}
function showPane(which) {
    for (const b of document.querySelectorAll('.tabs button')) {
        b.classList.toggle('on', b.dataset.pane === which);
    }
    for (const p of document.querySelectorAll('.pane')) {
        p.classList.toggle('on', p.id === 'pane-' + which);
    }
}

$('stop').onclick = stopEverything;
$('back').onclick = backToOutput;
$('csv').onchange = refreshColumns;
$('cx').onchange = writeCode;
$('ctype').onchange = writeCode;
$('plot').onclick = plot;
$('autosave').onchange = () => { if ($('autosave').checked) doSave(); };

// Start where they left off, or at the first example.
const last = localStorage.getItem('gccemu.last');
const saved = store.listSaved();
if (last && saved.some((s) => s.name === last)) openSaved(last);
else openTemplate(Object.keys(TEMPLATES)[0]);
renderProjects();

// The toolchain is 37 MB and the student is about to want it, so start now
// rather than when they press the button.
prepareWorker();
