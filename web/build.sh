#!/bin/sh
# The emulator as WebAssembly, for web/index.html.
#
# web/x86emu.js and web/x86emu.wasm are committed so GitHub Pages can serve
# them, so **rebuild and recommit both whenever web/wasm_api.cpp or
# x86_emu_cpp/src/ changes** - a page running last week's module against this
# week's JavaScript fails in ways that are nowhere in the source.
set -e
cd "$(dirname "$0")/.."
EMCC=${EMCC:-emcc}
command -v "$EMCC" >/dev/null 2>&1 || [ -x "$EMCC" ] ||
    { echo "emcc not found; set EMCC=/path/to/emcc"; exit 1; }

# WebAssembly's own exceptions, not emscripten's JavaScript ones.
#
# -sDISABLE_EXCEPTION_CATCHING=0 was added to find out why a C++ compile aborted
# with nothing readable in it.  It worked - and it wraps every call that can
# throw in JavaScript, and the emulator throws on faults.  The cost was 3.5x: a C
# compile went from 6.6 s to 23 s, and it went unnoticed for an afternoon because
# two genuine speedups landed in the same window and the browser numbers were
# read as "still slow" rather than "slower than this morning".
#
# -fwasm-exceptions is the native proposal - every browser since 2023 - and costs
# nothing when nothing throws.
#
# The link has to be a C++ one.  emcc decides that from its inputs and decides
# wrong here, and every `throw` in the emulator then comes back as an undefined
# symbol.  The driver is em++, not emcc++ - `${EMCC}++` looks right and names a
# file that does not exist.
EMXX=${EMXX:-$(dirname "$EMCC")/em++}
[ -x "$EMXX" ] || command -v "$EMXX" >/dev/null 2>&1 || EMXX="$EMCC -sDEFAULT_TO_CXX"

SOURCES=$(ls x86_emu_cpp/src/*.cpp | grep -v '/main\.cpp$')

echo "== web/x86emu.js"
# The heap has to grow a long way: cc1plus is 35 MB of guest image before it has
# read a line of the student's program, and the guest's own allocations follow.
# Not SINGLE_FILE - a 35 MB module base64'd into JavaScript is worse than two
# files, and the .wasm caches on its own.
$EMXX -std=c++17 -O3 -Ix86_emu_cpp/src \
    $SOURCES web/wasm_api.cpp \
    -o web/x86emu.js \
    -sMODULARIZE=1 \
    -sEXPORT_NAME=createEmu \
    -sALLOW_MEMORY_GROWTH=1 \
    -sMAXIMUM_MEMORY=4GB \
    -sSTACK_SIZE=4MB \
    -sEXPORTED_FUNCTIONS='["_emu_run","_emu_set_sysroot","_emu_setenv","_emu_error","_emu_instructions","_malloc","_free"]' \
    -sEXPORTED_RUNTIME_METHODS='["ccall","cwrap","HEAPU8","FS"]' \
    -sENVIRONMENT=web,worker,node \
    -sEXIT_RUNTIME=0 \
    -sASSERTIONS=0 \
    -fwasm-exceptions

ls -l web/x86emu.js web/x86emu.wasm
