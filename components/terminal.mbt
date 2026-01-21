///|
/// Terminal helpers - ANSI escape utilities

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
