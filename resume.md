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

**The page works and everything is committed.** In a browser, measured on a
quiet machine:

    gcc -O2 hello.c        4.3 s      (6.6 s this morning)
    g++ -O2 hello.cpp     72.1 s      (118 s)
    the program            0.0-0.8 s
    the toolchain           45 MB     (63 MB)

Three things got it there: gcc 6.4 instead of 13.2, an emulator about 2.6x
faster, and undoing a flag of mine that was costing 5x — see below, because that
one is the story worth reading.

What is left:

1. **C++ takes one to two minutes.** See below - this is the whole job.
2. **MNIST has never finished a run.** The data is in `web/data/` and the worker
   fetches it, but the sizes in `web/mnist.js` (4000 images, 3 epochs) were
   chosen before anything was timed. `tools/wslmnist.sh` runs it; set them to
   the largest that finishes in about a minute.
3. **Stopping a run kills the worker**, because there is no other way: `emu_run`
   is one synchronous call, and a shared stop flag would need
   `SharedArrayBuffer`, which needs COOP/COEP headers, which GitHub Pages does
   not send. The page keeps the downloaded toolchain so the restart is a
   re-unpack rather than a re-download.

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
    tools/wsluntar.sh      unpacks guest/tree.tar.gz through web/untar.js and
                           compares all 5459 files against guest/tree
    tools/wslnode.sh       the browser's own path: untar.js into MEMFS, then
                           compile and run C and C++

**Run wsluntar.sh before wslnode.sh, and never skip it.** It is seconds against
four minutes, and it checks the thing that has broken twice: what the browser
ends up holding. Two bugs shipped past a green wslnode.sh because that test used
to unpack with node's `tar` - so untar.js, the only unpacker the page has, was
never run. It read a hard link's target from the wrong offset (`ar` got `as`'s
bytes, `as` got `ld`'s - hence `as: unrecognized option '--64'`, which is `ld`
talking), and it did not know GNU long names, so seven C++ headers with paths
over 100 characters were silently absent from every browser that ever loaded
the page.

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

## Things the browser found that node could not

Each of these worked under node and failed in a browser, which is worth knowing
before trusting the next node run.

- **A program's `fopen("out.csv", "w")` went to `/`.** Nothing had set the
  emscripten filesystem's idea of "here", and passing `/work` to `emu_run` only
  put PWD in the guest's *environment* - which a shell reads and the C library
  does not. The page collects what appeared in `/work`, so the graph tab had
  nothing to plot. `FS.chdir` before staging; `web/test_cwd.mjs` shows it.
- **C++ aborted with `Aborted(undefined)`.** The build was missing
  `-sDISABLE_EXCEPTION_CATCHING=0`, and emscripten's default turns every throw
  into `abort()`. The emulator's own diagnostics are exceptions, so the real
  message was being destroyed on its way out. Not memory: the whole C++ compile
  peaks at 105 MB, which was measured before believing otherwise.
- **The project dropdown could not be used.** Saving runs on a timer after every
  keystroke and rebuilt the `<select>`, so it was replaced underneath whoever
  had just opened it.
- **Output arrived in bursts.** The emulator answered `ioctl` with "not a
  terminal", which is true of a pipe - and musl then buffers stdout in full, so
  a program printing its progress produced nothing until it finished or filled
  four kilobytes. The standard streams answer as terminals now, in
  `x86_emu_cpp/src/syscalls.cpp`.

## Carrying a filesystem in git

Three things, each of which would have broken the page somewhere far from the
cause:

- **Symlinks become copies** (`tools/wslpack.sh`). git on Windows cannot index
  one, and `untar.js` cannot create one in MEMFS - the browser would have had
  the name and no file.
- **A link whose target was removed goes with it.** `wslpayload.sh` drops the
  drivers this does not need, and `x86_64-alpine-linux-musl-cc` pointed at one.
- **`.gitattributes` marks `guest/tree/**` as not-text.** Otherwise git rewrites
  the line endings of every C++ header on checkout, and a compile then fails for
  reasons that have nothing to do with the program being compiled.

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

