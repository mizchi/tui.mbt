///|
/// ANSI Escape Sequences for terminal output.
/// This package is intentionally layout-free so browser and renderer adapters
/// can reuse terminal primitives without pulling in TUI layout dependencies.

///|
pub fn ansi_reset() -> String {
  "\u001b[0m"
}

///|
pub fn ansi_bold() -> String {
  "\u001b[1m"
}

///|
pub fn ansi_dim() -> String {
  "\u001b[2m"
}

///|
pub fn ansi_underline() -> String {
  "\u001b[4m"
}

///|
pub fn ansi_reverse() -> String {
  "\u001b[7m"
}

///|
pub fn ansi_fg_black() -> String {
  "\u001b[30m"
}

///|
pub fn ansi_fg_red() -> String {
  "\u001b[31m"
}

///|
pub fn ansi_fg_green() -> String {
  "\u001b[32m"
}

///|
pub fn ansi_fg_yellow() -> String {
  "\u001b[33m"
}

///|
pub fn ansi_fg_blue() -> String {
  "\u001b[34m"
}

///|
pub fn ansi_fg_magenta() -> String {
  "\u001b[35m"
}

///|
pub fn ansi_fg_cyan() -> String {
  "\u001b[36m"
}

///|
pub fn ansi_fg_white() -> String {
  "\u001b[37m"
}

///|
pub fn ansi_fg_gray() -> String {
  "\u001b[90m"
}

///|
pub fn ansi_fg_256(color_idx : Int) -> String {
  "\u001b[38;5;" + color_idx.to_string() + "m"
}

///|
pub fn ansi_bg_256(color_idx : Int) -> String {
  "\u001b[48;5;" + color_idx.to_string() + "m"
}

///|
pub fn ansi_bg_reset() -> String {
  "\u001b[49m"
}

///|
pub fn ansi_move_up(n? : Int = 1) -> String {
  "\u001b[" + n.to_string() + "A"
}

///|
pub fn ansi_move_down(n? : Int = 1) -> String {
  "\u001b[" + n.to_string() + "B"
}

///|
pub fn ansi_move_right(n? : Int = 1) -> String {
  "\u001b[" + n.to_string() + "C"
}

///|
pub fn ansi_move_left(n? : Int = 1) -> String {
  "\u001b[" + n.to_string() + "D"
}

///|
/// Move cursor to a 0-indexed row/column.
pub fn ansi_move_to(row : Int, col : Int) -> String {
  "\u001b[" + (row + 1).to_string() + ";" + (col + 1).to_string() + "H"
}

///|
pub fn ansi_clear_screen() -> String {
  "\u001b[2J"
}

///|
pub fn ansi_clear_line() -> String {
  "\u001b[2K"
}

///|
pub fn ansi_hide_cursor() -> String {
  "\u001b[?25l"
}

///|
pub fn ansi_show_cursor() -> String {
  "\u001b[?25h"
}

///|
pub fn ansi_enter_alt_screen() -> String {
  "\u001b[?1049h"
}

///|
pub fn ansi_leave_alt_screen() -> String {
  "\u001b[?1049l"
}

///|
pub fn ansi_reset_attrs() -> String {
  ansi_reset()
}

///|
pub fn ansi_full_reset() -> String {
  ansi_reset() +
  ansi_enter_alt_screen() +
  ansi_hide_cursor() +
  ansi_clear_screen() +
  "\u001b[H"
}

///|
pub fn rgb_to_256(r : Int, g : Int, b : Int) -> Int {
  if r == g && g == b {
    if r < 8 {
      16
    } else if r > 248 {
      231
    } else {
      232 + (r - 8) * 24 / 240
    }
  } else {
    let r6 = r * 6 / 256
    let g6 = g * 6 / 256
    let b6 = b * 6 / 256
    16 + r6 * 36 + g6 * 6 + b6
  }
}

///|
pub fn enable_mouse() -> String {
  "\u001b[?1000h\u001b[?1006h"
}

///|
pub fn disable_mouse() -> String {
  "\u001b[?1006l\u001b[?1000l"
}

///|
pub fn enable_mouse_all() -> String {
  "\u001b[?1003h\u001b[?1006h"
}

///|
pub fn disable_mouse_all() -> String {
  "\u001b[?1006l\u001b[?1003l"
}
