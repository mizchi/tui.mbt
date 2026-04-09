#ifndef TUI_FAKE_IO_H
#define TUI_FAKE_IO_H

#include <stdio.h>

int _isatty(int fd);
int _fileno(FILE* stream);

#endif
