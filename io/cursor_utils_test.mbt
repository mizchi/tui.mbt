///|
test "cursor_col_offset counts fullwidth characters" {
  let chars = "uoa日本語".to_array()
  let col = cursor_col_offset(chars, chars.length())
  inspect(col, content="9")
}

///|
test "cursor_position_wrapped uses display width" {
  let chars = "uoa日本語".to_array()
  let (line_idx, col) = cursor_position_wrapped(chars, chars.length(), 6)
  inspect(line_idx, content="1")
  inspect(col, content="4")
}

///|
test "cursor_line_bounds respects newlines" {
  let chars = "ab\n日本語cd".to_array()
  let cursor = 5 // inside second line (0-based index in array)
  let (start, end) = cursor_line_bounds(chars, cursor)
  inspect(start, content="3")
  inspect(end, content="8")
}
