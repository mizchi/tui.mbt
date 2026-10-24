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
/// 24-bit true color foreground
pub fn ansi_fg_rgb(r : Int, g : Int, b : Int) -> String {
  @ansi.ansi_fg_rgb(r, g, b)
}

///|
/// 24-bit true color background
pub fn ansi_bg_rgb(r : Int, g : Int, b : Int) -> String {
  @ansi.ansi_bg_rgb(r, g, b)
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
/// Convert a Color to its 256-color palette index
pub fn color_to_256(color : @core.Color) -> Int {
  rgb_to_256(color.r, color.g, color.b)
}

///|
/// Build the foreground SGR sequence for a color in the given color mode.
pub fn ansi_fg_color(
  color : @core.Color,
  color_mode? : ColorMode = ColorMode::Ansi256,
) -> String {
  match color_mode {
    TrueColor => ansi_fg_rgb(color.r, color.g, color.b)
    Ansi256 => ansi_fg_256(color_to_256(color))
  }
}

///|
/// Build the background SGR sequence for a color in the given color mode.
pub fn ansi_bg_color(
  color : @core.Color,
  color_mode? : ColorMode = ColorMode::Ansi256,
) -> String {
  match color_mode {
    TrueColor => ansi_bg_rgb(color.r, color.g, color.b)
    Ansi256 => ansi_bg_256(color_to_256(color))
  }
}

///|
/// SGR state already written, so that only changes are emitted.
/// An empty string means "nothing emitted yet" (every real sequence is
/// non-empty), which keeps the dedup check a plain string comparison.
priv struct AnsiStyleState {
  mut fg : String
  mut bg : String
  mut bold : Bool
  mut underline : Bool
}

///|
fn AnsiStyleState::new() -> AnsiStyleState {
  { fg: "", bg: "", bold: false, underline: false }
}

///|
fn AnsiStyleState::emit(
  self : AnsiStyleState,
  sb : StringBuilder,
  cell : CharCell,
  color_mode : ColorMode,
) -> Unit {
  if (self.bold && !cell.bold) || (self.underline && !cell.underline) {
    // SGR reset also clears colors, so forget them as well
    sb.write_string(ansi_reset())
    self.fg = ""
    self.bg = ""
    self.bold = false
    self.underline = false
  }
  if cell.bold && !self.bold {
    sb.write_string(ansi_bold())
    self.bold = true
  }
  if cell.underline && !self.underline {
    sb.write_string(ansi_underline())
    self.underline = true
  }
  let fg = if cell.fg.is_transparent() {
    ansi_fg_256(7)
  } else {
    ansi_fg_color(cell.fg, color_mode~)
  }
  if fg != self.fg {
    sb.write_string(fg)
    self.fg = fg
  }
  let bg = if cell.bg.is_transparent() {
    ansi_bg_reset()
  } else {
    ansi_bg_color(cell.bg, color_mode~)
  }
  if bg != self.bg {
    sb.write_string(bg)
    self.bg = bg
  }
}

///|
/// Convert CharBuffer to ANSI-encoded string
pub fn CharBuffer::to_ansi(
  self : CharBuffer,
  color_mode? : ColorMode = ColorMode::Ansi256,
) -> String {
  let sb = StringBuilder()
  let style = AnsiStyleState::new()
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
      style.emit(sb, cell, color_mode)
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
  color_mode? : ColorMode = ColorMode::Ansi256,
) -> String {
  let sb = StringBuilder()
  let style = AnsiStyleState::new()
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
      style.emit(sb, cell, color_mode)
      sb.write_char(cell.char)
    }
  }
  sb.write_string(ansi_reset())
  sb.to_string()
}

///|
/// Optimized ANSI output with diff (only output changed cells)
pub fn CharBuffer::diff_to_ansi(
  self : CharBuffer,
  prev : CharBuffer,
  color_mode? : ColorMode = ColorMode::Ansi256,
) -> String {
  let sb = StringBuilder()
  let mut last_row = -1
  let mut expected_col = -1 // Track expected cursor position (considering char width)
  let style = AnsiStyleState::new()
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
      style.emit(sb, cell, color_mode)
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
  color_mode? : ColorMode = ColorMode::Ansi256,
) -> String {
  let sb = StringBuilder()
  let mut last_row = -1
  let mut expected_col = -1 // Track expected cursor position (considering char width)
  let style = AnsiStyleState::new()
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
      style.emit(sb, cell, color_mode)
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
