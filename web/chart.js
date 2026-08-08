// Drawing a CSV, and showing the code that drew it.
//
// The point is not the picture.  A student who has just written a bubble sort
// wants to see it converge, and the useful part is that plotting it is a dozen
// lines of ordinary JavaScript they can read - so the page writes those lines
// out, shows them, and runs them.  Editing them and pressing the button again
// is the whole feature.
//
// Canvas rather than a charting library: nothing to load, nothing to learn, and
// the generated code stays short enough to read in one go.

// A CSV as a header row and rows of numbers.  Tolerant on purpose - a program
// that prints its output with printf will not produce a tidy file.
export function parseCsv(text) {
    const lines = String(text).split(/\r?\n/).filter((l) => l.trim() !== '');
    if (!lines.length) return { columns: [], rows: [] };
    const split = (l) => l.split(',').map((s) => s.trim());
    let head = split(lines[0]);
    let start = 1;
    // No header: a first row that is all numbers is data, and the columns get
    // names so the rest of the page has something to say.
    if (head.every((h) => h !== '' && Number.isFinite(Number(h)))) {
        head = head.map((_, i) => 'col' + (i + 1));
        start = 0;
    }
    const rows = [];
    for (let i = start; i < lines.length; i++) {
        const cells = split(lines[i]);
        if (cells.length === 1 && cells[0] === '') continue;
        rows.push(cells.map((c) => (c === '' ? NaN : Number(c))));
    }
    return { columns: head, rows };
}

export const CHART_TYPES = [
    { id: 'line', label: '折れ線' },
    { id: 'scatter', label: '散布図' },
    { id: 'bar', label: '棒' },
];

// The code the student sees, and the code that runs.  One string, so they
// cannot drift apart: what is shown *is* what is executed.
export function chartCode({ file, type, x, ys }) {
    const yList = ys.map((c) => JSON.stringify(c)).join(', ');
    return `// ${file} を ${type} で描く
const { columns, rows } = parseCsv(files[${JSON.stringify(file)}]);
const xi = columns.indexOf(${JSON.stringify(x)});
const series = [${yList}].map((name) => ({
    name,
    points: rows.map((r) => [xi < 0 ? 0 : r[xi], r[columns.indexOf(name)]])
                .filter((p) => Number.isFinite(p[0]) && Number.isFinite(p[1])),
}));

draw(canvas, {
    type: ${JSON.stringify(type)},
    xLabel: ${JSON.stringify(x)},
    series,
});
`;
}

// The colours.  Six is enough for a teaching plot, and they are picked to stay
// apart from each other for the most common kinds of colour blindness.
const COLOURS = ['#4c78a8', '#f58518', '#54a24b', '#e45756', '#b279a2', '#9c755f'];

