///|
/// Tests for TextInputController

///|
test "new controller with initial text" {
  let config = TextInputConfig::new(80, 10)
  let ctrl = TextInputController::new(config, "hello")
  assert_eq(ctrl.get_text(), "hello")
  assert_eq(ctrl.get_cursor_pos(), 5)
}

///|
test "insert text" {
  let config = TextInputConfig::new(80, 10)
  let ctrl = TextInputController::new(config, "")
  let _ = ctrl.apply_action(Insert("hello"))
  assert_eq(ctrl.get_text(), "hello")
  assert_eq(ctrl.get_cursor_pos(), 5)
}

///|
test "insert at cursor position" {
  let config = TextInputConfig::new(80, 10)
  let ctrl = TextInputController::new(config, "helo")
  ctrl.set_cursor_pos(3)
  let _ = ctrl.apply_action(Insert("l"))
  assert_eq(ctrl.get_text(), "hello")
  assert_eq(ctrl.get_cursor_pos(), 4)
}

///|
test "delete backward" {
  let config = TextInputConfig::new(80, 10)
  let ctrl = TextInputController::new(config, "hello")
  let _ = ctrl.apply_action(DeleteBackward)
  assert_eq(ctrl.get_text(), "hell")
  assert_eq(ctrl.get_cursor_pos(), 4)
}

///|
test "delete backward at start does nothing" {
  let config = TextInputConfig::new(80, 10)
  let ctrl = TextInputController::new(config, "hello")
  ctrl.set_cursor_pos(0)
  let _ = ctrl.apply_action(DeleteBackward)
  assert_eq(ctrl.get_text(), "hello")
  assert_eq(ctrl.get_cursor_pos(), 0)
}

///|
test "delete forward" {
  let config = TextInputConfig::new(80, 10)
  let ctrl = TextInputController::new(config, "hello")
  ctrl.set_cursor_pos(0)
  let _ = ctrl.apply_action(DeleteForward)
  assert_eq(ctrl.get_text(), "ello")
  assert_eq(ctrl.get_cursor_pos(), 0)
}

///|
test "delete forward at end does nothing" {
  let config = TextInputConfig::new(80, 10)
  let ctrl = TextInputController::new(config, "hello")
  let _ = ctrl.apply_action(DeleteForward)
  assert_eq(ctrl.get_text(), "hello")
  assert_eq(ctrl.get_cursor_pos(), 5)
}

///|
test "move cursor left" {
  let config = TextInputConfig::new(80, 10)
  let ctrl = TextInputController::new(config, "hello")
  let _ = ctrl.apply_action(MoveCursorLeft)
  assert_eq(ctrl.get_cursor_pos(), 4)
}

///|
test "move cursor left at start does nothing" {
  let config = TextInputConfig::new(80, 10)
  let ctrl = TextInputController::new(config, "hello")
  ctrl.set_cursor_pos(0)
  let _ = ctrl.apply_action(MoveCursorLeft)
  assert_eq(ctrl.get_cursor_pos(), 0)
}

///|
test "move cursor right" {
  let config = TextInputConfig::new(80, 10)
  let ctrl = TextInputController::new(config, "hello")
  ctrl.set_cursor_pos(0)
  let _ = ctrl.apply_action(MoveCursorRight)
  assert_eq(ctrl.get_cursor_pos(), 1)
}

///|
test "move cursor right at end does nothing" {
  let config = TextInputConfig::new(80, 10)
  let ctrl = TextInputController::new(config, "hello")
  let _ = ctrl.apply_action(MoveCursorRight)
  assert_eq(ctrl.get_cursor_pos(), 5)
}

///|
test "move to line start" {
  let config = TextInputConfig::new(80, 10)
  let ctrl = TextInputController::new(config, "hello world")
  let _ = ctrl.apply_action(MoveToLineStart)
  assert_eq(ctrl.get_cursor_pos(), 0)
}

///|
test "move to line end" {
  let config = TextInputConfig::new(80, 10)
  let ctrl = TextInputController::new(config, "hello world")
  ctrl.set_cursor_pos(0)
  let _ = ctrl.apply_action(MoveToLineEnd)
  assert_eq(ctrl.get_cursor_pos(), 11)
}

///|
test "delete to line start" {
  let config = TextInputConfig::new(80, 10)
  let ctrl = TextInputController::new(config, "hello world")
  ctrl.set_cursor_pos(6)
  let _ = ctrl.apply_action(DeleteToLineStart)
  assert_eq(ctrl.get_text(), "world")
  assert_eq(ctrl.get_cursor_pos(), 0)
}

