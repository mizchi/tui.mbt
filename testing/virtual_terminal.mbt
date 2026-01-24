///|
/// VirtualTerminal - A headless terminal emulator for testing
/// Processes ANSI escape sequences and maintains screen state

///|
/// Helper to trim trailing spaces from a string
fn trim_trailing_spaces(s : String) -> String {
  let chars = s.to_array()
  let mut end = chars.length()
  while end > 0 && chars[end - 1] == ' ' {
    end = end - 1
  }
  if end == 0 {
    ""
  } else {
    let sub : Array[Char] = []
    for i = 0; i < end; i = i + 1 {
      sub.push(chars[i])
    }
    String::from_array(sub)
  }
}

///|
/// Virtual terminal state
pub(all) struct VirtualTerminal {
  width : Int
  height : Int
  buffer : @render.CharBuffer
  mut cursor_x : Int
  mut cursor_y : Int
  mut current_fg : @core.Color
  mut current_bg : @core.Color
  mut current_bold : Bool
  mut current_underline : Bool
  mut saved_cursor_x : Int
  mut saved_cursor_y : Int
  // Input queue for simulating user input
  input_queue : Array[String]
  // History of cursor positions for debugging
  cursor_history : Array[(Int, Int)]
}

///|
/// Create a new virtual terminal
pub fn VirtualTerminal::new(width : Int, height : Int) -> VirtualTerminal {
  {
    width,
    height,
    buffer: @render.CharBuffer::new(width, height),
    cursor_x: 0,
    cursor_y: 0,
    current_fg: @core.Color::white(),
    current_bg: @core.Color::transparent(),
    current_bold: false,
    current_underline: false,
    saved_cursor_x: 0,
    saved_cursor_y: 0,
    input_queue: [],
    cursor_history: [],
  }
}

///|
/// Process ANSI output and update terminal state
pub fn VirtualTerminal::write(self : VirtualTerminal, data : String) -> Unit {
  let chars = data.to_array()
  let len = chars.length()
  let mut i = 0
  while i < len {
    let c = chars[i]
    if c == '\u001b' && i + 1 < len {
      // ESC sequence
      let next = chars[i + 1]
      if next == '[' {
        // CSI sequence
        i = self.parse_csi(chars, i + 2)
      } else if next == ']' {
        // OSC sequence - skip until BEL or ST
        i = i + 2
        while i < len {
          if chars[i] == '\u0007' {
            i = i + 1
            break
          } else if chars[i] == '\u001b' && i + 1 < len && chars[i + 1] == '\\' {
            i = i + 2
            break
          }
          i = i + 1
        }
      } else if next == '7' {
        // Save cursor (DECSC)
        self.saved_cursor_x = self.cursor_x
        self.saved_cursor_y = self.cursor_y
        i = i + 2
      } else if next == '8' {
        // Restore cursor (DECRC)
        self.cursor_x = self.saved_cursor_x
        self.cursor_y = self.saved_cursor_y
        i = i + 2
      } else {
        // Other escape - skip
        i = i + 2
      }
    } else if c == '\n' {
      self.cursor_y = self.cursor_y + 1
      self.cursor_x = 0
      if self.cursor_y >= self.height {
        self.scroll_up()
        self.cursor_y = self.height - 1
      }
      i = i + 1
    } else if c == '\r' {
      self.cursor_x = 0
      i = i + 1
    } else if c == '\t' {
      // Tab - move to next 8-column boundary
      self.cursor_x = (self.cursor_x / 8 + 1) * 8
      if self.cursor_x >= self.width {
        self.cursor_x = self.width - 1
      }
      i = i + 1
    } else if c == '\u0007' {
      // BEL - ignore
      i = i + 1
    } else if c == '\u0008' {
      // Backspace
      if self.cursor_x > 0 {
        self.cursor_x = self.cursor_x - 1
      }
      i = i + 1
    } else {
      // Regular character
      self.write_char(c)
      i = i + 1
    }
  }
  // Record cursor position
  self.cursor_history.push((self.cursor_x, self.cursor_y))
}

