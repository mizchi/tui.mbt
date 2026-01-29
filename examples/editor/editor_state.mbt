///|
struct EditorState {
  doc : Document
  selection : Selection
  viewport : Viewport
  mut preferred_col : Int
  highlight : HighlightState
}

///|
fn EditorState::new(text : String, height : Int) -> EditorState {
  let doc = Document::from_text(text)
  let caret = { line: 0, col: 0 }
  let selection = Selection::caret(caret)
  let viewport = Viewport::new(height)
  let highlight = HighlightState::new(HighlightKind::TypeScript, doc)
  { doc, selection, viewport, preferred_col: 0, highlight }
}

///|
fn EditorState::caret(self : EditorState) -> Position {
  self.selection.active
}

///|
fn EditorState::set_height(self : EditorState, height : Int) -> Unit {
  self.viewport.set_height(height)
  let caret = self.caret()
  self.viewport.ensure_visible(caret.line, self.doc.line_count())
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
fn EditorState::replace_selection(self : EditorState, text : String) -> Unit {
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
fn EditorState::scroll_view(self : EditorState, delta : Int) -> Unit {
  self.viewport.scroll(delta, self.doc.line_count())
}