///|
test "delete to line end" {
  let config = TextInputConfig::new(80, 10)
  let ctrl = TextInputController::new(config, "hello world")
  ctrl.set_cursor_pos(5)
  let _ = ctrl.apply_action(DeleteToLineEnd)
  assert_eq(ctrl.get_text(), "hello")
  assert_eq(ctrl.get_cursor_pos(), 5)
}

///|
test "newline in multiline mode" {
  let config = TextInputConfig::new(80, 10, multiline=true)
  let ctrl = TextInputController::new(config, "hello")
  let _ = ctrl.apply_action(NewLine)
  assert_eq(ctrl.get_text(), "hello\n")
  assert_eq(ctrl.get_cursor_pos(), 6)
}

///|
test "set text resets cursor if beyond length" {
  let config = TextInputConfig::new(80, 10)
  let ctrl = TextInputController::new(config, "hello world")
  ctrl.set_text("hi")
  assert_eq(ctrl.get_text(), "hi")
  assert_eq(ctrl.get_cursor_pos(), 2)
}

///|
test "get display state" {
  let config = TextInputConfig::new(80, 5)
  let ctrl = TextInputController::new(config, "line1\nline2\nline3")
  let state = ctrl.get_display_state()
  assert_eq(state.total_lines, 3)
  assert_eq(state.cursor_line, 2)
  assert_false(state.has_more_above)
  assert_false(state.has_more_below)
}

///|
test "scroll offset adjustment" {
  let config = TextInputConfig::new(80, 2)
  let ctrl = TextInputController::new(
    config, "line1\nline2\nline3\nline4\nline5",
  )
  let state = ctrl.get_display_state()
  // Cursor at end, should scroll down
  assert_eq(state.cursor_line, 4)
  assert_eq(state.scroll_offset, 3)
  assert_true(state.has_more_above)
  assert_false(state.has_more_below)
}

///|
test "cursor up and down with multiline" {
  let config = TextInputConfig::new(80, 10, multiline=true)
  let ctrl = TextInputController::new(config, "abc\ndefgh\nij")
  // Cursor at end of last line (position 12)
  assert_eq(ctrl.get_cursor_pos(), 12)
  // Move up
  let _ = ctrl.apply_action(MoveCursorUp)
  // Should be at "defgh" line, trying to keep column
  assert_eq(ctrl.get_cursor_pos(), 6) // position 4 + 2 = 6
}

///|
test "confirm action returns false" {
  let config = TextInputConfig::new(80, 10)
  let ctrl = TextInputController::new(config, "hello")
  let handled = ctrl.apply_action(Confirm)
  assert_false(handled)
}

///|
test "cancel action returns false" {
  let config = TextInputConfig::new(80, 10)
  let ctrl = TextInputController::new(config, "hello")
  let handled = ctrl.apply_action(Cancel)
  assert_false(handled)
}

///|
test "tab action returns false" {
  let config = TextInputConfig::new(80, 10)
  let ctrl = TextInputController::new(config, "hello")
  let handled = ctrl.apply_action(Tab)
  assert_false(handled)
}

///|
test "move to line start with multiline" {
  let config = TextInputConfig::new(80, 10, multiline=true)
  let ctrl = TextInputController::new(config, "line1\nline2\nline3")
  // Cursor at end (position 17)
  assert_eq(ctrl.get_cursor_pos(), 17)
  // Move to line start should go to start of "line3" (position 12)
  let _ = ctrl.apply_action(MoveToLineStart)
  assert_eq(ctrl.get_cursor_pos(), 12)
}

///|
test "move to line end with multiline" {
  let config = TextInputConfig::new(80, 10, multiline=true)
  let ctrl = TextInputController::new(config, "line1\nline2\nline3")
  // Set cursor to start of "line2" (position 6)
  ctrl.set_cursor_pos(6)
  // Move to line end should go to end of "line2" (position 11, before \n)
  let _ = ctrl.apply_action(MoveToLineEnd)
  assert_eq(ctrl.get_cursor_pos(), 11)
}

///|
test "move to line start from middle of line" {
  let config = TextInputConfig::new(80, 10, multiline=true)
  let ctrl = TextInputController::new(config, "abc\ndefgh\nij")
  // Set cursor to middle of "defgh" (position 6)
  ctrl.set_cursor_pos(6)
  // Move to line start should go to start of "defgh" (position 4)
  let _ = ctrl.apply_action(MoveToLineStart)
  assert_eq(ctrl.get_cursor_pos(), 4)
}

