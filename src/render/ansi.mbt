///|
/// ANSI Escape Sequences for terminal output

///|
pub fn ansi_reset() -> String {
  @ansi.ansi_reset()
}

///|
pub fn ansi_bold() -> String {
  @ansi.ansi_bold()
}

///|
pub fn ansi_dim() -> String {
  @ansi.ansi_dim()
}

///|
pub fn ansi_underline() -> String {
  @ansi.ansi_underline()
}

///|
pub fn ansi_reverse() -> String {
  @ansi.ansi_reverse()
}

// --- Basic foreground colors ---

///|
pub fn ansi_fg_black() -> String {
  @ansi.ansi_fg_black()
}

///|
pub fn ansi_fg_red() -> String {
  @ansi.ansi_fg_red()
}

///|
pub fn ansi_fg_green() -> String {
  @ansi.ansi_fg_green()
}

///|
pub fn ansi_fg_yellow() -> String {
  @ansi.ansi_fg_yellow()
}

///|
pub fn ansi_fg_blue() -> String {
  @ansi.ansi_fg_blue()
}

///|
pub fn ansi_fg_magenta() -> String {
  @ansi.ansi_fg_magenta()
}

///|
pub fn ansi_fg_cyan() -> String {
  @ansi.ansi_fg_cyan()
}

///|
pub fn ansi_fg_white() -> String {
  @ansi.ansi_fg_white()
}

///|
/// Dim gray (bright black)
pub fn ansi_fg_gray() -> String {
  @ansi.ansi_fg_gray()
}

///|
pub fn ansi_fg_256(color_idx : Int) -> String {
  @ansi.ansi_fg_256(color_idx)
}

///|
pub fn ansi_bg_256(color_idx : Int) -> String {
  @ansi.ansi_bg_256(color_idx)
}

///|
/// Reset background color to default
pub fn ansi_bg_reset() -> String {
  @ansi.ansi_bg_reset()
}

///|
/// Move cursor up by n lines
pub fn ansi_move_up(n? : Int = 1) -> String {
  @ansi.ansi_move_up(n~)
}

///|
/// Move cursor down by n lines
pub fn ansi_move_down(n? : Int = 1) -> String {
  @ansi.ansi_move_down(n~)
}

///|
/// Move cursor right by n columns
pub fn ansi_move_right(n? : Int = 1) -> String {
  @ansi.ansi_move_right(n~)
}

///|
/// Move cursor left by n columns
pub fn ansi_move_left(n? : Int = 1) -> String {
  @ansi.ansi_move_left(n~)
}

///|
pub fn ansi_move_to(row : Int, col : Int) -> String {
  @ansi.ansi_move_to(row, col)
}

///|
pub fn ansi_clear_screen() -> String {
  @ansi.ansi_clear_screen()
}

///|
pub fn ansi_clear_line() -> String {
  @ansi.ansi_clear_line()
}

///|
pub fn ansi_hide_cursor() -> String {
  @ansi.ansi_hide_cursor()
}

///|
pub fn ansi_show_cursor() -> String {
  @ansi.ansi_show_cursor()
}

///|
pub fn ansi_enter_alt_screen() -> String {
  @ansi.ansi_enter_alt_screen()
}

///|
pub fn ansi_leave_alt_screen() -> String {
  @ansi.ansi_leave_alt_screen()
}

///|
/// Reset all terminal attributes (colors, styles)
pub fn ansi_reset_attrs() -> String {
  @ansi.ansi_reset_attrs()
}

///|
/// Full terminal reset sequence for recovering from corrupted state
pub fn ansi_full_reset() -> String {
  @ansi.ansi_full_reset()
}

///|
/// Convert RGB color to 256-color palette index
pub fn rgb_to_256(r : Int, g : Int, b : Int) -> Int {
  @ansi.rgb_to_256(r, g, b)
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
      let need_reset = (last_bold && !cell.bold) ||
        (last_underline && !cell.underline)
      if need_reset {
        sb.write_string(ansi_reset())
        last_fg = -1
        last_bg = -1
        last_bold = false
        last_underline = false
      }
      if cell.bold && !last_bold {
        sb.write_string(ansi_bold())
        last_bold = true
      }
      if cell.underline && !last_underline {
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
      let need_reset = (last_bold && !cell.bold) ||
        (last_underline && !cell.underline)
      if need_reset {
        sb.write_string(ansi_reset())
        last_fg = -1
        last_bg = -1
        last_bold = false
        last_underline = false
      }
      if cell.bold && !last_bold {
        sb.write_string(ansi_bold())
        last_bold = true
      }
      if cell.underline && !last_underline {
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
      let need_reset = (last_bold && !cell.bold) ||
        (last_underline && !cell.underline)
      if need_reset {
        sb.write_string(ansi_reset())
        last_fg = -1
        last_bg = -1
        last_bold = false
        last_underline = false
      }
      if cell.bold && !last_bold {
        sb.write_string(ansi_bold())
        last_bold = true
      }
      if cell.underline && !last_underline {
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
      let need_reset = (last_bold && !cell.bold) ||
        (last_underline && !cell.underline)
      if need_reset {
        sb.write_string(ansi_reset())
        last_fg = -1
        last_bg = -1
        last_bold = false
        last_underline = false
      }
      if cell.bold && !last_bold {
        sb.write_string(ansi_bold())
        last_bold = true
      }
      if cell.underline && !last_underline {
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
  @ansi.enable_mouse()
}

///|
pub fn disable_mouse() -> String {
  @ansi.disable_mouse()
}

///|
/// Enable mouse with motion tracking (reports move events even without button press)
pub fn enable_mouse_all() -> String {
  @ansi.enable_mouse_all()
}

///|
/// Disable mouse motion tracking
pub fn disable_mouse_all() -> String {
  @ansi.disable_mouse_all()
}
