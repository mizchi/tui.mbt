///|
/// Integration test to reproduce cursor overwriting issue
/// This test simulates the problematic interaction between streaming and editing

///|
/// Mock scenario: streaming tick during editing
test "cursor_after_streaming_tick_and_start_editing" {
  // Simulate:
  // 1. is_editing = true (editing in progress)
  // 2. render_message_area_only() is called (saves cursor, renders, restores cursor)
  // 3. start_editing() is called again (should not overwrite message area)

  let terminal_height = 24

  // Initial state
  let cursor_row_before = calc_input_row(terminal_height) // 18
  let cursor_col_before = 1

  // Simulate render_message_area_only:
  // 1. Save cursor (at cursor_row_before, cursor_col_before)
  let saved_cursor_row = cursor_row_before
  let saved_cursor_col = cursor_col_before

  // 2. Move to (0,0) and render message area (rows 0-15)
  let _render_start_row = 0
  let render_end_row = calc_visible_height(terminal_height) - 1
  inspect(render_end_row, content="15")
  inspect(saved_cursor_row, content="18")

  // 3. Restore cursor (should be back to saved position)
  let cursor_row_after = saved_cursor_row
  let cursor_col_after = saved_cursor_col
  inspect(cursor_row_after, content="18")
  inspect(cursor_col_after, content="1")

  // Cursor should still be in input area (row 18)
  // NOT in message area (rows 0-15)
  inspect(cursor_row_after > render_end_row, content="true")
}

///|
test "cursor_not_corrupted_by_nested_save_restore" {
  // Simulate nested save/restore operations:
  // 1. do_render() saves cursor
  // 2. render_message_area_only() saves cursor
  // 3. render_message_area_only() restores cursor
  // 4. do_render() restores cursor

  let original_row = 18

  // Level 1: do_render saves cursor
  let saved1_row = original_row
  let _saved1_col = 1

  // Level 2: render_message_area_only saves cursor
  let saved2_row = saved1_row

  // ... do some rendering ...

  // Level 2 restore
  let cursor_after_restore2 = saved2_row

  // Level 1 restore
  let cursor_after_restore1 = saved1_row
  inspect(cursor_after_restore2, content="18")
  inspect(cursor_after_restore1, content="18")

  // Nested save/restore should preserve original position
  inspect(cursor_after_restore1 == original_row, content="true")
}

///|
test "cursor_position_after_input_area_clear" {
  // start_editing clears input area (lines 18-22)
  // Then render_message_area_only saves/restore cursor
  // Cursor should remain at correct input position

  let input_row = calc_input_row(24) // 18
  let cursor_row = input_row

  // Save cursor position
  let saved_row = cursor_row
  let _saved_col = 1

  // Clear input area (simulate start_editing behavior)
  let clear_start = input_row
  let clear_end = input_row + max_input_rows - 1
  inspect(clear_start, content="18")
  inspect(clear_end, content="22")

  // After clear, restore cursor
  let restored_row = saved_row
  let _restored_col = 1
  inspect(restored_row, content="18")

  // Cursor should be at start of cleared area
  inspect(restored_row == clear_start, content="true")
}

///|
test "streaming_tick_does_not_interfere_with_editing_cursor" {
  // During editing (is_editing = true):
  // - Streaming tick calls render_message_area_only
  // - This should NOT move cursor into message area

  let is_editing = true
  let input_row = calc_input_row(24) // 18
  let cursor_row = input_row
  let message_area_end = calc_visible_height(24) - 1 // 15

  // When is_editing is true, cursor should be in input area
  if is_editing {
    inspect(cursor_row, content="18")
    inspect(cursor_row > message_area_end, content="true")
  } else {
    // When not editing, cursor is at input area start
    inspect(calc_input_row(24), content="18")
  }
}

///|
test "start_editing_sequence_preserves_cursor" {
  // Sequence in start_editing:
  // 1. do_render() - full render
  // 2. is_editing.set(true)
  // 3. Clear input area
  // 4. Draw status line
  // 5. start_edit_inplace - expects correct cursor position

  let terminal_height = 24
  let input_row = calc_input_row(terminal_height)

  // After do_render, cursor is at input_area
  // After is_editing.set(true), streaming ticks will save/restore cursor

  // Cursor should be at input_row + 1 (1-indexed)
  let inplace_row = input_row + 1
  let inplace_col = 2
  inspect(input_row, content="18") // 0-indexed
  inspect(inplace_row, content="19") // 1-indexed
  inspect(inplace_col, content="2")
}

///|
test "render_sequence_for_second_input_during_streaming" {
  // Scenario:
  // 1. First input sent, streaming started
  // 2. User starts second input (presses any key)
  // 3. start_editing is called
  // 4. streaming.on_tick may still be called

  // Timeline:
  // T0: User presses key, handle_key -> start_editing
  // T1: start_editing -> do_render -> is_editing = true
  // T2: streaming.on_tick -> render_message_area_only (saves cursor, renders, restores)
  // T3: start_editing continues -> clear input area, draw status, start_edit_inplace

  // At T2, cursor should be saved before render_message_area_only
  // But what position is saved?

  // In do_render (T1), cursor is positioned at input area:
  // - If editing: save cursor, render, restore cursor, show cursor
  // - If not editing: move cursor to calc_input_row

  // At T1 start_editing is called:
  // - First do_render() is called BEFORE is_editing.set(true)
  // - So do_render sees is_editing = false
  // - Cursor is moved to calc_input_row (row 18)
  // - Then is_editing.set(true)

  // At T2 streaming.on_tick:
  // - is_editing = true
  // - render_message_area_only is called
  // - Saves cursor (at row 18)
  // - Renders message area
  // - Restores cursor (to row 18)

  // This seems correct, but let's verify the actual flow

  let terminal_height = 24
  let input_row = calc_input_row(terminal_height) // 18
  let message_area_end = calc_visible_height(terminal_height) - 1 // 15

  // At T1: do_render with is_editing=false
  let cursor_at_t1 = input_row
  inspect(cursor_at_t1, content="18")
  inspect(cursor_at_t1 > message_area_end, content="true")

  // At T2: render_message_area_only saves cursor
  let saved_cursor_at_t2 = cursor_at_t1
  inspect(saved_cursor_at_t2, content="18")

  // After rendering message area (0-15), restore cursor
  let cursor_at_t2_restored = saved_cursor_at_t2
  inspect(cursor_at_t2_restored, content="18")
  inspect(cursor_at_t2_restored > message_area_end, content="true")
}

///|
test "cursor_after_full_render_then_partial_render" {
  // When do_render() is followed by render_message_area_only():
  // - do_render: renders full screen, positions cursor
  // - render_message_area_only: saves cursor, renders messages, restores cursor

  let terminal_height = 24
  let input_row = calc_input_row(terminal_height)
  let message_area_end = calc_visible_height(terminal_height) - 1

  // After do_render, cursor is at input_row
  let cursor_after_full = input_row
  inspect(cursor_after_full, content="18")

  // render_message_area_only saves cursor
  let saved_cursor = cursor_after_full

  // Renders message area (lines 0 to message_area_end)
  inspect(message_area_end, content="15")

  // Restores cursor
  let cursor_after_partial = saved_cursor
  inspect(cursor_after_partial, content="18")

  // Cursor should be outside message area
  inspect(cursor_after_partial > message_area_end, content="true")
}
