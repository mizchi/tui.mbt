///|
/// Text Buffer - Core data structure for text editing

///|
/// Cursor position (1-indexed)
pub(all) struct CursorPosition {
  row : Int
  col : Int
}

///|
/// Create cursor position
pub fn CursorPosition::new(row? : Int = 1, col? : Int = 1) -> CursorPosition {
  { row, col }
}

///|
/// Selection range
pub(all) struct Selection {
  anchor : CursorPosition
  cursor : CursorPosition
}

///|
/// Check if selection is empty
pub fn Selection::is_empty(self : Selection) -> Bool {
  self.anchor.row == self.cursor.row && self.anchor.col == self.cursor.col
}

///|
/// Selection mode
pub(all) enum SelectionMode {
  Caret
  VisualChar
  VisualLine
  VisualBlock
}

///|
/// Text buffer state
pub(all) struct TextBuffer {
  lines : Array[String]
  cursor : CursorPosition
  selection : Selection
  mode : SelectionMode
  modified : Bool
}

///|
/// Create empty text buffer
pub fn TextBuffer::new() -> TextBuffer {
  let cursor = CursorPosition::new()
  TextBuffer::{
    lines: [""],
    cursor,
    selection: { anchor: cursor, cursor },
    mode: SelectionMode::Caret,
    modified: false,
  }
}

///|
/// Create text buffer from string (preserves \n line endings)
pub fn TextBuffer::from_string(text : String) -> TextBuffer {
  let lines = text.split("\n").map(fn(sv) { sv.to_string() }).to_array()
  TextBuffer::{
    lines,
    cursor: CursorPosition::new(),
    selection: { anchor: CursorPosition::new(), cursor: CursorPosition::new() },
    mode: SelectionMode::Caret,
    modified: false,
  }
}

///|
/// Create text buffer from file (not yet implemented)
pub fn TextBuffer::from_file(_path : String) -> TextBuffer {
  TextBuffer::new()
}

///|
/// Get current cursor position
pub fn TextBuffer::cursor(self : TextBuffer) -> CursorPosition {
  self.cursor
}

///|
/// Move cursor to position
pub fn TextBuffer::move_to(
  self : TextBuffer,
  row : Int,
  col : Int,
) -> TextBuffer {
  let max_row = self.lines.length()
  let clamped_row = row.clamp(min=1, max=max_row)
  let line = self.lines[clamped_row - 1]
  let max_col = line.length() + 1
  let clamped_col = col.clamp(min=1, max=max_col)
  let new_cursor = CursorPosition::new(row=clamped_row, col=clamped_col)
  TextBuffer::{
    lines: self.lines,
    cursor: new_cursor,
    selection: { anchor: self.selection.anchor, cursor: new_cursor },
    mode: self.mode,
    modified: self.modified,
  }
}

///|
/// Get current line text
pub fn TextBuffer::current_line(self : TextBuffer) -> String {
  self.lines[self.cursor.row - 1]
}

///|
/// Insert character at cursor
pub fn TextBuffer::insert_char(self : TextBuffer, ch : Char) -> TextBuffer {
  let line = self.lines[self.cursor.row - 1]
  let before = String::view(
    line,
    start_offset=0,
    end_offset=self.cursor.col - 1,
  ).to_string()
  let after = String::view(line, start_offset=self.cursor.col - 1).to_string()
  let new_line = before + ch.to_string() + after
  let new_lines = self.lines.copy()
  new_lines[self.cursor.row - 1] = new_line
  let new_cursor = CursorPosition::new(
    row=self.cursor.row,
    col=self.cursor.col + 1,
  )
  TextBuffer::{
    lines: new_lines,
    cursor: new_cursor,
    selection: { anchor: new_cursor, cursor: new_cursor },
    mode: self.mode,
    modified: true,
  }
}

///|
/// Insert string at cursor
pub fn TextBuffer::insert_string(
  self : TextBuffer,
  text : String,
) -> TextBuffer {
  let mut buffer = self
  let chars = text.to_array()
  for i = 0; i < chars.length(); i = i + 1 {
    buffer = buffer.insert_char(chars[i])
  }
  buffer
}

///|
/// Insert newline at cursor
pub fn TextBuffer::insert_newline(self : TextBuffer) -> TextBuffer {
  let line = self.lines[self.cursor.row - 1]
  let before = String::view(
    line,
    start_offset=0,
    end_offset=self.cursor.col - 1,
  ).to_string()
  let after = String::view(line, start_offset=self.cursor.col - 1).to_string()
  let new_lines = Array::new(capacity=self.lines.length() + 1)
  for i = 0; i < self.cursor.row - 1; i = i + 1 {
    new_lines.push(self.lines[i])
  }
  new_lines.push(before)
  new_lines.push(after)
  for i = self.cursor.row; i < self.lines.length(); i = i + 1 {
    new_lines.push(self.lines[i])
  }
  let new_cursor = CursorPosition::new(row=self.cursor.row + 1, col=1)
  TextBuffer::{
    lines: new_lines,
    cursor: new_cursor,
    selection: { anchor: new_cursor, cursor: new_cursor },
    mode: self.mode,
    modified: true,
  }
}

