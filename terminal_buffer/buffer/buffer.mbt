///|
/// Color value used by terminal buffer cells.
pub(all) struct Color {
  r : Int
  g : Int
  b : Int
  a : Double
}

///|
pub fn Color::rgb(r : Int, g : Int, b : Int) -> Color {
  { r, g, b, a: 1.0 }
}

///|
pub fn Color::rgba(r : Int, g : Int, b : Int, a : Double) -> Color {
  { r, g, b, a }
}

///|
pub fn Color::white() -> Color {
  Color::rgb(255, 255, 255)
}

///|
pub fn Color::black() -> Color {
  Color::rgb(0, 0, 0)
}

///|
pub fn Color::transparent() -> Color {
  { r: 0, g: 0, b: 0, a: 0.0 }
}

///|
pub fn Color::is_transparent(self : Color) -> Bool {
  self.a <= 0.0
}

///|
pub impl Eq for Color with equal(self, other) {
  self.r == other.r &&
  self.g == other.g &&
  self.b == other.b &&
  self.a == other.a
}

///|
/// A single terminal character cell.
pub(all) struct CharCell {
  char : Char
  fg : Color
  bg : Color
  bold : Bool
  underline : Bool
  reverse : Bool
}

///|
pub fn CharCell::default() -> CharCell {
  {
    char: ' ',
    fg: Color::white(),
    bg: Color::transparent(),
    bold: false,
    underline: false,
    reverse: false,
  }
}

///|
pub fn CharCell::from_char(c : Char) -> CharCell {
  { ..CharCell::default(), char: c }
}

///|
pub fn CharCell::styled(c : Char, fg : Color, bg : Color) -> CharCell {
  { ..CharCell::default(), char: c, fg, bg }
}

///|
pub impl Eq for CharCell with equal(self, other) {
  self.char == other.char &&
  self.fg == other.fg &&
  self.bg == other.bg &&
  self.bold == other.bold &&
  self.underline == other.underline &&
  self.reverse == other.reverse
}

///|
pub(all) struct Rect {
  x : Int
  y : Int
  w : Int
  h : Int
} derive(Debug, Eq)

///|
fn min_int(a : Int, b : Int) -> Int {
  if a < b {
    a
  } else {
    b
  }
}

///|
fn max_int(a : Int, b : Int) -> Int {
  if a > b {
    a
  } else {
    b
  }
}

///|
pub fn clip_rect(
  buffer_width : Int,
  buffer_height : Int,
  x : Int,
  y : Int,
  w : Int,
  h : Int,
) -> Rect? {
  if buffer_width <= 0 || buffer_height <= 0 || w <= 0 || h <= 0 {
    return None
  }
  let x1 = max_int(0, x)
  let y1 = max_int(0, y)
  let x2 = min_int(buffer_width, x + w)
  let y2 = min_int(buffer_height, y + h)
  if x2 <= x1 || y2 <= y1 {
    None
  } else {
    Some({ x: x1, y: y1, w: x2 - x1, h: y2 - y1 })
  }
}

///|
pub(all) struct TextWriteCell {
  x : Int
  y : Int
  char : Char
} derive(Debug, Eq)

///|
pub(all) struct TextWritePlan {
  columns : Int
  lines : Int
  cells : Array[TextWriteCell]
} derive(Debug, Eq)

///|
fn push_planned_char(
  cells : Array[TextWriteCell],
  x : Int,
  y : Int,
  c : Char,
  end_x : Int,
) -> Int {
  let width = char_display_width(c)
  cells.push({ x, y, char: c })
  if width == 2 && x + 1 < end_x {
    cells.push({ x: x + 1, y, char: '\u0000' })
  }
  width
}

///|
pub fn plan_write_text(
  x : Int,
  y : Int,
  text : String,
  max_width : Int,
) -> TextWritePlan {
  let cells : Array[TextWriteCell] = []
  let mut cur_x = x
  let end_x = x + max_width
  for c in text {
    if c == '\n' {
      break
    }
    if c.to_int() < 32 {
      continue
    }
    let width = char_display_width(c)
    if cur_x + width > end_x {
      break
    }
    cur_x += push_planned_char(cells, cur_x, y, c, end_x)
  }
  { columns: cur_x - x, lines: 1, cells }
}

