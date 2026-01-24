///|
/// Tests for VirtualTerminal - headless terminal emulator

// =============================================================================
// Basic output tests
// =============================================================================

///|
test "VirtualTerminal: basic text output" {
  let vt = VirtualTerminal::new(20, 5)
  vt.write("Hello")
  assert_true(vt.contains("Hello"))
  let (x, _) = vt.get_cursor()
  assert_eq(x, 5)
}

///|
test "VirtualTerminal: newline handling" {
  let vt = VirtualTerminal::new(20, 5)
  vt.write("Line1\nLine2\nLine3")
  assert_true(vt.line_contains(0, "Line1"))
  assert_true(vt.line_contains(1, "Line2"))
  assert_true(vt.line_contains(2, "Line3"))
}

///|
test "VirtualTerminal: carriage return" {
  let vt = VirtualTerminal::new(20, 5)
  vt.write("AAAAA\rBBB")
  // CR moves cursor to start, BBB overwrites AAA
  assert_true(vt.line_contains(0, "BBBAA"))
}

///|
test "VirtualTerminal: auto-wrap at line end" {
  let vt = VirtualTerminal::new(5, 3)
  vt.write("ABCDEFGH")
  // Should wrap to next line
  assert_eq(vt.get_line_trimmed(0), "ABCDE")
  assert_eq(vt.get_line_trimmed(1), "FGH")
}

// =============================================================================
// Cursor movement tests (CSI sequences)
// =============================================================================

///|
test "VirtualTerminal: cursor position (CUP)" {
  let vt = VirtualTerminal::new(20, 10)
  // ESC[5;10H = move to row 5, col 10 (1-indexed)
  vt.write("\u001b[5;10H")
  let (x, y) = vt.get_cursor()
  assert_eq(y, 4) // 0-indexed
  assert_eq(x, 9) // 0-indexed
}

///|
test "VirtualTerminal: cursor up (CUU)" {
  let vt = VirtualTerminal::new(20, 10)
  vt.write("\u001b[5;5H") // Start at row 5, col 5
  vt.write("\u001b[2A") // Move up 2
  let (_, y) = vt.get_cursor()
  assert_eq(y, 2)
}

///|
test "VirtualTerminal: cursor down (CUD)" {
  let vt = VirtualTerminal::new(20, 10)
  vt.write("\u001b[2;1H") // Start at row 2
  vt.write("\u001b[3B") // Move down 3
  let (_, y) = vt.get_cursor()
  assert_eq(y, 4)
}

///|
test "VirtualTerminal: cursor forward (CUF)" {
  let vt = VirtualTerminal::new(20, 10)
  vt.write("AB")
  vt.write("\u001b[5C") // Move right 5
  let (x, _) = vt.get_cursor()
  assert_eq(x, 7)
}

///|
test "VirtualTerminal: cursor back (CUB)" {
  let vt = VirtualTerminal::new(20, 10)
  vt.write("ABCDEFGH")
  vt.write("\u001b[3D") // Move left 3
  let (x, _) = vt.get_cursor()
  assert_eq(x, 5)
}

///|
test "VirtualTerminal: cursor position and write" {
  let vt = VirtualTerminal::new(20, 5)
  vt.write("........")
  vt.write("\u001b[1;3H") // Move to row 1, col 3
  vt.write("XXX")
  assert_eq(vt.get_line_trimmed(0), "..XXX...")
}

// =============================================================================
// Erase tests
// =============================================================================

///|
test "VirtualTerminal: clear screen (ED)" {
  let vt = VirtualTerminal::new(10, 3)
  vt.write("Line1\nLine2\nLine3")
  vt.write("\u001b[2J") // Clear entire screen
  assert_eq(vt.get_line_trimmed(0), "")
  assert_eq(vt.get_line_trimmed(1), "")
  assert_eq(vt.get_line_trimmed(2), "")
}

///|
test "VirtualTerminal: clear line (EL)" {
  let vt = VirtualTerminal::new(10, 3)
  vt.write("AAAAAAAAAA")
  vt.write("\u001b[1;5H") // Move to col 5
  vt.write("\u001b[K") // Clear from cursor to end of line
  assert_eq(vt.get_line_trimmed(0), "AAAA")
}

