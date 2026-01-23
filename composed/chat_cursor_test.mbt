///|
/// Cursor/layout invariants for chat layout helpers

///|
test "input area is below message area" {
  let terminal_height = 24
  let visible_height = calc_visible_height(terminal_height)
  let input_row = calc_input_row(terminal_height)
  let message_area_bottom = visible_height - 1
  let gap = input_row - message_area_bottom - 1
  inspect(visible_height, content="16")
  inspect(input_row, content="18")
  inspect(gap, content="2") // divider(1) + buffer(1)
  inspect(input_row > message_area_bottom, content="true")
}

///|
test "status line position" {
  let terminal_height = 24
  let row = calc_input_row(terminal_height)
  let content_height = max_input_rows
  let status_row = row + content_height
  inspect(row, content="18") // input content starts at row 18
  inspect(content_height, content="5") // max 5 lines for content
  inspect(status_row, content="23") // status at row 23
  let bottom_line = terminal_height - 1
  inspect(status_row, content="23")
  inspect(bottom_line, content="23")
}

///|
test "ansi_cursor_sequences" {
  let save_seq = @components.ansi_save_cursor()
  let restore_seq = @components.ansi_restore_cursor()
  let move_seq = @components.ansi_move_to(18, 1)
  inspect(save_seq, content="\u{1b}[s")
  inspect(restore_seq, content="\u{1b}[u")
  inspect(move_seq, content="\u{1b}[19;2H") // 0-indexed (18,1) -> 1-indexed (19,2)
}

///|
test "inplace_edit_coordinates" {
  let terminal_height = 24
  let input_row = calc_input_row(terminal_height)

  // start_edit_inplace expects 1-indexed coordinates
  let inplace_row = input_row + 1
  let inplace_col = 2 // column after leading space
  inspect(input_row, content="18") // 0-indexed
  inspect(inplace_row, content="19") // 1-indexed
  inspect(inplace_col, content="2")
}