///|
pub fn plan_write_text_pre(
  x : Int,
  y : Int,
  text : String,
  max_width : Int,
  max_height : Int,
) -> TextWritePlan {
  let cells : Array[TextWriteCell] = []
  let mut cur_x = x
  let mut cur_y = y
  let end_x = x + max_width
  let end_y = y + max_height
  for c in text {
    if cur_y >= end_y {
      break
    }
    if c == '\n' {
      cur_x = x
      cur_y += 1
      continue
    }
    if c != '\t' && c.to_int() < 32 {
      continue
    }
    if c == '\t' {
      let tab_size = 8
      let next_tab = ((cur_x - x) / tab_size + 1) * tab_size + x
      cur_x = next_tab.min(end_x)
      continue
    }
    let width = char_display_width(c)
    if cur_x + width > end_x {
      continue
    }
    cur_x += push_planned_char(cells, cur_x, cur_y, c, end_x)
  }
  { columns: cur_x - x, lines: cur_y - y + 1, cells }
}

///|
pub fn plan_write_text_wrapped(
  x : Int,
  y : Int,
  text : String,
  max_width : Int,
  max_height : Int,
) -> TextWritePlan {
  let cells : Array[TextWriteCell] = []
  let mut cur_x = x
  let mut cur_y = y
  let end_x = x + max_width
  let end_y = y + max_height
  for c in text {
    if cur_y >= end_y {
      break
    }
    if c == '\n' {
      cur_x = x
      cur_y += 1
      continue
    }
    if c.to_int() < 32 {
      continue
    }
    let width = char_display_width(c)
    if cur_x + width > end_x {
      cur_x = x
      cur_y += 1
      if cur_y >= end_y {
        break
      }
    }
    cur_x += push_planned_char(cells, cur_x, cur_y, c, end_x)
  }
  { columns: cur_x - x, lines: cur_y - y + 1, cells }
}

///|
pub(all) struct TextStyle {
  fg : Color
  bg : Color
  bold : Bool
  underline : Bool
}

///|
pub fn TextStyle::default() -> TextStyle {
  {
    fg: Color::white(),
    bg: Color::transparent(),
    bold: false,
    underline: false,
  }
}

///|
/// Character-based framebuffer for terminal renderers.
pub struct CharBuffer {
  width : Int
  height : Int
  cells : Array[CharCell]
}

///|
pub fn CharBuffer::new(width : Int, height : Int) -> CharBuffer {
  let size = width * height
  { width, height, cells: Array::make(size, CharCell::default()) }
}

///|
pub fn CharBuffer::clone(self : CharBuffer) -> CharBuffer {
  { width: self.width, height: self.height, cells: self.cells.copy() }
}

///|
pub fn CharBuffer::get_cell(self : CharBuffer, x : Int, y : Int) -> CharCell {
  if x >= 0 && x < self.width && y >= 0 && y < self.height {
    self.cells[y * self.width + x]
  } else {
    CharCell::default()
  }
}

///|
pub fn CharBuffer::set_cell(
  self : CharBuffer,
  x : Int,
  y : Int,
  cell : CharCell,
) -> Unit {
  if x >= 0 && x < self.width && y >= 0 && y < self.height {
    self.cells[y * self.width + x] = cell
  }
}

///|
pub fn CharBuffer::fill_rect(
  self : CharBuffer,
  x : Int,
  y : Int,
  w : Int,
  h : Int,
  cell : CharCell,
) -> Unit {
  match clip_rect(self.width, self.height, x, y, w, h) {
    Some(rect) =>
      for row = rect.y; row < rect.y + rect.h; row = row + 1 {
        for col = rect.x; col < rect.x + rect.w; col = col + 1 {
          self.set_cell(col, row, cell)
        }
      }
    None => ()
  }
}

///|
fn CharBuffer::apply_text_write_plan(
  self : CharBuffer,
  plan : TextWritePlan,
  style : TextStyle,
) -> Unit {
  for cell in plan.cells {
    self.set_cell(
      cell.x,
      cell.y,
      self.styled_cell_at(cell.x, cell.y, cell.char, style),
    )
  }
}

///|
fn CharBuffer::styled_cell_at(
  self : CharBuffer,
  x : Int,
  y : Int,
  c : Char,
  style : TextStyle,
) -> CharCell {
  let bg = if style.bg.is_transparent() {
    self.get_cell(x, y).bg
  } else {
    style.bg
  }
  {
    char: c,
    fg: style.fg,
    bg,
    bold: style.bold,
    underline: style.underline,
    reverse: false,
  }
}

///|
pub fn CharBuffer::write_text(
  self : CharBuffer,
  x : Int,
  y : Int,
  text : String,
  style : TextStyle,
  max_width : Int,
) -> Int {
  let plan = plan_write_text(x, y, text, max_width)
  self.apply_text_write_plan(plan, style)
  plan.columns
}

