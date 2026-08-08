// A zip file, without a library.
//
// A tar would be less code, but a student on Windows double-clicks a zip and
// gets a folder, and double-clicks a tar.gz and gets nothing.  That decides it.
//
// The format is simpler than its reputation: each file gets a small header and
// its bytes, then a directory of those headers is appended, then a record saying
// where the directory starts.  Compression is deflate, which the browser already
// has - CompressionStream('deflate-raw') is exactly the raw stream zip wants.

const CRC_TABLE = (() => {
    const t = new Uint32Array(256);
    for (let i = 0; i < 256; i++) {
        let c = i;
        for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
        t[i] = c >>> 0;
    }
    return t;
})();

function crc32(bytes) {
    let c = 0xffffffff;
    for (let i = 0; i < bytes.length; i++) c = CRC_TABLE[(c ^ bytes[i]) & 0xff] ^ (c >>> 8);
    return (c ^ 0xffffffff) >>> 0;
}

async function deflate(bytes) {
    if (typeof CompressionStream === 'undefined') return null;
    const stream = new Blob([bytes]).stream().pipeThrough(new CompressionStream('deflate-raw'));
    return new Uint8Array(await new Response(stream).arrayBuffer());
}

// MS-DOS packed date and time, which is what a zip records.  Two-second
// resolution and a 1980 epoch, both of which are the format's age showing.
function dosTime(d) {
    const time = (d.getHours() << 11) | (d.getMinutes() << 5) | (d.getSeconds() >> 1);
    const date = ((d.getFullYear() - 1980) << 9) | ((d.getMonth() + 1) << 5) | d.getDate();
    return { time, date };
}

export async function makeZip(files) {
    const enc = new TextEncoder();
    const now = dosTime(new Date());
    const parts = [];
    const entries = [];
    let offset = 0;

    for (const [name, content] of Object.entries(files)) {
        const data = typeof content === 'string' ? enc.encode(content)
                                                 : new Uint8Array(content);
        const nameBytes = enc.encode(name);
        const crc = crc32(data);
        let body = await deflate(data);
        let method = 8;
        // Deflate can come out larger than the input for tiny or random files,
        // and a zip is allowed to just store those.
        if (!body || body.length >= data.length) { body = data; method = 0; }

        const head = new DataView(new ArrayBuffer(30));
        head.setUint32(0, 0x04034b50, true);      // local file header
        head.setUint16(4, 20, true);              // version needed
        head.setUint16(6, 0x0800, true);          // the name is UTF-8
        head.setUint16(8, method, true);
        head.setUint16(10, now.time, true);
        head.setUint16(12, now.date, true);
        head.setUint32(14, crc, true);
        head.setUint32(18, body.length, true);
        head.setUint32(22, data.length, true);
        head.setUint16(26, nameBytes.length, true);
        head.setUint16(28, 0, true);              // no extra field

        parts.push(new Uint8Array(head.buffer), nameBytes, body);
        entries.push({ nameBytes, crc, method, packed: body.length, raw: data.length, offset });
        offset += 30 + nameBytes.length + body.length;
    }

    const dirStart = offset;
    for (const e of entries) {
        const rec = new DataView(new ArrayBuffer(46));
        rec.setUint32(0, 0x02014b50, true);       // central directory header
        rec.setUint16(4, 20, true);               // version made by
        rec.setUint16(6, 20, true);               // version needed
        rec.setUint16(8, 0x0800, true);
        rec.setUint16(10, e.method, true);
        rec.setUint16(12, now.time, true);
        rec.setUint16(14, now.date, true);
        rec.setUint32(16, e.crc, true);
        rec.setUint32(20, e.packed, true);
        rec.setUint32(24, e.raw, true);
        rec.setUint16(28, e.nameBytes.length, true);
        rec.setUint32(42, e.offset, true);        // where its local header is
        parts.push(new Uint8Array(rec.buffer), e.nameBytes);
        offset += 46 + e.nameBytes.length;
    }

    const end = new DataView(new ArrayBuffer(22));
    end.setUint32(0, 0x06054b50, true);           // end of central directory
    end.setUint16(8, entries.length, true);
    end.setUint16(10, entries.length, true);
    end.setUint32(12, offset - dirStart, true);
    end.setUint32(16, dirStart, true);
    parts.push(new Uint8Array(end.buffer));

    return new Blob(parts, { type: 'application/zip' });
}

// Reading one back, so a project downloaded from here can be uploaded again.
// Stored and deflated entries only, which is all this writes and all anything
// else is likely to produce for text.
export async function readZip(buffer) {
    const view = new DataView(buffer);
    const bytes = new Uint8Array(buffer);
    const dec = new TextDecoder('utf-8');

    // Find the end-of-directory record, searching back from the end: it is the
    // only structure whose position is not written down anywhere.
    let end = -1;
    for (let i = bytes.length - 22; i >= 0 && i > bytes.length - 65558; i--) {
        if (view.getUint32(i, true) === 0x06054b50) { end = i; break; }
    }
    if (end < 0) throw new Error('zip ファイルではないようです');

    const count = view.getUint16(end + 10, true);
    let at = view.getUint32(end + 16, true);
    const out = {};
    for (let i = 0; i < count; i++) {
        if (view.getUint32(at, true) !== 0x02014b50) break;
        const method = view.getUint16(at + 10, true);
        const packed = view.getUint32(at + 20, true);
        const nameLen = view.getUint16(at + 28, true);
        const extraLen = view.getUint16(at + 30, true);
        const commentLen = view.getUint16(at + 32, true);
        const localAt = view.getUint32(at + 42, true);
        const name = dec.decode(bytes.subarray(at + 46, at + 46 + nameLen));
        at += 46 + nameLen + extraLen + commentLen;

        // The local header repeats the name and may have a different extra
        // field, so the data's position has to come from it and not from here.
        const lNameLen = view.getUint16(localAt + 26, true);
        const lExtraLen = view.getUint16(localAt + 28, true);
        const from = localAt + 30 + lNameLen + lExtraLen;
        const raw = bytes.subarray(from, from + packed);

        if (name.endsWith('/')) continue;            // a directory entry
        if (method === 0) {
            out[name] = raw;
        } else if (method === 8) {
            const s = new Blob([raw]).stream().pipeThrough(new DecompressionStream('deflate-raw'));
            out[name] = new Uint8Array(await new Response(s).arrayBuffer());
        } else {
            throw new Error(`${name}: 対応していない圧縮方式です (${method})`);
        }
    }
    return out;
}
