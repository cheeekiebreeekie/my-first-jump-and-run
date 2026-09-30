#include <string>
#include <iostream>
#include <filesystem>

namespace fs = std::filesystem;

#if defined(_WIN32)

#include <windows.h>
#include <cstdio>

#define EXE_EXT ".exe"
#define LIB_EXT "EXTENSION-NAME.windows.template_release.x86_64.dll"

void ensure_terminal(int argc, char* argv[]) {
    if (GetConsoleWindow() == NULL) {
        AllocConsole();
        freopen("CONOUT$", "w", stdout);
        freopen("CONOUT$", "w", stderr);
        freopen("CONIN$", "r", stdin);
    }
}

#else

#include <spawn.h>
#include <sys/wait.h>
#include <unistd.h>
#include <vector>

extern char** environ;

#define EXE_EXT ".x86_64"
#define LIB_EXT "libEXTENSION-NAME.linux.template_release.x86_64.so"

void ensure_terminal(int argc, char* argv[]) {
    if (isatty(STDOUT_FILENO)) return;

    // Terminals known to consistently accept -e
    std::vector<const char*> e_terminals = {
        "xterm",
        "konsole",
        "alacritty",
        "kitty",
        "foot",
        "termite",
        "urxvt",
        "rxvt",
        "x-terminal-emulator"
    };

    // If $TERMINAL is set, try it first
    if (const char* env_term = std::getenv("TERMINAL")) {
        e_terminals.insert(e_terminals.begin(), env_term);
    }

    // Build the fixed argument array: <terminal> -e <argv[0]> <argv[1]> ... NULL
    std::vector<char*> args;
    args.push_back(nullptr); // Placeholder for terminal binary name
    args.push_back(const_cast<char*>("-e"));

    for (int i = 0; i < argc; ++i) {
        args.push_back(argv[i]);
    }
    args.push_back(nullptr);

    // Probe PATH by swapping args[0] and calling execvp

    for (const char* term : e_terminals) {
        args[0] = const_cast<char*>(term);
        execvp(args[0], args.data());
    }

    system("zenity --error --text=\"No supported terminal found. Please install xterm, alacritty, kitty, or konsole.\" 2>/dev/null || "
        "kdialog --error \"No supported terminal found. Please install xterm, alacritty, kitty, or konsole.\" 2>/dev/null");

    std::cerr << "[ERROR] No compatible terminal emulator (-e) found on PATH.\n"
        << "Please install alacritty, kitty, konsole, or xterm.\n";

    _exit(EXIT_FAILURE);
}

#endif

bool file_exists(const std::string& path, bool regular_file){
    if (!regular_file){
    return fs::exists(path);
    }
    return fs::is_regular_file(path);
}

bool launch_executable(const char* path, char* const argv[]){
    #if defined(_WIN32)
        STARTUPINFOA si = {sizeof(si) };
        PROCESS_INFORMATION pi;
        if (CreateProcessA(path, NULL, NULL, NULL, FALSE, 0, NULL, "bin", &si, &pi)){
            CloseHandle(pi.hProcess);
            CloseHandle(pi.hThread);
            return true;
        }
        return false;
    #else
    pid_t pid;
    posix_spawnattr_t attr;
    posix_spawnattr_init(&attr);
    posix_spawnattr_setflags(&attr, POSIX_SPAWN_SETSID);
    int status = posix_spawn(&pid, path, NULL, &attr, argv, environ);
    posix_spawnattr_destroy(&attr);
    return (status == 0);
    #endif
}

void pause_terminal() {
    std::cout << "\nPress Enter to exit...";
    std::cin.get();
}

int main(int argc, char* argv[]){
    ensure_terminal(argc, argv);
    std::string exe_path = "bin/My_First_Jump_And_Run" EXE_EXT;
    std::string lib_path = "bin/" LIB_EXT;


    if (!file_exists(exe_path, true)){
        std::cerr << "[ERROR] Target binaries missing: " << exe_path << "\n";
        pause_terminal();
        return 1;
    }
    if (!file_exists(lib_path, true)){
        std::cerr << "[ERROR] Target binaries missing: " << lib_path << "\n";
        pause_terminal();
        return 1;
    }

    std::cout << "[LAUNCHER] Console initialized sucessfully!\n";
    std::cout << "[LAUNCHER] Initializing JumpAndRun...\n";
    std::cout << "[LAUNCHER] Target binaries: " << exe_path << "\n";

    if (!launch_executable(exe_path.c_str(), argv)){
        std::cerr << "[LAUNCHER] Failed to launch executable at: " << exe_path << std::endl;
        pause_terminal();
        return 1;
    }

    return 0;

}