///|
/// Parse CSI sequence and return new index
fn VirtualTerminal::parse_csi(
  self : VirtualTerminal,
  chars : Array[Char],
  start : Int,
) -> Int {
  let len = chars.length()
  let mut i = start
  let params : Array[Int] = []
  let mut current_param = 0
  let mut has_param = false
  let mut private_mode = false

  // Check for private mode indicator
  if i < len && chars[i] == '?' {
    private_mode = true
    i = i + 1
  }

  // Parse parameters
  while i < len {
    let c = chars[i]
    let code = c.to_int()
    if code >= 0x30 && code <= 0x39 {
      // Digit 0-9
      current_param = current_param * 10 + (code - 0x30)
      has_param = true
      i = i + 1
    } else if c == ';' {
      params.push(if has_param { current_param } else { 0 })
      current_param = 0
      has_param = false
      i = i + 1
    } else if code >= 0x40 && code <= 0x7E {
      // Final byte
      if has_param {
        params.push(current_param)
      }
      self.execute_csi(c, params, private_mode)
      return i + 1
    } else {
      // Intermediate byte or unknown
      i = i + 1
    }
  }
  i
}

///|
/// Execute CSI command
fn VirtualTerminal::execute_csi(
  self : VirtualTerminal,
  cmd : Char,
  params : Array[Int],
  private_mode : Bool,
) -> Unit {
  let p0 = if params.length() > 0 { params[0] } else { 0 }
  let p1 = if params.length() > 1 { params[1] } else { 0 }
  match cmd {
    'A' => {
      // Cursor Up
      let n = if p0 < 1 { 1 } else { p0 }
      self.cursor_y = if self.cursor_y - n < 0 { 0 } else { self.cursor_y - n }
    }
    'B' => {
      // Cursor Down
      let n = if p0 < 1 { 1 } else { p0 }
      let new_y = self.cursor_y + n
      self.cursor_y = if new_y >= self.height { self.height - 1 } else { new_y }
    }
    'C' => {
      // Cursor Forward
      let n = if p0 < 1 { 1 } else { p0 }
      let new_x = self.cursor_x + n
      self.cursor_x = if new_x >= self.width { self.width - 1 } else { new_x }
    }
    'D' => {
      // Cursor Back
      let n = if p0 < 1 { 1 } else { p0 }
      self.cursor_x = if self.cursor_x - n < 0 { 0 } else { self.cursor_x - n }
    }
    'E' => {
      // Cursor Next Line
      let n = if p0 < 1 { 1 } else { p0 }
      let new_y = self.cursor_y + n
      self.cursor_y = if new_y >= self.height { self.height - 1 } else { new_y }
      self.cursor_x = 0
    }
    'F' => {
      // Cursor Previous Line
      let n = if p0 < 1 { 1 } else { p0 }
      self.cursor_y = if self.cursor_y - n < 0 { 0 } else { self.cursor_y - n }
      self.cursor_x = 0
    }
    'G' => {
      // Cursor Horizontal Absolute
      let col = if p0 < 1 { 0 } else { p0 - 1 }
      self.cursor_x = if col >= self.width { self.width - 1 } else { col }
    }
    'H' | 'f' => {
      // Cursor Position (1-indexed)
      let row = if p0 == 0 { 1 } else { p0 }
      let col = if p1 == 0 { 1 } else { p1 }
      let new_y = row - 1
      let new_x = col - 1
      self.cursor_y = if new_y < 0 {
        0
      } else if new_y >= self.height {
        self.height - 1
      } else {
        new_y
      }
      self.cursor_x = if new_x < 0 {
        0
      } else if new_x >= self.width {
        self.width - 1
      } else {
        new_x
      }
    }
    'J' =>
      // Erase in Display
      match p0 {
        0 =>
          // Clear from cursor to end
          self.clear_from_cursor_to_end()
        1 =>
          // Clear from start to cursor
          self.clear_from_start_to_cursor()
        2 | 3 =>
          // Clear entire screen
          self.buffer.clear()
        _ => ()
      }
    'K' =>
      // Erase in Line
      match p0 {
        0 =>
          // Clear from cursor to end of line
          self.clear_line_from_cursor()
        1 =>
          // Clear from start of line to cursor
          self.clear_line_to_cursor()
        2 =>
          // Clear entire line
          self.clear_entire_line()
        _ => ()
      }
    'm' =>
      // SGR (Select Graphic Rendition)
      self.process_sgr(params)
    'h' =>
      // Set Mode (private modes like cursor visibility)
      if private_mode {
        // Ignore for now (cursor show/hide, alt screen, etc.)
        ()
      }
    'l' =>
      // Reset Mode
      if private_mode {
        // Ignore for now
        ()
      }
    's' => {
      // Save cursor position
      self.saved_cursor_x = self.cursor_x
      self.saved_cursor_y = self.cursor_y
    }
    'u' => {
      // Restore cursor position
      self.cursor_x = self.saved_cursor_x
      self.cursor_y = self.saved_cursor_y
    }
    _ => () // Unknown command
  }
}

