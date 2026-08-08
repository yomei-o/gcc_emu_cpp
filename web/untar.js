// A tar reader, small enough to read and big enough for the one archive here.
//
// The toolchain ships as one tar.gz that the page fetches in a single request,
// lets the browser's DecompressionStream ungzip, and walks with this.
//
// Regular files, directories, and **hard links**.  That last one was skipped as
// "a member type nobody produces" and is produced by every tar: gcc, g++ and c++
// are one file under three names, so the archive holds the first and records the
// other two as zero-length link entries.  Skipping them gave a browser a `g++`
// that existed and was empty, and a C++ compile that said `cannot open
// /usr/bin/g++` - true, and silent about why.
//
// Loadable three ways so the browser worker and the node rehearsal share it:
// importScripts, a plain script tag, or require.
(function (root) {
    'use strict';

    // `write(name, bytes, linkTo)` is called for each member, in archive order.
    // `bytes` is a view into the input, not a copy: use it before the next call
    // if the consumer keeps references.
    //
    // For a hard link, `bytes` is empty and `linkTo` names an earlier member
    // with the same contents.  The consumer copies it - which it can do cheaply
    // from wherever it just put that one, whereas holding every member here to
    // answer the question later would mean keeping the whole archive twice.
    function untar(bytes, write) {
        let off = 0;
        const dec = new TextDecoder();
        // A name too long for the header's 100 characters, carried by the
        // member before it.  GNU tar writes one of these ('L' for a name, 'K'
        // for a link target) rather than using the ustar prefix field, and
        // seven of this toolchain's C++ headers are long enough to need it.
        // Without this they were simply absent - no error, no empty file, just
        // a header the compiler could not find.
        let longName = '';
        let longLink = '';
        const field = (start, len) => {
            const s = bytes.subarray(off + start, off + start + len);
            const end = s.indexOf(0);
            return dec.decode(end < 0 ? s : s.subarray(0, end));
        };
        while (off + 512 <= bytes.length) {
            const name = field(0, 100);
            if (!name) {  // the two zero blocks that end an archive
                off += 512;
                continue;
            }
            const size = parseInt(field(124, 12).trim() || '0', 8);
            const type = String.fromCharCode(bytes[off + 156]);
            const prefix = field(345, 155);
            const full = longName || (prefix ? prefix + '/' + name : name);
            // Every header field has to be read here, while `off` still points
            // at the header.  Reading one after the line below reads the *next*
            // member's contents instead - and where those bytes are zero it
            // comes back empty rather than wrong, so a hard link looks like an
            // ordinary file of length zero and is written as one.  That is how
            // g++ became a valid, empty file and `unrecognised executable
            // format`.
            const link = type === '1' ? (longLink || field(157, 100)) : '';
            off += 512;
            // '0' and NUL are both "regular file"; '1' is a hard link, whose
            // target is in the linkname field; '5' is a directory, which the
            // consumer creates implicitly.  'L' and 'K' carry a long name for
            // the member that follows, and are not files themselves.
            if (type === 'L' || type === 'K') {
                const s = bytes.subarray(off, off + size);
                const end = s.indexOf(0);
                const text = dec.decode(end < 0 ? s : s.subarray(0, end));
                if (type === 'L') longName = text; else longLink = text;
            } else {
                if (type === '0' || type === '\0') {
                    write(full, bytes.subarray(off, off + size));
                } else if (type === '1') {
                    // Loudly, because the quiet version of this wrote an empty
                    // file and let the failure surface an hour later as a
                    // compiler that could not be executed.
                    if (!link) throw new Error(full + ': hard link with no target');
                    write(full, bytes.subarray(off, off), link);
                }
                // Consumed by this member, whatever its type: a long name
                // applies to exactly the one header after it.
                longName = '';
                longLink = '';
            }
            off += Math.ceil(size / 512) * 512;
        }
    }

    root.untarBytes = untar;
    if (typeof module !== 'undefined' && module.exports) module.exports = untar;
})(typeof globalThis !== 'undefined' ? globalThis : this);
