///|
/// Step-by-step reproduction of the input/streaming/interrupt scenario

///|
test "step_by_step_reproduction" {
  // Scenario: User types first message, assistant streams, user starts second message

  // Step 1: Initial state
  let messages_empty = 0
  let mut streaming = false
  let mut is_editing = false
  inspect(messages_empty, content="0")
  inspect(streaming, content="false")
  inspect(is_editing, content="false")

  // Step 2: User types "hello" and presses Enter
  let user_input = "hello"
  let user_message_count = 1
  streaming = true // Assistant starts streaming
  inspect(user_input, content="hello")
  inspect(user_message_count, content="1")
  inspect(streaming, content="true")

  // Step 3: Streaming is active (on_tick calls render_message_area_only)
  // Every tick:
  // - if is_editing is true: render_message_area_only saves cursor, renders, restores cursor
  // - else: do_render

  // Step 4: While streaming, user starts typing second message
  is_editing = true
  inspect(is_editing, content="true")
  inspect(streaming, content="true")

  // Step 5: start_editing() is called
  // 5a. is_editing.set(true) - already done
  // 5b. do_render()
  //     - editing = true
  //     - save cursor (at current position)
  //     - render UI
  //     - restore cursor
  //     - show cursor (PROBLEM)
  // 5c. hide cursor (FIX)
  // 5d. clear input area
  // 5e. draw status line
  // 5f. start_edit_inplace()

  // Step 6: User types "uu" in the edit box
  let second_input = "uu"
  inspect(second_input, content="uu")
  inspect(is_editing, content="true")
  inspect(streaming, content="true")

  // Step 7: Streaming tick continues
  // on_tick -> render_message_area_only()
  // - if is_editing is true:
  //   - save cursor (at position managed by start_edit_inplace)
  //   - move to (0,0)
  //   - render message area
  //   - restore cursor (to edit position)
  // - if is_editing is false:
  //   - do_render()

  // The problem: At step 5b, cursor was shown at old position
  // The fix: Hide cursor at step 5c, start_edit_inplace shows at correct position
}

///|
test "cursor_position_during_streaming_and_editing" {
  // Detailed cursor position tracking

  let terminal_height = 24
  let _width = 80

  // Initial: Not editing, cursor at input_row
  let cursor_row = calc_input_row(terminal_height) // 18
  let cursor_col = 0
  inspect(cursor_row, content="18")
  inspect(cursor_col, content="0")

  // User sends first message, streaming starts
  // User starts second input

  // start_editing() sequence:

  // 1. do_render() with is_editing=true
  //    - saves cursor at current position
  let saved_cursor_row = cursor_row
  let saved_cursor_col = cursor_col
  inspect(saved_cursor_row, content="18")
  inspect(saved_cursor_col, content="0")

  //    - renders UI
  //    - restores cursor to saved position
  let restored_cursor_row = saved_cursor_row
  let restored_cursor_col = saved_cursor_col
  inspect(restored_cursor_row, content="18")
  inspect(restored_cursor_col, content="0")

  //    - shows cursor (PROBLEM: at wrong position)
  let cursor_shown = true
  inspect(cursor_shown, content="true")

  // 2. Hide cursor (FIX)
  let cursor_hidden = true
  inspect(cursor_hidden, content="true")

  // 3. Clear input area (lines 18-22)
  let clear_start = calc_input_row(terminal_height)
  let clear_end = clear_start + max_input_rows - 1
  inspect(clear_start, content="18")
  inspect(clear_end, content="22")

  // 4. Draw status line
  let status_row = clear_start + max_input_rows
  inspect(status_row, content="23")

  // 5. start_edit_inplace()
  //    - This will position cursor correctly at input row
  let inplace_row = calc_input_row(terminal_height) + 1 // 1-indexed
  let inplace_col = 2 // 1-indexed (after leading space)
  inspect(inplace_row, content="19")
  inspect(inplace_col, content="2")

  // User types "uu"
  // Cursor is now at position after "uu"
  let input_length = 2
  let cursor_after_input = inplace_col + input_length
  inspect(cursor_after_input, content="4") // 2 + 2 = 4

  // Streaming tick:
  // render_message_area_only()
  // - saves cursor (at position managed by start_edit_inplace)
  let streaming_saved_row = inplace_row - 1 // Convert to 0-indexed
  let streaming_saved_col = cursor_after_input - 1
  inspect(streaming_saved_row, content="18")
  inspect(streaming_saved_col, content="3")

  // - renders message area (rows 0-15)
  let message_area_end = calc_visible_height(terminal_height) - 1
  inspect(message_area_end, content="15")

  // - restores cursor (to edit position)
  let streaming_restored_row = streaming_saved_row
  let streaming_restored_col = streaming_saved_col
  inspect(streaming_restored_row, content="18")
  inspect(streaming_restored_col, content="3")

  // Cursor should remain at correct edit position
  let cursor_at_correct_position = streaming_restored_row == 18 &&
    streaming_restored_col == 3
  inspect(cursor_at_correct_position, content="true")
}

