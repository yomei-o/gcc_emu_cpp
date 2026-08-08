// The emulator, as something a page can call.
//
// One entry point does the whole job: run a program from the guest's filesystem
// and hand back its exit code.  The page compiles by running gcc, and runs the
// result by running the file gcc produced - the same call, twice, which is what
// makes this small.
//
// Everything else the page needs it does through emscripten's FS: it writes the
// student's source in, it reads the program's output back.  There is no protocol
// to keep in step.
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <string>
#include <vector>

#include "emulator.h"
#include "files.h"

#if defined(__EMSCRIPTEN__)
#include <emscripten.h>

// Guest output is bytes, not text: a compiler's diagnostics are UTF-8 and a
// student's program may print anything at all, so the decoding happens in JS
// where a partial character can be held over to the next chunk.
EM_JS(void, js_guest_output, (int fd, const char* ptr, int len), {
    globalThis.emuOutput(fd, HEAPU8.slice(ptr, ptr + len));
});
EM_JS(void, js_guest_log, (const char* ptr), { globalThis.emuLog(UTF8ToString(ptr)); });
#else
static void js_guest_output(int, const char*, int) {}
static void js_guest_log(const char*) {}
#endif

namespace {

std::string g_error;
uint64_t g_instructions = 0;
std::vector<std::pair<std::string, std::string>> g_env;

std::vector<std::string> split_nul(const char* data, int len) {
    std::vector<std::string> out;
    int i = 0;
    while (i < len) {
        int j = i;
        while (j < len && data[j] != '\0') ++j;
        out.emplace_back(data + i, data + j);
        i = j + 1;
    }
    return out;
}

}  // namespace

extern "C" {

// Runs `argv[0]` with `argv`, both inside the sysroot, and returns its exit
// code - or -1 with emu_error() set if it could not be started at all.
//
// A compiler that fails to compile something exits non-zero, which is not this
// failing: the page shows the diagnostics and the student fixes the program.
int emu_run(const char* argv_data, int argv_len, const char* cwd, double max_insns) {
    g_error.clear();
    g_instructions = 0;

    std::vector<std::string> argv = split_nul(argv_data, argv_len);
    if (argv.empty()) {
        g_error = "no program";
        return -1;
    }

    x86emu::Emulator::Options opt;
    // A runaway net rather than a budget.  A student's infinite loop should stop
    // being a browser tab that never comes back, and forty billion instructions
    // is far past anything a teaching program does - gcc itself takes about two
    // hundred million to build hello world.
    opt.max_instructions = max_insns > 0 ? static_cast<uint64_t>(max_insns)
                                         : 40000000000ull;
    x86emu::Emulator emu(opt);
    emu.output_sink = [](int fd, const char* p, size_t n) {
        js_guest_output(fd, p, static_cast<int>(n));
    };

    // The guest gets a plausible environment rather than the page's: gcc reads
    // PATH and TMPDIR, and a Linux guest is given only PATH unless told
    // otherwise.
    std::vector<std::pair<std::string, std::string>> env{
        {"PATH", "/usr/bin:/bin"},
        {"TMPDIR", "/tmp"},
        {"HOME", "/work"},
        {"PWD", cwd && *cwd ? cwd : "/work"},
        {"LANG", "C"},
    };
    for (const auto& kv : g_env) env.push_back(kv);
    emu.set_environment(std::move(env));

    try {
        emu.load(argv[0], argv);
    } catch (const std::exception& err) {
        g_error = err.what();
        return -1;
    }
    int code;
    try {
        code = emu.run();
    } catch (const std::exception& err) {
        g_error = err.what();
        g_instructions = emu.cpu().instructions_executed;
        return -1;
    }
    g_instructions = emu.cpu().instructions_executed;
    return code;
}

// Where the guest's `/` is, in the emscripten filesystem.
void emu_set_sysroot(const char* dir) {
    x86emu::FileTable::set_sysroot(dir ? dir : "");
}

// A variable the *guest* will see.  Not the same as this process's environment,
// which the guest cannot read.
void emu_setenv(const char* name, const char* value) {
    if (!name || !*name) return;
    for (size_t i = 0; i < g_env.size(); i++) {
        if (g_env[i].first != name) continue;
        if (value && *value) g_env[i].second = value;
        else g_env.erase(g_env.begin() + static_cast<long>(i));
        return;
    }
    if (value && *value) g_env.emplace_back(name, value);
}

const char* emu_error() { return g_error.c_str(); }
double emu_instructions() { return static_cast<double>(g_instructions); }

}  // extern "C"