///|
test "VirtualTerminal: clear line to cursor (EL 1)" {
  let vt = VirtualTerminal::new(10, 3)
  vt.write("AAAAAAAAAA")
  vt.write("\u001b[1;5H") // Move to col 5
  vt.write("\u001b[1K") // Clear from start to cursor
  // Positions 0-4 should be cleared, 5-9 remain
  let line = vt.get_line(0)
  assert_true(line.contains("AAAAA"))
}

// =============================================================================
// SGR (color/style) tests
// =============================================================================

///|
test "VirtualTerminal: SGR reset" {
  let vt = VirtualTerminal::new(20, 5)
  vt.write("\u001b[31mRed\u001b[0mNormal")
  // Check that text was written
  assert_true(vt.contains("RedNormal"))
  // Check colors
  let red_cell = vt.get_cell(0, 0)
  assert_true(red_cell.fg.r > 100) // Should be reddish
  let normal_cell = vt.get_cell(3, 0)
  assert_true(normal_cell.fg.r == 255 && normal_cell.fg.g == 255) // White-ish
}

///|
test "VirtualTerminal: SGR bold and underline" {
  let vt = VirtualTerminal::new(20, 5)
  vt.write("\u001b[1;4mStyled\u001b[0m")
  let cell = vt.get_cell(0, 0)
  assert_true(cell.bold)
  assert_true(cell.underline)
}

///|
test "VirtualTerminal: 256-color foreground" {
  let vt = VirtualTerminal::new(20, 5)
  vt.write("\u001b[38;5;196mRed256\u001b[0m")
  let cell = vt.get_cell(0, 0)
  // Color 196 is bright red in 256-color palette
  assert_true(cell.fg.r > 200)
}

///|
test "VirtualTerminal: 256-color background" {
  let vt = VirtualTerminal::new(20, 5)
  vt.write("\u001b[48;5;21mBlueBg\u001b[0m")
  let cell = vt.get_cell(0, 0)
  // Color 21 is blue
  assert_true(cell.bg.b > 100)
}

// =============================================================================
// Unicode and CJK tests
// =============================================================================

///|
test "VirtualTerminal: CJK character width" {
  let vt = VirtualTerminal::new(20, 5)
  vt.write("日本語")
  let (x, _) = vt.get_cursor()
  assert_eq(x, 6) // 3 CJK chars * 2 width each
}

///|
test "VirtualTerminal: CJK placeholder cells" {
  let vt = VirtualTerminal::new(20, 5)
  vt.write("日")
  // Cell 0 has the character
  assert_eq(vt.get_cell(0, 0).char, '日')
  // Cell 1 has placeholder
  assert_eq(vt.get_cell(1, 0).char, '\u0000')
}

///|
test "VirtualTerminal: mixed ASCII and CJK" {
  let vt = VirtualTerminal::new(20, 5)
  vt.write("A日B")
  assert_eq(vt.get_cell(0, 0).char, 'A')
  assert_eq(vt.get_cell(1, 0).char, '日')
  assert_eq(vt.get_cell(2, 0).char, '\u0000') // placeholder
  assert_eq(vt.get_cell(3, 0).char, 'B')
}

///|
test "VirtualTerminal: CJK wrap at line boundary" {
  let vt = VirtualTerminal::new(5, 3)
  vt.write("AAAA日") // 4 + 2 = 6, but width is 5
  // CJK char should wrap to next line
  assert_eq(vt.get_line_trimmed(0), "AAAA")
  assert_true(vt.get_line(1).contains("日"))
}

// =============================================================================
// Diff rendering tests
// =============================================================================

///|
test "VirtualTerminal: diff-based update" {
  let vt = VirtualTerminal::new(20, 5)

  // Initial render
  vt.write("\u001b[1;1HHello World")

  // Partial update (only change "World" to "MoonBit")
  vt.write("\u001b[1;7HMoonBit")
  assert_eq(vt.get_line_trimmed(0), "Hello MoonBit")
}

