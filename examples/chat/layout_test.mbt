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
test "calc_input_row: standard terminal" {
  // For a 24-row terminal:
  // input_row = 24 - 6 + 1 = 19
  let row = calc_input_row(24)
  inspect(row, content="19")
}

///|
test "calc_input_row: small terminal" {
  let row = calc_input_row(15)
  inspect(row, content="10")
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
