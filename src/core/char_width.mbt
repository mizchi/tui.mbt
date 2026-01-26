///|
/// Character width utilities for CJK and wide character support

///|
/// Check if code point is wide (CJK/fullwidth)
/// Covers Unicode East Asian Width property for common cases
fn is_wide_char_code(code : Int) -> Bool {
  code >= 0x1100 &&
  (
    code <= 0x115F || // Hangul Jamo
    code == 0x2329 ||
    code == 0x232A || // Angle brackets
    (code >= 0x2E80 && code <= 0x303E) || // CJK Radicals, Kangxi, etc
    (code >= 0x3040 && code <= 0x33FF) || // Hiragana, Katakana, CJK symbols
    (code >= 0x3400 && code <= 0x4DBF) || // CJK Extension A
    (code >= 0x4E00 && code <= 0x9FFF) || // CJK Unified Ideographs
    (code >= 0xAC00 && code <= 0xD7A3) || // Hangul Syllables
    (code >= 0xF900 && code <= 0xFAFF) || // CJK Compatibility Ideographs
    (code >= 0xFE10 && code <= 0xFE1F) || // Vertical forms
    (code >= 0xFE30 && code <= 0xFE6F) || // CJK Compatibility Forms
    (code >= 0xFF00 && code <= 0xFF60) || // Fullwidth forms
    (code >= 0xFFE0 && code <= 0xFFE6) || // Fullwidth symbols
    (
      code >= 0x20000 &&
      code <= // CJK Extension B-F
      0x2FFFF
    )
  )
}

///|
/// Get display width of a character (1 for normal, 2 for wide/CJK)
pub fn char_display_width(c : Char) -> Int {
  let code = c.to_int()
  if code < 0x80 {
    1
  } else if is_wide_char_code(code) {
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