///|
test "VirtualTerminal: cursor jump and write" {
  let vt = VirtualTerminal::new(20, 5)

  // Write at different positions
  vt.write("\u001b[1;1HA")
  vt.write("\u001b[2;5HB")
  vt.write("\u001b[3;10HC")
  assert_eq(vt.get_cell(0, 0).char, 'A')
  assert_eq(vt.get_cell(4, 1).char, 'B')
  assert_eq(vt.get_cell(9, 2).char, 'C')
}

///|
test "VirtualTerminal: real diff sequence" {
  let vt = VirtualTerminal::new(20, 5)

  // Simulate buffer_diff_to_ansi output
  // First write original content
  vt.write("\u001b[1;1HLeft  Right")

  // Then apply diff (change Left to LEFT - only changed chars)
  vt.write("\u001b[1;2HEFT") // Position at 'e' and write "EFT"
  assert_eq(vt.get_line_trimmed(0), "LEFT  Right")
}

// =============================================================================
// Input simulation tests
// =============================================================================

///|
test "VirtualTerminal: input queue" {
  let vt = VirtualTerminal::new(20, 5)
  vt.inject_input("a")
  vt.inject_input("b")
  vt.inject_input("\u001b[A") // Up arrow
  assert_true(vt.has_input())
  assert_eq(vt.read_input(), Some("a"))
  assert_eq(vt.read_input(), Some("b"))
  assert_eq(vt.read_input(), Some("\u001b[A"))
  assert_eq(vt.read_input(), None)
}

// =============================================================================
// Snapshot matching tests
// =============================================================================

///|
test "VirtualTerminal: snapshot matching" {
  let vt = VirtualTerminal::new(20, 5)
  vt.write("Line1\nLine2\nLine3")
  assert_true(vt.matches("Line1\nLine2\nLine3"))
}

///|
test "VirtualTerminal: get_visible_lines" {
  let vt = VirtualTerminal::new(20, 5)
  vt.write("A\n\nB\n\nC")
  let lines = vt.get_visible_lines()
  assert_eq(lines.length(), 3)
  assert_eq(lines[0], "A")
  assert_eq(lines[1], "B")
  assert_eq(lines[2], "C")
}

// =============================================================================
// Integration with render output
// =============================================================================

///|
test "VirtualTerminal: process render buffer output" {
  let vt = VirtualTerminal::new(20, 3)

  // Simulate what buffer_to_ansi might produce
  let ansi = "\u001b[1;1H\u001b[38;5;231mHello\u001b[0m"
  vt.write(ansi)
  assert_true(vt.contains("Hello"))
  let (x, y) = vt.get_cursor()
  assert_eq(y, 0)
  assert_eq(x, 5)
}

///|
test "VirtualTerminal: full render simulation" {
  // Create a buffer using the render API
  let buf = @render.CharBuffer::new(20, 3)
  let style = @render.TextStyle::default()
  let _ = buf.write_text(0, 0, "Hello", style, 20)
  let _ = buf.write_text(0, 1, "World", style, 20)

  // Convert to ANSI
  let ansi = buf.to_ansi()

  // Process in virtual terminal
  let vt = VirtualTerminal::new(20, 3)
  vt.write(ansi)

  // Verify content
  assert_true(vt.line_contains(0, "Hello"))
  assert_true(vt.line_contains(1, "World"))
}

///|
test "VirtualTerminal: diff rendering simulation" {
  let vt = VirtualTerminal::new(20, 3)

  // Create initial state
  let prev = @render.CharBuffer::new(20, 3)
  let style = @render.TextStyle::default()
  let _ = prev.write_text(0, 0, "AAAA", style, 20)

  // Write initial content to terminal
  let initial = prev.to_ansi()
  vt.write(initial)
  assert_true(vt.line_contains(0, "AAAA"))

  // Create new state
  let current = @render.CharBuffer::new(20, 3)
  let _ = current.write_text(0, 0, "BBBB", style, 20)

  // Apply diff
  let diff = current.diff_to_ansi(prev)
  vt.write(diff)

  // Verify updated content
  assert_true(vt.line_contains(0, "BBBB"))
}
