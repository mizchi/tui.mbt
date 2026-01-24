///|
/// Tests for basic rectangle operations on CharBuffer

///|
/// Helper to extract a rectangular region as a string (for debugging)
fn extract_rect(buf : CharBuffer, x : Int, y : Int, w : Int, h : Int) -> String {
  let sb = StringBuilder::new()
  for row = y; row < y + h; row = row + 1 {
    for col = x; col < x + w; col = col + 1 {
      let cell = buf.get_cell(col, row)
      if cell.char == '\u0000' {
        sb.write_char(' ') // Placeholder for wide chars
      } else {
        sb.write_char(cell.char)
      }
    }
    if row < y + h - 1 {
      sb.write_char('\n')
    }
  }
  sb.to_string()
}

///|
/// Helper to count cells with a specific character
fn count_char(buf : CharBuffer, c : Char) -> Int {
  let mut count = 0
  for y = 0; y < buf.height; y = y + 1 {
    for x = 0; x < buf.width; x = x + 1 {
      if buf.get_cell(x, y).char == c {
        count = count + 1
      }
    }
  }
  count
}

// =============================================================================
// fill_rect tests
// =============================================================================

///|
test "fill_rect: basic rectangle" {
  let buf = CharBuffer::new(10, 5)
  let cell = CharCell::from_char('X')
  buf.fill_rect(2, 1, 4, 2, cell)

  // Check filled area
  assert_eq(buf.get_cell(2, 1).char, 'X')
  assert_eq(buf.get_cell(5, 1).char, 'X')
  assert_eq(buf.get_cell(2, 2).char, 'X')
  assert_eq(buf.get_cell(5, 2).char, 'X')

  // Check outside area is empty
  assert_eq(buf.get_cell(1, 1).char, ' ')
  assert_eq(buf.get_cell(6, 1).char, ' ')
  assert_eq(buf.get_cell(2, 0).char, ' ')
  assert_eq(buf.get_cell(2, 3).char, ' ')

  // Total X count should be 4*2=8
  inspect(count_char(buf, 'X'), content="8")
}

///|
test "fill_rect: full buffer" {
  let buf = CharBuffer::new(5, 3)
  let cell = CharCell::from_char('#')
  buf.fill_rect(0, 0, 5, 3, cell)

  // All cells should be '#'
  inspect(count_char(buf, '#'), content="15")
}

///|
test "fill_rect: single cell" {
  let buf = CharBuffer::new(5, 5)
  let cell = CharCell::from_char('*')
  buf.fill_rect(2, 2, 1, 1, cell)
  inspect(count_char(buf, '*'), content="1")
  assert_eq(buf.get_cell(2, 2).char, '*')
}

///|
test "fill_rect: at edges" {
  let buf = CharBuffer::new(10, 5)
  let cell = CharCell::from_char('E')

  // Top-left corner
  buf.fill_rect(0, 0, 2, 2, cell)
  assert_eq(buf.get_cell(0, 0).char, 'E')
  assert_eq(buf.get_cell(1, 1).char, 'E')

  // Bottom-right corner
  buf.fill_rect(8, 3, 2, 2, cell)
  assert_eq(buf.get_cell(9, 4).char, 'E')
}

///|
test "fill_rect: clipping (partially out of bounds)" {
  let buf = CharBuffer::new(5, 5)
  let cell = CharCell::from_char('C')

  // Rectangle extending beyond right edge
  buf.fill_rect(3, 1, 5, 2, cell) // x=3..7, but buffer only goes to x=4

  // Only x=3,4 should be filled
  assert_eq(buf.get_cell(3, 1).char, 'C')
  assert_eq(buf.get_cell(4, 1).char, 'C')
  inspect(count_char(buf, 'C'), content="4") // 2 cols * 2 rows
}

///|
test "fill_rect: completely out of bounds" {
  let buf = CharBuffer::new(5, 5)
  let cell = CharCell::from_char('O')

  // Rectangle completely outside buffer
  buf.fill_rect(10, 10, 3, 3, cell)

  // No cells should be filled
  inspect(count_char(buf, 'O'), content="0")
}

///|
test "fill_rect: negative coordinates" {
  let buf = CharBuffer::new(5, 5)
  let cell = CharCell::from_char('N')

  // Rectangle starting at negative coordinates
  buf.fill_rect(-2, -2, 4, 4, cell) // x=-2..1, y=-2..1

  // Only x=0,1 and y=0,1 should be filled
  assert_eq(buf.get_cell(0, 0).char, 'N')
  assert_eq(buf.get_cell(1, 1).char, 'N')
  inspect(count_char(buf, 'N'), content="4")
}

