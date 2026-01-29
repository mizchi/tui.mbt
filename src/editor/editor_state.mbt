///|
pub struct EditorState {
  doc : Document
  selection : Selection
  viewport : Viewport
  mut preferred_col : Int
  highlight : HighlightState
}

///|
fn is_word_char(c : Char) -> Bool {
  if c.is_whitespace() || c.is_control() {
    false
  } else if c.is_ascii_punctuation() {
    c == '_'
  } else {
    true
  }
}

///|
fn word_bounds(line_text : String, col : Int) -> (Int, Int) {
  let chars = line_text.to_array()
  let len = chars.length()
  let idx = if col < 0 { 0 } else if col > len { len } else { col }
  let mut start = idx
  while start > 0 && is_word_char(chars[start - 1]) {
    start = start - 1
  }
  let mut end = idx
  while end < len && is_word_char(chars[end]) {
    end = end + 1
  }
  (start, end)
}

///|
fn slice_chars(chars : Array[Char], start : Int, end : Int) -> String {
  let sb = StringBuilder::new()
  let s = if start < 0 { 0 } else { start }
  let e = if end < s { s } else if end > chars.length() { chars.length() } else { end }
  for i in s..<e {
    sb.write_char(chars[i])
  }
  sb.to_string()
}

///|
pub fn EditorState::new(text : String, height : Int) -> EditorState {
  EditorState::new_with_kind(text, height, HighlightKind::TypeScript)
}

///|
pub fn EditorState::new_with_kind(
  text : String,
  height : Int,
  kind : HighlightKind,
) -> EditorState {
  let doc = Document::from_text(text)
  let caret : Position = { line: 0, col: 0 }
  let selection = Selection::caret(caret)
  let viewport = Viewport::new(height)
  let highlight = HighlightState::new(kind, doc)
  { doc, selection, viewport, preferred_col: 0, highlight }
}

///|
pub fn EditorState::new_with_filename(
  text : String,
  height : Int,
  filename : String,
) -> EditorState {
  let kind = HighlightKind::from_filename(filename)
  EditorState::new_with_kind(text, height, kind)
}

///|
fn EditorState::caret(self : EditorState) -> Position {
  self.selection.active
}

///|
pub fn EditorState::set_height(self : EditorState, height : Int) -> Unit {
  self.viewport.set_height(height)
  let caret = self.caret()
  self.viewport.ensure_visible(caret.line, self.doc.line_count())
}

///|
pub fn EditorState::caret_line(self : EditorState) -> Int {
  self.caret().line
}

///|
pub fn EditorState::caret_col(self : EditorState) -> Int {
  self.caret().col
}

///|
pub fn EditorState::current_word_prefix(self : EditorState) -> String {
  let caret = self.caret()
  let line_text = self.doc.line(caret.line)
  let chars = line_text.to_array()
  let (start, _) = word_bounds(line_text, caret.col)
  slice_chars(chars, start, caret.col)
}

///|
pub fn EditorState::current_word_bounds(self : EditorState) -> (Int, Int) {
  let caret = self.caret()
  let line_text = self.doc.line(caret.line)
  word_bounds(line_text, caret.col)
}

///|
pub fn EditorState::completion_request(
  self : EditorState,
  request_id : Int,
) -> CompletionRequest {
  let caret = self.caret()
  let line_text = self.doc.line(caret.line)
  let (start_col, end_col) = word_bounds(line_text, caret.col)
  let prefix = slice_chars(line_text.to_array(), start_col, caret.col)
  {
    id: request_id,
    line: caret.line,
    col: caret.col,
    prefix,
    line_text,
    anchor: { line: caret.line, col: start_col },
    replace: { start_col, end_col },
  }
}

///|
pub fn EditorState::replace_current_word(
  self : EditorState,
  word : String,
) -> Unit {
  let caret = self.caret()
  let line_text = self.doc.line(caret.line)
  let (start_col, end_col) = word_bounds(line_text, caret.col)
  let start_pos : Position = { line: caret.line, col: start_col }
  let end_pos : Position = { line: caret.line, col: end_col }
  let edit_line = caret.line
  let _ = self.doc.delete_range(start_pos, end_pos)
  let new_pos = self.doc.insert_text(start_pos, word)
  self.selection.set_caret(new_pos)
  self.preferred_col = new_pos.col
  self.viewport.ensure_visible(new_pos.line, self.doc.line_count())
  self.highlight.update(self.doc, edit_line)
}

///|
fn EditorState::set_caret(
  self : EditorState,
  pos : Position,
  extend : Bool,
  keep_preferred~ : Bool,
) -> Unit {
  let pos = self.doc.clamp_position(pos)
  if extend {
    self.selection.set_active(pos)
  } else {
    self.selection.set_caret(pos)
  }
  if !keep_preferred {
    self.preferred_col = pos.col
  }
  self.viewport.ensure_visible(pos.line, self.doc.line_count())
}

