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
  anchor : CursorPosition  // Selection start point
  cursor : CursorPosition  // Current cursor position
}

///|
/// Check if selection is empty
pub fn Selection::is_empty(self : Selection) -> Bool {
  self.anchor.row == self.cursor.row && self.anchor.col == self.cursor.col
}

///|
/// Selection mode
pub(all) enum SelectionMode {
  Caret       // Single cursor, no selection
  VisualChar  // Character selection
  VisualLine  // Line selection
  VisualBlock // Block selection (rectangular)
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
  let lines = text.split("\n").to_array()
  let buffer = TextBuffer::new()
  TextBuffer::{ lines, ..buffer }
}

///|
/// Create text buffer from file (not yet implemented)
pub fn TextBuffer::from_file(path : String) -> TextBuffer {
  TextBuffer::new()
}

///|
/// Get current cursor position
pub fn TextBuffer::cursor(self : TextBuffer) -> CursorPosition {
  self.cursor
}

///|
/// Move cursor to position
pub fn TextBuffer::move_to(self : TextBuffer, row : Int, col : Int) -> TextBuffer {
  let max_row = self.lines.length()
  let clamped_row = row.clamp(min=1, max=max_row)
  let line = self.lines[clamped_row - 1]
  let max_col = line.length() + 1
  let clamped_col = col.clamp(min=1, max=max_col)
  let new_cursor = CursorPosition::new(row=clamped_row, col=clamped_col)
  TextBuffer::{ cursor: new_cursor, ..self }
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
  let before = line.substring(0, self.cursor.col - 1)
  let after = line.substring(self.cursor.col - 1)
  let new_line = before + ch.to_string() + after
  let mut new_lines = self.lines
  new_lines[self.cursor.row - 1] = new_line
  let new_cursor = CursorPosition::new(row=self.cursor.row, col=self.cursor.col + 1)
  TextBuffer::{
    lines: new_lines,
    cursor: new_cursor,
    selection: { anchor: new_cursor, cursor: new_cursor },
    modified: true,
    ..self
  }
}

///|
/// Insert string at cursor
pub fn TextBuffer::insert_string(self : TextBuffer, text : String) -> TextBuffer {
  let mut buffer = self
  for ch in text.to_array() {
    buffer = buffer.insert_char(ch)
  }
  buffer
}

///|
/// Insert newline at cursor
pub fn TextBuffer::insert_newline(self : TextBuffer) -> TextBuffer {
  let line = self.lines[self.cursor.row - 1]
  let before = line.substring(0, self.cursor.col - 1)
  let after = line.substring(self.cursor.col - 1)
  let mut new_lines = self.lines
  new_lines[self.cursor.row - 1] = before
  let mut after_insert = []
  for i = self.cursor.row; i < new_lines.length(); i = i + 1 {
    after_insert.push(new_lines[i])
  }
  after_insert.push(after)
  new_lines = new_lines.slice(end=self.cursor.row)
  new_lines.append_array(after_insert)
  let new_cursor = CursorPosition::new(row=self.cursor.row + 1, col=1)
  TextBuffer::{
    lines: new_lines,
    cursor: new_cursor,
    selection: { anchor: new_cursor, cursor: new_cursor },
    modified: true,
    ..self
  }
}

///|
/// Delete character before cursor (backspace)
pub fn TextBuffer::delete_backwards(self : TextBuffer) -> TextBuffer {
  if self.cursor.row == 1 && self.cursor.col == 1 {
    return self
  }
  if self.cursor.col == 1 {
    // Delete newline - merge with previous line
    let prev_line = self.lines[self.cursor.row - 2]
    let curr_line = self.lines[self.cursor.row - 1]
    let merged = prev_line + curr_line
    let mut new_lines = self.lines
    new_lines[self.cursor.row - 2] = merged
    new_lines.remove_at(self.cursor.row - 1)
    let new_cursor = CursorPosition::new(row=self.cursor.row - 1, col=prev_line.length() + 1)
    TextBuffer::{
      lines: new_lines,
      cursor: new_cursor,
      selection: { anchor: new_cursor, cursor: new_cursor },
      modified: true,
      ..self
    }
  } else {
    // Delete character in current line
    let line = self.lines[self.cursor.row - 1]
    let before = line.substring(0, self.cursor.col - 2)
    let after = line.substring(self.cursor.col - 1)
    let new_line = before + after
    let mut new_lines = self.lines
    new_lines[self.cursor.row - 1] = new_line
    let new_cursor = CursorPosition::new(row=self.cursor.row, col=self.cursor.col - 1)
    TextBuffer::{
      lines: new_lines,
      cursor: new_cursor,
      selection: { anchor: new_cursor, cursor: new_cursor },
      modified: true,
      ..self
    }
  }
}

///|
/// Delete character at cursor (delete key)
pub fn TextBuffer::delete_forwards(self : TextBuffer) -> TextBuffer {
  let line = self.lines[self.cursor.row - 1]
  if self.cursor.col <= line.length() {
    // Delete character in current line
    let before = line.substring(0, self.cursor.col - 1)
    let after = line.substring(self.cursor.col)
    let new_line = before + after
    let mut new_lines = self.lines
    new_lines[self.cursor.row - 1] = new_line
    TextBuffer::{ lines: new_lines, modified: true, ..self }
  } else if self.cursor.row < self.lines.length() {
    // Delete newline - merge with next line
    let curr_line = self.lines[self.cursor.row - 1]
    let next_line = self.lines[self.cursor.row]
    let merged = curr_line + next_line
    let mut new_lines = self.lines
    new_lines[self.cursor.row - 1] = merged
    new_lines.remove_at(self.cursor.row)
    TextBuffer::{ lines: new_lines, modified: true, ..self }
  } else {
    self
  }
}

///|
/// Delete current line
pub fn TextBuffer::delete_line(self : TextBuffer) -> TextBuffer {
  if self.lines.length() == 1 {
    // Clear single line
    TextBuffer::{
      lines: [""],
      cursor: CursorPosition::new(row=1, col=1),
      selection: { anchor: { row=1, col=1 }, cursor: { row=1, col=1 } },
      modified: true,
      ..self
    }
  } else if self.cursor.row == self.lines.length() {
    // Delete last line
    let mut new_lines = self.lines
    new_lines.remove_at(self.cursor.row - 1)
    let new_cursor = CursorPosition::new(row=self.lines.length() - 1, col=self.lines[self.lines.length() - 2].length() + 1)
    TextBuffer::{
      lines: new_lines,
      cursor: new_cursor,
      selection: { anchor: new_cursor, cursor: new_cursor },
      modified: true,
      ..self
    }
  } else {
    // Delete middle line
    let mut new_lines = self.lines
    new_lines.remove_at(self.cursor.row - 1)
    TextBuffer::{ lines: new_lines, modified: true, ..self }
  }
}

///|
/// Get full text as string
pub fn TextBuffer::to_string(self : TextBuffer) -> String {
  let mut result = ""
  let mut first = true
  for line in self.lines {
    if not(first) {
      result = result + "\n"
    }
    first = false
    result = result + line
  }
  result
}

///|
/// Get line count
pub fn TextBuffer::line_count(self : TextBuffer) -> Int {
  self.lines.length()
}
