///|
/// Character width utilities for CJK and wide character support

///|
fn is_wide_char(c : Char) -> Bool {
  let cp = c.to_int()
  (cp >= 0x4E00 && cp <= 0x9FFF) ||
  (cp >= 0x3400 && cp <= 0x4DBF) ||
  (cp >= 0x3040 && cp <= 0x309F) ||
  (cp >= 0x30A0 && cp <= 0x30FF) ||
  (cp >= 0xAC00 && cp <= 0xD7AF) ||
  (cp >= 0xFF00 && cp <= 0xFFEF) ||
  (cp >= 0x3000 && cp <= 0x303F)
}

///|
/// Get display width of a character (1 for normal, 2 for wide/CJK)
pub fn char_display_width(c : Char) -> Int {
  if is_wide_char(c) {
    2
  } else {
    1
  }
}

///|
/// Calculate display width of a string
pub fn string_display_width(s : String) -> Int {
  let mut width = 0
  for c in s {
    width = width + char_display_width(c)
  }
  width
}
