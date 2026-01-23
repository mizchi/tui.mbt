///|
/// Queue - A generic queue for batching items while processing

///|
/// Generic queue for storing items while a task is running
/// Useful for batching user inputs, commands, or any items during async operations
pub(all) struct Queue[T] {
  items : Array[T]
  is_processing : Ref[Bool]
}

///|
pub fn[T] Queue::new() -> Queue[T] {
  { items: [], is_processing: { val: false } }
}

///|
/// Add an item to the queue
pub fn[T] Queue::enqueue(self : Queue[T], item : T) -> Unit {
  self.items.push(item)
}

///|
/// Remove and return all items from the queue
pub fn[T] Queue::dequeue_all(self : Queue[T]) -> Array[T] {
  let result = self.items.copy()
  self.items.clear()
  result
}

///|
/// Get a copy of all items without removing them
pub fn[T] Queue::peek_all(self : Queue[T]) -> Array[T] {
  self.items.copy()
}

///|
/// Check if the queue is empty
pub fn[T] Queue::is_empty(self : Queue[T]) -> Bool {
  self.items.length() == 0
}

///|
/// Get the number of items in the queue
pub fn[T] Queue::length(self : Queue[T]) -> Int {
  self.items.length()
}

///|
/// Mark processing as started
pub fn[T] Queue::start_processing(self : Queue[T]) -> Unit {
  self.is_processing.val = true
}

///|
/// Mark processing as finished
pub fn[T] Queue::finish_processing(self : Queue[T]) -> Unit {
  self.is_processing.val = false
}

///|
/// Check if currently processing
pub fn[T] Queue::is_busy(self : Queue[T]) -> Bool {
  self.is_processing.val
}

///|
/// Clear all items from the queue
pub fn[T] Queue::clear(self : Queue[T]) -> Unit {
  self.items.clear()
}
