///|
/// Text input controller - platform-independent editing logic

///|
/// Text input controller for handling text editing operations
pub(all) struct TextInputController {
  mut buffer : Array[Char]
  mut cursor_pos : Int
  mut scroll_offset : Int
  mut config : TextInputConfig
}

///|
/// Create a new TextInputController
pub fn TextInputController::new(
  config : TextInputConfig,
  initial : String,
) -> TextInputController {
  let buffer = initial.to_array()
  { buffer, cursor_pos: buffer.length(), scroll_offset: 0, config }
}

///|
/// Apply an edit action to the controller
/// Returns true if the action was handled, false otherwise
pub fn TextInputController::apply_action(
  self : TextInputController,
  action : EditAction,
) -> Bool {
  match action {
    Insert(s) => {
      self.insert_text(s)
      true
    }
    DeleteBackward => {
      self.delete_backward()
      true
    }
    DeleteForward => {
      self.delete_forward()
      true
    }
    DeleteToLineStart => {
      self.delete_to_line_start()
      true
    }
    DeleteToLineEnd => {
      self.delete_to_line_end()
      true
    }
    MoveCursorLeft => {
      self.move_left()
      true
    }
    MoveCursorRight => {
      self.move_right()
      true
    }
    MoveCursorUp => {
      self.move_up()
      true
    }
    MoveCursorDown => {
      self.move_down()
      true
    }
    MoveToLineStart => {
      self.move_to_line_start()
      true
    }
    MoveToLineEnd => {
      self.move_to_line_end()
      true
    }
    NewLine => {
      self.insert_newline()
      true
    }
    // These actions should be handled by the caller
    Confirm | Cancel | Tab | BackTab | ForceQuit | None => false
  }
}

///|
/// Get the current text
pub fn TextInputController::get_text(self : TextInputController) -> String {
  String::from_array(self.buffer)
}

///|
/// Set the text content
pub fn TextInputController::set_text(
  self : TextInputController,
  text : String,
) -> Unit {
  self.buffer = text.to_array()
  if self.cursor_pos > self.buffer.length() {
    self.cursor_pos = self.buffer.length()
  }
  self.update_scroll()
}

///|
/// Get cursor position
pub fn TextInputController::get_cursor_pos(self : TextInputController) -> Int {
  self.cursor_pos
}

///|
/// Set cursor position
pub fn TextInputController::set_cursor_pos(
  self : TextInputController,
  pos : Int,
) -> Unit {
  self.cursor_pos = if pos < 0 {
    0
  } else if pos > self.buffer.length() {
    self.buffer.length()
  } else {
    pos
  }
  self.update_scroll()
}

///|
/// Resize the input area
pub fn TextInputController::resize(
  self : TextInputController,
  width : Int,
  height : Int,
) -> Unit {
  self.config.width = width
  self.config.height = height
  self.update_scroll()
}

///|
/// Get the display state for rendering
pub fn TextInputController::get_display_state(
  self : TextInputController,
) -> DisplayState {
  let lines = wrap_text_to_lines(self.buffer, self.config.width)
  let (cursor_line, cursor_col) = find_cursor_line(lines, self.cursor_pos)
  self.scroll_offset = adjust_scroll_offset(
    self.scroll_offset,
    cursor_line,
    self.config.height,
    lines.length(),
  )
  let total_lines = lines.length()
  let has_more_above = self.scroll_offset > 0
  let has_more_below = self.scroll_offset + self.config.height < total_lines
  {
    lines,
    cursor_line,
    cursor_col,
    scroll_offset: self.scroll_offset,
    has_more_above,
    has_more_below,
    total_lines,
  }
}

///|
/// Insert text at cursor position
fn TextInputController::insert_text(
  self : TextInputController,
  text : String,
) -> Unit {
  let chars = text.to_array()
  for i = chars.length() - 1; i >= 0; i = i - 1 {
    self.buffer.insert(self.cursor_pos, chars[i])
  }
  self.cursor_pos = self.cursor_pos + chars.length()
  self.update_scroll()
}

///|
/// Insert newline at cursor position
fn TextInputController::insert_newline(self : TextInputController) -> Unit {
  self.buffer.insert(self.cursor_pos, '\n')
  self.cursor_pos = self.cursor_pos + 1
  self.update_scroll()
}

///|
/// Delete character before cursor (backspace)
fn TextInputController::delete_backward(self : TextInputController) -> Unit {
  if self.cursor_pos > 0 {
    self.cursor_pos = self.cursor_pos - 1
    let _ = self.buffer.remove(self.cursor_pos)
    self.update_scroll()
  }
}