///|
test "move to line start after inserting newline" {
  let config = TextInputConfig::new(80, 10, multiline=true)
  let ctrl = TextInputController::new(config, "")
  // Simulate typing: "abc" + Enter + "def"
  let _ = ctrl.apply_action(Insert("abc"))
  let _ = ctrl.apply_action(NewLine)
  let _ = ctrl.apply_action(Insert("def"))
  // Buffer should be "abc\ndef", cursor at position 7
  assert_eq(ctrl.get_text(), "abc\ndef")
  assert_eq(ctrl.get_cursor_pos(), 7)
  // Move to line start should go to start of "def" (position 4)
  let _ = ctrl.apply_action(MoveToLineStart)
  assert_eq(ctrl.get_cursor_pos(), 4)
}

///|
test "move to line end after inserting newline" {
  let config = TextInputConfig::new(80, 10, multiline=true)
  let ctrl = TextInputController::new(config, "")
  // Simulate typing: "abc" + Enter + "def"
  let _ = ctrl.apply_action(Insert("abc"))
  let _ = ctrl.apply_action(NewLine)
  let _ = ctrl.apply_action(Insert("def"))
  // Set cursor to start of "def" (position 4)
  ctrl.set_cursor_pos(4)
  // Move to line end should go to end of "def" (position 7)
  let _ = ctrl.apply_action(MoveToLineEnd)
  assert_eq(ctrl.get_cursor_pos(), 7)
}

///|
test "buffer contains newline character" {
  let config = TextInputConfig::new(80, 10, multiline=true)
  let ctrl = TextInputController::new(config, "")
  let _ = ctrl.apply_action(Insert("line1"))
  let _ = ctrl.apply_action(NewLine)
  let _ = ctrl.apply_action(Insert("line2"))
  // Check buffer contents
  let text = ctrl.get_text()
  assert_eq(text.length(), 11)
  // Check that newline character is at position 5
  let chars : Array[Char] = text.iter().collect()
  assert_eq(chars[5], '\n')
}

///|
test "move to line start - cursor at end of second line" {
  let config = TextInputConfig::new(80, 10, multiline=true)
  let ctrl = TextInputController::new(config, "")
  // Type: "hello" + Enter + "world"
  let _ = ctrl.apply_action(Insert("hello"))
  assert_eq(ctrl.get_cursor_pos(), 5)
  let _ = ctrl.apply_action(NewLine)
  assert_eq(ctrl.get_cursor_pos(), 6)
  assert_eq(ctrl.get_text(), "hello\n")
  let _ = ctrl.apply_action(Insert("world"))
  assert_eq(ctrl.get_cursor_pos(), 11)
  assert_eq(ctrl.get_text(), "hello\nworld")
  // Ctrl+A should move to start of "world" (position 6)
  let _ = ctrl.apply_action(MoveToLineStart)
  assert_eq(ctrl.get_cursor_pos(), 6)
}

///|
test "move to line start - cursor in middle of second line" {
  let config = TextInputConfig::new(80, 10, multiline=true)
  let ctrl = TextInputController::new(config, "")
  // Type: "hello" + Enter + "world"
  let _ = ctrl.apply_action(Insert("hello"))
  let _ = ctrl.apply_action(NewLine)
  let _ = ctrl.apply_action(Insert("world"))
  // Move cursor to middle of "world" (position 8, between 'o' and 'r')
  ctrl.set_cursor_pos(8)
  // Ctrl+A should move to start of "world" (position 6)
  let _ = ctrl.apply_action(MoveToLineStart)
  assert_eq(ctrl.get_cursor_pos(), 6)
}

///|
test "move to line start - cursor at start of line already" {
  let config = TextInputConfig::new(80, 10, multiline=true)
  let ctrl = TextInputController::new(config, "")
  // Type: "hello" + Enter + "world"
  let _ = ctrl.apply_action(Insert("hello"))
  let _ = ctrl.apply_action(NewLine)
  let _ = ctrl.apply_action(Insert("world"))
  // Move cursor to start of "world" (position 6)
  ctrl.set_cursor_pos(6)
  // Ctrl+A should stay at position 6
  let _ = ctrl.apply_action(MoveToLineStart)
  assert_eq(ctrl.get_cursor_pos(), 6)
}

///|
test "wrap_text_to_lines with narrow width" {
  // Simulate narrow editor width
  let config = TextInputConfig::new(10, 5, multiline=true)
  let ctrl = TextInputController::new(config, "")
  // Type a long line that wraps
  let _ = ctrl.apply_action(Insert("abcdefghijklmnop"))
  // With width=10, should wrap into 2 lines: "abcdefghij" and "klmnop"
  let text = ctrl.get_text()
  assert_eq(text, "abcdefghijklmnop")
  assert_eq(ctrl.get_cursor_pos(), 16)

  // Check wrap_text_to_lines
  let chars : Array[Char] = text.iter().collect()
  let lines = wrap_text_to_lines(chars, 10)
  assert_eq(lines.length(), 2)
  assert_eq(lines[0].start_idx, 0)
  assert_eq(lines[1].start_idx, 10)

  // Cursor at position 16 (end of second line)
  let (line_idx, _) = find_cursor_line(lines, 16)
  assert_eq(line_idx, 1)

  // MoveToLineStart should go to position 10 (start of second line)
  let _ = ctrl.apply_action(MoveToLineStart)
  assert_eq(ctrl.get_cursor_pos(), 10)
}

