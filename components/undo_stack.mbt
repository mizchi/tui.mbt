///|
/// Undo/Redo System for text buffer (simplified version)

///|
/// Undo/Redo stack
pub(all) struct UndoStack {
  history : Array[String]
  max_size : Int
}

///|
/// Create empty undo stack
pub fn UndoStack::new() -> UndoStack {
  UndoStack::{ history: [], max_size: 100 }
}

///|
/// Add operation to history
pub fn UndoStack::push(self : UndoStack, op : String) -> UndoStack {
  let new_history = Array::new(capacity=self.history.length() + 1)
  for i = 0; i < self.history.length(); i = i + 1 {
    new_history.push(self.history[i])
  }
  new_history.push(op)
  if new_history.length() > self.max_size {
    ignore(Array::remove(new_history, 0))
  }
  UndoStack::{ history: new_history, max_size: self.max_size }
}

///|
/// Get undo count
pub fn UndoStack::undo_count(self : UndoStack) -> Int {
  self.history.length()
}

///|
/// Get redo count
pub fn UndoStack::redo_count(_self : UndoStack) -> Int {
  0
}