///|
/// Process SGR (color/style) parameters
fn VirtualTerminal::process_sgr(
  self : VirtualTerminal,
  params : Array[Int],
) -> Unit {
  if params.length() == 0 {
    // Reset all attributes
    self.reset_attributes()
    return
  }
  let mut i = 0
  while i < params.length() {
    let p = params[i]
    match p {
      0 => self.reset_attributes()
      1 => self.current_bold = true
      2 => () // Dim - ignore
      4 => self.current_underline = true
      7 => () // Reverse - ignore for now
      22 => self.current_bold = false
      24 => self.current_underline = false
      27 => () // Reverse off
      30 => self.current_fg = @core.Color::rgb(0, 0, 0) // Black
      31 => self.current_fg = @core.Color::rgb(205, 49, 49) // Red
      32 => self.current_fg = @core.Color::rgb(13, 188, 121) // Green
      33 => self.current_fg = @core.Color::rgb(229, 229, 16) // Yellow
      34 => self.current_fg = @core.Color::rgb(36, 114, 200) // Blue
      35 => self.current_fg = @core.Color::rgb(188, 63, 188) // Magenta
      36 => self.current_fg = @core.Color::rgb(17, 168, 205) // Cyan
      37 => self.current_fg = @core.Color::rgb(229, 229, 229) // White
      38 =>
        // Extended foreground color
        if i + 2 < params.length() && params[i + 1] == 5 {
          // 256-color mode
          self.current_fg = color_from_256(params[i + 2])
          i = i + 2
        } else if i + 4 < params.length() && params[i + 1] == 2 {
          // True color mode
          self.current_fg = @core.Color::rgb(
            params[i + 2],
            params[i + 3],
            params[i + 4],
          )
          i = i + 4
        }
      39 => self.current_fg = @core.Color::white() // Default foreground
      40 => self.current_bg = @core.Color::rgb(0, 0, 0) // Black bg
      41 => self.current_bg = @core.Color::rgb(205, 49, 49) // Red bg
      42 => self.current_bg = @core.Color::rgb(13, 188, 121) // Green bg
      43 => self.current_bg = @core.Color::rgb(229, 229, 16) // Yellow bg
      44 => self.current_bg = @core.Color::rgb(36, 114, 200) // Blue bg
      45 => self.current_bg = @core.Color::rgb(188, 63, 188) // Magenta bg
      46 => self.current_bg = @core.Color::rgb(17, 168, 205) // Cyan bg
      47 => self.current_bg = @core.Color::rgb(229, 229, 229) // White bg
      48 =>
        // Extended background color
        if i + 2 < params.length() && params[i + 1] == 5 {
          // 256-color mode
          self.current_bg = color_from_256(params[i + 2])
          i = i + 2
        } else if i + 4 < params.length() && params[i + 1] == 2 {
          // True color mode
          self.current_bg = @core.Color::rgb(
            params[i + 2],
            params[i + 3],
            params[i + 4],
          )
          i = i + 4
        }
      49 => self.current_bg = @core.Color::transparent() // Default background
      90 => self.current_fg = @core.Color::rgb(128, 128, 128) // Bright black
      91 => self.current_fg = @core.Color::rgb(255, 0, 0) // Bright red
      92 => self.current_fg = @core.Color::rgb(0, 255, 0) // Bright green
      93 => self.current_fg = @core.Color::rgb(255, 255, 0) // Bright yellow
      94 => self.current_fg = @core.Color::rgb(0, 0, 255) // Bright blue
      95 => self.current_fg = @core.Color::rgb(255, 0, 255) // Bright magenta
      96 => self.current_fg = @core.Color::rgb(0, 255, 255) // Bright cyan
      97 => self.current_fg = @core.Color::rgb(255, 255, 255) // Bright white
      _ => () // Unknown SGR
    }
    i = i + 1
  }
}

