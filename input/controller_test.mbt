///|
/// Tests for TextInputController

// ===== TextInputController tests =====

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
test "narrow width wrapping and MoveToLineStart" {
  // Simulate narrow editor width
  let config = TextInputConfig::new(10, 5, multiline=true)
  let ctrl = TextInputController::new(config, "")
  // Type a long line that wraps
  let _ = ctrl.apply_action(Insert("abcdefghijklmnop"))
  // With width=10, should wrap into 2 lines: "abcdefghij" and "klmnop"
  let text = ctrl.get_text()
  assert_eq(text, "abcdefghijklmnop")
  assert_eq(ctrl.get_cursor_pos(), 16)

  // Verify display state shows wrapped lines
  let state = ctrl.get_display_state()
  assert_eq(state.lines.length(), 2)

  // MoveToLineStart should go to position 10 (start of second wrapped line)
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
    80,
    10,
    multiline=true,
    confirm_on_shift_enter=true,
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
    80,
    10,
    multiline=true,
    confirm_on_shift_enter=true,
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

///|
/// Test: Insert multiple Unicode characters at line start (single Insert action)
test "insert multiple unicode chars at line start - single action" {
  let config = TextInputConfig::new(80, 10)
  let ctrl = TextInputController::new(config, "")

  // Insert "日本語" as a single action (like paste or IME commit)
  let _ = ctrl.apply_action(Insert("日本語"))
  assert_eq(ctrl.get_text(), "日本語")
  assert_eq(ctrl.get_cursor_pos(), 3)
}

///|
/// Test: Insert multiple Unicode characters at line start (one by one, like IME in raw mode)
test "insert multiple unicode chars at line start - one by one" {
  let config = TextInputConfig::new(80, 10)
  let ctrl = TextInputController::new(config, "")

  // Insert each character separately (like read_key processes IME input)
  let _ = ctrl.apply_action(Insert("日"))
  assert_eq(ctrl.get_text(), "日")
  assert_eq(ctrl.get_cursor_pos(), 1)
  let _ = ctrl.apply_action(Insert("本"))
  assert_eq(ctrl.get_text(), "日本")
  assert_eq(ctrl.get_cursor_pos(), 2)
  let _ = ctrl.apply_action(Insert("語"))
  assert_eq(ctrl.get_text(), "日本語")
  assert_eq(ctrl.get_cursor_pos(), 3)
}

///|
/// Test: Insert Unicode at cursor position 0 in non-empty buffer
test "insert unicode at position 0 in non-empty buffer" {
  let config = TextInputConfig::new(80, 10)
  let ctrl = TextInputController::new(config, "abc")

  // Move to start
  ctrl.set_cursor_pos(0)
  assert_eq(ctrl.get_cursor_pos(), 0)

  // Insert "日" at position 0
  let _ = ctrl.apply_action(Insert("日"))
  assert_eq(ctrl.get_text(), "日abc")
  assert_eq(ctrl.get_cursor_pos(), 1)

  // Move to start again
  ctrl.set_cursor_pos(0)

  // Insert "本"
  let _ = ctrl.apply_action(Insert("本"))
  assert_eq(ctrl.get_text(), "本日abc")
  assert_eq(ctrl.get_cursor_pos(), 1)
}

///|
/// Test: Insert emoji (surrogate pair) at line start
test "insert emoji at line start" {
  let config = TextInputConfig::new(80, 10)
  let ctrl = TextInputController::new(config, "")

  // Insert emoji (4-byte UTF-8)
  let _ = ctrl.apply_action(Insert("😀"))

  // The emoji should be inserted correctly
  assert_eq(ctrl.get_text(), "😀")
  // MoonBit's to_array() returns Unicode scalar values, not UTF-16 code units
  // So "😀".to_array().length() == 1
  assert_eq(ctrl.get_cursor_pos(), 1)
}

///|
/// Test: Insert multiple emojis at line start
test "insert multiple emojis at line start" {
  let config = TextInputConfig::new(80, 10)
  let ctrl = TextInputController::new(config, "")
  let _ = ctrl.apply_action(Insert("😀"))
  assert_eq(ctrl.get_cursor_pos(), 1) // 1 emoji = 1 char in MoonBit
  let _ = ctrl.apply_action(Insert("🎉"))
  assert_eq(ctrl.get_cursor_pos(), 2)
  assert_eq(ctrl.get_text(), "😀🎉")
}

///|
/// Test: String length for CJK characters
test "string length for CJK chars" {
  // Verify MoonBit string behavior with CJK
  assert_eq("日".length(), 1)
  assert_eq("日本語".length(), 3)
  assert_eq("日".to_array().length(), 1)
  assert_eq("日本語".to_array().length(), 3)
  // Emoji (4-byte UTF-8, but single Unicode code point)
  assert_eq("😀".length(), 2) // UTF-16 surrogate pair
  assert_eq("😀".to_array().length(), 1) // Single Unicode scalar value
}

///|
/// Test: String iteration and char conversion
test "string iter for emoji" {
  let emoji = "😀"
  // Iterate over the string
  let mut count = 0
  let chars : Array[Char] = []
  for c in emoji {
    count = count + 1
    chars.push(c)
  }
  // iter() should return 1 Unicode scalar value, not 2 UTF-16 code units
  assert_eq(count, 1)
  assert_eq(chars.length(), 1)
  // The char should be the full emoji
  assert_eq(chars[0].to_string(), "😀")
}

///|
/// Test: parse_raw_key handling of emoji would work if we could import it
test "char to_string for emoji roundtrip" {
  let emoji_char = "😀".to_array()[0]
  let back_to_string = emoji_char.to_string()
  assert_eq(back_to_string, "😀")
}

///|
/// Test: Display state with empty buffer
test "display state with empty buffer" {
  let config = TextInputConfig::new(80, 10)
  let ctrl = TextInputController::new(config, "")

  // Get display state for empty buffer
  let state = ctrl.get_display_state()
  assert_eq(state.lines.length(), 1) // One empty line
  assert_eq(state.cursor_line, 0)
  assert_eq(state.cursor_col, 0)
  assert_eq(state.scroll_offset, 0)
}

///|
/// Test: Display state after inserting at position 0
test "display state after insert at position 0" {
  let config = TextInputConfig::new(80, 10)
  let ctrl = TextInputController::new(config, "")

  // Insert first character
  let _ = ctrl.apply_action(Insert("日"))
  let state = ctrl.get_display_state()
  assert_eq(state.lines.length(), 1)
  assert_eq(state.cursor_line, 0)
  assert_eq(state.cursor_col, 2) // CJK width = 2
  assert_eq(state.lines[0].chars.length(), 1)
}

///|
/// Test: Rapid sequential inserts at position 0 (simulating IME)
test "rapid sequential inserts simulating IME" {
  let config = TextInputConfig::new(80, 10)
  let ctrl = TextInputController::new(config, "")

  // Simulate IME sending characters one by one rapidly
  let chars = ["日", "本", "語"]
  for i = 0; i < chars.length(); i = i + 1 {
    let _ = ctrl.apply_action(Insert(chars[i]))
    // Verify state after each insert
    let state = ctrl.get_display_state()
    assert_eq(state.lines[0].chars.length(), i + 1)
  }

  // Final verification
  assert_eq(ctrl.get_text(), "日本語")
  assert_eq(ctrl.get_cursor_pos(), 3)
}