///|
pub fn CharBuffer::write_text_pre(
  self : CharBuffer,
  x : Int,
  y : Int,
  text : String,
  style : TextStyle,
  max_width : Int,
  max_height : Int,
) -> Int {
  let plan = plan_write_text_pre(x, y, text, max_width, max_height)
  self.apply_text_write_plan(plan, style)
  plan.lines
}

///|
pub fn CharBuffer::write_text_wrapped(
  self : CharBuffer,
  x : Int,
  y : Int,
  text : String,
  style : TextStyle,
  max_width : Int,
  max_height : Int,
) -> Int {
  let plan = plan_write_text_wrapped(x, y, text, max_width, max_height)
  self.apply_text_write_plan(plan, style)
  plan.lines
}

///|
pub fn CharBuffer::clear(self : CharBuffer) -> Unit {
  let default_cell = CharCell::default()
  for i = 0; i < self.cells.length(); i = i + 1 {
    self.cells[i] = default_cell
  }
}

///|
/// Fill cell backgrounds while preserving existing characters and foregrounds.
pub fn CharBuffer::fill_bg_preserve(
  self : CharBuffer,
  x : Int,
  y : Int,
  w : Int,
  h : Int,
  bg : Color,
) -> Unit {
  match clip_rect(self.width, self.height, x, y, w, h) {
    Some(rect) =>
      for row = rect.y; row < rect.y + rect.h; row = row + 1 {
        for col = rect.x; col < rect.x + rect.w; col = col + 1 {
          let existing = self.get_cell(col, row)
          self.set_cell(col, row, { ..existing, bg, })
        }
      }
    None => ()
  }
}

///|
/// Fill backgrounds for an overlay, replacing visible cells with spaces.
pub fn CharBuffer::fill_bg_cover(
  self : CharBuffer,
  x : Int,
  y : Int,
  w : Int,
  h : Int,
  bg : Color,
) -> Unit {
  match clip_rect(self.width, self.height, x, y, w, h) {
    Some(rect) =>
      for row = rect.y; row < rect.y + rect.h; row = row + 1 {
        for col = rect.x; col < rect.x + rect.w; col = col + 1 {
          let existing = self.get_cell(col, row)
          let char = if existing.char == '\u0000' { '\u0000' } else { ' ' }
          self.set_cell(col, row, {
            char,
            fg: Color::white(),
            bg,
            bold: false,
            underline: false,
            reverse: false,
          })
        }
      }
    None => ()
  }
}

///|
fn is_wide_char_code(code : Int) -> Bool {
  code >= 0x1100 &&
  (
    code <= 0x115F ||
    code == 0x2329 ||
    code == 0x232A ||
    (code >= 0x2E80 && code <= 0x303E) ||
    (code >= 0x3040 && code <= 0x33FF) ||
    (code >= 0x3400 && code <= 0x4DBF) ||
    (code >= 0x4E00 && code <= 0x9FFF) ||
    (code >= 0xAC00 && code <= 0xD7A3) ||
    (code >= 0xF900 && code <= 0xFAFF) ||
    (code >= 0xFE10 && code <= 0xFE1F) ||
    (code >= 0xFE30 && code <= 0xFE6F) ||
    (code >= 0xFF00 && code <= 0xFF60) ||
    (code >= 0xFFE0 && code <= 0xFFE6) ||
    (code >= 0x20000 && code <= 0x2FFFF)
  )
}

///|
/// Get display width of a character.
pub fn char_display_width(c : Char) -> Int {
  let code = c.to_int()
  if code < 0x80 {
    1
  } else if is_wide_char_code(code) {
    2
  } else {
    1
  }
}

///|
pub fn string_display_width(s : String) -> Int {
  let mut width = 0
  for c in s {
    width += char_display_width(c)
  }
  width
}

///|
pub fn CharBuffer::get_row_text(self : CharBuffer, row : Int) -> String {
  if row < 0 || row >= self.height {
    return ""
  }
  let buf = StringBuilder::new()
  let mut started = false
  for col = 0; col < self.width; col = col + 1 {
    let cell = self.get_cell(col, row)
    if cell.char == '\u0000' {
      continue
    }
    if cell.char != ' ' {
      started = true
      buf.write_char(cell.char)
    } else if started {
      buf.write_char(' ')
    }
  }
  buf.to_string().trim().to_string()
}
