///|
/// InputQueue behavior

///|
test "input_queue_enqueue_and_dequeue" {
  let queue = InputQueue::new()
  queue.enqueue("a")
  queue.enqueue("b")
  inspect(queue.length(), content="2")
  let items = queue.dequeue_all()
  inspect(items.length(), content="2")
  inspect(items[0], content="a")
  inspect(items[1], content="b")
  inspect(queue.is_empty(), content="true")
}

///|
test "input_queue_busy_state" {
  let queue = InputQueue::new()
  inspect(queue.is_busy(), content="false")
  queue.start_processing()
  inspect(queue.is_busy(), content="true")
  queue.finish_processing()
  inspect(queue.is_busy(), content="false")
}

///|
test "input_queue_items_returns_copy" {
  let queue = InputQueue::new()
  queue.enqueue("first")
  let items = queue.items()
  items.push("second")
  inspect(queue.length(), content="1")
  inspect(items.length(), content="2")
}
