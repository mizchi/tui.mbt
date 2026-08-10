#!/bin/sh

set -eu

if [ "$#" -lt 1 ]; then
  echo "usage: $0 <program.wasm> [args...]" >&2
  exit 2
fi

if [ ! -t 0 ]; then
  exec moonrun "$@"
fi

saved_tty=$(stty -g)
restore_tty() {
  stty "$saved_tty"
}
trap restore_tty EXIT HUP INT TERM

stty raw -echo
moonrun "$@"
