#!/usr/bin/env bash
# Guards the native C stub against issue #6, where the Windows build broke
# because tui_native.c reached for <unistd.h> and friends unconditionally.
#
# Both sides of the `#ifdef _WIN32` split are checked for two things:
#
#   1. the translation unit compiles, warning-free
#   2. every symbol io_native.mbt declares `extern "C"` is actually defined
#
# (2) matters because the two branches are written independently, so a helper
# added to one and forgotten in the other still compiles and only fails when a
# user links it on the other platform.
#
# The Windows side is compiled with mingw-w64 against the real Windows SDK
# headers, with scripts/windows-poison/ ahead of them on the include path.
# mingw ships a <unistd.h> that MSVC does not, so without those poison headers
# this check would happily accept the exact bug from issue #6.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
POISON_DIR="$ROOT_DIR/scripts/windows-poison"
STUB="$ROOT_DIR/src/io/tui_native.c"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

# Kept in sync with the `extern "C"` declarations at the top of
# src/io/io_native.mbt.
EXTERNS=(
  tui_enable_raw_mode
  tui_disable_raw_mode
  tui_is_raw_mode
  tui_get_terminal_cols
  tui_get_terminal_rows
  tui_read_byte
  tui_write_bytes
  tui_flush
  tui_is_tty
  tui_sleep_ms
  tui_get_time_ms
)

fail=0

check_externs() {
  local label="$1" nm_tool="$2" obj="$3" defined missing=()
  defined="$("$nm_tool" --defined-only "$obj")"
  for sym in "${EXTERNS[@]}"; do
    grep -qw "$sym" <<<"$defined" || missing+=("$sym")
  done
  if [ ${#missing[@]} -gt 0 ]; then
    echo "  $label: missing definitions: ${missing[*]}" >&2
    fail=1
  else
    echo "  $label: all ${#EXTERNS[@]} externs defined"
  fi
}

echo "POSIX (host cc)"
if cc -c -Wall -Wextra -Werror -o "$WORK_DIR/posix.o" "$STUB"; then
  check_externs "POSIX" nm "$WORK_DIR/posix.o"
else
  echo "  POSIX: compile failed" >&2
  fail=1
fi

MINGW="${MINGW_CC:-x86_64-w64-mingw32-gcc}"
if command -v "$MINGW" >/dev/null 2>&1; then
  echo "Windows ($MINGW, real SDK headers, POSIX headers poisoned)"
  if "$MINGW" -c -Wall -Wextra -Werror -I"$POISON_DIR" \
      -o "$WORK_DIR/windows.o" "$STUB"; then
    check_externs "Windows" "${MINGW%-gcc}-nm" "$WORK_DIR/windows.o"
  else
    echo "  Windows: compile failed" >&2
    fail=1
  fi
else
  echo "Windows: SKIPPED, $MINGW not found" >&2
  echo "  install mingw-w64 (apt install gcc-mingw-w64-x86-64) to run it" >&2
  echo "  CI always runs this side, so a Windows regression is still caught" >&2
fi

exit "$fail"
