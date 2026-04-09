// TUI native C stub for terminal I/O
// Provides raw mode, terminal size, and non-blocking I/O

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

#ifdef _WIN32
#include <windows.h>
#include <conio.h>
#include <io.h>
#else
#include <unistd.h>
#include <termios.h>
#include <sys/ioctl.h>
#include <fcntl.h>
#include <errno.h>
#include <time.h>
#endif

#ifdef _WIN32

// Store original console mode for restoration
static DWORD orig_input_mode = 0;
static int raw_mode_enabled = 0;

// Console handle for keyboard input (STDIN or CONIN$ fallback)
static HANDLE tty_handle = INVALID_HANDLE_VALUE;
static int tty_handle_opened = 0; // 1 if we opened CONIN$ ourselves

// Queue translated ANSI bytes for Windows special keys
static unsigned char pending_bytes[8];
static int pending_len = 0;
static int pending_pos = 0;

static void reset_pending_bytes(void) {
    pending_len = 0;
    pending_pos = 0;
}

static int queue_sequence(const unsigned char* seq, int len) {
    if (len <= 0) return -1;
    if (len > (int)sizeof(pending_bytes)) {
        len = (int)sizeof(pending_bytes);
    }
    memcpy(pending_bytes, seq, (size_t)len);
    pending_len = len;
    pending_pos = 1;
    return pending_bytes[0];
}

static void release_tty_handle(void) {
    if (tty_handle_opened && tty_handle != INVALID_HANDLE_VALUE) {
        CloseHandle(tty_handle);
    }
    tty_handle = INVALID_HANDLE_VALUE;
    tty_handle_opened = 0;
}

static int pop_pending_byte(void) {
    if (pending_pos >= pending_len) {
        reset_pending_bytes();
        return -1;
    }
    int byte = pending_bytes[pending_pos++];
    if (pending_pos >= pending_len) {
        reset_pending_bytes();
    }
    return byte;
}

// Get the input console handle
// Falls back to CONIN$ if stdin is not attached to a console
static HANDLE get_tty_handle(void) {
    if (tty_handle != INVALID_HANDLE_VALUE) return tty_handle;

    HANDLE stdin_handle = GetStdHandle(STD_INPUT_HANDLE);
    DWORD mode = 0;
    if (stdin_handle != INVALID_HANDLE_VALUE && GetConsoleMode(stdin_handle, &mode)) {
        tty_handle = stdin_handle;
        tty_handle_opened = 0;
        return tty_handle;
    }

    tty_handle = CreateFileA(
        "CONIN$",
        GENERIC_READ | GENERIC_WRITE,
        FILE_SHARE_READ | FILE_SHARE_WRITE,
        NULL,
        OPEN_EXISTING,
        0,
        NULL
    );
    if (tty_handle != INVALID_HANDLE_VALUE) {
        tty_handle_opened = 1;
    }
    return tty_handle;
}

static int translate_special_key(int code) {
    switch (code) {
        case 72: { // Up
            static const unsigned char seq[] = { 0x1b, '[', 'A' };
            return queue_sequence(seq, 3);
        }
        case 80: { // Down
            static const unsigned char seq[] = { 0x1b, '[', 'B' };
            return queue_sequence(seq, 3);
        }
        case 77: { // Right
            static const unsigned char seq[] = { 0x1b, '[', 'C' };
            return queue_sequence(seq, 3);
        }
        case 75: { // Left
            static const unsigned char seq[] = { 0x1b, '[', 'D' };
            return queue_sequence(seq, 3);
        }
        case 71: { // Home
            static const unsigned char seq[] = { 0x1b, '[', 'H' };
            return queue_sequence(seq, 3);
        }
        case 79: { // End
            static const unsigned char seq[] = { 0x1b, '[', 'F' };
            return queue_sequence(seq, 3);
        }
        case 73: { // Page Up
            static const unsigned char seq[] = { 0x1b, '[', '5', '~' };
            return queue_sequence(seq, 4);
        }
        case 81: { // Page Down
            static const unsigned char seq[] = { 0x1b, '[', '6', '~' };
            return queue_sequence(seq, 4);
        }
        case 82: { // Insert
            static const unsigned char seq[] = { 0x1b, '[', '2', '~' };
            return queue_sequence(seq, 4);
        }
        case 83: { // Delete
            static const unsigned char seq[] = { 0x1b, '[', '3', '~' };
            return queue_sequence(seq, 4);
        }
        default:
            return -1;
    }
}

