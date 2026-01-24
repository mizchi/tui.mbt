///|
/// Test: Long streaming content overflows into input area
/// Reproduces the bug where long message stream output overwrites the input area

///|
test "streaming_overflow_into_input_area" {
  // Terminal dimensions
  let width = 80
  let height = 24

  // Calculate layout dimensions
  let visible_height = calc_visible_height(height) // 24 - 6 - 1 - 1 = 16
  let input_row = calc_input_row(height) // 16 + 1 + 1 = 18
  inspect(visible_height, content="16")
  inspect(input_row, content="18")

  // Create a VirtualTerminal to capture actual output
  let vt = @testing.VirtualTerminal::new(width, height)

  // Create stream buffer with visible height
  let stream_buffer = @components.StreamBuffer::new(width, visible_height)

  // Create messages and streaming state
  let messages : Array[Message] = [Message::{ role: User, content: "Hello" }]
  let queue = InputQueue::new()
  let streaming = @components.StreamingState::new()

  // Generate a long streaming response with many newlines
  let long_content = "Line 1\nLine 2\nLine 3\nLine 4\nLine 5\nLine 6\nLine 7\nLine 8\nLine 9\nLine 10\nLine 11\nLine 12\nLine 13\nLine 14\nLine 15\nLine 16\nLine 17\nLine 18\nLine 19\nLine 20"
  streaming.full_text.set(long_content)
  streaming.position.set(long_content.length())

  // Build message content
  let items = chat_message_list(
    messages, streaming, queue, width, streaming_message_height,
  )
  let message_area = @components.column(
    items,
    width=@types.Dimension::Length(width.to_double()),
    height=@types.Dimension::Length(visible_height.to_double()),
    justify=@types.Alignment::FlexEnd,
  )

  // Render to stream buffer
  let output = stream_buffer.render_output(message_area)

  // Apply output to virtual terminal
  vt.write(output)

  // Check that content doesn't appear below visible_height
  // The input area starts at row `input_row` (18), so rows 18-23 should be empty
  // But with the bug, some streaming content might leak into these rows
  let mut content_below_visible = false
  for row = visible_height; row < height; row = row + 1 {
    for col = 0; col < width; col = col + 1 {
      let cell = vt.get_cell(col, row)
      // Check if cell has any content (not space or null)
      if cell.char != ' ' && cell.char != '\u0000' {
        println(
          "Content found at row " +
          row.to_string() +
          ", col " +
          col.to_string() +
          ": '" +
          cell.char.to_string() +
          "'",
        )
        content_below_visible = true
      }
    }
  }

  // This should be false - no content should leak below visible_height
  inspect(content_below_visible, content="false")
}

///|
test "streaming_with_full_render_overflow" {
  // Test the scenario where do_render is called during streaming
  let width = 80
  let height = 24
  let visible_height = calc_visible_height(height)
  let vt = @testing.VirtualTerminal::new(width, height)
  let app = @render.App::new(width, height)
  let messages : Array[Message] = [Message::{ role: User, content: "Hello" }]
  let queue = InputQueue::new()
  let streaming = @components.StreamingState::new()

  // Long content
  let long_content = "A\nB\nC\nD\nE\nF\nG\nH\nI\nJ\nK\nL\nM\nN\nO\nP\nQ\nR\nS\nT"
  streaming.full_text.set(long_content)
  streaming.position.set(long_content.length())

  // Build full UI similar to chat example
  let message_items = chat_message_list(
    messages, streaming, queue, width, streaming_message_height,
  )
  let message_area = @components.column(
    message_items,
    width=@types.Dimension::Length(width.to_double()),
    height=@types.Dimension::Length(visible_height.to_double()),
    justify=@types.Alignment::FlexEnd,
  )
  let divider = @components.text("─".repeat(width))
  let input_content = @components.text(" Type a message...")
  let status = @components.text(" Enter: send", fg=@core.Color::rgb(80, 80, 80))
  let input_area = @components.column(
    [input_content, status],
    height=@types.Dimension::Length(input_area_height.to_double()),
  )
  let buffer_line = @components.column(
    [],
    height=@types.Dimension::Length(buffer_lines.to_double()),
  )
  let full_ui = @components.column(
    [message_area, divider, buffer_line, input_area],
    width=@types.Dimension::Length(width.to_double()),
    height=@types.Dimension::Length(height.to_double()),
  )
  let output = app.render_frame(full_ui)
  vt.write(output)

  // The input area should show "Type a message..." not streaming content
  // Check if the input row contains expected text
  let input_row = calc_input_row(height)
  inspect(vt.line_contains(input_row, "Type a message"), content="true")
}

///|
test "streaming_block_respects_height_constraint" {
  // Test that streaming_block clips content to its height
  let width = 40
  let container_height = 4
  let long_text = "Line1\nLine2\nLine3\nLine4\nLine5\nLine6\nLine7\nLine8"
  let block = @components.streaming_block(
    "✦",
    "Assistant",
    long_text,
    width~,
    height=container_height,
  )

  // Render to buffer and check
  let app = @render.App::new(width, 10)
  let buf_output = app.render(block)
  let vt = @testing.VirtualTerminal::new(width, 10)
  vt.write(buf_output)

  // Count how many rows have content
  let mut rows_with_content = 0
  for row = 0; row < 10; row = row + 1 {
    let line = vt.get_line_trimmed(row)
    if line.length() > 0 {
      rows_with_content = rows_with_content + 1
    }
  }

  // Content should be limited to container_height (4) rows
  // But if there's overflow, it might exceed this
  println("Rows with content: " + rows_with_content.to_string())

  // The streaming_block has height=4, so content should not exceed 4 rows
  // However, the current implementation may not enforce this...
  inspect(rows_with_content <= container_height, content="true")
}