///|
/// Delete character at cursor (delete key)
fn TextInputController::delete_forward(self : TextInputController) -> Unit {
  if self.cursor_pos < self.buffer.length() {
    let _ = self.buffer.remove(self.cursor_pos)
    self.update_scroll()
  }
}

///|
/// Delete from cursor to start of current line (Ctrl+U)
fn TextInputController::delete_to_line_start(
  self : TextInputController,
) -> Unit {
  let lines = wrap_text_to_lines(self.buffer, self.config.width)
  let (line_idx, _) = find_cursor_line(lines, self.cursor_pos)
  let line_start = lines[line_idx].start_idx
  if self.cursor_pos > line_start {
    let delete_count = self.cursor_pos - line_start
    for _ in 0..<delete_count {
      let _ = self.buffer.remove(line_start)

    }
    self.cursor_pos = line_start
    self.update_scroll()
  }
}

///|
/// Delete from cursor to end of current line (Ctrl+K)
fn TextInputController::delete_to_line_end(self : TextInputController) -> Unit {
  let lines = wrap_text_to_lines(self.buffer, self.config.width)
  let (line_idx, _) = find_cursor_line(lines, self.cursor_pos)
  let line = lines[line_idx]
  let line_end = line.start_idx + line.chars.length()
  if self.cursor_pos < line_end {
    let delete_count = line_end - self.cursor_pos
    for _ in 0..<delete_count {
      let _ = self.buffer.remove(self.cursor_pos)

    }
    self.update_scroll()
  }
}

///|
/// Move cursor left
fn TextInputController::move_left(self : TextInputController) -> Unit {
  if self.cursor_pos > 0 {
    self.cursor_pos = self.cursor_pos - 1
    self.update_scroll()
  }
}

///|
/// Move cursor right
fn TextInputController::move_right(self : TextInputController) -> Unit {
  if self.cursor_pos < self.buffer.length() {
    self.cursor_pos = self.cursor_pos + 1
    self.update_scroll()
  }
}

///|
/// Move cursor up
fn TextInputController::move_up(self : TextInputController) -> Unit {
  let lines = wrap_text_to_lines(self.buffer, self.config.width)
  self.cursor_pos = cursor_up(lines, self.cursor_pos)
  self.update_scroll()
}

///|
/// Move cursor down
fn TextInputController::move_down(self : TextInputController) -> Unit {
  let lines = wrap_text_to_lines(self.buffer, self.config.width)
  self.cursor_pos = cursor_down(lines, self.cursor_pos)
  self.update_scroll()
}

///|
/// Move cursor to start of current line (Ctrl+A)
/// Uses display lines (includes both \n and soft wraps)
fn TextInputController::move_to_line_start(self : TextInputController) -> Unit {
  if self.cursor_pos == 0 {
    return
  }
  let lines = wrap_text_to_lines(self.buffer, self.config.width)
  let (cursor_line, _) = find_cursor_line(lines, self.cursor_pos)
  self.cursor_pos = lines[cursor_line].start_idx
  self.update_scroll()
}

///|
/// Move cursor to end of current line (Ctrl+E)
/// Uses display lines (includes both \n and soft wraps)
fn TextInputController::move_to_line_end(self : TextInputController) -> Unit {
  let len = self.buffer.length()
  if self.cursor_pos >= len {
    return
  }
  let lines = wrap_text_to_lines(self.buffer, self.config.width)
  let (cursor_line, _) = find_cursor_line(lines, self.cursor_pos)
  let line = lines[cursor_line]
  // End of line is start + length, but don't include trailing newline
  let line_end = line.start_idx + line.chars.length()
  // If the line ends with \n, position cursor before it
  if line_end > 0 && line_end <= len && line.chars.length() > 0 {
    let last_char = line.chars[line.chars.length() - 1]
    if last_char == '\n' {
      self.cursor_pos = line_end - 1
      self.update_scroll()
      return
    }
  }
  self.cursor_pos = line_end
  self.update_scroll()
}

///|
/// Update scroll offset to keep cursor visible
fn TextInputController::update_scroll(self : TextInputController) -> Unit {
  let lines = wrap_text_to_lines(self.buffer, self.config.width)
  let (cursor_line, _) = find_cursor_line(lines, self.cursor_pos)
  self.scroll_offset = adjust_scroll_offset(
    self.scroll_offset,
    cursor_line,
    self.config.height,
    lines.length(),
  )
}