static int read_console_byte(void) {
    int pending = pop_pending_byte();
    if (pending >= 0) {
        return pending;
    }

    if (!_kbhit()) {
        return -1;
    }

    int ch = _getch();
    if (ch == 0 || ch == 0xE0) {
        return translate_special_key(_getch());
    }
    if (ch == 8) {
        return 127; // Normalize backspace to DEL like POSIX terminals
    }
    return ch;
}

// Enable raw mode for character-by-character input
int tui_enable_raw_mode(void) {
    if (raw_mode_enabled) return 0;

    HANDLE handle = get_tty_handle();
    if (handle == INVALID_HANDLE_VALUE) return -1;

    if (!GetConsoleMode(handle, &orig_input_mode)) {
        release_tty_handle();
        return -1;
    }

    DWORD raw_mode = orig_input_mode & ~(ENABLE_ECHO_INPUT | ENABLE_LINE_INPUT | ENABLE_PROCESSED_INPUT);
#ifdef ENABLE_VIRTUAL_TERMINAL_INPUT
    if (!SetConsoleMode(handle, raw_mode | ENABLE_VIRTUAL_TERMINAL_INPUT) &&
        !SetConsoleMode(handle, raw_mode)) {
        release_tty_handle();
        return -1;
    }
#else
    if (!SetConsoleMode(handle, raw_mode)) {
        release_tty_handle();
        return -1;
    }
#endif

    raw_mode_enabled = 1;
    return 0;
}

// Disable raw mode and restore original settings
int tui_disable_raw_mode(void) {
    if (!raw_mode_enabled) return 0;

    HANDLE handle = get_tty_handle();
    if (handle == INVALID_HANDLE_VALUE) return 0;

    if (!SetConsoleMode(handle, orig_input_mode)) {
        release_tty_handle();
        return -1;
    }

    release_tty_handle();
    reset_pending_bytes();
    raw_mode_enabled = 0;
    return 0;
}

// Check if raw mode is enabled
int tui_is_raw_mode(void) {
    return raw_mode_enabled;
}

// Get terminal size (columns, rows)
int tui_get_terminal_cols(void) {
    CONSOLE_SCREEN_BUFFER_INFO info;
    HANDLE stdout_handle = GetStdHandle(STD_OUTPUT_HANDLE);
    if (stdout_handle == INVALID_HANDLE_VALUE ||
        !GetConsoleScreenBufferInfo(stdout_handle, &info)) {
        return 80; // default
    }
    return (int)(info.srWindow.Right - info.srWindow.Left + 1);
}

int tui_get_terminal_rows(void) {
    CONSOLE_SCREEN_BUFFER_INFO info;
    HANDLE stdout_handle = GetStdHandle(STD_OUTPUT_HANDLE);
    if (stdout_handle == INVALID_HANDLE_VALUE ||
        !GetConsoleScreenBufferInfo(stdout_handle, &info)) {
        return 24; // default
    }
    return (int)(info.srWindow.Bottom - info.srWindow.Top + 1);
}

// Read a single byte from console input (non-blocking)
// Returns -1 if no data available, or the byte value (0-255)
int tui_read_byte(void) {
    return read_console_byte();
}