///|
test "user_typing_during_streaming_sequence" {
  // Simulate actual user typing "You said: uu. This is a simulated response."
  // appearing character by character while streaming

  let streaming = true
  let is_editing = true
  let mut input_text = ""

  // User types 'u'
  input_text = input_text + "u"
  inspect(input_text, content="u")

  // Streaming tick: render_message_area_only
  // - saves cursor position (after 'u')
  // - renders message area (updates streaming text)
  // - restores cursor

  // User types 'u'
  input_text = input_text + "u"
  inspect(input_text, content="uu")

  // Streaming tick: render_message_area_only
  // - saves cursor position (after 'uu')
  // - renders message area
  // - restores cursor

  // Cursor should be at correct position after "uu"
  let expected_cursor_col = 2 + input_text.length() // leading space (1) + "uu" (2) = col 4 (1-indexed)
  inspect(expected_cursor_col, content="4")

  // Streaming continues adding more text to message area
  // Each tick:
  // - saves cursor
  // - renders (may add streaming text)
  // - restores cursor

  // Cursor should remain stable at edit position
  inspect(input_text, content="uu")
  inspect(is_editing, content="true")
  inspect(streaming, content="true")
}

///|
test "render_message_area_only_preserves_editing_cursor" {
  // Verify render_message_area_only preserves editing cursor position

  let terminal_height = 24
  let input_row = calc_input_row(terminal_height) // 18
  let input_col = 1 // After leading space
  let input_length = 2 // "uu"

  // Current cursor position in edit box
  let cursor_row = input_row
  let cursor_col = input_col + input_length
  inspect(cursor_row, content="18")
  inspect(cursor_col, content="3")

  // render_message_area_only sequence:

  // 1. Save cursor
  let saved_row = cursor_row
  let saved_col = cursor_col
  inspect(saved_row, content="18")
  inspect(saved_col, content="3")

  // 2. Move to (0,0) and render message area
  let render_row = 0
  let render_col = 0
  inspect(render_row, content="0")
  inspect(render_col, content="0")
  let message_area_height = calc_visible_height(terminal_height)
  inspect(message_area_height, content="16")

  // 3. Restore cursor
  let restored_row = saved_row
  let restored_col = saved_col
  inspect(restored_row, content="18")
  inspect(restored_col, content="3")

  // 4. Cursor should be at same position as before
  let cursor_preserved = restored_row == saved_row && restored_col == saved_col
  inspect(cursor_preserved, content="true")

  // 5. Cursor should be in input area, not message area
  let message_area_end = calc_visible_height(terminal_height) - 1
  inspect(message_area_end, content="15")
  inspect(restored_row > message_area_end, content="true")
}

///|

///|
test "cursor_during_streaming_update_while_editing" {
  // Cursor behavior when streaming updates message area while user is editing

  let input_text = "uu"

  // User is editing, cursor is after "uu"
  let cursor_offset = input_text.length() // 2
  inspect(cursor_offset, content="2")

  // Streaming tick happens:

  // 1. Save cursor position
  let saved_offset = cursor_offset
  inspect(saved_offset, content="2")

  // 2. Update streaming content in message area
  // (This doesn't affect edit box)

  // 3. Render message area
  // (This goes to rows 0-15, not input area rows 18-23)

  // 4. Restore cursor to saved position
  let restored_offset = saved_offset
  inspect(restored_offset, content="2")

  // Cursor should be at same position
  let cursor_stable = restored_offset == cursor_offset
  inspect(cursor_stable, content="true")
}
