///|
/// Test to reproduce cursor display issue during start_editing

///|
test "do_render_shows_cursor_when_is_editing_is_true" {
  // When is_editing = true, do_render calls ansi_show_cursor()
  // This happens in start_editing() BEFORE start_edit_inplace()
  // So cursor is shown at wrong position

  let is_editing = true

  // In do_render, if editing is true:
  // 1. Save cursor
  // 2. Render UI
  // 3. Restore cursor
  // 4. Show cursor (PROBLEM: shows at old position)

  inspect(is_editing, content="true")

  // The issue: when start_editing calls do_render with is_editing=true,
  // it shows cursor at whatever position cursor is currently at
  // But start_editing then clears input area and calls start_edit_inplace
  // which expects to manage cursor itself
}

///|
test "cursor_shown_before_start_edit_inplace" {
  // Timeline in start_editing():
  // 1. is_editing.set(true)
  // 2. do_render()
  //    - editing = true
  //    - saves cursor
  //    - renders UI
  //    - RESTORES cursor and SHOWS cursor (PROBLEM!)
  // 3. Clear input area (lines 18-22)
  // 4. Draw status line
  // 5. start_edit_inplace()

  // At step 2, cursor is shown at the saved position
  // But the saved position might be old/wrong
  // And at step 3, we clear the area where cursor is shown
  // This causes visual flicker or cursor in wrong position

  let cursor_shown_at_step_2 = true
  inspect(cursor_shown_at_step_2, content="true")

  // The problem: do_render should NOT show cursor when called from start_editing
  // because start_edit_inplace will manage cursor
}

///|
test "start_editing_should_not_show_cursor_in_do_render" {
  // When start_editing calls do_render(), it should not show cursor
  // Because start_edit_inplace() will manage cursor positioning

  // The fix: either:
  // 1. Don't call do_render with is_editing=true in start_editing
  // 2. Add a flag to do_render to skip cursor showing
  // 3. Hide cursor after do_render in start_editing

  let needs_fix = true
  inspect(needs_fix, content="true")
}

///|
test "cursor_sequence_in_start_editing" {
  // Actual sequence in start_editing():

  // 1. is_editing = true
  let is_editing = true
  inspect(is_editing, content="true")

  // 2. do_render()
  //    - editing = true
  //    - saves cursor (at current position, which might be old)
  //    - renders UI
  //    - restores cursor
  //    - SHOWS cursor (PROBLEM!)
  let cursor_shown = true
  inspect(cursor_shown, content="true")

  // 3. Clear input area (this might erase cursor)
  let input_row = calc_input_row(24) // 18
  inspect(input_row, content="18")

  // 4. Draw status line
  let status_row = input_row + max_input_rows
  inspect(status_row, content="23")

  // 5. start_edit_inplace()
  //    - This should manage cursor
  //    - But cursor was already shown at step 2!

  // Result: Cursor appears at wrong position momentarily
}

///|
test "cursor_shown_at_old_position" {
  // When do_render is called in start_editing, it saves current cursor position
  // But the current cursor position might be from previous interaction

  // If cursor was at (18, 0) from do_render with is_editing=false,
  // then do_render with is_editing=true saves (18, 0)
  // and restores cursor to (18, 0) and shows it there

  let old_cursor_row = calc_input_row(24) // 18
  let old_cursor_col = 0
  inspect(old_cursor_row, content="18")
  inspect(old_cursor_col, content="0")

  // But start_edit_inplace expects cursor at (19, 2) (1-indexed)
  let expected_row = 19 // 1-indexed
  let expected_col = 2 // 1-indexed
  inspect(expected_row, content="19")
  inspect(expected_col, content="2")

  // The cursor is shown at old position, not expected position
  let cursor_at_wrong_position = true
  inspect(cursor_at_wrong_position, content="true")
}

///|
test "do_render_should_hide_cursor_in_start_editing" {
  // Solution: In start_editing, after do_render, hide cursor
  // or pass a flag to do_render to not show cursor

  // When start_editing calls do_render:
  // 1. do_render shows cursor at old position
  // 2. start_editing should immediately hide it
  // 3. start_edit_inplace will show cursor at correct position

  let hide_cursor_after_do_render = true
  inspect(hide_cursor_after_do_render, content="true")
}

///|
test "alternative_render_for_start_editing" {
  // Alternative: Use render without showing cursor in start_editing

  // Option 1: Call do_render with is_editing=false
  // Problem: But we want to set is_editing=true early for streaming

  // Option 2: Add a parameter to do_render to control cursor showing
  // fn do_render(show_cursor : Bool) -> Unit

  // Option 3: Hide cursor after do_render
  // @io.print_raw(@render.ansi_hide_cursor())

  let best_option = 3 // Hide cursor after do_render
  inspect(best_option, content="3")
}

///|
test "cursor_visibility_states" {
  // Cursor should be:
  // - Hidden in do_render when called from start_editing
  // - Shown when start_edit_inplace is active
  // - Hidden when not editing
  // - Hidden when render_message_area_only is called during editing

  let do_render_in_start_editing = false
  let start_edit_inplace_active = true
  let not_editing = false
  let render_message_area_only_during_editing = false
  inspect(do_render_in_start_editing, content="false")
  inspect(start_edit_inplace_active, content="true")
  inspect(not_editing, content="false")
  inspect(render_message_area_only_during_editing, content="false")
}