// Read up to max_len bytes into buffer
// Returns number of bytes read, or -1 when no data is available
int tui_read_bytes(unsigned char* buf, int max_len) {
    if (max_len <= 0) return -1;

    int first = read_console_byte();
    if (first < 0) return -1;

    buf[0] = (unsigned char)first;
    int count = 1;
    while (count < max_len) {
        int next = read_console_byte();
        if (next < 0) break;
        buf[count++] = (unsigned char)next;
    }
    return count;
}

// Write string to stdout without newline
void tui_print_raw(const char* str, int len) {
    DWORD written = 0;
    HANDLE stdout_handle = GetStdHandle(STD_OUTPUT_HANDLE);
    if (stdout_handle != INVALID_HANDLE_VALUE &&
        WriteFile(stdout_handle, str, (DWORD)len, &written, NULL)) {
        return;
    }
    fwrite(str, 1, (size_t)len, stdout);
}

// Write bytes to stdout without newline
void tui_write_bytes(const unsigned char* buf, int len) {
    DWORD written = 0;
    HANDLE stdout_handle = GetStdHandle(STD_OUTPUT_HANDLE);
    if (stdout_handle != INVALID_HANDLE_VALUE &&
        WriteFile(stdout_handle, buf, (DWORD)len, &written, NULL)) {
        return;
    }
    fwrite(buf, 1, (size_t)len, stdout);
}

// Flush stdout
void tui_flush(void) {
    fflush(stdout);
}

// Check if a TTY is available for input (stdin or CONIN$)
int tui_is_tty(void) {
    HANDLE stdin_handle = GetStdHandle(STD_INPUT_HANDLE);
    DWORD mode = 0;
    if (stdin_handle != INVALID_HANDLE_VALUE && GetConsoleMode(stdin_handle, &mode)) {
        return 1;
    }

    HANDLE conin = CreateFileA(
        "CONIN$",
        GENERIC_READ | GENERIC_WRITE,
        FILE_SHARE_READ | FILE_SHARE_WRITE,
        NULL,
        OPEN_EXISTING,
        0,
        NULL
    );
    if (conin != INVALID_HANDLE_VALUE) {
        CloseHandle(conin);
        return 1;
    }
    return 0;
}

// Sleep for milliseconds
void tui_sleep_ms(int ms) {
    Sleep(ms > 0 ? (DWORD)ms : 0);
}

// Get current time in milliseconds (monotonic, relative to first call)
static ULONGLONG start_time_ms = 0;
static int start_time_initialized = 0;

int tui_get_time_ms(void) {
    ULONGLONG now_ms = GetTickCount64();
    if (!start_time_initialized) {
        start_time_ms = now_ms;
        start_time_initialized = 1;
    }
    return (int)(now_ms - start_time_ms);
}

#else

// Store original terminal settings for restoration
static struct termios orig_termios;
static int raw_mode_enabled = 0;

// File descriptor for keyboard input (STDIN_FILENO or /dev/tty)
static int tty_fd = -1;
static int tty_fd_opened = 0; // 1 if we opened /dev/tty ourselves

// Get the file descriptor for keyboard input
// Falls back to /dev/tty if stdin is not a tty (e.g., when used in a pipe)
static int get_tty_fd(void) {
    if (tty_fd >= 0) return tty_fd;

    if (isatty(STDIN_FILENO)) {
        tty_fd = STDIN_FILENO;
        tty_fd_opened = 0;
    } else {
        // stdin is not a tty (piped input), try /dev/tty
        tty_fd = open("/dev/tty", O_RDONLY);
        if (tty_fd >= 0) {
            tty_fd_opened = 1;
        }
    }
    return tty_fd;
}