## The flag that cost 5x, and how it went unnoticed

Worth reading before touching `web/build.sh`.

A C++ compile aborted in the browser with `Aborted(undefined)`. The cause was
that emscripten's default turns every `throw` into `abort()`, so the emulator's
own diagnostics - which are exceptions - were destroyed on the way out. Adding
`-sDISABLE_EXCEPTION_CATCHING=0` fixed that and was the right diagnosis.

It also wraps every call that can throw in JavaScript, and this emulator throws
on faults. **A C compile went from 6.6 s to 23 s.**

It stayed there for an afternoon, because in the same window gcc dropped from
13.2 to 6.4 and the emulator got 2.6x faster - so the browser numbers read as
"C++ is still slow" rather than "everything is slower than this morning". Two
real improvements were hiding a regression three times their size.

What caught it: the prediction and the measurement disagreed. 35 s expected from
the arithmetic, 241 s observed. Had the arithmetic been trusted - and it was
sound arithmetic about two sound improvements - students would have been handed
a four-minute compile.

`-fwasm-exceptions` is the native proposal, in every browser since 2023, costs
nothing when nothing throws, and makes the module smaller (1.09 MB against 1.31).
**If a diagnostic flag goes in, take it out.**

## Where the speed work got to (2026-08-08 evening)

Two changes to `x86_emu_cpp/src/cpu.cpp`, committed as `b1f54c9`, both of which
remove work from before every instruction rather than changing how instructions
run. The test suite stayed at 10 passed, 0 failed throughout, which is the point
of doing it in this order.

- **The hook check.** `step()` called `on_hook_call` - a `std::function` - for
  every instruction, and the first thing that callback did was compare the
  address against two numbers and return false. The range is on the `Cpu` now
  and the callback is reached only when the address is inside it. `add_hook`
  keeps it current, because hooks are registered while the guest runs.
- **Three diagnostics that are always off.** Profiling, the census and the
  instruction history each cost a load and a branch to establish they were
  disabled. One `watching_` flag now covers all three.

**About 2.6x.** Seven runs of the same binary gave 323 to 396 ms against a
baseline of 838; the best is 2.59x. The commit message says 2.74x, which was one
run of three and the top of the spread - the right order of magnitude quoted
with more precision than it had. `RUNS=7 sh tools/bench.sh` is the honest form.

### What was tried and made it slower

Removing a *real* redundancy: every instruction without a prefix read its opcode
byte twice, once for the prefix loop to discover it was not a prefix and once to
use it. Keeping the byte instead cost 33% - the extra branch was worse than the
memory read it saved.

That result is the useful one. **An optimisation that adds a branch is likely to
lose**, and the two that worked did not add any: the hook check replaced an
indirect call with a comparison that was already being made, and the diagnostics
change turned three branches into one. Judge the next idea by that first.

### Not attempted, on purpose

- **A separate code-page cache for instruction fetch.** It would be a second
  cache alongside `Memory`'s TLB, and both would have to be invalidated when a
  page is remapped. Forget one and the guest executes stale instructions, which
  looks like data corruption a long way from the cause.
- **The decoded-instruction cache below.** Same hazard, larger. And now that a
  removed memory read has been seen to lose to an added branch, its benefit is a
  hypothesis rather than an expectation: it removes decoding but adds a lookup
  and a branch per instruction. Measure a prototype before committing to the
  rewrite.

## The larger prize, still unclaimed: a decoded-instruction cache

**C is fine and C++ is not.** In WebAssembly, under node:

| | |
| --- | --- |
| `gcc -O2 hello.c` | **6.6 s** |
| running what it produced | 0.0–0.3 s |
| `g++ -O2 hello.cpp` (iostream, vector, sort) | **118 s** |

