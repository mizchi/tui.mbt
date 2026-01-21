///|
/// Test to identify the exact cursor overwriting bug
/// The issue: start_editing() clears input area AFTER do_render()
/// But render_message_area_only() saves cursor BEFORE clearing
/// So when it restores cursor, it writes to old input position

///|
test "cursor_save_before_clear_vs_restore_after_clear" {
  // Bug scenario:
  // T1: do_render() - cursor moved to input_row (18)
  // T2: render_message_area_only() saves cursor at (18, 1)
  // T3: start_editing() clears input area (lines 18-22)
  // T4: render_message_area_only() renders message area
  // T5: render_message_area_only() restores cursor to (18, 1)
  //     BUT cursor position (18, 1) is now in CLEARED area!
  // T6: Cursor is shown at (18, 1), potentially overwriting content

  let terminal_height = 24
  let input_row = calc_input_row(terminal_height) // 18

  // T1: After do_render (with is_editing=false)
  let cursor_pos = input_row
  inspect(cursor_pos, content="18")

  // T2: render_message_area_only saves cursor
  let saved_cursor = cursor_pos
  inspect(saved_cursor, content="18")

  // T3: start_editing clears input area (lines 18-22)
  let clear_start = input_row
  let clear_end = input_row + max_input_rows - 1
  inspect(clear_start, content="18")
  inspect(clear_end, content="22")

  // T4: render_message_area_only renders (lines 0-15)
  let message_area_end = calc_visible_height(terminal_height) - 1
  inspect(message_area_end, content="15")

  // T5: render_message_area_only restores cursor
  let restored_cursor = saved_cursor
  inspect(restored_cursor, content="18")

  // PROBLEM: restored_cursor (18) is in cleared area [18-22]
  let cursor_in_cleared_area = restored_cursor >= clear_start &&
    restored_cursor <= clear_end
  inspect(cursor_in_cleared_area, content="true")

  // The cursor will appear at (18, 1), but:
  // - This area was just cleared (spaces)
  // - Cursor "█" will be drawn there
  // - If streaming continues updating message area,
  //   cursor position might get overwritten or cause issues

  // The fix: cursor should be saved AFTER clearing input area,
  // or cursor should be repositioned after clearing
}

///|
test "start_editing_clears_then_render_message_area_saves_old_cursor" {
  // This test shows the problematic sequence

  let input_row = calc_input_row(24) // 18

  // start_editing sequence:
  // 1. do_render() - cursor to input_row
  let cursor_step1 = input_row
  inspect(cursor_step1, content="18")

  // 2. is_editing = true (in the fix, this happens BEFORE do_render)

  // 3. Streaming tick may occur here!
  //    render_message_area_only() saves cursor at input_row (18)
  //    With the fix, cursor is saved AFTER is_editing = true
  //    so render_message_area_only correctly handles cursor during editing

  // 4. start_editing clears input area
  let cleared_row = input_row // row 18 cleared
  inspect(cleared_row, content="18")

  // 5. start_editing draws status line
  let status_row = input_row + max_input_rows
  inspect(status_row, content="23")

  // 6. If render_message_area_only runs AFTER clearing:
  //    It saved cursor at (18, 1) but now (18, 1) is in cleared area
  //    Restoring cursor there shows "█" in wrong position

  // 7. start_editing calls start_edit_inplace at (19, 2)
  //    This should move cursor to correct position

  let inplace_row = input_row + 1 // 1-indexed
  let inplace_col = 2
  inspect(inplace_row, content="19")
  inspect(inplace_col, content="2")

  // But between steps 2-6, if streaming tick runs,
  // cursor "█" appears at (18, 1) instead of correct position
}

///|
test "timing_window_for_bug" {
  // Identify the exact timing window where bug occurs

  // Window: between is_editing.set(true) and start_edit_inplace()
  // During this window, render_message_area_only can be called
  // and it will save cursor at old position (18, 1)

  let input_row = calc_input_row(24) // 18

  // Before is_editing.set(true):
  // - do_render() moves cursor to (18, 0)  // calc_input_row with col=0

  // After is_editing.set(true):
  // - streaming tick: render_message_area_only saves cursor at current position
  // - Problem: what IS the current cursor position?

  // do_render() with is_editing=false does:
  // @io.print_raw(ansi_move_to(calc_input_row(height.val), 0))
  // This moves cursor to (input_row, 0) = (18, 0)

  // So render_message_area_only saves cursor at (18, 0)
  let saved_cursor_col = 0 // Column 0
  let saved_cursor_row = input_row // Row 18
  inspect(saved_cursor_row, content="18")
  inspect(saved_cursor_col, content="0")

  // Then start_editing clears area from row 18, column 0
  let clear_col = 0
  inspect(clear_col, content="0")

  // When cursor is restored to (18, 0), it's in the cleared area
  let restored_in_cleared = saved_cursor_row >= input_row &&
    saved_cursor_row < input_row + max_input_rows
  inspect(restored_in_cleared, content="true")

  // The cursor "█" will appear at (18, 0) - the cleared area
  // This overwrites the space that was just cleared
}

///|
test "cursor_position_difference_do_render_vs_editing" {
  // do_render() moves cursor to (input_row, 0)
  // But start_editing expects cursor to be positioned correctly

  let input_row = calc_input_row(24)

  // do_render with is_editing=false:
  let do_render_col = 0
  let do_render_row = input_row
  inspect(do_render_row, content="18")
  inspect(do_render_col, content="0")

  // start_edit_inplace expects (row+1, col+1) in 1-indexed:
  // Where row = input_row, col = 1 (not 0!)
  let expected_col = 1 // Column after leading space
  let expected_row_1indexed = input_row + 1
  let expected_col_1indexed = expected_col + 1
  inspect(expected_col_1indexed, content="2")
  inspect(expected_row_1indexed, content="19")

  // Problem: do_render moves to (18, 0) but editing expects cursor near (19, 2)
  // The difference in column (0 vs 1) might cause visual issues
}

///|
test "actual_bug_cursor_at_edge_of_input_area" {
  // The actual bug:
  // When render_message_area_only restores cursor to (input_row, 0)
  // It's at the left edge of input area
  // But start_editing clears the entire input area including that position
  // So the cursor appears in cleared area, potentially overwriting

  let input_row = calc_input_row(24)

  // Cursor saved at (input_row, 0) - left edge of input area
  let cursor_row = input_row
  let cursor_col = 0
  inspect(cursor_row, content="18")
  inspect(cursor_col, content="0")

  // Input area spans from row 18 to 23 (input_row + input_area_height - 1)
  let input_area_end = input_row + input_area_height - 1
  inspect(input_area_end, content="23")

  // Cursor is within input area
  let cursor_in_input_area = cursor_row >= input_row &&
    cursor_row <= input_area_end
  inspect(cursor_in_input_area, content="true")

  // When input area is cleared, cursor position is overwritten with spaces
  // Then cursor "█" is drawn there
  // If streaming continues, message area updates might affect this

  // The solution: cursor should be saved AFTER input area is cleared,
  // OR cursor should be moved to correct position BEFORE being saved
}
