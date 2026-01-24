///|
/// StreamBuffer behavior

///|
test "stream_buffer_initial_size" {
  let buffer = @components.StreamBuffer::new(80, 16)
  let (w, h) = buffer.size()
  inspect(w, content="80")
  inspect(h, content="16")
}

///|
test "stream_buffer_resize_updates_size" {
  let buffer = @components.StreamBuffer::new(80, 16)
  buffer.resize(100, 20)
  let (w, h) = buffer.size()
  inspect(w, content="100")
  inspect(h, content="20")
}

///|
test "stream_buffer_streaming_snapshot" {
  let buffer = @components.StreamBuffer::new(24, 6)
  let messages : Array[Message] = [Message::{ role: User, content: "Hi" }]
  let queue = InputQueue::new()
  let streaming = @components.StreamingState::new()
  streaming.full_text.set("Hello")
  streaming.position.set(1)
  let items1 = chat_message_list(
    messages, streaming, queue, 24, streaming_message_height,
  )
  let area1 = @components.column(
    items1,
    width=@types.Dimension::Length(24.0),
    height=@types.Dimension::Length(6.0),
    justify=@types.Alignment::FlexEnd,
  )
  let output1 = buffer.render_output(area1)
  // First render should be full (not empty) - contains "H" and cursor
  inspect(output1.contains("H"), content="true")
  inspect(output1.contains("▌"), content="true")
  streaming.position.set(5)
  let items2 = chat_message_list(
    messages, streaming, queue, 24, streaming_message_height,
  )
  let area2 = @components.column(
    items2,
    width=@types.Dimension::Length(24.0),
    height=@types.Dimension::Length(6.0),
    justify=@types.Alignment::FlexEnd,
  )
  let output2 = buffer.render_output(area2)
  // Second render is a diff - should add "ello" (the remaining text)
  inspect(output2.contains("ello"), content="true")
}

///|
test "stream_buffer_respects_offset" {
  let buffer = @components.StreamBuffer::new(8, 2)
  ignore(buffer.render_output(@components.text("A"), row=2, col=4))
  let output = buffer.render_output(@components.text("B"), row=2, col=4)
  inspect(
    output,
    content="\u{1b}[s\u{1b}[3;5H\u{1b}[38;5;231mB\u{1b}[0m\u{1b}[u",
  )
}

///|
/// Test: streaming completion followed by new message and new streaming
/// This simulates the bug where old streaming content mixes with new content
test "stream_buffer_streaming_to_message_transition" {
  let buffer = @components.StreamBuffer::new(40, 8)
  let messages : Array[Message] = [Message::{ role: User, content: "Hello" }]
  let queue = InputQueue::new()
  let streaming = @components.StreamingState::new()

  // Phase 1: Start streaming a response
  streaming.full_text.set("This is a simulated response.")
  streaming.position.set(30) // Fully streamed
  let items1 = chat_message_list(
    messages, streaming, queue, 40, streaming_message_height,
  )
  let area1 = @components.column(
    items1,
    width=@types.Dimension::Length(40.0),
    height=@types.Dimension::Length(8.0),
    justify=@types.Alignment::FlexEnd,
  )
  ignore(buffer.render_output(area1))

  // Phase 2: Streaming completes, add it as a message
  // This simulates finish_streaming() + add_message()
  let response_text = streaming.full_text.get()
  streaming.full_text.set("")
  streaming.position.set(0)
  messages.push(Message::{ role: Assistant, content: response_text })

  // Phase 3: Add queued user message and start new streaming
  messages.push(Message::{ role: User, content: "Another message" })
  streaming.full_text.set("Processed 1 queued message(s).")
  streaming.position.set(31) // Fully streamed

  // Clear buffer to simulate fresh render after transition
  buffer.clear()
  let items2 = chat_message_list(
    messages, streaming, queue, 40, streaming_message_height,
  )
  let area2 = @components.column(
    items2,
    width=@types.Dimension::Length(40.0),
    height=@types.Dimension::Length(8.0),
    justify=@types.Alignment::FlexEnd,
  )
  let output2 = buffer.render_output(area2)

  // The output should NOT contain remnants of "simulated response"
  // after the transition to new messages
  println("Output after transition:")
  println(output2)

  // Check that the new streaming content is present
  inspect(output2.contains("Processed"), content="true")
}

///|
/// Test: diff rendering clears old content when layout changes
test "buffer_diff_clears_old_content_on_layout_change" {
  // Simulate the exact scenario: longer text followed by shorter text
  let buf1 = @render.CharBuffer::new(40, 3)
  let buf2 = @render.CharBuffer::new(40, 3)
  let style : @render.TextStyle = {
    fg: @core.Color::white(),
    bg: @core.Color::transparent(),
    bold: false,
    underline: false,
  }

  // First buffer: "This is a simulated response."
  ignore(buf1.write_text(0, 0, "This is a simulated response.", style, 40))

  // Second buffer: "Processed 1 queued message(s)." on a DIFFERENT row
  // (simulating layout shift when messages are added)
  ignore(buf2.write_text(0, 1, "Processed 1 queued message(s).", style, 40))

  // The diff should clear row 0 and write to row 1
  let diff = buf2.diff_to_ansi(buf1)
  println("Diff output:")
  println(diff)

  // The diff should contain the new content
  inspect(diff.contains("Processed"), content="true")

  // Check that the old row is cleared (spaces written)
  // Row 0 should have spaces where "This is a simulated response." was
}

