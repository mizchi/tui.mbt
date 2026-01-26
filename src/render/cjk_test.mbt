///|
test "CJK characters render correctly without spaces" {
  let buf = CharBuffer::new(20, 1)
  let style : TextStyle = {
    fg: @core.Color::white(),
    bg: @core.Color::transparent(),
    bold: false,
    underline: false,
  }

  // Write Japanese text to buffer
  let text = "日本語abc"
  let lines = buf.write_text_wrapped(0, 0, text, style, 20, 1)

  // Check lines written (should be 1)
  inspect(lines, content="1")

  // Check buffer contents
  // [0] = 日, [1] = NUL, [2] = 本, [3] = NUL, [4] = 語, [5] = NUL, [6] = a, [7] = b, [8] = c
  inspect(buf.get_cell(0, 0).char.to_int(), content="26085") // 日
  inspect(buf.get_cell(1, 0).char.to_int(), content="0") // NUL placeholder
  inspect(buf.get_cell(2, 0).char.to_int(), content="26412") // 本
  inspect(buf.get_cell(3, 0).char.to_int(), content="0") // NUL placeholder
  inspect(buf.get_cell(4, 0).char.to_int(), content="35486") // 語
  inspect(buf.get_cell(5, 0).char.to_int(), content="0") // NUL placeholder
  inspect(buf.get_cell(6, 0).char, content="a")
  inspect(buf.get_cell(7, 0).char, content="b")
  inspect(buf.get_cell(8, 0).char, content="c")

  // Generate ANSI and check it doesn't have unexpected spaces between CJK
  let ansi = buf.to_ansi()
  println("ANSI output:")
  println(ansi)
  // Check consecutive CJK without spaces in ANSI (ignoring escape codes)
  inspect(ansi.contains("日本語abc"), content="true")
}

///|
test "CJK with background fill before text (simulates render_layout)" {
  let buf = CharBuffer::new(20, 1)
  let bg = @core.Color::rgb(30, 30, 50)

  // Step 1: Fill background first (like render_layout does)
  buf.fill_bg(0, 0, 20, 1, bg)

  // Step 2: Write Japanese text (like render_layout does after fill_bg)
  let style : TextStyle = {
    fg: @core.Color::white(),
    bg: @core.Color::transparent(), // transparent, so uses existing bg
    bold: false,
    underline: false,
  }
  let text = "日本語abc"
  let _ = buf.write_text_wrapped(0, 0, text, style, 20, 1)

  // Check buffer contents - placeholders should exist
  inspect(buf.get_cell(0, 0).char.to_int(), content="26085") // 日
  inspect(buf.get_cell(1, 0).char.to_int(), content="0") // NUL placeholder
  inspect(buf.get_cell(2, 0).char.to_int(), content="26412") // 本
  inspect(buf.get_cell(3, 0).char.to_int(), content="0") // NUL placeholder

  // Generate ANSI and check
  let ansi = buf.to_ansi()
  println("ANSI with bg fill:")
  println(ansi)
  inspect(ansi.contains("日本語abc"), content="true")
}

///|
test "CJK with parent fill_bg then child fill_bg (nested layout simulation)" {
  let buf = CharBuffer::new(20, 3)
  let parent_bg = @core.Color::rgb(20, 20, 20)
  let child_bg = @core.Color::rgb(40, 40, 60)

  // Step 1: Parent fills entire area
  buf.fill_bg(0, 0, 20, 3, parent_bg)

  // Step 2: Child fills its area (row 1)
  buf.fill_bg(0, 1, 20, 1, child_bg)

  // Step 3: Write text to child area
  let style : TextStyle = {
    fg: @core.Color::white(),
    bg: @core.Color::transparent(),
    bold: false,
    underline: false,
  }
  let _ = buf.write_text_wrapped(0, 1, "日本語", style, 20, 1)

  // Step 4: Sibling fills its area (row 2) - should NOT affect row 1
  buf.fill_bg(0, 2, 20, 1, child_bg)

  // Check row 1 still has CJK placeholders preserved
  inspect(buf.get_cell(0, 1).char.to_int(), content="26085") // 日
  inspect(buf.get_cell(1, 1).char.to_int(), content="0") // NUL placeholder
  let ansi = buf.to_ansi()
  println("Nested layout ANSI:")
  println(ansi)
  inspect(ansi.contains("日本語"), content="true")
}

///|
test "CJK diff rendering: ASCII to CJK transition" {
  // Previous buffer had "abc"
  let prev = CharBuffer::new(20, 1)
  let style : TextStyle = {
    fg: @core.Color::white(),
    bg: @core.Color::transparent(),
    bold: false,
    underline: false,
  }
  let _ = prev.write_text_wrapped(0, 0, "abc", style, 20, 1)

  // Current buffer has "日本語"
  let current = CharBuffer::new(20, 1)
  let _ = current.write_text_wrapped(0, 0, "日本語", style, 20, 1)

  // Generate diff
  let diff_ansi = current.diff_to_ansi(prev)
  println("Diff ANSI (abc -> 日本語):")
  println(diff_ansi)

  // The diff should contain "日本語" without spaces
  inspect(diff_ansi.contains("日本語"), content="true")
}

///|
test "CJK diff rendering: CJK to ASCII transition" {
  // Previous buffer had "日本語"
  let prev = CharBuffer::new(20, 1)
  let style : TextStyle = {
    fg: @core.Color::white(),
    bg: @core.Color::transparent(),
    bold: false,
    underline: false,
  }
  let _ = prev.write_text_wrapped(0, 0, "日本語", style, 20, 1)

  // Current buffer has "abcdef" (need to cover all 6 columns)
  let current = CharBuffer::new(20, 1)
  let _ = current.write_text_wrapped(0, 0, "abcdef", style, 20, 1)

  // Generate diff
  let diff_ansi = current.diff_to_ansi(prev)
  println("Diff ANSI (日本語 -> abcdef):")
  println(diff_ansi)

  // The diff should contain "abcdef"
  inspect(diff_ansi.contains("abcdef"), content="true")
}
