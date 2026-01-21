///|
/// Chat components - message rendering, queueing, and layout helpers

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
/// Input queue for storing user inputs while task is running
pub(all) struct InputQueue {
  queue : Array[String]
  is_processing : Ref[Bool]
}

///|
pub fn InputQueue::new() -> InputQueue {
  { queue: [], is_processing: { val: false } }
}

///|
pub fn InputQueue::enqueue(self : InputQueue, input : String) -> Unit {
  self.queue.push(input)
}

///|
pub fn InputQueue::dequeue_all(self : InputQueue) -> Array[String] {
  let items = self.queue.copy()
  self.queue.clear()
  items
}

///|
pub fn InputQueue::items(self : InputQueue) -> Array[String] {
  self.queue.copy()
}

///|
pub fn InputQueue::is_empty(self : InputQueue) -> Bool {
  self.queue.length() == 0
}

///|
pub fn InputQueue::length(self : InputQueue) -> Int {
  self.queue.length()
}

///|
pub fn InputQueue::start_processing(self : InputQueue) -> Unit {
  self.is_processing.val = true
}

///|
pub fn InputQueue::finish_processing(self : InputQueue) -> Unit {
  self.is_processing.val = false
}

///|
pub fn InputQueue::is_busy(self : InputQueue) -> Bool {
  self.is_processing.val
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
/// total_height: terminal height
/// Returns: number of visible lines for messages
pub fn calc_visible_height(total_height : Int) -> Int {
  total_height - input_area_height - divider_height - buffer_lines
}

///|
/// Calculate the row position where input content starts (0-indexed)
/// Layout: message_area | divider(1) | buffer(1) | input_area(6)
/// total_height: terminal height
/// Returns: row number for input content start (0-indexed for use with ansi_move_to)
pub fn calc_input_row(total_height : Int) -> Int {
  // input_area starts after message_area + divider + buffer
  calc_visible_height(total_height) + divider_height + buffer_lines
}

///|
/// Calculate total lines for scroll based on message count
/// message_count: number of messages
/// has_streaming: whether there's streaming content
/// Returns: total number of logical lines
pub fn calc_total_lines(message_count : Int, has_streaming : Bool) -> Int {
  let mut total = message_count * 2 // role + content per message
  if has_streaming {
    total = total + 2
  }
  total
}

///|
/// Clamp line count for input area
/// line_count: current line count
/// Returns: clamped line count between 1 and max_input_rows
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
/// Build a single chat message component
pub fn chat_message(msg : Message, width : Int) -> @core.Component {
  let (icon, role_name, color) = match msg.role {
    User => ("◆", "You", @core.Color::cyan())
    Assistant => ("✦", "Assistant", @core.Color::rgb(255, 150, 100))
  }
  column(
    [
      text(icon + " " + role_name, fg=color, bold=true),
      text("   " + msg.content, fg=@core.Color::rgb(220, 220, 220)),
    ],
    gap=0.0,
    width=@types.Dimension::Length(width.to_double()),
  )
}

///|
/// Build streaming message component with fixed height to prevent layout jumps
pub fn chat_streaming_message(
  streaming : StreamingState,
  width : Int,
  height : Int,
) -> @core.Component {
  let partial = streaming.get_partial()
  let display = if streaming.is_streaming() { partial + "▌" } else { partial }
  column(
    [
      text("✦ Assistant", fg=@core.Color::rgb(255, 150, 100), bold=true),
      text("   " + display, fg=@core.Color::rgb(220, 220, 220)),
    ],
    gap=0.0,
    width=@types.Dimension::Length(width.to_double()),
    height=@types.Dimension::Length(height.to_double()),
  )
}

///|
/// Build a queued (pending) message preview in gray
pub fn chat_queued_message(
  content : String,
  index : Int,
  total : Int,
  width : Int,
) -> @core.Component {
  let gray = @core.Color::rgb(100, 100, 100)
  let label = if total > 1 {
    "◇ Queued [" + (index + 1).to_string() + "]"
  } else {
    "◇ Queued"
  }
  column(
    [text(label, fg=gray, bold=false), text("   " + content, fg=gray)],
    gap=0.0,
    width=@types.Dimension::Length(width.to_double()),
  )
}

///|
/// Build message list components for chat view
pub fn chat_message_list(
  messages : Array[Message],
  streaming : StreamingState,
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
  let queued_items = input_queue.items()
  let total = queued_items.length()
  for i, queued in queued_items {
    items.push(chat_queued_message(queued, i, total, width))
  }
  items
}
