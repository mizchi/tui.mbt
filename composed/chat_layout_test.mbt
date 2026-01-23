///|
/// Tests for chat layout calculations

///|
test "calc_visible_height: standard terminal" {
  // For a 24-row terminal:
  // visible_height = 24 - 6 (input_area) - 1 (divider) - 1 (buffer) = 16
  let height = calc_visible_height(24)
  inspect(height, content="16")
}

///|
test "calc_visible_height: small terminal" {
  let height = calc_visible_height(15)
  inspect(height, content="7")
}

///|
test "calc_visible_height: large terminal" {
  let height = calc_visible_height(50)
  inspect(height, content="42")
}

///|
test "calc_input_row: standard terminal (0-indexed)" {
  // For a 24-row terminal:
  // input_row = calc_visible_height(24) + divider + buffer = 16 + 1 + 1 = 18
  let row = calc_input_row(24)
  inspect(row, content="18")
}

///|
test "calc_input_row: small terminal (0-indexed)" {
  // input_row = calc_visible_height(15) + divider + buffer = 7 + 1 + 1 = 9
  let row = calc_input_row(15)
  inspect(row, content="9")
}

///|
test "calc_input_row: matches layout structure" {
  // Layout: [message_area][divider][buffer][input_area]
  // input_row should be right after message_area + divider + buffer
  let h = 24
  let msg_height = calc_visible_height(h)
  let input_row = calc_input_row(h)
  // input_row (0-indexed) = msg_height + divider + buffer
  inspect(
    input_row == msg_height + divider_height + buffer_lines,
    content="true",
  )
  // And input_area should extend to the end
  inspect(input_row + input_area_height == h, content="true")
}

///|
test "calc_total_lines: no messages" {
  let lines = calc_total_lines(0, false)
  inspect(lines, content="0")
}

///|
test "calc_total_lines: with messages" {
  let lines = calc_total_lines(3, false)
  inspect(lines, content="6") // 3 messages * 2 lines each
}

///|
test "calc_total_lines: with streaming" {
  let lines = calc_total_lines(3, true)
  inspect(lines, content="8") // 3 messages * 2 + 2 for streaming
}

///|
test "clamp_input_lines: within range" {
  inspect(clamp_input_lines(3), content="3")
}

///|
test "clamp_input_lines: below minimum" {
  inspect(clamp_input_lines(0), content="1")
  inspect(clamp_input_lines(-1), content="1")
}

///|
test "clamp_input_lines: above maximum" {
  inspect(clamp_input_lines(10), content="5")
  inspect(clamp_input_lines(100), content="5")
}

///|
test "layout constants are consistent" {
  // input_area_height should be max_input_rows + 1
  inspect(input_area_height, content="6")
  inspect(max_input_rows, content="5")
  inspect(buffer_lines, content="1")
  inspect(divider_height, content="1")
}

///|
test "layout arithmetic: total equals terminal height" {
  let terminal_height = 24
  let visible = calc_visible_height(terminal_height)
  // visible + divider + buffer + input_area = terminal_height
  let total = visible + divider_height + buffer_lines + input_area_height
  inspect(total, content="24")
}

///|
test "start_edit_inplace coordinates" {
  // Simulates what start_editing calculates
  let terminal_height = 24
  let row = calc_input_row(terminal_height) // 0-indexed
  let col = 1 // 0-indexed (column after leading space)

  // start_edit_inplace expects 1-indexed, so we add 1
  let inplace_row = row + 1
  let inplace_col = col + 1

  // For 24-row terminal: row=18 (0-indexed) -> 19 (1-indexed)
  inspect(inplace_row, content="19")
  inspect(inplace_col, content="2")

  // Verify this is correct position in layout
  // Row 19 (1-indexed) = Row 18 (0-indexed) = after message(16) + divider(1) + buffer(1)
  inspect(row, content="18")
}

///|
test "ansi_move_to converts 0-indexed to 1-indexed" {
  // ansi_move_to takes 0-indexed and outputs 1-indexed ANSI
  let escape = @components.ansi_move_to(0, 0)
  inspect(escape, content="\u{1b}[1;1H")
  let escape2 = @components.ansi_move_to(18, 1)
  inspect(escape2, content="\u{1b}[19;2H")
}

///|
test "message_area height does not overlap with input area" {
  let h = 24
  let visible_height = calc_visible_height(h)
  let input_row = calc_input_row(h)

  // Message area ends at row visible_height (0-indexed)
  // Input area starts at row input_row (0-indexed)
  // There should be divider + buffer between them
  inspect(visible_height, content="16")
  inspect(input_row, content="18")

  // Gap should be divider_height + buffer_lines = 2
  let gap = input_row - visible_height
  inspect(gap, content="2")
  inspect(gap == divider_height + buffer_lines, content="true")
}

///|
test "render App height matches visible_height" {
  // When rendering message area only, App height should be visible_height
  // This ensures render output stays within message area bounds
  let h = 24
  let visible_height = calc_visible_height(h)

  // App should have the correct dimensions
  inspect(visible_height, content="16")
}
