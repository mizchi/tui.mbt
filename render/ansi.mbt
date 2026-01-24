///|
/// ANSI Escape Sequences for terminal output

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

// --- Basic foreground colors ---

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
/// Dim gray (bright black)
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
/// Reset background color to default
pub fn ansi_bg_reset() -> String {
  "\u001b[49m"
}

///|
/// Move cursor up by n lines
pub fn ansi_move_up(n? : Int = 1) -> String {
  "\u001b[" + n.to_string() + "A"
}

///|
/// Move cursor down by n lines
pub fn ansi_move_down(n? : Int = 1) -> String {
  "\u001b[" + n.to_string() + "B"
}

///|
/// Move cursor right by n columns
pub fn ansi_move_right(n? : Int = 1) -> String {
  "\u001b[" + n.to_string() + "C"
}

///|
/// Move cursor left by n columns
pub fn ansi_move_left(n? : Int = 1) -> String {
  "\u001b[" + n.to_string() + "D"
}

///|
pub fn ansi_move_to(row : Int, col : Int) -> String {
  // ANSI escape sequences use 1-indexed coordinates
  // We convert from 0-indexed to 1-indexed internally
  let ansi_row = row + 1
  let ansi_col = col + 1
  "\u001b[" + ansi_row.to_string() + ";" + ansi_col.to_string() + "H"
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
/// Reset all terminal attributes (colors, styles)
pub fn ansi_reset_attrs() -> String {
  "\u001b[0m"
}

///|
/// Full terminal reset sequence for recovering from corrupted state
pub fn ansi_full_reset() -> String {
  // Reset attributes + enter alt screen + hide cursor + clear + move to origin
  "\u001b[0m\u001b[?1049h\u001b[?25l\u001b[2J\u001b[H"
}

///|
/// Convert RGB color to 256-color palette index
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
pub fn color_to_256(color : @core.Color) -> Int {
  rgb_to_256(color.r, color.g, color.b)
}

///|
pub fn ansi_fg_color(color : @core.Color) -> String {
  ansi_fg_256(color_to_256(color))
}

///|
pub fn ansi_bg_color(color : @core.Color) -> String {
  ansi_bg_256(color_to_256(color))
}

///|
/// Convert CharBuffer to ANSI-encoded string
pub fn CharBuffer::to_ansi(self : CharBuffer) -> String {
  let sb = StringBuilder::new()
  let mut last_fg = -1
  let mut last_bg = -1
  let mut last_bold = false
  let mut last_underline = false
  for row = 0; row < self.height; row = row + 1 {
    sb.write_string(ansi_move_to(row, 0))
    let mut expected_col = 0
    for col = 0; col < self.width; col = col + 1 {
      let cell = self.get_cell(col, row)
      if cell.char == '\u0000' {
        // Skip wide char placeholder, but track that cursor should not advance
        continue
      }
      // If cursor position doesn't match expected, reposition
      if col != expected_col {
        sb.write_string(ansi_move_to(row, col))
      }
      expected_col = col + @core.char_display_width(cell.char)
      let fg_idx = if cell.fg.is_transparent() {
        7
      } else {
        color_to_256(cell.fg)
      }
      let bg_idx = if cell.bg.is_transparent() {
        -1
      } else {
        color_to_256(cell.bg)
      }
      let need_reset = (last_bold && not(cell.bold)) ||
        (last_underline && not(cell.underline))
      if need_reset {
        sb.write_string(ansi_reset())
        last_fg = -1
        last_bg = -1
        last_bold = false
        last_underline = false
      }
      if cell.bold && not(last_bold) {
        sb.write_string(ansi_bold())
        last_bold = true
      }
      if cell.underline && not(last_underline) {
        sb.write_string(ansi_underline())
        last_underline = true
      }
      if fg_idx != last_fg {
        sb.write_string(ansi_fg_256(fg_idx))
        last_fg = fg_idx
      }
      if bg_idx != last_bg {
        if bg_idx >= 0 {
          sb.write_string(ansi_bg_256(bg_idx))
        } else {
          sb.write_string(ansi_bg_reset())
        }
        last_bg = bg_idx
      }
      sb.write_char(cell.char)
    }
  }
  sb.write_string(ansi_reset())
  sb.to_string()
}

///|
/// Convert CharBuffer to ANSI-encoded string with an offset
pub fn CharBuffer::to_ansi_offset(
  self : CharBuffer,
  row_offset : Int,
  col_offset : Int,
) -> String {
  let sb = StringBuilder::new()
  let mut last_fg = -1
  let mut last_bg = -1
  let mut last_bold = false
  let mut last_underline = false
  for row = 0; row < self.height; row = row + 1 {
    sb.write_string(ansi_move_to(row + row_offset, col_offset))
    let mut expected_col = 0
    for col = 0; col < self.width; col = col + 1 {
      let cell = self.get_cell(col, row)
      if cell.char == '\u0000' {
        continue
      }
      // If cursor position doesn't match expected, reposition
      if col != expected_col {
        sb.write_string(ansi_move_to(row + row_offset, col + col_offset))
      }
      expected_col = col + @core.char_display_width(cell.char)
      let fg_idx = if cell.fg.is_transparent() {
        7
      } else {
        color_to_256(cell.fg)
      }
      let bg_idx = if cell.bg.is_transparent() {
        -1
      } else {
        color_to_256(cell.bg)
      }
      let need_reset = (last_bold && not(cell.bold)) ||
        (last_underline && not(cell.underline))
      if need_reset {
        sb.write_string(ansi_reset())
        last_fg = -1
        last_bg = -1
        last_bold = false
        last_underline = false
      }
      if cell.bold && not(last_bold) {
        sb.write_string(ansi_bold())
        last_bold = true
      }
      if cell.underline && not(last_underline) {
        sb.write_string(ansi_underline())
        last_underline = true
      }
      if fg_idx != last_fg {
        sb.write_string(ansi_fg_256(fg_idx))
        last_fg = fg_idx
      }
      if bg_idx != last_bg {
        if bg_idx >= 0 {
          sb.write_string(ansi_bg_256(bg_idx))
        } else {
          sb.write_string(ansi_bg_reset())
        }
        last_bg = bg_idx
      }
      sb.write_char(cell.char)
    }
  }
  sb.write_string(ansi_reset())
  sb.to_string()
}

///|
/// Optimized ANSI output with diff (only output changed cells)
pub fn CharBuffer::diff_to_ansi(self : CharBuffer, prev : CharBuffer) -> String {
  let sb = StringBuilder::new()
  let mut last_row = -1
  let mut expected_col = -1 // Track expected cursor position (considering char width)
  let mut last_fg = -1
  let mut last_bg = -1
  let mut last_bold = false
  let mut last_underline = false
  for row = 0; row < self.height; row = row + 1 {
    for col = 0; col < self.width; col = col + 1 {
      let cell = self.get_cell(col, row)
      let prev_cell = prev.get_cell(col, row)
      if cell == prev_cell {
        continue
      }
      let ch = cell.char
      // Skip wide char placeholder - the wide character before it already covers this column
      if ch == '\u0000' {
        continue
      }
      if row != last_row || col != expected_col {
        sb.write_string(ansi_move_to(row, col))
      }
      let fg_idx = if cell.fg.is_transparent() {
        7
      } else {
        color_to_256(cell.fg)
      }
      let bg_idx = if cell.bg.is_transparent() {
        -1
      } else {
        color_to_256(cell.bg)
      }
      let need_reset = (last_bold && not(cell.bold)) ||
        (last_underline && not(cell.underline))
      if need_reset {
        sb.write_string(ansi_reset())
        last_fg = -1
        last_bg = -1
        last_bold = false
        last_underline = false
      }
      if cell.bold && not(last_bold) {
        sb.write_string(ansi_bold())
        last_bold = true
      }
      if cell.underline && not(last_underline) {
        sb.write_string(ansi_underline())
        last_underline = true
      }
      if fg_idx != last_fg {
        sb.write_string(ansi_fg_256(fg_idx))
        last_fg = fg_idx
      }
      if bg_idx != last_bg {
        if bg_idx >= 0 {
          sb.write_string(ansi_bg_256(bg_idx))
        } else {
          sb.write_string(ansi_bg_reset())
        }
        last_bg = bg_idx
      }
      sb.write_char(ch)
      last_row = row
      // Wide characters advance cursor by 2, narrow by 1
      expected_col = col + @core.char_display_width(ch)
    }
  }
  sb.write_string(ansi_reset())
  sb.to_string()
}

///|
/// Optimized ANSI output with diff and an offset
pub fn CharBuffer::diff_to_ansi_offset(
  self : CharBuffer,
  prev : CharBuffer,
  row_offset : Int,
  col_offset : Int,
) -> String {
  let sb = StringBuilder::new()
  let mut last_row = -1
  let mut expected_col = -1 // Track expected cursor position (considering char width)
  let mut last_fg = -1
  let mut last_bg = -1
  let mut last_bold = false
  let mut last_underline = false
  for row = 0; row < self.height; row = row + 1 {
    for col = 0; col < self.width; col = col + 1 {
      let cell = self.get_cell(col, row)
      let prev_cell = prev.get_cell(col, row)
      if cell == prev_cell {
        continue
      }
      let ch = cell.char
      // Skip wide char placeholder - the wide character before it already covers this column
      if ch == '\u0000' {
        continue
      }
      let out_row = row + row_offset
      let out_col = col + col_offset
      if out_row != last_row || out_col != expected_col {
        sb.write_string(ansi_move_to(out_row, out_col))
      }
      let fg_idx = if cell.fg.is_transparent() {
        7
      } else {
        color_to_256(cell.fg)
      }
      let bg_idx = if cell.bg.is_transparent() {
        -1
      } else {
        color_to_256(cell.bg)
      }
      let need_reset = (last_bold && not(cell.bold)) ||
        (last_underline && not(cell.underline))
      if need_reset {
        sb.write_string(ansi_reset())
        last_fg = -1
        last_bg = -1
        last_bold = false
        last_underline = false
      }
      if cell.bold && not(last_bold) {
        sb.write_string(ansi_bold())
        last_bold = true
      }
      if cell.underline && not(last_underline) {
        sb.write_string(ansi_underline())
        last_underline = true
      }
      if fg_idx != last_fg {
        sb.write_string(ansi_fg_256(fg_idx))
        last_fg = fg_idx
      }
      if bg_idx != last_bg {
        if bg_idx >= 0 {
          sb.write_string(ansi_bg_256(bg_idx))
        } else {
          sb.write_string(ansi_bg_reset())
        }
        last_bg = bg_idx
      }
      sb.write_char(ch)
      last_row = out_row
      // Wide characters advance cursor by 2, narrow by 1
      expected_col = out_col + @core.char_display_width(ch)
    }
  }
  sb.write_string(ansi_reset())
  sb.to_string()
}

///|
pub fn enable_mouse() -> String {
  "\u001b[?1000h\u001b[?1006h"
}

///|
pub fn disable_mouse() -> String {
  "\u001b[?1006l\u001b[?1000l"
}