///|
test "fill_rect: zero size" {
  let buf = CharBuffer::new(5, 5)
  let cell = CharCell::from_char('Z')
  buf.fill_rect(2, 2, 0, 3, cell) // Zero width
  inspect(count_char(buf, 'Z'), content="0")
  buf.fill_rect(2, 2, 3, 0, cell) // Zero height
  inspect(count_char(buf, 'Z'), content="0")
}

// =============================================================================
// fill_bg tests
// =============================================================================

///|
test "fill_bg: basic background fill" {
  let buf = CharBuffer::new(10, 5)
  let style = TextStyle::default()
  let _ = buf.write_text(0, 0, "Hello", style, 10)
  let blue = @core.Color::rgb(0, 0, 255)
  buf.fill_bg(0, 0, 5, 1, blue)

  // Background should be blue, text replaced with spaces
  assert_true(buf.get_cell(0, 0).bg == blue)
  assert_eq(buf.get_cell(0, 0).char, ' ')
}

///|
test "fill_bg: preserves wide char placeholder but replaces main char" {
  let buf = CharBuffer::new(10, 3)
  let style = TextStyle::default()
  let _ = buf.write_text(0, 1, "日本", style, 10) // 2 CJK chars = 4 display width
  let red = @core.Color::rgb(255, 0, 0)
  buf.fill_bg(0, 1, 4, 1, red)

  // fill_bg replaces regular characters with spaces (for overlay effect)
  // but preserves NUL placeholders to avoid breaking wide char rendering
  assert_eq(buf.get_cell(0, 1).char, ' ') // CJK char replaced with space
  assert_eq(buf.get_cell(1, 1).char, '\u0000') // Placeholder preserved
  assert_eq(buf.get_cell(2, 1).char, ' ') // CJK char replaced with space
  assert_eq(buf.get_cell(3, 1).char, '\u0000') // Placeholder preserved

  // Background should be red
  assert_true(buf.get_cell(0, 1).bg == red)
  assert_true(buf.get_cell(1, 1).bg == red)
}

///|
test "fill_bg: overlay covers underlying content" {
  let buf = CharBuffer::new(20, 5)
  let style = TextStyle::default()

  // Write background text
  let _ = buf.write_text(0, 0, "Background text here", style, 20)

  // Overlay with background fill
  let gray = @core.Color::rgb(128, 128, 128)
  buf.fill_bg(5, 0, 10, 1, gray)

  // Original text outside overlay
  assert_eq(buf.get_cell(0, 0).char, 'B')
  assert_eq(buf.get_cell(4, 0).char, 'g')

  // Overlay area should be spaces with gray background
  assert_eq(buf.get_cell(5, 0).char, ' ')
  assert_true(buf.get_cell(5, 0).bg == gray)
}

// =============================================================================
// write_text tests
// =============================================================================

///|
test "write_text: basic text" {
  let buf = CharBuffer::new(20, 3)
  let style = TextStyle::default()
  let written = buf.write_text(0, 0, "Hello", style, 20)
  inspect(written, content="5")
  assert_eq(buf.get_cell(0, 0).char, 'H')
  assert_eq(buf.get_cell(4, 0).char, 'o')
}

///|
test "write_text: truncation at max_width" {
  let buf = CharBuffer::new(20, 3)
  let style = TextStyle::default()
  let written = buf.write_text(0, 0, "Hello World", style, 5)
  inspect(written, content="5")
  assert_eq(buf.get_cell(4, 0).char, 'o')
  assert_eq(buf.get_cell(5, 0).char, ' ') // Not written
}

///|
test "write_text: with offset" {
  let buf = CharBuffer::new(20, 3)
  let style = TextStyle::default()
  let _ = buf.write_text(5, 1, "Test", style, 10)
  assert_eq(buf.get_cell(5, 1).char, 'T')
  assert_eq(buf.get_cell(8, 1).char, 't')
  assert_eq(buf.get_cell(4, 1).char, ' ') // Before text
}

