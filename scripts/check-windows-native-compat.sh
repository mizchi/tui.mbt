#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
HEADER_DIR="$ROOT_DIR/scripts/windows-headers"

cc \
  -D_WIN32 \
  -I"$HEADER_DIR" \
  -fsyntax-only \
  "$ROOT_DIR/src/io/tui_native.c"