///|
/// Reset text attributes to default
fn VirtualTerminal::reset_attributes(self : VirtualTerminal) -> Unit {
  self.current_fg = @core.Color::white()
  self.current_bg = @core.Color::transparent()
  self.current_bold = false
  self.current_underline = false
}

///|
/// Write a single character at cursor position
fn VirtualTerminal::write_char(self : VirtualTerminal, c : Char) -> Unit {
  if self.cursor_x >= self.width {
    // Auto-wrap
    self.cursor_x = 0
    self.cursor_y = self.cursor_y + 1
    if self.cursor_y >= self.height {
      self.scroll_up()
      self.cursor_y = self.height - 1
    }
  }
  let width = @core.char_display_width(c)

  // Check if wide char fits
  if width == 2 && self.cursor_x + 1 >= self.width {
    // Wide char doesn't fit, wrap first
    self.cursor_x = 0
    self.cursor_y = self.cursor_y + 1
    if self.cursor_y >= self.height {
      self.scroll_up()
      self.cursor_y = self.height - 1
    }
  }
  let cell : @render.CharCell = {
    char: c,
    fg: self.current_fg,
    bg: self.current_bg,
    bold: self.current_bold,
    underline: self.current_underline,
    reverse: false,
  }
  self.buffer.set_cell(self.cursor_x, self.cursor_y, cell)

  // Handle wide characters
  if width == 2 && self.cursor_x + 1 < self.width {
    let placeholder : @render.CharCell = {
      char: '\u0000',
      fg: self.current_fg,
      bg: self.current_bg,
      bold: self.current_bold,
      underline: self.current_underline,
      reverse: false,
    }
    self.buffer.set_cell(self.cursor_x + 1, self.cursor_y, placeholder)
  }
  self.cursor_x = self.cursor_x + width
}

///|
/// Scroll the screen up by one line
fn VirtualTerminal::scroll_up(self : VirtualTerminal) -> Unit {
  // Move all lines up by one
  for y = 0; y < self.height - 1; y = y + 1 {
    for x = 0; x < self.width; x = x + 1 {
      let cell = self.buffer.get_cell(x, y + 1)
      self.buffer.set_cell(x, y, cell)
    }
  }
  // Clear the last line
  let empty = @render.CharCell::default()
  for x = 0; x < self.width; x = x + 1 {
    self.buffer.set_cell(x, self.height - 1, empty)
  }
}

///|
/// Clear from cursor to end of screen
fn VirtualTerminal::clear_from_cursor_to_end(self : VirtualTerminal) -> Unit {
  let empty = @render.CharCell::default()
  // Clear rest of current line
  for x = self.cursor_x; x < self.width; x = x + 1 {
    self.buffer.set_cell(x, self.cursor_y, empty)
  }
  // Clear all lines below
  for y = self.cursor_y + 1; y < self.height; y = y + 1 {
    for x = 0; x < self.width; x = x + 1 {
      self.buffer.set_cell(x, y, empty)
    }
  }
}