///|
test "write_text: CJK characters" {
  let buf = CharBuffer::new(20, 3)
  let style = TextStyle::default()
  let written = buf.write_text(0, 0, "日本語", style, 20)
  inspect(written, content="6") // 3 chars * 2 width each
  assert_eq(buf.get_cell(0, 0).char, '日')
  assert_eq(buf.get_cell(1, 0).char, '\u0000') // Placeholder
  assert_eq(buf.get_cell(2, 0).char, '本')
}

///|
test "write_text: mixed ASCII and CJK" {
  let buf = CharBuffer::new(20, 3)
  let style = TextStyle::default()
  let written = buf.write_text(0, 0, "A日B", style, 20)
  inspect(written, content="4") // A=1 + 日=2 + B=1
  assert_eq(buf.get_cell(0, 0).char, 'A')
  assert_eq(buf.get_cell(1, 0).char, '日')
  assert_eq(buf.get_cell(2, 0).char, '\u0000')
  assert_eq(buf.get_cell(3, 0).char, 'B')
}

///|
test "write_text: CJK truncation at boundary" {
  let buf = CharBuffer::new(20, 3)
  let style = TextStyle::default()
  // max_width=3, but CJK char needs 2 columns
  let written = buf.write_text(0, 0, "A日B", style, 3)
  inspect(written, content="3") // A=1 + 日=2, B doesn't fit
  assert_eq(buf.get_cell(0, 0).char, 'A')
  assert_eq(buf.get_cell(1, 0).char, '日')
  assert_eq(buf.get_cell(3, 0).char, ' ') // B not written
}

///|
test "write_text: stops at newline" {
  let buf = CharBuffer::new(20, 3)
  let style = TextStyle::default()
  let written = buf.write_text(0, 0, "Line1\nLine2", style, 20)
  inspect(written, content="5") // Only "Line1"
  assert_eq(buf.get_cell(4, 0).char, '1')
  assert_eq(buf.get_cell(5, 0).char, ' ') // After newline stop
}

///|
test "write_text: with styles" {
  let buf = CharBuffer::new(20, 3)
  let red = @core.Color::rgb(255, 0, 0)
  let blue = @core.Color::rgb(0, 0, 255)
  let style : TextStyle = { fg: red, bg: blue, bold: true, underline: true }
  let _ = buf.write_text(0, 0, "Styled", style, 20)
  let cell = buf.get_cell(0, 0)
  assert_true(cell.fg == red)
  assert_true(cell.bg == blue)
  assert_true(cell.bold)
  assert_true(cell.underline)
}

///|
test "write_text: transparent bg preserves existing" {
  let buf = CharBuffer::new(20, 3)

  // First fill with a background color
  let green = @core.Color::rgb(0, 255, 0)
  buf.fill_bg(0, 0, 10, 1, green)

  // Write text with transparent background
  let style = TextStyle::default() // transparent bg
  let _ = buf.write_text(0, 0, "Text", style, 10)

  // Background should still be green
  assert_true(buf.get_cell(0, 0).bg == green)
  assert_eq(buf.get_cell(0, 0).char, 'T')
}

// =============================================================================
// write_text_wrapped tests
// =============================================================================

///|
test "write_text_wrapped: basic wrapping" {
  let buf = CharBuffer::new(10, 5)
  let style = TextStyle::default()
  let lines = buf.write_text_wrapped(0, 0, "Hello World Test", style, 5, 5)
  inspect(lines, content="4") // "Hello", " Worl", "d Tes", "t"

  // First line
  assert_eq(extract_rect(buf, 0, 0, 5, 1), "Hello")
  // Second line (wrapped)
  assert_eq(extract_rect(buf, 0, 1, 5, 1), " Worl")
}

///|
test "write_text_wrapped: explicit newlines" {
  let buf = CharBuffer::new(20, 5)
  let style = TextStyle::default()
  let lines = buf.write_text_wrapped(0, 0, "Line1\nLine2\nLine3", style, 10, 5)
  inspect(lines, content="3")
  assert_eq(buf.get_cell(0, 0).char, 'L')
  assert_eq(buf.get_cell(0, 1).char, 'L')
  assert_eq(buf.get_cell(0, 2).char, 'L')
}

///|
test "write_text_wrapped: height limit" {
  let buf = CharBuffer::new(10, 3)
  let style = TextStyle::default()
  let lines = buf.write_text_wrapped(0, 0, "AAAA BBBB CCCC DDDD", style, 4, 2)

  // Returns cur_y - y + 1, which counts lines touched (including partial)
  inspect(lines, content="3")
  // But only first 2 lines should have content
  assert_eq(buf.get_cell(0, 0).char, 'A')
  assert_eq(buf.get_cell(0, 1).char, ' ') // Space after wrap
}