Six seconds is a usable tool. Two minutes is not, and the difference is not the
language: it was measured apart, and here is where it goes.

    9.1 s  C, nothing included
    8.1 s  C++, nothing included        <- cc1plus itself is not the problem
    8.8 s  C++, <cstdio> only
   71.4 s  C++, <vector> <algorithm>    <- it jumps here
   75.3 s  C++, <iostream>
   78.3 s  C++, <iostream>, -O2         <- the optimiser is almost free
   16.6 s  C++, <iostream>, -E only     <- preprocessing is 17 of the 75

`<iostream>` preprocesses to 808 KB and the remaining sixty seconds are spent
parsing it. Not preprocessing - parsing. `<vector>` and `<algorithm>` alone cost
71 s, so this is not something about iostream. It is what a C++ standard library
is.

### The precompiled header, which ships

    66.9 s   g++ -O2 -Wall, in WebAssembly, as the page runs it
    24.3 s   the same with the header the toolchain now carries

Both compile, both run, both print the same thing - which matters more than the
clock, because a faster build that produces something else is not a faster
build. `tools/wslmkpch.sh` builds it (100 s, once, here), `tools/wslpack.sh`
carries it, and `web/worker.js` passes `-I/pch -include std.hpp`.

**Only for -O2.** GCC declines a header whose options do not match, says nothing
whatever about it, and re-reads the real ones - having first read the 28 MB file
it is about to reject. At `-O0 -g` that is 72 s against 57 s without: passing it
where it does not apply is worse than not having it at all.

This was written off twice, and both reasons were wrong.

*"A third again on the payload"* compared an uncompressed 28 MB file against a
download that is gzipped 3.5x. The header adds **4.6 MB** to a 54.3 MB tarball -
eight per cent, for a compile nearly three times faster.

*"Tried, and not the answer"* was measured before the feature broke and never
re-measured after. `Sys::Mmap` ignored the address on a mapping without
MAP_FIXED and handed back a fresh region; GCC maps a .gch at the address it was
built for - asking, not insisting - and then follows pointers stored inside the
file. It read seventeen megabytes into the range it had asked for and died
there, saying `unmapped memory read` and nothing about PCH. Fixed upstream in
x86_emu_cpp: the hint is honoured when the range is free. `X86EMU_MMAP_TRACE=1`
prints every mapping with MOVED against the ones that were relocated, which is
the whole diagnosis.

The remaining idea, unmeasured: a second .gch built for `-O0 -g`, so the debug
setting gets this too. Another 4.6 MB and another 100 s of build; whether the
debug option is used enough to be worth it is a judgement, not a measurement.

And a measurement that says where any of this would have to pay off. The C++
compile, by stage (`tools/wslstages.sh`, native emulator):

    96.16 s  g++, everything
    93.19 s    cc1plus alone (-S)
    61.33 s      of which parsing (-fsyntax-only)
     0.67 s    as
     ~3.9 s    collect2 and ld
     4.05 s  a whole four-process gcc run on an empty .c

cc1plus is **97 %** of it. Anything that reorganises the *pipeline* - fewer
processes, no .s file, a different assembler - is playing for three per cent.

### What cc1plus executes, and what the emulator spends on it

Two different questions, two tools, and they disagree about what matters.

`tools/wslopcount.sh` counts the guest's opcodes. Parsing is 1.5 G instructions:

    89 MOV r/m,r 14.0 %   8B MOV r,r/m 9.7 %   83 ALU imm8 7.7 %
    74 JE 6.1 %   75 JNE 3.9 %   85 TEST 3.6 %   C3 RET 3.0 %   E8 CALL 2.9 %
    39 CMP 2.6 %   31 XOR 2.5 %   8D LEA 2.4 %   55/5D push/pop rbp 1.9 % each

Nothing like voicevox's parse, which was MOV/XOR/AND/shift and no branches worth
naming. This is **16 % conditional branches and 6 % call/ret** - a compiler
walking trees and chasing pointers.

`tools/wslprofile.sh` says where the emulator's own time goes running that:

    step()          53.6 %
    decode_modrm    15.1 %   (929 M calls - 62 % of instructions)
    run_slice        6.8 %
    read_sized       4.0 %
    set_szp          2.4 %
    rm_read          2.3 %
    cond             2.0 %

