# Where this is, and what to do next

Working notes for picking this up. The README says what it is; this says what is
done, what is not, and what has already been tried and found wrong.

Written 2026-08-08, part way through the first build.

## What this is meant to be

A page where a student writes C or C++, presses a button, and sees their program
run — with nothing installed and nothing sent anywhere. The compiler is a real
Alpine gcc/g++ 13.2.1, x86-64 Linux binaries, running inside an emulator
(`x86_emu_cpp`) compiled to WebAssembly. The program it produces runs in the same
emulator.

Asked for, in the user's words:

- projects, downloadable whole; per-project file upload and download
- **no subdirectories** — a project is a flat set of files
- projects kept in localStorage so they survive closing the browser
- **only changed files stored**, because machine-learning projects have data
- a CSV plotter: pick a file, pick a chart type, **JavaScript appears**, press a
  button and the graph is drawn
- default projects: C hello, C++ hello, sin by Newton's method, a sine from a
  Z-transform recurrence, bubble sort and quicksort with convergence graphs,
  and MNIST trained and inferred in C++ alone

## State

**The compiler works.** Natively, under the emulator, on this machine:

    gcc /work/hello.c -o /work/hello      5.3 s
    /work/hello                           prints

and C++ with `<vector> <map> <memory> <sstream> <algorithm> <cmath>`, at -O0 and
-O2, compiles and runs. `sh tools/wslcheck.sh` is that check.

**Not yet done, in the order it matters:**

1. **The WebAssembly build has never been run.** `web/build.sh` exists;
   `web/x86emu.js` and `.wasm` are not committed yet. Nothing in `web/` has been
   loaded in a browser.
2. **The toolchain is not in the repository yet.** `tools/wslpack.sh` puts it
   there as `guest/tree/` (the files, so a library can be added later) and
   `guest/tree.tar.gz` (what the page fetches).
3. **MNIST has no data.** `web/mnist.js` names four `.gz` files under `data/`
   that nobody has put there, and the sizes in it (4000 training images, 3
   epochs) are a guess at what a minute of emulated arithmetic buys. Measure it.
4. The page has never been opened. Expect the first hour there to be ordinary
   web bugs.

## How it is put together

    x86_emu_cpp/src/     a copy of the emulator, unmodified except as noted below
    web/wasm_api.cpp     one entry point: run a program in the guest, return its code
    web/worker.js        holds the emulator and the toolchain; compiles and runs
    web/app.js           the page: files, editor, output, graph
    web/store.js         localStorage, as template + patch
    web/chart.js         CSV parsing and a canvas plot
    web/projects.js      six example projects, as text
    web/mnist.js         the seventh, whose data is fetched
    tools/fetch_alpine.sh  downloads the Alpine packages
    tools/wslpayload.sh    turns them into the tree the browser carries
    tools/wslcheck.sh      compiles and runs C and C++ against that tree
    tools/wslpack.sh       copies the tree into guest/

Compiling is `gcc` or `g++` with every source in the project on one command
line — the driver spawns cc1/cc1plus, as, collect2 and ld as guest processes,
and the emulator runs all of them. Running is the same call with the file gcc
produced. There is no protocol between the page and the emulator beyond the
filesystem.

### One change to the emulator

`Emulator::load` now looks inside the sysroot before treating the path as a host
path. Without it, `/usr/bin/gcc` found *this machine's* gcc — a glibc binary —
and the failure appeared two steps later as a missing `ld-linux`, because the
program had been read from one world and its interpreter looked up in the other.
The host path still works; front ends that hand over `sysroot/opt/thing/prog`
are naming a real file.

This is in `x86_emu_cpp` upstream as well, or should be — check before copying
the emulator again.

## What has already been tried and was wrong

**Do not hand-write the list of files the toolchain needs.** Three attempts,
three different failures, none of them guessable:

- binutils' own `libbfd` and `libopcodes` — without them nothing assembles
- `liblto_plugin.so` — the driver passes `-fuse-linker-plugin` by default, so
  every link loads it, and the error names a flag nobody typed
- `Scrt1.o` — which `crt*.o` does not match, because it starts with a capital S
- `libm.a` — an empty archive on musl, there so that `-lm` resolves

`tools/wslpayload.sh` now takes the whole tree and removes a short list of things
that are large and provably unused, checking with `tools/wslcheck.sh` after each.
Keep it that way. The tree is 105 MB, 57 MB gzipped; `usr/share` and `lto1` are
most of what was removed.

**The interpreter question is not what it looks like.** A musl binary naming
`/lib/ld-musl-x86_64.so.1` reported a missing `/lib64/ld-linux-x86-64.so.2`. That
is the sysroot bug above, not a parsing bug — `readelf -l` on the actual file is
the way to check, not `strings | grep ld-`.

## Numbers, so far

| | |
| --- | --- |
| gcc hello.c, under the emulator, natively | 5.3 s |
| the toolchain tree | 105 MB, 57 MB gzipped |
| what four compiles actually open | 255 files, 6.7 MB |
| cc1 / cc1plus | 33 MB / 35 MB — the floor |

The 6.7 MB figure is a temptation and a trap: it is what *those* compiles opened.
A student who includes `<thread>` opens a different set, and headers compress to
nothing, so they all go in.

## Things worth deciding

- **Speed in the browser.** 5.3 s natively; the WebAssembly build is usually two
  to three times slower than that. If `hello.c` takes twenty seconds the shape of
  the page has to change — compile on a timer rather than on a button, say.
- **How much MNIST.** 4000 images × 3 epochs is a guess. It should be the largest
  number that finishes in about a minute.
- **Whether the emulator gets a decoded-instruction cache.** It is a plain
  decode-and-execute loop; this is the single biggest lever on every number
  above, and `x86_emu_cpp/resume.md` lists it as the first thing to try for
  performance.
