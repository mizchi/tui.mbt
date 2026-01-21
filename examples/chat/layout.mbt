///|
/// Layout constants and calculations for chat UI
/// Extracted for testability

///|
/// Layout configuration constants
pub let max_input_rows : Int = 5

///|
pub let input_area_height : Int = 6 // max_input_rows + 1 (status line)

///|
pub let buffer_lines : Int = 1 // Buffer line between divider and input

///|
pub let divider_height : Int = 1

///|
pub let streaming_message_height : Int = 4 // Fixed height for streaming message

///|
/// Calculate the visible height for message area
/// total_height: terminal height
/// Returns: number of visible lines for messages
pub fn calc_visible_height(total_height : Int) -> Int {
  total_height - input_area_height - divider_height - buffer_lines
}

///|
/// Calculate the row position where input content starts (0-indexed)
/// Layout: message_area | divider(1) | buffer(1) | input_area(6)
/// total_height: terminal height
/// Returns: row number for input content start (0-indexed for use with ansi_move_to)
pub fn calc_input_row(total_height : Int) -> Int {
  // input_area starts after message_area + divider + buffer
  calc_visible_height(total_height) + divider_height + buffer_lines
}

///|
/// Calculate total lines for scroll based on message count
/// message_count: number of messages
/// has_streaming: whether there's streaming content
/// Returns: total number of logical lines
pub fn calc_total_lines(message_count : Int, has_streaming : Bool) -> Int {
  let mut total = message_count * 2 // role + content per message
  if has_streaming {
    total = total + 2
  }
  total
}

///|
/// Clamp line count for input area
/// line_count: current line count
/// Returns: clamped line count between 1 and max_input_rows
pub fn clamp_input_lines(line_count : Int) -> Int {
  if line_count < 1 {
    1
  } else if line_count > max_input_rows {
    max_input_rows
  } else {
    line_count
  }
}

///|
/// ANSI escape: save cursor position
pub fn ansi_save_cursor() -> String {
  "\u001b[s"
}

///|
/// ANSI escape: restore cursor position
pub fn ansi_restore_cursor() -> String {
  "\u001b[u"
}

///|
/// ANSI escape: move cursor to row, col (0-indexed input, 1-indexed output)
pub fn ansi_move_to(row : Int, col : Int) -> String {
  // ANSI escape sequences use 1-indexed coordinates
  let ansi_row = row + 1
  let ansi_col = col + 1
  "\u001b[" + ansi_row.to_string() + ";" + ansi_col.to_string() + "H"
}
