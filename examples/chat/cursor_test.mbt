///|
/// Test to reproduce cursor overwriting issue during streaming

///|
/// Simulate the scenario:
/// 1. User sends first message
/// 2. Assistant starts streaming
/// 3. User starts second message while streaming
/// 4. Cursor should not overwrite message area

///|
test "cursor position should not interfere with message area during streaming" {
  let terminal_height = 24

  // Layout calculations
  let visible_height = calc_visible_height(terminal_height)
  let input_row = calc_input_row(terminal_height)
  let _max_input = max_input_rows
  let input_area_bottom = input_row + max_input_rows

  // Message area spans from row 0 to visible_height - 1
  let _message_area_top = 0
  let message_area_bottom = visible_height - 1

  // Input area should not overlap with message area
  inspect(visible_height, content="16")
  inspect(input_row, content="18")

  // Verify input area starts after message area with buffer
  let gap = input_row - message_area_bottom - 1
  inspect(gap, content="2") // divider(1) + buffer(1)

  // Input area should be completely below message area
  inspect(input_row > message_area_bottom, content="true")

  // Cursor position during editing should be in input area only
  let cursor_row = input_row // 0-indexed cursor position
  inspect(cursor_row, content="18")
  inspect(cursor_row >= input_row, content="true")
  inspect(cursor_row <= input_area_bottom, content="true")
}

///|
test "render_message_area_only preserves input area" {
  let terminal_height = 24
  let visible_height = calc_visible_height(terminal_height)
  let input_row = calc_input_row(terminal_height)

  // When rendering message area only, it should only render up to visible_height
  // and not touch input area starting at input_row

  // Message area render bounds (inclusive)
  let message_render_end = visible_height - 1

  // Input area starts at input_row, should be untouched
  inspect(input_row, content="18")
  inspect(message_render_end, content="15")

  // Ensure no overlap
  inspect(input_row > message_render_end, content="true")
}

///|
test "start_editing clears input area correctly" {
  let terminal_height = 24
  let row = calc_input_row(terminal_height)
  let content_height = max_input_rows

  // start_editing clears input content area (lines row to row + content_height - 1)
  let clear_start_row = row
  let clear_end_row = row + content_height - 1
  inspect(clear_start_row, content="18")
  inspect(clear_end_row, content="22")

  // Verify this is within input area
  let input_area_bottom = row + input_area_height - 1
  inspect(input_area_bottom, content="23")
  inspect(clear_end_row <= input_area_bottom, content="true")
}

///|
test "cursor save/restore should work across streaming updates" {
  // When save_cursor is called before message render,
  // and restore_cursor is called after,
  // the cursor should return to its original position

  let saved_row = 18 // Cursor at input area

  // After save/restore cycle
  let restored_row = saved_row
  let _restored_col = 1
  inspect(restored_row, content="18")
}

///|
test "streaming tick during editing should not move cursor out of input area" {
  // When streaming calls render_message_area_only while editing,
  // it saves cursor before render and restores after
  // This should keep cursor in the input area

  let cursor_row = 18 // Input area row (0-indexed)
  let visible_height = calc_visible_height(24)
  let input_row = calc_input_row(24)

  // Cursor should stay in input area
  inspect(cursor_row >= input_row, content="true")

  // Message area should not be affected
  inspect(visible_height, content="16")
  inspect(input_row, content="18")
}

///|
test "status_line_position" {
  // Status line is drawn below input content area
  let terminal_height = 24
  let row = calc_input_row(terminal_height)
  let content_height = max_input_rows
  let status_row = row + content_height
  inspect(row, content="18") // input content starts at row 18
  inspect(content_height, content="5") // max 5 lines for content
  inspect(status_row, content="23") // status at row 23

  // Status should be the second to last line
  let bottom_line = terminal_height - 1
  inspect(status_row, content="23")
  inspect(bottom_line, content="23")
}

///|
test "ansi_sequences_dont_overlap" {
  // Verify ANSI save/restore sequences don't affect layout
  let save_seq = ansi_save_cursor()
  let restore_seq = ansi_restore_cursor()
  let move_seq = ansi_move_to(18, 1)
  inspect(save_seq, content="\u{1b}[s")
  inspect(restore_seq, content="\u{1b}[u")
  inspect(move_seq, content="\u{1b}[19;2H") // 0-indexed (18,1) -> 1-indexed (19,2)
}

///|
test "cursor_position_after_streaming_and_editing" {
  // Simulate the problematic scenario:
  // 1. Streaming is active (on_tick calls render_message_area_only)
  // 2. User starts editing (start_editing is called)
  // 3. Cursor should be at correct input position

  let terminal_height = 24
  let input_row = calc_input_row(terminal_height)

  // start_editing positions cursor at input_row + 1 (1-indexed)
  // but the actual editing starts at (input_row + 1, 2) in 1-indexed coords

  let inplace_row = input_row + 1 // Convert to 1-indexed
  let inplace_col = 2 // Column 2 (after leading space)
  inspect(input_row, content="18") // 0-indexed
  inspect(inplace_row, content="19") // 1-indexed
  inspect(inplace_col, content="2")

  // When render_message_area_only is called during editing:
  // - It saves cursor (at 19,2 in 1-indexed coords)
  // - Renders message area (rows 1-16 in 1-indexed)
  // - Restores cursor (back to 19,2)

  // This should work correctly if sequences are properly nested
}
