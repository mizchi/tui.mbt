///|
test "input nav: scroll offset updates when moving cursor up" {
  let text = "line1\nline2\nline3\nline4\nline5"
  let chars = text.to_array()
  let lines = wrap_text_to_lines(chars, 10)
  let max_height = 2
  let cursor = chars.length()
  let (line_idx, _) = find_cursor_line(lines, cursor)
  let scroll0 = adjust_scroll_offset(0, line_idx, max_height, lines.length())
  inspect(scroll0 > 0, content="true")
  let cursor_up_1 = cursor_up(lines, cursor)
  let cursor_up_2 = cursor_up(lines, cursor_up_1)
  let (line_idx2, _) = find_cursor_line(lines, cursor_up_2)
  let scroll1 = adjust_scroll_offset(
    scroll0,
    line_idx2,
    max_height,
    lines.length(),
  )
  inspect(scroll1 < scroll0, content="true")
}

///|
test "input nav: cursor up at top stays" {
  let text = "a\nb\nc"
  let chars = text.to_array()
  let lines = wrap_text_to_lines(chars, 10)
  let cursor = 0
  let moved = cursor_up(lines, cursor)
  inspect(moved == cursor, content="true")
}

///|
test "input nav: cursor down at bottom stays" {
  let text = "a\nb\nc"
  let chars = text.to_array()
  let lines = wrap_text_to_lines(chars, 10)
  let cursor = chars.length()
  let moved = cursor_down(lines, cursor)
  inspect(moved == cursor, content="true")
}

///|
test "input nav: scroll offset updates when moving cursor down" {
  let text = "line1\nline2\nline3\nline4\nline5"
  let chars = text.to_array()
  let lines = wrap_text_to_lines(chars, 10)
  let max_height = 2
  let start_cursor = 0
  let (start_idx, _) = find_cursor_line(lines, start_cursor)
  let scroll0 = adjust_scroll_offset(0, start_idx, max_height, lines.length())
  inspect(scroll0 == 0, content="true")
  let cursor_down_1 = cursor_down(lines, start_cursor)
  let cursor_down_2 = cursor_down(lines, cursor_down_1)
  let cursor_down_3 = cursor_down(lines, cursor_down_2)
  let (line_idx, _) = find_cursor_line(lines, cursor_down_3)
  let scroll1 = adjust_scroll_offset(
    scroll0,
    line_idx,
    max_height,
    lines.length(),
  )
  inspect(scroll1 > scroll0, content="true")
}
