///|
/// Tests for diff-based rendering with split pane layouts
/// Verifies that partial updates only affect changed regions

///|
/// Simple ANSI stripper for tests (local implementation to avoid circular deps)
fn strip_ansi_local(input : String) -> String {
  let result : Array[Char] = []
  let chars = input.to_array()
  let len = chars.length()
  let mut i = 0
  while i < len {
    let c = chars[i]
    if c == '\u001b' && i + 1 < len {
      let next = chars[i + 1]
      if next == '[' {
        i = i + 2
        while i < len {
          let code = chars[i].to_int()
          i = i + 1
          if code >= 0x40 && code <= 0x7E {
            break
          }
        }
      } else {
        i = i + 2
      }
    } else {
      result.push(c)
      i = i + 1
    }
  }
  String::from_array(result)
}

///|
/// Helper to count non-empty characters in a string (excluding ANSI codes)
fn count_visible_chars(s : String) -> Int {
  let plain = strip_ansi_local(s)
  let mut count = 0
  for c in plain {
    if c != ' ' && c != '\u0000' {
      count = count + 1
    }
  }
  count
}

///|
test "buffer_diff: unchanged buffer produces minimal output" {
  let buf1 = CharBuffer::new(20, 5)
  let buf2 = CharBuffer::new(20, 5)
  let style = TextStyle::default()

  // Write same content to both buffers
  let _ = buf1.write_text(0, 0, "Hello", style, 20)
  let _ = buf2.write_text(0, 0, "Hello", style, 20)
  let diff = buf1.diff_to_ansi(buf2)
  // Diff should only contain reset sequence (no content changes)
  inspect(diff, content="\u{1b}[0m")
}

///|
test "buffer_diff: single cell change produces minimal diff" {
  let prev = CharBuffer::new(20, 5)
  let current = CharBuffer::new(20, 5)
  let style = TextStyle::default()

  // Write same content initially
  let _ = prev.write_text(0, 0, "Hello", style, 20)
  let _ = current.write_text(0, 0, "Hallo", style, 20) // Change 'e' to 'a'
  let diff = current.diff_to_ansi(prev)
  let plain = strip_ansi_local(diff)

  // Should contain 'a' (the changed character)
  assert_true(plain.contains("a"))
  // Should only have 1 visible character changed
  inspect(count_visible_chars(diff), content="1")
}

///|
test "buffer_diff: left pane change only affects left side" {
  let width = 20
  let height = 5
  let prev = CharBuffer::new(width, height)
  let current = CharBuffer::new(width, height)
  let style = TextStyle::default()

  // Simulate a vertical split: left (0-9) and right (10-19)
  // Initial state: "Left" on left, "Right" on right
  let _ = prev.write_text(0, 1, "aaaa", style, 10)
  let _ = prev.write_text(10, 1, "Right", style, 10)
  let _ = current.write_text(0, 1, "LEFT", style, 10) // Change left pane completely
  let _ = current.write_text(10, 1, "Right", style, 10) // Right pane unchanged
  let diff = current.diff_to_ansi(prev)
  let plain = strip_ansi_local(diff)

  // Should contain the changed text (all 4 chars changed)
  assert_true(plain.contains("LEFT"))
  // Should NOT re-render the unchanged right pane
  assert_false(plain.contains("Right"))
}

///|
test "buffer_diff: right pane change only affects right side" {
  let width = 20
  let height = 5
  let prev = CharBuffer::new(width, height)
  let current = CharBuffer::new(width, height)
  let style = TextStyle::default()

  // Simulate a vertical split
  let _ = prev.write_text(0, 1, "Left", style, 10)
  let _ = prev.write_text(10, 1, "xxxxx", style, 10)
  let _ = current.write_text(0, 1, "Left", style, 10) // Left pane unchanged
  let _ = current.write_text(10, 1, "RIGHT", style, 10) // Change right pane completely
  let diff = current.diff_to_ansi(prev)
  let plain = strip_ansi_local(diff)

  // Should contain the changed text (all 5 chars changed)
  assert_true(plain.contains("RIGHT"))
  // Should NOT re-render the unchanged left pane
  assert_false(plain.contains("Left"))
}

