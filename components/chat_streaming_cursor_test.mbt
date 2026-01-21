///|
/// StreamBuffer behavior

///|
test "stream_buffer_initial_size" {
  let buffer = StreamBuffer::new(80, 16)
  let (w, h) = buffer.size()
  inspect(w, content="80")
  inspect(h, content="16")
}

///|
test "stream_buffer_resize_updates_size" {
  let buffer = StreamBuffer::new(80, 16)
  buffer.resize(100, 20)
  let (w, h) = buffer.size()
  inspect(w, content="100")
  inspect(h, content="20")
}

///|
test "stream_buffer_streaming_snapshot" {
  let buffer = StreamBuffer::new(24, 6)
  let messages : Array[Message] = [Message::{ role: User, content: "Hi" }]
  let queue = InputQueue::new()
  let streaming = StreamingState::new()
  streaming.full_text.set("Hello")
  streaming.position.set(1)
  let items1 = chat_message_list(
    messages, streaming, queue, 24, streaming_message_height,
  )
  let area1 = column(
    items1,
    width=@types.Dimension::Length(24.0),
    height=@types.Dimension::Length(6.0),
    justify=@types.Alignment::FlexEnd,
  )
  let output1 = buffer.render_output(area1)
  inspect(output1, content="\u{1b}[s\u{1b}[0m\u{1b}[u")
  streaming.position.set(5)
  let items2 = chat_message_list(
    messages, streaming, queue, 24, streaming_message_height,
  )
  let area2 = column(
    items2,
    width=@types.Dimension::Length(24.0),
    height=@types.Dimension::Length(6.0),
    justify=@types.Alignment::FlexEnd,
  )
  let output2 = buffer.render_output(area2)
  inspect(
    output2,
    content="\u{1b}[s\u{1b}[5;5H\u{1b}[38;5;253mello\u{1b}[0m\u{1b}[u",
  )
}

///|
test "stream_buffer_respects_offset" {
  let buffer = StreamBuffer::new(8, 2)
  ignore(buffer.render_output(text("A"), row=2, col=4))
  let output = buffer.render_output(text("B"), row=2, col=4)
  inspect(output, content="\u{1b}[s\u{1b}[3;5H\u{1b}[38;5;231mB\u{1b}[0m\u{1b}[u")
}
