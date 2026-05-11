///|
/// Character width utilities for CJK and wide character support

///|
/// Get display width of a character (1 for normal, 2 for wide/CJK)
pub fn char_display_width(c : Char) -> Int {
  @terminal_buffer.char_display_width(c)
}

///|
/// Calculate display width of a string
pub fn string_display_width(s : String) -> Int {
  @terminal_buffer.string_display_width(s)
}