**Flags are not the lever.** 20 % of the guest's instructions set them, which
looked like a target - and `set_szp` + `set_flags_sub` + `set_flags_logic` +
`set_flags_add` together are **4.8 %** of host time. Batching the six
read-modify-writes of `rflags` into one would win a fraction of that. Lazy flags
are worse than they look for the same reason: flag-setting instructions are
20 % and the conditional branches that read them are 16 %, so nearly every
computed flag is actually consumed - deferring the work does not remove it and
adds a test to every read.

**step() and decode_modrm are 69 %.** The one bounded idea in that was to split
mod == 3 - a register operand, no SIB, no displacement - into an inline fast
path, so the shortest route through `decode_modrm` stopped going through a call
to a large out-of-line function.

**Tried, and it is slower.** `tools/wslab.sh`, three interleaved rounds of
`g++ -fsyntax-only`:

    before  56.90  55.74  55.42     (56.02 avg)
    after   76.15  59.12  56.31     (63.86 avg)

The 76 is an outlier, but every paired round has `after` above `before`. The
explanation that fits: `step()` is already 53 % of host time and the largest
function there is, `decode_modrm` is called by 62 % of instructions, and
inlining the second into the first trades one call for a great deal more code in
the hottest loop. This repository already records that *an optimisation which
adds a branch tends to lose here*; this is the same lesson arriving through code
size instead.

So `-pg`'s 15 % for `decode_modrm` was mostly the instrumentation: with
inlining on, the call is not what costs. Reverted.

Which leaves the honest position: nothing cheap is left in the interpreter for
this workload. Four things have now been measured and three of them were
nothing - the prefix switch, the census hoist, and this - while the fetch cursor
was 3 %. The remaining idea of any size is still the one in
`x86_emu_cpp/resume.md`: restructure dispatch, with a differential harness built
first so it can be done safely. Days, not hours.

**So: give the CPU a decoded-instruction cache.** It is the first thing
`x86_emu_cpp/resume.md` lists under performance, it helps everything rather than
one language, and cc1plus parsing templates is exactly the shape it is for - a
few hot loops executing the same bytes millions of times, decoded from scratch
every single time.

What that means concretely, in `x86_emu_cpp/src/cpu.cpp`:

- `step()` currently decodes prefixes, opcode, ModRM and SIB from memory on
  every instruction, then dispatches through a switch. The decode is pure
  function of the bytes at RIP.
- So: a hash map (or a direct-mapped array, which is faster and enough) from
  guest address to a small struct holding the decoded form - opcode, operand
  sizes, register numbers, displacement, immediate, and the length. On a hit,
  skip straight to execution.
- **Invalidation is the part to get right.** Guest code can be written to: a
  loader relocating, a JIT, `mmap` of a new library over an old address. The
  cheap and correct rule is to clear the whole cache on any write to a page that
  has ever been decoded from - `Memory` already knows which pages exist and
  would need a "code" bit per page. Getting this wrong produces a guest that
  executes stale instructions, which looks like data corruption a long way
  from the cause.
- Measure with `tools/wslcheck.sh` (native, 5.3 s today) before touching
  anything, and against the four cases above afterwards.

A reasonable target is 3-5x. That would put C++ at fifteen to twenty seconds and
C at two, which is a different product.

Do this in `x86_emu_cpp` rather than in the copy here, and bring the copy
forward afterwards - `voicevox_emu_cpp` gets it for free and has its own
timings to check it against.

## Things worth deciding

- **How much MNIST.** 4000 images × 3 epochs is a guess made before any of it
  was timed. It should be the largest number that finishes in about a minute,
  and that number changes if the cache above lands.
- **What to do about C++ until then.** The examples could stay on `<cstdio>`,
  which compiles in 8.8 s — but a C++ course that avoids `<vector>` is not
  teaching C++, so this is a stopgap and not a design.
