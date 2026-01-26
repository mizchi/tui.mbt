// TUI native C stub for terminal I/O
// Provides raw mode, terminal size, and non-blocking I/O

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <termios.h>
#include <sys/ioctl.h>
#include <fcntl.h>
#include <errno.h>

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
#include <time.h>

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