///|
pub fn EditorState::replace_selection(self : EditorState, text : String) -> Unit {
  let (start, end) = self.selection.ordered()
  let edit_line = start.line
  if !self.selection.is_empty() {
    let _ = self.doc.delete_range(start, end)
  }
  let new_pos = self.doc.insert_text(start, text)
  self.selection.set_caret(new_pos)
  self.preferred_col = new_pos.col
  self.viewport.ensure_visible(new_pos.line, self.doc.line_count())
  self.highlight.update(self.doc, edit_line)
}

///|
fn EditorState::delete_backward(self : EditorState) -> Unit {
  let (start, end) = self.selection.ordered()
  let edit_line = start.line
  let new_pos = if !self.selection.is_empty() {
    self.doc.delete_range(start, end)
  } else {
    self.doc.delete_backward(self.selection.active)
  }
  self.selection.set_caret(new_pos)
  self.preferred_col = new_pos.col
  self.viewport.ensure_visible(new_pos.line, self.doc.line_count())
  self.highlight.update(self.doc, edit_line)
}

///|
fn EditorState::delete_forward(self : EditorState) -> Unit {
  let (start, end) = self.selection.ordered()
  let edit_line = start.line
  let new_pos = if !self.selection.is_empty() {
    self.doc.delete_range(start, end)
  } else {
    self.doc.delete_forward(self.selection.active)
  }
  self.selection.set_caret(new_pos)
  self.preferred_col = new_pos.col
  self.viewport.ensure_visible(new_pos.line, self.doc.line_count())
  self.highlight.update(self.doc, edit_line)
}

///|
fn EditorState::move_left(self : EditorState, extend : Bool) -> Unit {
  let caret = self.selection.active
  let mut line = caret.line
  let mut col = caret.col
  if col > 0 {
    col = col - 1
  } else if line > 0 {
    line = line - 1
    col = self.doc.line_length(line)
  }
  self.set_caret({ line, col }, extend, keep_preferred=false)
}

///|
fn EditorState::move_right(self : EditorState, extend : Bool) -> Unit {
  let caret = self.selection.active
  let mut line = caret.line
  let mut col = caret.col
  let line_len = self.doc.line_length(line)
  if col < line_len {
    col = col + 1
  } else if line + 1 < self.doc.line_count() {
    line = line + 1
    col = 0
  }
  self.set_caret({ line, col }, extend, keep_preferred=false)
}

///|
fn EditorState::move_up(self : EditorState, extend : Bool) -> Unit {
  let caret = self.selection.active
  if caret.line == 0 {
    self.set_caret(caret, extend, keep_preferred=true)
    return
  }
  let line = caret.line - 1
  let max_col = self.doc.line_length(line)
  let col = if self.preferred_col > max_col {
    max_col
  } else {
    self.preferred_col
  }
  self.set_caret({ line, col }, extend, keep_preferred=true)
}

///|
fn EditorState::move_down(self : EditorState, extend : Bool) -> Unit {
  let caret = self.selection.active
  if caret.line + 1 >= self.doc.line_count() {
    self.set_caret(caret, extend, keep_preferred=true)
    return
  }
  let line = caret.line + 1
  let max_col = self.doc.line_length(line)
  let col = if self.preferred_col > max_col {
    max_col
  } else {
    self.preferred_col
  }
  self.set_caret({ line, col }, extend, keep_preferred=true)
}

///|
fn EditorState::move_home(self : EditorState, extend : Bool) -> Unit {
  let caret = self.selection.active
  self.set_caret({ line: caret.line, col: 0 }, extend, keep_preferred=false)
}

///|
fn EditorState::move_end(self : EditorState, extend : Bool) -> Unit {
  let caret = self.selection.active
  let col = self.doc.line_length(caret.line)
  self.set_caret({ line: caret.line, col }, extend, keep_preferred=false)
}

///|
fn EditorState::move_page_up(self : EditorState, extend : Bool) -> Unit {
  let caret = self.selection.active
  let delta = if self.viewport.height > 0 { self.viewport.height } else { 1 }
  let line = if caret.line - delta < 0 { 0 } else { caret.line - delta }
  let max_col = self.doc.line_length(line)
  let col = if self.preferred_col > max_col {
    max_col
  } else {
    self.preferred_col
  }
  self.set_caret({ line, col }, extend, keep_preferred=true)
}

///|
fn EditorState::move_page_down(self : EditorState, extend : Bool) -> Unit {
  let caret = self.selection.active
  let delta = if self.viewport.height > 0 { self.viewport.height } else { 1 }
  let mut line = caret.line + delta
  if line >= self.doc.line_count() {
    line = self.doc.line_count() - 1
  }
  let max_col = self.doc.line_length(line)
  let col = if self.preferred_col > max_col {
    max_col
  } else {
    self.preferred_col
  }
  self.set_caret({ line, col }, extend, keep_preferred=true)
}

///|
pub fn EditorState::scroll_view(self : EditorState, delta : Int) -> Unit {
  self.viewport.scroll(delta, self.doc.line_count())
}