///|
test "write_text_wrapped: CJK wrapping" {
  let buf = CharBuffer::new(10, 5)
  let style = TextStyle::default()
  let lines = buf.write_text_wrapped(0, 0, "日本語テスト", style, 4, 5)
  inspect(lines, content="3") // "日本" (4), "語テ" (4), "スト" (4)
  assert_eq(buf.get_cell(0, 0).char, '日')
  assert_eq(buf.get_cell(0, 1).char, '語')
}

// =============================================================================
// set_cell/get_cell tests
// =============================================================================

///|
test "get_cell: out of bounds returns default" {
  let buf = CharBuffer::new(5, 5)
  let cell = buf.get_cell(-1, 0)
  assert_eq(cell.char, ' ')
  let cell2 = buf.get_cell(10, 10)
  assert_eq(cell2.char, ' ')
}

///|
test "set_cell: out of bounds is ignored" {
  let buf = CharBuffer::new(5, 5)
  let cell = CharCell::from_char('X')
  buf.set_cell(-1, 0, cell) // Should be ignored
  buf.set_cell(10, 10, cell) // Should be ignored

  // Buffer should be unchanged
  inspect(count_char(buf, 'X'), content="0")
}

// =============================================================================
// clone/clear tests
// =============================================================================

///|
test "clone: creates independent copy" {
  let buf = CharBuffer::new(5, 5)
  let _ = buf.write_text(0, 0, "Test", TextStyle::default(), 5)
  let cloned = buf.clone()

  // Modify original
  let _ = buf.write_text(0, 0, "XXXX", TextStyle::default(), 5)

  // Clone should be unchanged
  assert_eq(cloned.get_cell(0, 0).char, 'T')
  assert_eq(buf.get_cell(0, 0).char, 'X')
}

///|
test "clear: resets all cells" {
  let buf = CharBuffer::new(10, 5)
  let cell = CharCell::from_char('X')
  buf.fill_rect(0, 0, 10, 5, cell)
  inspect(count_char(buf, 'X'), content="50")
  buf.clear()
  inspect(count_char(buf, 'X'), content="0")
  inspect(count_char(buf, ' '), content="50")
}

// =============================================================================
// Overlapping rectangle tests
// =============================================================================

///|
test "overlapping: later fill overwrites earlier" {
  let buf = CharBuffer::new(10, 5)
  buf.fill_rect(0, 0, 5, 3, CharCell::from_char('A'))
  buf.fill_rect(3, 1, 5, 3, CharCell::from_char('B'))

  // Overlap region (3,1)-(4,2) should be 'B'
  assert_eq(buf.get_cell(3, 1).char, 'B')
  assert_eq(buf.get_cell(4, 2).char, 'B')

  // Non-overlap of first rect
  assert_eq(buf.get_cell(0, 0).char, 'A')
  assert_eq(buf.get_cell(2, 2).char, 'A')

  // Non-overlap of second rect
  assert_eq(buf.get_cell(7, 3).char, 'B')
}

///|
test "overlapping: text over filled rect" {
  let buf = CharBuffer::new(10, 3)
  buf.fill_rect(0, 0, 10, 3, CharCell::from_char('.'))
  let _ = buf.write_text(2, 1, "TEXT", TextStyle::default(), 10)

  // Text should overwrite dots
  assert_eq(buf.get_cell(2, 1).char, 'T')
  assert_eq(buf.get_cell(5, 1).char, 'T')

  // Dots around text
  assert_eq(buf.get_cell(0, 1).char, '.')
  assert_eq(buf.get_cell(6, 1).char, '.')
}

///|
test "overlapping: multiple layers" {
  let buf = CharBuffer::new(10, 5)

  // Layer 1: Full background
  buf.fill_rect(0, 0, 10, 5, CharCell::from_char('1'))

  // Layer 2: Smaller rect
  buf.fill_rect(2, 1, 6, 3, CharCell::from_char('2'))

  // Layer 3: Even smaller
  buf.fill_rect(4, 2, 2, 1, CharCell::from_char('3'))
  assert_eq(buf.get_cell(0, 0).char, '1') // Outside all inner rects
  assert_eq(buf.get_cell(2, 1).char, '2') // In layer 2
  assert_eq(buf.get_cell(4, 2).char, '3') // In layer 3
}