///|
/// Delete character before cursor (backspace)
pub fn TextBuffer::delete_backwards(self : TextBuffer) -> TextBuffer {
  if self.cursor.row == 1 && self.cursor.col == 1 {
    return self
  }
  if self.cursor.col == 1 {
    let prev_line = self.lines[self.cursor.row - 2]
    let curr_line = self.lines[self.cursor.row - 1]
    let merged = prev_line + curr_line
    let new_lines = self.lines.copy()
    new_lines[self.cursor.row - 2] = merged
    ignore(Array::remove(new_lines, self.cursor.row - 1))
    let new_cursor = CursorPosition::new(
      row=self.cursor.row - 1,
      col=prev_line.length() + 1,
    )
    TextBuffer::{
      lines: new_lines,
      cursor: new_cursor,
      selection: { anchor: new_cursor, cursor: new_cursor },
      mode: self.mode,
      modified: true,
    }
  } else {
    let line = self.lines[self.cursor.row - 1]
    let before = String::view(
      line,
      start_offset=0,
      end_offset=self.cursor.col - 2,
    ).to_string()
    let after = String::view(line, start_offset=self.cursor.col - 1).to_string()
    let new_line = before + after
    let new_lines = self.lines.copy()
    new_lines[self.cursor.row - 1] = new_line
    let new_cursor = CursorPosition::new(
      row=self.cursor.row,
      col=self.cursor.col - 1,
    )
    TextBuffer::{
      lines: new_lines,
      cursor: new_cursor,
      selection: { anchor: new_cursor, cursor: new_cursor },
      mode: self.mode,
      modified: true,
    }
  }
}

///|
/// Delete character at cursor (delete key)
pub fn TextBuffer::delete_forwards(self : TextBuffer) -> TextBuffer {
  let line = self.lines[self.cursor.row - 1]
  if self.cursor.col <= line.length() {
    let before = String::view(
      line,
      start_offset=0,
      end_offset=self.cursor.col - 1,
    ).to_string()
    let after = String::view(line, start_offset=self.cursor.col).to_string()
    let new_line = before + after
    let new_lines = self.lines.copy()
    new_lines[self.cursor.row - 1] = new_line
    TextBuffer::{
      lines: new_lines,
      cursor: self.cursor,
      selection: self.selection,
      mode: self.mode,
      modified: true,
    }
  } else if self.cursor.row < self.lines.length() {
    let curr_line = self.lines[self.cursor.row - 1]
    let next_line = self.lines[self.cursor.row]
    let merged = curr_line + next_line
    let new_lines = self.lines.copy()
    new_lines[self.cursor.row - 1] = merged
    ignore(Array::remove(new_lines, self.cursor.row))
    TextBuffer::{
      lines: new_lines,
      cursor: self.cursor,
      selection: self.selection,
      mode: self.mode,
      modified: true,
    }
  } else {
    self
  }
}

///|
/// Delete current line
pub fn TextBuffer::delete_line(self : TextBuffer) -> TextBuffer {
  if self.lines.length() == 1 {
    TextBuffer::{
      lines: [""],
      cursor: CursorPosition::new(row=1, col=1),
      selection: {
        anchor: CursorPosition::new(row=1, col=1),
        cursor: CursorPosition::new(row=1, col=1),
      },
      mode: self.mode,
      modified: true,
    }
  } else if self.cursor.row == self.lines.length() {
    let new_lines = self.lines.copy()
    ignore(Array::remove(new_lines, self.cursor.row - 1))
    let new_cursor = CursorPosition::new(
      row=self.lines.length() - 1,
      col=self.lines[self.lines.length() - 2].length() + 1,
    )
    TextBuffer::{
      lines: new_lines,
      cursor: new_cursor,
      selection: { anchor: new_cursor, cursor: new_cursor },
      mode: self.mode,
      modified: true,
    }
  } else {
    let new_lines = self.lines.copy()
    ignore(Array::remove(new_lines, self.cursor.row - 1))
    TextBuffer::{
      lines: new_lines,
      cursor: self.cursor,
      selection: self.selection,
      mode: self.mode,
      modified: true,
    }
  }
}

///|
/// Get full text as string
pub fn TextBuffer::to_string(self : TextBuffer) -> String {
  let mut result = ""
  let mut first = true
  for i = 0; i < self.lines.length(); i = i + 1 {
    if not(first) {
      result = result + "\n"
    }
    first = false
    result = result + self.lines[i]
  }
  result
}

///|
/// Get line count
pub fn TextBuffer::line_count(self : TextBuffer) -> Int {
  self.lines.length()
}
