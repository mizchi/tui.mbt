///|
test "char and string display width include CJK ranges" {
  inspect(char_display_width('A'), content="1")
  inspect(char_display_width('あ'), content="2")
  inspect(char_display_width('中'), content="2")
  inspect(char_display_width('Ａ'), content="2")
  inspect(string_display_width("Aあ中"), content="5")
}

///|
test "write_text stores wide character placeholders" {
  let buf = CharBuffer::new(6, 2)
  let written = buf.write_text(0, 0, "A中B", TextStyle::default(), 6)
  inspect(written, content="4")
  inspect(buf.get_row_text(0), content="A中B")
  inspect(buf.get_cell(1, 0).char, content="中")
  inspect(buf.get_cell(2, 0).char.to_int(), content="0")
}

///|
test "fill background preserve keeps existing text" {
  let buf = CharBuffer::new(4, 1)
  ignore(buf.write_text(0, 0, "AB", TextStyle::default(), 4))
  let bg = Color::rgb(10, 20, 30)
  buf.fill_bg_preserve(0, 0, 4, 1, bg)
  inspect(buf.get_row_text(0), content="AB")
  inspect(buf.get_cell(0, 0).bg == bg, content="true")
  inspect(buf.get_cell(1, 0).fg == Color::white(), content="true")
}

///|
test "fill background cover replaces visible cells and preserves placeholders" {
  let buf = CharBuffer::new(4, 1)
  ignore(buf.write_text(0, 0, "中A", TextStyle::default(), 4))
  let bg = Color::rgb(7, 8, 9)
  buf.fill_bg_cover(0, 0, 4, 1, bg)
  inspect(buf.get_cell(0, 0).char, content=" ")
  inspect(buf.get_cell(1, 0).char.to_int(), content="0")
  inspect(buf.get_cell(2, 0).char, content=" ")
  inspect(buf.get_cell(0, 0).bg == bg, content="true")
}

///|
test "write_text_pre handles newlines and tabs" {
  let buf = CharBuffer::new(12, 3)
  let lines = buf.write_text_pre(0, 0, "A\tB\nC", TextStyle::default(), 12, 3)
  inspect(lines, content="2")
  inspect(buf.get_cell(0, 0).char, content="A")
  inspect(buf.get_cell(8, 0).char, content="B")
  inspect(buf.get_cell(0, 1).char, content="C")
}

///|
test "write_text_wrapped wraps by display width" {
  let buf = CharBuffer::new(4, 3)
  let lines = buf.write_text_wrapped(0, 0, "AB中C", TextStyle::default(), 4, 3)
  inspect(lines, content="2")
  inspect(buf.get_row_text(0), content="AB中")
  inspect(buf.get_row_text(1), content="C")
}