export function draw(canvas, { type, xLabel, series, title }) {
    const ctx = canvas.getContext('2d');
    const dpr = globalThis.devicePixelRatio || 1;
    const w = canvas.clientWidth || 640;
    const h = canvas.clientHeight || 360;
    canvas.width = Math.round(w * dpr);
    canvas.height = Math.round(h * dpr);
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);

    const style = getComputedStyle(document.documentElement);
    const ink = style.getPropertyValue('--ink').trim() || '#222';
    const faint = style.getPropertyValue('--faint').trim() || '#8888';
    ctx.clearRect(0, 0, w, h);

    const pad = { l: 56, r: 12, t: title ? 26 : 12, b: 34 };
    const plotW = w - pad.l - pad.r;
    const plotH = h - pad.t - pad.b;

    const all = series.flatMap((s) => s.points);
    if (!all.length) {
        ctx.fillStyle = faint;
        ctx.font = '13px system-ui, sans-serif';
        ctx.fillText('描けるデータがありません', pad.l, pad.t + 20);
        return;
    }
    let x0 = Math.min(...all.map((p) => p[0]));
    let x1 = Math.max(...all.map((p) => p[0]));
    let y0 = Math.min(...all.map((p) => p[1]));
    let y1 = Math.max(...all.map((p) => p[1]));
    if (x0 === x1) { x0 -= 0.5; x1 += 0.5; }
    if (y0 === y1) { y0 -= 0.5; y1 += 0.5; }
    // A little air above and below, so a curve does not touch the frame.
    const padY = (y1 - y0) * 0.05;
    y0 -= padY; y1 += padY;

    const sx = (v) => pad.l + ((v - x0) / (x1 - x0)) * plotW;
    const sy = (v) => pad.t + plotH - ((v - y0) / (y1 - y0)) * plotH;

    // Axes and four gridlines, labelled.  More than that is noise at this size.
    ctx.strokeStyle = faint;
    ctx.fillStyle = faint;
    ctx.lineWidth = 1;
    ctx.font = '11px system-ui, sans-serif';
    ctx.textAlign = 'right';
    ctx.textBaseline = 'middle';
    for (let i = 0; i <= 4; i++) {
        const v = y0 + ((y1 - y0) * i) / 4;
        const y = Math.round(sy(v)) + 0.5;
        ctx.globalAlpha = i === 0 ? 1 : 0.35;
        ctx.beginPath();
        ctx.moveTo(pad.l, y);
        ctx.lineTo(pad.l + plotW, y);
        ctx.stroke();
        ctx.globalAlpha = 1;
        ctx.fillText(format(v), pad.l - 6, y);
    }
    ctx.textAlign = 'center';
    ctx.textBaseline = 'top';
    for (let i = 0; i <= 4; i++) {
        const v = x0 + ((x1 - x0) * i) / 4;
        ctx.fillText(format(v), sx(v), pad.t + plotH + 8);
    }
    if (xLabel) {
        ctx.fillText(xLabel, pad.l + plotW / 2, pad.t + plotH + 22);
    }
    if (title) {
        ctx.textAlign = 'left';
        ctx.fillStyle = ink;
        ctx.font = '13px system-ui, sans-serif';
        ctx.fillText(title, pad.l, 6);
    }

    series.forEach((s, i) => {
        const colour = COLOURS[i % COLOURS.length];
        ctx.strokeStyle = colour;
        ctx.fillStyle = colour;
        if (type === 'bar') {
            const bw = Math.max(1, (plotW / s.points.length) * 0.8 / series.length);
            s.points.forEach((p) => {
                const x = sx(p[0]) - (series.length * bw) / 2 + i * bw;
                const y = sy(p[1]);
                const base = sy(Math.max(y0, 0));
                ctx.fillRect(x, Math.min(y, base), bw, Math.abs(base - y));
            });
        } else if (type === 'scatter') {
            // Small dots: a sort's trace is thousands of points and large ones
            // would be a solid block.
            const r = s.points.length > 2000 ? 0.8 : s.points.length > 400 ? 1.4 : 2.2;
            s.points.forEach((p) => {
                ctx.beginPath();
                ctx.arc(sx(p[0]), sy(p[1]), r, 0, Math.PI * 2);
                ctx.fill();
            });
        } else {
            ctx.lineWidth = 1.6;
            ctx.beginPath();
            s.points.forEach((p, k) => {
                const x = sx(p[0]), y = sy(p[1]);
                if (k === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
            });
            ctx.stroke();
        }
    });

    // The legend, only when there is more than one thing to tell apart.
    if (series.length > 1) {
        ctx.textAlign = 'left';
        ctx.textBaseline = 'middle';
        ctx.font = '11px system-ui, sans-serif';
        let x = pad.l;
        series.forEach((s, i) => {
            ctx.fillStyle = COLOURS[i % COLOURS.length];
            ctx.fillRect(x, pad.t - 8, 9, 9);
            ctx.fillStyle = ink;
            ctx.fillText(s.name, x + 13, pad.t - 3.5);
            x += 13 + ctx.measureText(s.name).width + 14;
        });
    }
}

function format(v) {
    if (!Number.isFinite(v)) return '';
    const a = Math.abs(v);
    if (a !== 0 && (a < 0.001 || a >= 100000)) return v.toExponential(1);
    return String(Math.round(v * 1000) / 1000);
}
