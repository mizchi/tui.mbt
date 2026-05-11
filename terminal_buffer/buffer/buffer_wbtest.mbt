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

///|
test "clip_rect clips negative origins and rejects empty intersections" {
  match clip_rect(10, 5, -2, 1, 5, 2) {
    Some(r) => {
      inspect(r.x, content="0")
      inspect(r.y, content="1")
      inspect(r.w, content="3")
      inspect(r.h, content="2")
    }
    None => fail("expected clipped rect")
  }
  match clip_rect(10, 5, 8, 3, 5, 5) {
    Some(r) => {
      inspect(r.x, content="8")
      inspect(r.y, content="3")
      inspect(r.w, content="2")
      inspect(r.h, content="2")
    }
    None => fail("expected clipped rect")
  }
  inspect(clip_rect(10, 5, 12, 0, 2, 2) is None, content="true")
  inspect(clip_rect(10, 5, 0, 0, 0, 2) is None, content="true")
}

///|
test "plan_write_text returns cells and wide placeholders without colors" {
  let plan = plan_write_text(2, 1, "A中B", 8)
  inspect(plan.columns, content="4")
  inspect(plan.lines, content="1")
  inspect(plan.cells.length(), content="4")
  inspect(plan.cells[0].x, content="2")
  inspect(plan.cells[0].y, content="1")
  inspect(plan.cells[0].char, content="A")
  inspect(plan.cells[1].x, content="3")
  inspect(plan.cells[1].y, content="1")
  inspect(plan.cells[1].char, content="中")
  inspect(plan.cells[2].char.to_int(), content="0")
  inspect(plan.cells[3].x, content="5")
  inspect(plan.cells[3].y, content="1")
  inspect(plan.cells[3].char, content="B")
}

///|
test "plan_write_text_pre handles tabs newlines and clipping" {
  let plan = plan_write_text_pre(0, 0, "A\tB\nC", 12, 3)
  inspect(plan.lines, content="2")
  inspect(plan.cells.length(), content="3")
  inspect(plan.cells[0].x, content="0")
  inspect(plan.cells[0].y, content="0")
  inspect(plan.cells[0].char, content="A")
  inspect(plan.cells[1].x, content="8")
  inspect(plan.cells[1].y, content="0")
  inspect(plan.cells[1].char, content="B")
  inspect(plan.cells[2].x, content="0")
  inspect(plan.cells[2].y, content="1")
  inspect(plan.cells[2].char, content="C")
}

///|
test "plan_write_text_wrapped wraps by display width" {
  let plan = plan_write_text_wrapped(0, 0, "AB中C", 4, 3)
  inspect(plan.lines, content="2")
  inspect(plan.cells[0].x, content="0")
  inspect(plan.cells[0].y, content="0")
  inspect(plan.cells[0].char, content="A")
  inspect(plan.cells[1].x, content="1")
  inspect(plan.cells[1].y, content="0")
  inspect(plan.cells[1].char, content="B")
  inspect(plan.cells[2].x, content="2")
  inspect(plan.cells[2].y, content="0")
  inspect(plan.cells[2].char, content="中")
  inspect(plan.cells[3].char.to_int(), content="0")
  inspect(plan.cells[4].x, content="0")
  inspect(plan.cells[4].y, content="1")
  inspect(plan.cells[4].char, content="C")
}

///|
test "BoxChars constructors provide reusable border sets" {
  let single = BoxChars::single()
  inspect(single.top_left, content="┌")
  inspect(single.horizontal, content="─")
  inspect(single.vertical, content="│")
  let ascii = BoxChars::ascii()
  inspect(ascii.top_left, content="+")
  inspect(ascii.horizontal, content="-")
  inspect(ascii.vertical, content="|")
}

///|
test "plan_box returns corners and edges" {
  let cells = plan_box(1, 2, 4, 3, BoxChars::single())
  inspect(cells.length(), content="10")
  inspect(cells[0].x, content="1")
  inspect(cells[0].y, content="2")
  inspect(cells[0].char, content="┌")
  inspect(cells[1].x, content="4")
  inspect(cells[1].y, content="2")
  inspect(cells[1].char, content="┐")
  inspect(cells[4].x, content="2")
  inspect(cells[4].y, content="2")
  inspect(cells[4].char, content="─")
  inspect(cells[8].x, content="1")
  inspect(cells[8].y, content="3")
  inspect(cells[8].char, content="│")
}

///|
test "plan_box rejects boxes too small for an outline" {
  inspect(plan_box(0, 0, 1, 3, BoxChars::single()).length(), content="0")
  inspect(plan_box(0, 0, 3, 1, BoxChars::single()).length(), content="0")
}

///|
test "plan_hline and plan_vline return simple cell plans" {
  let h = plan_hline(2, 3, 3, '-')
  inspect(h.length(), content="3")
  inspect(h[0].x, content="2")
  inspect(h[2].x, content="4")
  inspect(h[1].char, content="-")
  let v = plan_vline(4, 1, 3, '|')
  inspect(v.length(), content="3")
  inspect(v[0].y, content="1")
  inspect(v[2].y, content="3")
  inspect(v[1].char, content="|")
}

///|
test "plan_scrollbar emits track cells followed by thumb cells" {
  let cells = plan_scrollbar(9, 1, 6, 4, 20, 6, '│', '█')
  inspect(cells.length(), content="7")
  inspect(cells[0].x, content="9")
  inspect(cells[0].y, content="1")
  inspect(cells[0].char, content="│")
  inspect(cells[0].thumb, content="false")
  inspect(cells[6].x, content="9")
  inspect(cells[6].y, content="2")
  inspect(cells[6].char, content="█")
  inspect(cells[6].thumb, content="true")
}

///|
test "plan_scrollbar skips non-scrollable content" {
  inspect(plan_scrollbar(0, 0, 6, 0, 6, 6, '│', '█').length(), content="0")
  inspect(plan_scrollbar(0, 0, 2, 0, 20, 6, '│', '█').length(), content="0")
}