///|
/// Clear from start of screen to cursor
fn VirtualTerminal::clear_from_start_to_cursor(self : VirtualTerminal) -> Unit {
  let empty = @render.CharCell::default()
  // Clear all lines above
  for y = 0; y < self.cursor_y; y = y + 1 {
    for x = 0; x < self.width; x = x + 1 {
      self.buffer.set_cell(x, y, empty)
    }
  }
  // Clear current line up to cursor
  for x = 0; x <= self.cursor_x; x = x + 1 {
    self.buffer.set_cell(x, self.cursor_y, empty)
  }
}

///|
/// Clear from cursor to end of line
fn VirtualTerminal::clear_line_from_cursor(self : VirtualTerminal) -> Unit {
  let empty = @render.CharCell::default()
  for x = self.cursor_x; x < self.width; x = x + 1 {
    self.buffer.set_cell(x, self.cursor_y, empty)
  }
}

///|
/// Clear from start of line to cursor
fn VirtualTerminal::clear_line_to_cursor(self : VirtualTerminal) -> Unit {
  let empty = @render.CharCell::default()
  for x = 0; x <= self.cursor_x; x = x + 1 {
    self.buffer.set_cell(x, self.cursor_y, empty)
  }
}

///|
/// Clear entire line
fn VirtualTerminal::clear_entire_line(self : VirtualTerminal) -> Unit {
  let empty = @render.CharCell::default()
  for x = 0; x < self.width; x = x + 1 {
    self.buffer.set_cell(x, self.cursor_y, empty)
  }
}

///|
/// Convert 256-color index to RGB
fn color_from_256(idx : Int) -> @core.Color {
  if idx < 16 {
    // Standard colors
    match idx {
      0 => @core.Color::rgb(0, 0, 0)
      1 => @core.Color::rgb(128, 0, 0)
      2 => @core.Color::rgb(0, 128, 0)
      3 => @core.Color::rgb(128, 128, 0)
      4 => @core.Color::rgb(0, 0, 128)
      5 => @core.Color::rgb(128, 0, 128)
      6 => @core.Color::rgb(0, 128, 128)
      7 => @core.Color::rgb(192, 192, 192)
      8 => @core.Color::rgb(128, 128, 128)
      9 => @core.Color::rgb(255, 0, 0)
      10 => @core.Color::rgb(0, 255, 0)
      11 => @core.Color::rgb(255, 255, 0)
      12 => @core.Color::rgb(0, 0, 255)
      13 => @core.Color::rgb(255, 0, 255)
      14 => @core.Color::rgb(0, 255, 255)
      15 => @core.Color::rgb(255, 255, 255)
      _ => @core.Color::white()
    }
  } else if idx < 232 {
    // 216 colors (6x6x6 cube)
    let n = idx - 16
    let r = n / 36
    let g = n % 36 / 6
    let b = n % 6
    @core.Color::rgb(
      if r == 0 {
        0
      } else {
        r * 40 + 55
      },
      if g == 0 {
        0
      } else {
        g * 40 + 55
      },
      if b == 0 {
        0
      } else {
        b * 40 + 55
      },
    )
  } else {
    // Grayscale (24 shades)
    let gray = (idx - 232) * 10 + 8
    @core.Color::rgb(gray, gray, gray)
  }
}

// =============================================================================
// Public API for testing
// =============================================================================

