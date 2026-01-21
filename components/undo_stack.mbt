///|
/// Undo/Redo System for text buffer

///|
/// Text operation for undo/redo
pub(all) enum EditOp {
  Insert { pos : CursorPosition, text : String }
  Delete { pos : CursorPosition, text : String }
  MoveCursor { from : CursorPosition, to : CursorPosition }
}

///|
/// Undo/Redo stack
pub(all) struct UndoStack {
  undos : Array[EditOp]
  redos : Array[EditOp]
  current_group : Array[EditOp]
  max_size : Int
}

///|
/// Create empty undo stack
pub fn UndoStack::new() -> UndoStack {
  UndoStack::{
    undos: [],
    redos: [],
    current_group: [],
    max_size: 1000,
  }
}

///|
/// Start a new undo group
pub fn UndoStack::begin_group(self : UndoStack) -> UndoStack {
  UndoStack::{ current_group: [], ..self }
}

///|
/// End current undo group and push to undo stack
pub fn UndoStack::end_group(self : UndoStack) -> UndoStack {
  if self.current_group.length() == 0 {
    return self
  }
  let mut new_undos = self.undos
  new_undos.push_array(self.current_group)
  if new_undos.length() > self.max_size {
    // Remove oldest
    new_undos.remove_at(0)
  }
  UndoStack::{
    undos: new_undos,
    redos: [],
    current_group: [],
    ..self
  }
}

///|
/// Add single operation to current group
pub fn UndoStack::push(self : UndoStack, op : EditOp) -> UndoStack {
  let mut new_group = self.current_group
  new_group.push(op)
  UndoStack::{ current_group: new_group, ..self }
}

///|
/// Undo last operation
pub fn UndoStack::undo(self : UndoStack, buffer : TextBuffer) -> (TextBuffer, UndoStack) {
  if self.undos.length() == 0 {
    return (buffer, self)
  }
  let mut new_undos = self.undos
  let mut new_redos = self.redos
  let mut new_buffer = buffer
  let ops = new_undos[new_undos.length() - 1]
  
  // Undo operations in reverse order
  for i = ops.length() - 1; i >= 0; i = i - 1 {
    let op = ops[i]
    (new_buffer, _) = undo_op(new_buffer, op)
  }
  
  new_undos.remove_at(new_undos.length() - 1)
  new_redos.push(ops)
  
  (new_buffer, UndoStack::{ undos: new_undos, redos: new_redos, ..self })
}

///|
/// Redo last undone operation
pub fn UndoStack::redo(self : UndoStack, buffer : TextBuffer) -> (TextBuffer, UndoStack) {
  if self.redos.length() == 0 {
    return (buffer, self)
  }
  let mut new_undos = self.undos
  let mut new_redos = self.redos
  let mut new_buffer = buffer
  let ops = new_redos[new_redos.length() - 1]
  
  // Redo operations in order
  for op in ops {
    new_buffer = redo_op(new_buffer, op)
  }
  
  new_redos.remove_at(new_redos.length() - 1)
  new_undos.push(ops)
  
  (new_buffer, UndoStack::{ undos: new_undos, redos: new_redos, ..self })
}

///|
/// Check if can undo
pub fn UndoStack::can_undo(self : UndoStack) -> Bool {
  self.undos.length() > 0
}

///|
/// Check if can redo
pub fn UndoStack::can_redo(self : UndoStack) -> Bool {
  self.redos.length() > 0
}

///|
/// Undo single operation
fn undo_op(buffer : TextBuffer, op : EditOp) -> (TextBuffer, EditOp) {
  match op {
    EditOp::Insert { pos, text } => {
      // Delete inserted text
      let mut new_buffer = buffer.move_to(pos.row, pos.col)
      for _i = 0; i < text.length(); i = i + 1 {
        new_buffer = new_buffer.delete_backwards()
      }
      (new_buffer, EditOp::Delete { pos, text })
    }
    EditOp::Delete { pos, text } => {
      // Re-insert deleted text
      let new_buffer = buffer.move_to(pos.row, pos.col).insert_string(text)
      (new_buffer, EditOp::Insert { pos, text })
    }
    EditOp::MoveCursor { from, to } =>
      // Move cursor back
      (buffer.move_to(from.row, from.col), EditOp::MoveCursor { from: to, to: from })
  }
}

///|
/// Redo single operation
fn redo_op(buffer : TextBuffer, op : EditOp) -> TextBuffer {
  match op {
    EditOp::Insert { pos, text } =>
      // Re-insert text
      buffer.move_to(pos.row, pos.col).insert_string(text)
    
    EditOp::Delete { pos, text } =>
      // Re-delete text
      let moved = buffer.move_to(pos.row, pos.col)
      let mut new_buffer = moved
      for _i = 0; i < text.length(); i = i + 1 {
        new_buffer = new_buffer.delete_forwards()
      }
      new_buffer
    
    EditOp::MoveCursor { to } =>
      // Move cursor to position
      buffer.move_to(to.row, to.col)
  }
}
