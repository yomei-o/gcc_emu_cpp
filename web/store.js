// Where a student's work lives between visits.
//
// The rule asked for, and the reason it matters: **only what was changed is
// stored**.  A project starts as a template this site already serves, so
// keeping a copy of every file would mean storing the same MNIST loader for
// every student who never opened it - and localStorage is five megabytes for
// the whole origin, which one training set would end on its own.
//
// So a saved project is the template's name plus a patch: the files that differ
// from it, the files added, and the names of the files deleted.  Opening a
// project is the template plus that patch.  A project made from scratch has no
// template and is simply all patch.
//
// localStorage rather than IndexedDB because everything here is small by
// construction and synchronous storage is far easier to reason about; the one
// thing that is not small - a dataset the student uploaded - is exactly what
// this refuses to store, and says so.

const KEY = 'gccemu.projects.v1';
// Well under the 5 MB an origin usually gets, and leaving room for several
// projects.  A file over this is kept for the session and dropped on reload,
// with the page saying so rather than failing to save in silence.
export const MAX_FILE = 256 * 1024;
export const MAX_TOTAL = 3 * 1024 * 1024;

function read() {
    try {
        return JSON.parse(localStorage.getItem(KEY) || '{}');
    } catch (e) {
        // A corrupt entry should cost the student their saved work, not the
        // ability to use the site at all.
        console.warn('saved projects could not be read:', e);
        return {};
    }
}

function write(all) {
    localStorage.setItem(KEY, JSON.stringify(all));
}

export function listSaved() {
    const all = read();
    return Object.keys(all).sort().map((name) => ({
        name,
        template: all[name].template || null,
        files: Object.keys(all[name].files || {}).length,
        deleted: (all[name].deleted || []).length,
        saved: all[name].saved || 0,
    }));
}

// What is stored for one project: the template it came from, the files that
// differ from it, and the names of the ones removed.
export function save(name, { template, files, templateFiles }) {
    const all = read();
    const patch = {};
    const deleted = [];
    const base = templateFiles || {};
    const skipped = [];

    for (const [file, text] of Object.entries(files)) {
        if (base[file] === text) continue;          // unchanged: the template has it
        if (text.length > MAX_FILE) { skipped.push(file); continue; }
        patch[file] = text;
    }
    for (const file of Object.keys(base)) {
        if (!(file in files)) deleted.push(file);
    }

    all[name] = { template: template || null, files: patch, deleted, saved: Date.now() };
    const size = JSON.stringify(all).length;
    if (size > MAX_TOTAL) {
        const e = new Error(
            `保存できる大きさ (${(MAX_TOTAL / 1048576).toFixed(1)} MB) を超えました。` +
            `大きなデータファイルは保存されません。`);
        e.tooBig = true;
        throw e;
    }
    try {
        write(all);
    } catch (e) {
        const err = new Error('ブラウザの保存領域がいっぱいです: ' + e.message);
        err.tooBig = true;
        throw err;
    }
    return { skipped, bytes: size };
}

// The template's files with the patch laid over them.
export function load(name, templateFiles) {
    const all = read();
    const entry = all[name];
    if (!entry) return null;
    const files = { ...(templateFiles || {}) };
    for (const file of entry.deleted || []) delete files[file];
    Object.assign(files, entry.files || {});
    return { template: entry.template || null, files };
}

export function templateOf(name) {
    const entry = read()[name];
    return entry ? entry.template || null : null;
}

export function remove(name) {
    const all = read();
    delete all[name];
    write(all);
}

export function usage() {
    const bytes = (localStorage.getItem(KEY) || '').length;
    return { bytes, limit: MAX_TOTAL };
}
