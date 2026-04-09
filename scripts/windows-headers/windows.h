#ifndef TUI_FAKE_WINDOWS_H
#define TUI_FAKE_WINDOWS_H

#include <stdint.h>

typedef void* HANDLE;
typedef unsigned long DWORD;
typedef int BOOL;
typedef unsigned short WORD;
typedef uintptr_t ULONG_PTR;
typedef intptr_t LONG_PTR;
typedef uint64_t ULONGLONG;

typedef struct _COORD {
  short X;
  short Y;
} COORD;

typedef struct _SMALL_RECT {
  short Left;
  short Top;
  short Right;
  short Bottom;
} SMALL_RECT;

typedef struct _CONSOLE_SCREEN_BUFFER_INFO {
  COORD dwSize;
  COORD dwCursorPosition;
  WORD wAttributes;
  SMALL_RECT srWindow;
  COORD dwMaximumWindowSize;
} CONSOLE_SCREEN_BUFFER_INFO;

#define STD_INPUT_HANDLE ((DWORD)-10)
#define STD_OUTPUT_HANDLE ((DWORD)-11)

#define ENABLE_PROCESSED_INPUT 0x0001
#define ENABLE_LINE_INPUT 0x0002
#define ENABLE_ECHO_INPUT 0x0004
#define ENABLE_VIRTUAL_TERMINAL_INPUT 0x0200

#define FILE_SHARE_READ 0x00000001
#define FILE_SHARE_WRITE 0x00000002
#define GENERIC_READ 0x80000000
#define GENERIC_WRITE 0x40000000
#define OPEN_EXISTING 3

#define INVALID_HANDLE_VALUE ((HANDLE)(LONG_PTR)-1)

HANDLE GetStdHandle(DWORD nStdHandle);
BOOL GetConsoleMode(HANDLE hConsoleHandle, DWORD* lpMode);
BOOL SetConsoleMode(HANDLE hConsoleHandle, DWORD dwMode);
HANDLE CreateFileA(
  const char* lpFileName,
  DWORD dwDesiredAccess,
  DWORD dwShareMode,
  void* lpSecurityAttributes,
  DWORD dwCreationDisposition,
  DWORD dwFlagsAndAttributes,
  HANDLE hTemplateFile
);
BOOL CloseHandle(HANDLE hObject);
BOOL GetConsoleScreenBufferInfo(
  HANDLE hConsoleOutput,
  CONSOLE_SCREEN_BUFFER_INFO* lpConsoleScreenBufferInfo
);
BOOL WriteFile(
  HANDLE hFile,
  const void* lpBuffer,
  DWORD nNumberOfBytesToWrite,
  DWORD* lpNumberOfBytesWritten,
  void* lpOverlapped
);
void Sleep(DWORD dwMilliseconds);
ULONGLONG GetTickCount64(void);

#endif