// Enable raw mode for character-by-character input
// Uses TCSADRAIN instead of TCSAFLUSH to preserve pending input
int tui_enable_raw_mode(void) {
    if (raw_mode_enabled) return 0;

    int fd = get_tty_fd();
    if (fd < 0) return -1;

    if (tcgetattr(fd, &orig_termios) == -1) return -1;

    struct termios raw = orig_termios;
    // Input: no break, no CR to NL, no parity check, no strip, no flow control
    raw.c_iflag &= ~(BRKINT | ICRNL | INPCK | ISTRIP | IXON);
    // Output: disable post processing
    raw.c_oflag &= ~(OPOST);
    // Control: set 8 bit chars
    raw.c_cflag |= (CS8);
    // Local: no echo, no canonical, no extended, no signal chars
    raw.c_lflag &= ~(ECHO | ICANON | IEXTEN | ISIG);
    // Return each byte, no timeout
    raw.c_cc[VMIN] = 0;
    raw.c_cc[VTIME] = 1; // 100ms timeout

    if (tcsetattr(fd, TCSADRAIN, &raw) == -1) return -1;

    raw_mode_enabled = 1;
    return 0;
}

// Disable raw mode and restore original settings
// Uses TCSADRAIN instead of TCSAFLUSH to preserve pending input
int tui_disable_raw_mode(void) {
    if (!raw_mode_enabled) return 0;

    int fd = get_tty_fd();
    if (fd < 0) return 0;

    if (tcsetattr(fd, TCSADRAIN, &orig_termios) == -1) return -1;

    // Close /dev/tty if we opened it
    if (tty_fd_opened && tty_fd >= 0) {
        close(tty_fd);
        tty_fd = -1;
        tty_fd_opened = 0;
    }

    raw_mode_enabled = 0;
    return 0;
}

// Check if raw mode is enabled
int tui_is_raw_mode(void) {
    return raw_mode_enabled;
}

// Get terminal size (columns, rows)
int tui_get_terminal_cols(void) {
    struct winsize ws;
    if (ioctl(STDOUT_FILENO, TIOCGWINSZ, &ws) == -1 || ws.ws_col == 0) {
        return 80; // default
    }
    return ws.ws_col;
}

int tui_get_terminal_rows(void) {
    struct winsize ws;
    if (ioctl(STDOUT_FILENO, TIOCGWINSZ, &ws) == -1 || ws.ws_row == 0) {
        return 24; // default
    }
    return ws.ws_row;
}

// Read a single byte from tty (non-blocking in raw mode)
// Returns -1 if no data available, or the byte value (0-255)
int tui_read_byte(void) {
    int fd = get_tty_fd();
    if (fd < 0) return -1;

    unsigned char c;
    ssize_t n = read(fd, &c, 1);
    if (n <= 0) return -1;
    return (int)c;
}

// Read up to max_len bytes into buffer
// Returns number of bytes read, or -1 on error
int tui_read_bytes(unsigned char* buf, int max_len) {
    int fd = get_tty_fd();
    if (fd < 0) return -1;

    ssize_t n = read(fd, buf, max_len);
    if (n < 0) return -1;
    return (int)n;
}

// Write string to stdout without newline
void tui_print_raw(const char* str, int len) {
    write(STDOUT_FILENO, str, len);
}

// Write bytes to stdout without newline
void tui_write_bytes(const unsigned char* buf, int len) {
    write(STDOUT_FILENO, buf, len);
}

// Flush stdout
void tui_flush(void) {
    fflush(stdout);
}

// Check if a TTY is available for input (stdin or /dev/tty)
int tui_is_tty(void) {
    if (isatty(STDIN_FILENO)) return 1;
    // Check if /dev/tty is available
    int fd = open("/dev/tty", O_RDONLY);
    if (fd >= 0) {
        close(fd);
        return 1;
    }
    return 0;
}

// Sleep for milliseconds
void tui_sleep_ms(int ms) {
    usleep(ms * 1000);
}

// Get current time in milliseconds (monotonic, relative to first call)
static int64_t start_time_ms = -1;

int tui_get_time_ms(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    int64_t now_ms = (int64_t)ts.tv_sec * 1000 + ts.tv_nsec / 1000000;
    if (start_time_ms < 0) {
        start_time_ms = now_ms;
    }
    return (int)(now_ms - start_time_ms);
}

#endif