///|
test "buffer_diff: multiple rows changed in one pane" {
  let width = 20
  let height = 5
  let prev = CharBuffer::new(width, height)
  let current = CharBuffer::new(width, height)
  let style = TextStyle::default()

  // Left pane content (rows 0-4, cols 0-9)
  let _ = prev.write_text(0, 0, "Line 1", style, 10)
  let _ = prev.write_text(0, 1, "Line 2", style, 10)
  let _ = prev.write_text(0, 2, "Line 3", style, 10)
  // Right pane content (rows 0-4, cols 10-19)
  let _ = prev.write_text(10, 0, "Alpha", style, 10)
  let _ = prev.write_text(10, 1, "Beta", style, 10)
  let _ = prev.write_text(10, 2, "Gamma", style, 10)

  // Update left pane only
  let _ = current.write_text(0, 0, "NEW  1", style, 10)
  let _ = current.write_text(0, 1, "NEW  2", style, 10)
  let _ = current.write_text(0, 2, "NEW  3", style, 10)
  // Right pane unchanged
  let _ = current.write_text(10, 0, "Alpha", style, 10)
  let _ = current.write_text(10, 1, "Beta", style, 10)
  let _ = current.write_text(10, 2, "Gamma", style, 10)
  let diff = current.diff_to_ansi(prev)
  let plain = strip_ansi_local(diff)

  // Should contain NEW text
  assert_true(plain.contains("NEW"))
  // Should NOT contain unchanged right pane text
  assert_false(plain.contains("Alpha"))
  assert_false(plain.contains("Beta"))
  assert_false(plain.contains("Gamma"))
}

///|
test "buffer_diff: border unchanged when content changes" {
  let width = 20
  let height = 5
  let prev = CharBuffer::new(width, height)
  let current = CharBuffer::new(width, height)
  let style = TextStyle::default()

  // Draw a border (unchanged in both)
  let border = @core.BorderChars::single()
  // Top border
  let _ = prev.write_text(0, 0, border.top_left.to_string(), style, 1)
  let _ = prev.write_text(
    1,
    0,
    border.horizontal.to_string().repeat(8),
    style,
    8,
  )
  let _ = prev.write_text(9, 0, border.top_right.to_string(), style, 1)
  // Same for current
  let _ = current.write_text(0, 0, border.top_left.to_string(), style, 1)
  let _ = current.write_text(
    1,
    0,
    border.horizontal.to_string().repeat(8),
    style,
    8,
  )
  let _ = current.write_text(9, 0, border.top_right.to_string(), style, 1)

  // Content inside (different)
  let _ = prev.write_text(1, 1, "Old text", style, 8)
  let _ = current.write_text(1, 1, "New text", style, 8)
  let diff = current.diff_to_ansi(prev)
  let plain = strip_ansi_local(diff)

  // Should contain the new content
  assert_true(plain.contains("New"))
  // Should NOT contain border characters (unchanged)
  assert_false(plain.contains(border.top_left.to_string()))
  assert_false(plain.contains(border.top_right.to_string()))
}

///|
test "buffer_diff: CJK text change in split pane" {
  let width = 24
  let height = 3
  let prev = CharBuffer::new(width, height)
  let current = CharBuffer::new(width, height)
  let style = TextStyle::default()

  // Left pane with CJK (cols 0-11)
  let _ = prev.write_text(0, 1, "日本語", style, 12) // 6 display width
  // Right pane with ASCII (cols 12-23)
  let _ = prev.write_text(12, 1, "English", style, 12)

  // Change left pane CJK
  let _ = current.write_text(0, 1, "中文字", style, 12) // Different CJK
  // Right pane unchanged
  let _ = current.write_text(12, 1, "English", style, 12)
  let diff = current.diff_to_ansi(prev)
  let plain = strip_ansi_local(diff)

  // Should contain new CJK text
  assert_true(plain.contains("中"))
  // Should NOT contain unchanged English
  assert_false(plain.contains("English"))
}

///|
test "buffer_diff: partial row update" {
  let width = 30
  let height = 3
  let prev = CharBuffer::new(width, height)
  let current = CharBuffer::new(width, height)
  let style = TextStyle::default()

  // Write a full row
  let _ = prev.write_text(0, 1, "AAAAAABBBBBBCCCCCC", style, 30)
  // Change only middle section
  let _ = current.write_text(0, 1, "AAAAAA******CCCCCC", style, 30)
  let diff = current.diff_to_ansi(prev)
  let plain = strip_ansi_local(diff)

  // Should contain only the changed characters
  assert_true(plain.contains("*"))
  // Should NOT contain unchanged parts
  assert_false(plain.contains("A"))
  assert_false(plain.contains("C"))
}

///|
test "buffer_diff: empty to content transition" {
  let width = 20
  let height = 3
  let prev = CharBuffer::new(width, height) // Empty buffer
  let current = CharBuffer::new(width, height)
  let style = TextStyle::default()

  // Add content to left side only
  let _ = current.write_text(0, 1, "Hello", style, 10)
  let diff = current.diff_to_ansi(prev)
  let plain = strip_ansi_local(diff)

  // Should contain the new text
  assert_true(plain.contains("Hello"))
  // Visible chars should be exactly 5
  inspect(count_visible_chars(diff), content="5")
}
