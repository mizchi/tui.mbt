///|
/// Input navigation helpers (moved from io/input_nav.mbt)

///|
/// Get character display width from code point (ASCII=1, CJK/fullwidth=2)
fn char_width_code(code : Int) -> Int {
  @core.char_display_width(code.unsafe_to_char())
}

///|
/// Wrap text into lines (considering newlines and max_width)
fn wrap_text_to_lines(buf : Array[Char], max_width : Int) -> Array[LineInfo] {
  let lines : Array[LineInfo] = []
  let mut current_chars : Array[Char] = []
  let mut current_width = 0
  let mut line_start_idx = 0
  for i, c in buf {
    let code = c.to_int()
    if code == 10 {
      lines.push({ start_idx: line_start_idx, chars: current_chars })
      current_chars = []
      current_width = 0
      line_start_idx = i + 1
      continue
    }
    let cw = char_width_code(code)
    if current_width + cw > max_width {
      lines.push({ start_idx: line_start_idx, chars: current_chars })
      current_chars = [c]
      current_width = cw
      line_start_idx = i
    } else {
      current_chars.push(c)
      current_width = current_width + cw
    }
  }
  lines.push({ start_idx: line_start_idx, chars: current_chars })
  lines
}

///|
/// Find cursor line index and column offset
fn find_cursor_line(lines : Array[LineInfo], cursor : Int) -> (Int, Int) {
  for line_idx, line in lines {
    let next_start = if line_idx + 1 < lines.length() {
      lines[line_idx + 1].start_idx
    } else {
      line.start_idx + line.chars.length()
    }
    if cursor < next_start {
      let pos_in_line = cursor - line.start_idx
      let mut col_offset = 0
      for i = 0; i < pos_in_line && i < line.chars.length(); i = i + 1 {
        col_offset = col_offset + char_width_code(line.chars[i].to_int())
      }
      return (line_idx, col_offset)
    }
  }
  let last_idx = lines.length() - 1
  let last_line = lines[last_idx]
  let mut col_offset = 0
  for c in last_line.chars {
    col_offset = col_offset + char_width_code(c.to_int())
  }
  (last_idx, col_offset)
}

///|
/// Move cursor to previous wrapped line (keeps column offset when possible)
fn cursor_up(lines : Array[LineInfo], cursor : Int) -> Int {
  let (line_idx, col_offset) = find_cursor_line(lines, cursor)
  if line_idx <= 0 {
    return cursor
  }
  let prev_line = lines[line_idx - 1]
  let mut new_cursor = prev_line.start_idx
  let mut w = 0
  for i = 0; i < prev_line.chars.length(); i = i + 1 {
    let cw = char_width_code(prev_line.chars[i].to_int())
    if w + cw > col_offset {
      break
    }
    w = w + cw
    new_cursor = prev_line.start_idx + i + 1
  }
  let max_pos = prev_line.start_idx + prev_line.chars.length()
  if new_cursor > max_pos {
    max_pos
  } else {
    new_cursor
  }
}

///|
/// Move cursor to next wrapped line (keeps column offset when possible)
fn cursor_down(lines : Array[LineInfo], cursor : Int) -> Int {
  let (line_idx, col_offset) = find_cursor_line(lines, cursor)
  if line_idx + 1 >= lines.length() {
    return cursor
  }
  let next_line = lines[line_idx + 1]
  let mut new_cursor = next_line.start_idx
  let mut w = 0
  for i = 0; i < next_line.chars.length(); i = i + 1 {
    let cw = char_width_code(next_line.chars[i].to_int())
    if w + cw > col_offset {
      break
    }
    w = w + cw
    new_cursor = next_line.start_idx + i + 1
  }
  let max_pos = next_line.start_idx + next_line.chars.length()
  if new_cursor > max_pos {
    max_pos
  } else {
    new_cursor
  }
}

///|
/// Adjust scroll offset to keep cursor visible
fn adjust_scroll_offset(
  scroll_offset : Int,
  cursor_line_idx : Int,
  max_height : Int,
  total_lines : Int,
) -> Int {
  if total_lines <= max_height {
    return 0
  }
  if cursor_line_idx < scroll_offset {
    cursor_line_idx
  } else if cursor_line_idx >= scroll_offset + max_height {
    cursor_line_idx - max_height + 1
  } else {
    scroll_offset
  }
}