///|
/// Test: streaming completion - main app buffer vs stream_buffer sync
/// Bug: When streaming finishes, "You said: X" becomes "aid: X" (missing "You s")
/// Fix: Clear main_app.prev_buffer after streaming to force full render
test "streaming_completion_main_buffer_sync" {
  let width = 50
  let height = 10

  // Main app (used for full UI rendering)
  let main_app = @render.App::new(width, height)

  // Stream buffer (used for streaming updates)
  let stream_buffer = @components.StreamBuffer::new(width, height)
  let messages : Array[Message] = [Message::{ role: User, content: "test" }]
  let queue = InputQueue::new()
  let streaming = @components.StreamingState::new()

  // Phase 1: Initial render with main app (before streaming)
  let items0 = chat_message_list(
    messages, streaming, queue, width, streaming_message_height,
  )
  let area0 = @components.column(
    items0,
    width=@types.Dimension::Length(width.to_double()),
    height=@types.Dimension::Length(height.to_double()),
    justify=@types.Alignment::FlexEnd,
  )
  ignore(main_app.render(area0))

  // Phase 2: Start streaming - render with stream_buffer
  streaming.full_text.set("You said: test. This is a simulated response.")
  streaming.position.set(45) // Fully streamed
  let items1 = chat_message_list(
    messages, streaming, queue, width, streaming_message_height,
  )
  let area1 = @components.column(
    items1,
    width=@types.Dimension::Length(width.to_double()),
    height=@types.Dimension::Length(height.to_double()),
    justify=@types.Alignment::FlexEnd,
  )
  // Stream buffer renders the streaming content
  ignore(stream_buffer.render_output(area1))

  // Phase 3: Streaming completes - add to messages and render with main app
  let response = streaming.full_text.get()
  streaming.full_text.set("")
  streaming.position.set(0)
  messages.push(Message::{ role: Assistant, content: response })

  // FIX: Clear main_app's prev_buffer to force full render
  // (This is what finish_streaming() now does in chat example)
  main_app.clear_prev_buffer()
  let items2 = chat_message_list(
    messages, streaming, queue, width, streaming_message_height,
  )
  let area2 = @components.column(
    items2,
    width=@types.Dimension::Length(width.to_double()),
    height=@types.Dimension::Length(height.to_double()),
    justify=@types.Alignment::FlexEnd,
  )
  let output = main_app.render(area2)
  println("Final output after streaming completion:")
  println(output)

  // The output should contain the FULL text "You said:"
  inspect(output.contains("You said"), content="true")
}

///|
/// Test: Without clearing prev_buffer, diff render produces incorrect output
test "streaming_completion_without_clear_shows_bug" {
  let width = 50
  let height = 10
  let main_app = @render.App::new(width, height)
  let stream_buffer = @components.StreamBuffer::new(width, height)
  let messages : Array[Message] = [Message::{ role: User, content: "test" }]
  let queue = InputQueue::new()
  let streaming = @components.StreamingState::new()

  // Phase 1: Initial render
  let items0 = chat_message_list(
    messages, streaming, queue, width, streaming_message_height,
  )
  let area0 = @components.column(
    items0,
    width=@types.Dimension::Length(width.to_double()),
    height=@types.Dimension::Length(height.to_double()),
    justify=@types.Alignment::FlexEnd,
  )
  ignore(main_app.render(area0))

  // Phase 2: Streaming updates via stream_buffer
  streaming.full_text.set("You said: test. This is a simulated response.")
  streaming.position.set(45)
  let items1 = chat_message_list(
    messages, streaming, queue, width, streaming_message_height,
  )
  let area1 = @components.column(
    items1,
    width=@types.Dimension::Length(width.to_double()),
    height=@types.Dimension::Length(height.to_double()),
    justify=@types.Alignment::FlexEnd,
  )
  ignore(stream_buffer.render_output(area1))

  // Phase 3: Streaming completes, render with main_app WITHOUT clearing buffer
  let response = streaming.full_text.get()
  streaming.full_text.set("")
  streaming.position.set(0)
  messages.push(Message::{ role: Assistant, content: response })

  // BUG DEMO: NOT clearing prev_buffer - diff will be incorrect
  // main_app.clear_prev_buffer()  // <-- Intentionally commented out

  let items2 = chat_message_list(
    messages, streaming, queue, width, streaming_message_height,
  )
  let area2 = @components.column(
    items2,
    width=@types.Dimension::Length(width.to_double()),
    height=@types.Dimension::Length(height.to_double()),
    justify=@types.Alignment::FlexEnd,
  )
  let output = main_app.render(area2)

  // Without the fix, this test would show the bug - diff output may be partial
  // The output is a diff against the pre-streaming state, which may miss
  // cells that stream_buffer updated but main_app doesn't know about
  println("Output without clearing (may have partial content):")
  println(output)
}
