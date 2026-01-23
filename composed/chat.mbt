///|
/// Chat components - message rendering and layout helpers
/// Built on top of generic components (labeled_block, streaming_text, queue)

///|
/// Message role for chat
pub(all) enum MessageRole {
  User
  Assistant
} derive(Eq)

///|
/// Chat message
pub(all) struct Message {
  role : MessageRole
  content : String
}

///|
/// Type alias for chat input queue
pub(all) struct InputQueue(@components.Queue[String])

///|
pub fn InputQueue::new() -> InputQueue {
  InputQueue(@components.Queue::new())
}

///|
pub fn InputQueue::enqueue(self : InputQueue, item : String) -> Unit {
  self.0.enqueue(item)
}

///|
pub fn InputQueue::dequeue_all(self : InputQueue) -> Array[String] {
  self.0.dequeue_all()
}

///|
pub fn InputQueue::items(self : InputQueue) -> Array[String] {
  self.0.peek_all()
}

///|
pub fn InputQueue::is_empty(self : InputQueue) -> Bool {
  self.0.is_empty()
}

///|
pub fn InputQueue::length(self : InputQueue) -> Int {
  self.0.length()
}

///|
pub fn InputQueue::start_processing(self : InputQueue) -> Unit {
  self.0.start_processing()
}

///|
pub fn InputQueue::finish_processing(self : InputQueue) -> Unit {
  self.0.finish_processing()
}

///|
pub fn InputQueue::is_busy(self : InputQueue) -> Bool {
  self.0.is_busy()
}

///|
/// Layout configuration constants
pub let max_input_rows : Int = 5

///|
pub let input_area_height : Int = 6 // max_input_rows + 1 (status line)

///|
pub let buffer_lines : Int = 1 // Buffer line between divider and input

///|
pub let divider_height : Int = 1

///|
pub let streaming_message_height : Int = 4 // Fixed height for streaming message

///|
/// Calculate the visible height for message area
pub fn calc_visible_height(total_height : Int) -> Int {
  total_height - input_area_height - divider_height - buffer_lines
}

///|
/// Calculate the row position where input content starts (0-indexed)
pub fn calc_input_row(total_height : Int) -> Int {
  calc_visible_height(total_height) + divider_height + buffer_lines
}

///|
/// Calculate total lines for scroll based on message count
pub fn calc_total_lines(message_count : Int, has_streaming : Bool) -> Int {
  let mut total = message_count * 2
  if has_streaming {
    total = total + 2
  }
  total
}

///|
/// Clamp line count for input area
pub fn clamp_input_lines(line_count : Int) -> Int {
  if line_count < 1 {
    1
  } else if line_count > max_input_rows {
    max_input_rows
  } else {
    line_count
  }
}

///|
/// Get icon and color for a message role
fn role_style(role : MessageRole) -> (String, String, @core.Color) {
  match role {
    User => ("◆", "You", @core.Color::cyan())
    Assistant => ("✦", "Assistant", @core.Color::rgb(255, 150, 100))
  }
}

///|
/// Build a single chat message component using labeled_block
pub fn chat_message(msg : Message, width : Int) -> @core.Component {
  let (icon, label, color) = role_style(msg.role)
  @components.labeled_block(icon, label, msg.content, label_color=color, width~)
}

///|
/// Build streaming message component using streaming_block
pub fn chat_streaming_message(
  streaming : @components.StreamingState,
  width : Int,
  height : Int,
) -> @core.Component {
  @components.streaming_block(
    "✦",
    "Assistant",
    streaming.get_partial(),
    is_streaming=streaming.is_streaming(),
    label_color=@core.Color::rgb(255, 150, 100),
    width~,
    height~,
  )
}

///|
/// Build a queued (pending) message preview using labeled_block
pub fn chat_queued_message(
  content : String,
  index : Int,
  total : Int,
  width : Int,
) -> @core.Component {
  let gray = @components.labeled_block_pending_color()
  let label = if total > 1 {
    "Queued [" + (index + 1).to_string() + "]"
  } else {
    "Queued"
  }
  @components.labeled_block(
    "◇",
    label,
    content,
    label_color=gray,
    content_color=gray,
    bold_label=false,
    width~,
  )
}

///|
/// Build message list components for chat view
pub fn chat_message_list(
  messages : Array[Message],
  streaming : @components.StreamingState,
  input_queue : InputQueue,
  width : Int,
  streaming_height : Int,
) -> Array[@core.Component] {
  let items : Array[@core.Component] = []
  for msg in messages {
    items.push(chat_message(msg, width))
  }
  if streaming.has_content() {
    items.push(chat_streaming_message(streaming, width, streaming_height))
  }
  let queued_items = input_queue.0.peek_all()
  let total = queued_items.length()
  for i, queued in queued_items {
    items.push(chat_queued_message(queued, i, total, width))
  }
  items
}