///|
test "move to line start with narrow width - middle of wrapped line" {
  let config = TextInputConfig::new(10, 5, multiline=true)
  let ctrl = TextInputController::new(config, "abcdefghijklmnop")
  // Cursor at position 12 (middle of second wrapped line)
  ctrl.set_cursor_pos(12)
  // MoveToLineStart should go to position 10
  let _ = ctrl.apply_action(MoveToLineStart)
  assert_eq(ctrl.get_cursor_pos(), 10)
}

///|
/// Test: Simulate Mac Enter key behavior
/// Problem: User presses Enter on Mac expecting newline, but gets Confirm instead
test "interpret_key - Enter with default config returns Confirm not NewLine" {
  // Default multiline config: confirm_on_shift_enter = false
  // This means Enter = Confirm, Shift+Enter = NewLine
  let config = TextInputConfig::new(80, 10, multiline=true)

  // Simulate Enter key (no shift) - this is what Mac Enter sends
  let enter_event = @events.KeyEvent::Special(
    @events.SpecialKey::Enter,
    @events.KeyModifier::None,
  )
  let action = interpret_key(enter_event, config)

  // With default config, Enter should return Confirm (NOT NewLine!)
  // This is why user's Enter doesn't insert newline
  assert_eq(action, Confirm)
}

///|
/// Test: With confirm_on_shift_enter=true, Enter inserts newline
test "interpret_key - Enter with confirm_on_shift_enter=true returns NewLine" {
  // Config where Enter inserts newline, Shift+Enter confirms
  let config = TextInputConfig::new(
    80, 10, multiline=true, confirm_on_shift_enter=true,
  )

  // Simulate Enter key (no shift)
  let enter_event = @events.KeyEvent::Special(
    @events.SpecialKey::Enter,
    @events.KeyModifier::None,
  )
  let action = interpret_key(enter_event, config)

  // With confirm_on_shift_enter=true, Enter should return NewLine
  assert_eq(action, NewLine)
}

///|
/// Test: User scenario - types text, presses Enter (Mac), expects newline
/// This test demonstrates the current broken behavior
test "user scenario - Enter on Mac does NOT insert newline with default config" {
  let config = TextInputConfig::new(80, 10, multiline=true)
  let ctrl = TextInputController::new(config, "")

  // User types "hello"
  let _ = ctrl.apply_action(Insert("hello"))
  assert_eq(ctrl.get_text(), "hello")

  // User presses Enter on Mac - interpret as Enter key event
  let enter_event = @events.KeyEvent::Special(
    @events.SpecialKey::Enter,
    @events.KeyModifier::None,
  )
  let action = interpret_key(enter_event, config)

  // With default config, this returns Confirm, not NewLine!
  // So the newline is NOT inserted, editing ends
  assert_eq(action, Confirm)

  // The buffer has NO newline
  assert_eq(ctrl.get_text(), "hello")
  assert_false(ctrl.get_text().contains("\n"))

  // Therefore, Ctrl+A goes to position 0 (start of buffer)
  let _ = ctrl.apply_action(MoveToLineStart)
  assert_eq(ctrl.get_cursor_pos(), 0)
}

///|
/// Test: User scenario - with correct config, Enter inserts newline
test "user scenario - Enter inserts newline with confirm_on_shift_enter=true" {
  let config = TextInputConfig::new(
    80, 10, multiline=true, confirm_on_shift_enter=true,
  )
  let ctrl = TextInputController::new(config, "")

  // User types "hello"
  let _ = ctrl.apply_action(Insert("hello"))

  // User presses Enter on Mac
  let enter_event = @events.KeyEvent::Special(
    @events.SpecialKey::Enter,
    @events.KeyModifier::None,
  )
  let action = interpret_key(enter_event, config)

  // With confirm_on_shift_enter=true, Enter returns NewLine
  assert_eq(action, NewLine)

  // Apply the action
  let _ = ctrl.apply_action(action)
  assert_eq(ctrl.get_text(), "hello\n")
  assert_true(ctrl.get_text().contains("\n"))

  // User types "world"
  let _ = ctrl.apply_action(Insert("world"))
  assert_eq(ctrl.get_text(), "hello\nworld")

  // Now Ctrl+A goes to line start (position 6), not buffer start
  let _ = ctrl.apply_action(MoveToLineStart)
  assert_eq(ctrl.get_cursor_pos(), 6)
}
