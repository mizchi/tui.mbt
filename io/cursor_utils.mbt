///|
/// Cursor utilities for display width and line bounds

///|
/// Get (start, end) indices of the current line (newline-delimited)
pub fn cursor_line_bounds(chars : Array[Char], cursor : Int) -> (Int, Int) {
  let mut start = 0
  if cursor > 0 {
    let mut i = cursor - 1
    for {
      if chars[i] == '\n' {
        start = i + 1
        break
      }
      if i == 0 {
        break
      }
      i = i - 1
    }
  }
  let mut end = chars.length()
  let mut j = cursor
  while j < chars.length() {
    if chars[j] == '\n' {
      end = j
      break
    }
    j = j + 1
  }
  (start, end)
}

///|
/// Display column offset from line start to cursor (newline-delimited)
pub fn cursor_col_offset(chars : Array[Char], cursor : Int) -> Int {
  let (start, _) = cursor_line_bounds(chars, cursor)
  let mut col = 0
  let mut i = start
  while i < cursor && i < chars.length() {
    col = col + @input.char_width(chars[i])
    i = i + 1
  }
  col
}

///|
/// Cursor position (line index, col offset) with display-width wrapping
pub fn cursor_position_wrapped(
  chars : Array[Char],
  cursor : Int,
  max_width : Int,
) -> (Int, Int) {
  let width = if max_width > 0 { max_width } else { 1 }
  let mut line_idx = 0
  let mut col = 0
  let mut i = 0
  while i < chars.length() {
    if i == cursor {
      return (line_idx, col)
    }
    let c = chars[i]
    if c == '\n' {
      line_idx = line_idx + 1
      col = 0
      i = i + 1
      continue
    }
    let w = @input.char_width(c)
    if col + w > width {
      line_idx = line_idx + 1
      col = 0
    }
    if i == cursor {
      return (line_idx, col)
    }
    col = col + w
    i = i + 1
  }
  (line_idx, col)
}