///|
/// Get the plain text content of the screen
pub fn VirtualTerminal::get_screen(self : VirtualTerminal) -> String {
  let sb = StringBuilder::new()
  for y = 0; y < self.height; y = y + 1 {
    for x = 0; x < self.width; x = x + 1 {
      let cell = self.buffer.get_cell(x, y)
      if cell.char == '\u0000' {
        // Skip wide char placeholder
        continue
      }
      sb.write_char(cell.char)
    }
    if y < self.height - 1 {
      sb.write_char('\n')
    }
  }
  sb.to_string()
}

///|
/// Get a specific line (0-indexed)
pub fn VirtualTerminal::get_line(self : VirtualTerminal, y : Int) -> String {
  if y < 0 || y >= self.height {
    return ""
  }
  let sb = StringBuilder::new()
  for x = 0; x < self.width; x = x + 1 {
    let cell = self.buffer.get_cell(x, y)
    if cell.char == '\u0000' {
      continue
    }
    sb.write_char(cell.char)
  }
  sb.to_string()
}

///|
/// Get cell at position
pub fn VirtualTerminal::get_cell(
  self : VirtualTerminal,
  x : Int,
  y : Int,
) -> @render.CharCell {
  self.buffer.get_cell(x, y)
}

///|
/// Get current cursor position
pub fn VirtualTerminal::get_cursor(self : VirtualTerminal) -> (Int, Int) {
  (self.cursor_x, self.cursor_y)
}

///|
/// Check if screen contains text
pub fn VirtualTerminal::contains(self : VirtualTerminal, text : String) -> Bool {
  self.get_screen().contains(text)
}

///|
/// Check if specific line contains text
pub fn VirtualTerminal::line_contains(
  self : VirtualTerminal,
  y : Int,
  text : String,
) -> Bool {
  self.get_line(y).contains(text)
}

///|
/// Clear the terminal
pub fn VirtualTerminal::clear(self : VirtualTerminal) -> Unit {
  self.buffer.clear()
  self.cursor_x = 0
  self.cursor_y = 0
  self.reset_attributes()
}

///|
/// Queue input for simulating user input
pub fn VirtualTerminal::inject_input(
  self : VirtualTerminal,
  input : String,
) -> Unit {
  self.input_queue.push(input)
}

///|
/// Get next input from queue
pub fn VirtualTerminal::read_input(self : VirtualTerminal) -> String? {
  if self.input_queue.length() > 0 {
    Some(self.input_queue.remove(0))
  } else {
    None
  }
}

///|
/// Check if input queue has data
pub fn VirtualTerminal::has_input(self : VirtualTerminal) -> Bool {
  self.input_queue.length() > 0
}

///|
/// Get the underlying buffer for advanced assertions
pub fn VirtualTerminal::get_buffer(
  self : VirtualTerminal,
) -> @render.CharBuffer {
  self.buffer
}

///|
/// Get trimmed line (without trailing spaces)
pub fn VirtualTerminal::get_line_trimmed(
  self : VirtualTerminal,
  y : Int,
) -> String {
  trim_trailing_spaces(self.get_line(y))
}

///|
/// Get all non-empty lines
pub fn VirtualTerminal::get_visible_lines(
  self : VirtualTerminal,
) -> Array[String] {
  let lines : Array[String] = []
  for y = 0; y < self.height; y = y + 1 {
    let line = self.get_line_trimmed(y)
    if line.length() > 0 {
      lines.push(line)
    }
  }
  lines
}

///|
/// Snapshot comparison: compare screen with expected content
pub fn VirtualTerminal::matches(
  self : VirtualTerminal,
  expected : String,
) -> Bool {
  // Normalize both strings (trim trailing whitespace per line)
  let actual_lines = self.get_visible_lines()
  let expected_lines : Array[String] = expected
    .split("\n")
    .map(fn(sv) { trim_trailing_spaces(sv.to_string()) })
    .filter(fn(s) { s.length() > 0 })
    .collect()
  if actual_lines.length() != expected_lines.length() {
    return false
  }
  for i = 0; i < actual_lines.length(); i = i + 1 {
    if actual_lines[i] != expected_lines[i] {
      return false
    }
  }
  true
}
