///|
/// ANSI key sequence constants for simulating keyboard input in tests
/// These match the sequences parsed by @events.parse_input

///|
// Special characters
pub fn key_esc() -> String {
  "\u001b"
}

///|
pub fn key_enter() -> String {
  "\r"
}

///|
pub fn key_tab() -> String {
  "\t"
}

///|
pub fn key_backspace() -> String {
  "\u007f"
}

///|
// Arrow keys (CSI sequences)
pub fn key_up() -> String {
  "\u001b[A"
}

///|
pub fn key_down() -> String {
  "\u001b[B"
}

///|
pub fn key_right() -> String {
  "\u001b[C"
}

///|
pub fn key_left() -> String {
  "\u001b[D"
}

///|
// Navigation keys
pub fn key_home() -> String {
  "\u001b[H"
}

///|
pub fn key_end() -> String {
  "\u001b[F"
}

///|
pub fn key_page_up() -> String {
  "\u001b[5~"
}

///|
pub fn key_page_down() -> String {
  "\u001b[6~"
}

///|
pub fn key_insert() -> String {
  "\u001b[2~"
}

///|
pub fn key_delete() -> String {
  "\u001b[3~"
}

///|
// Shift+Tab (BackTab)
pub fn key_backtab() -> String {
  "\u001b[Z"
}

///|
// Function keys (SS3 for F1-F4, CSI for F5-F12)
pub fn key_f1() -> String {
  "\u001bOP"
}

///|
pub fn key_f2() -> String {
  "\u001bOQ"
}

///|
pub fn key_f3() -> String {
  "\u001bOR"
}

///|
pub fn key_f4() -> String {
  "\u001bOS"
}

///|
pub fn key_f5() -> String {
  "\u001b[15~"
}

///|
pub fn key_f6() -> String {
  "\u001b[17~"
}

///|
pub fn key_f7() -> String {
  "\u001b[18~"
}

///|
pub fn key_f8() -> String {
  "\u001b[19~"
}

///|
pub fn key_f9() -> String {
  "\u001b[20~"
}

///|
pub fn key_f10() -> String {
  "\u001b[21~"
}

///|
pub fn key_f11() -> String {
  "\u001b[23~"
}

///|
pub fn key_f12() -> String {
  "\u001b[24~"
}

///|
/// Generate Ctrl+key sequence
/// Ctrl+A = 0x01, Ctrl+B = 0x02, ..., Ctrl+Z = 0x1A
pub fn ctrl(c : Char) -> String {
  let code = c.to_int()
  let ctrl_code = if code >= 97 && code <= 122 {
    // lowercase a-z
    code - 96
  } else if code >= 65 && code <= 90 {
    // uppercase A-Z
    code - 64
  } else {
    return c.to_string()
  }
  ctrl_code.unsafe_to_char().to_string()
}

///|
/// Generate Alt+key sequence (ESC + key)
pub fn alt(c : Char) -> String {
  key_esc() + c.to_string()
}

///|
/// Generate SGR mouse click at position
/// button: 0=left, 1=middle, 2=right
pub fn mouse_click(x : Int, y : Int, button? : Int = 0) -> String {
  "\u001b[<" +
  button.to_string() +
  ";" +
  x.to_string() +
  ";" +
  y.to_string() +
  "M"
}

///|
/// Generate SGR mouse release at position
pub fn mouse_release(x : Int, y : Int, button? : Int = 0) -> String {
  "\u001b[<" +
  button.to_string() +
  ";" +
  x.to_string() +
  ";" +
  y.to_string() +
  "m"
}

///|
/// Generate scroll up event at position
pub fn scroll_up(x : Int, y : Int) -> String {
  "\u001b[<64;" + x.to_string() + ";" + y.to_string() + "M"
}

///|
/// Generate scroll down event at position
pub fn scroll_down(x : Int, y : Int) -> String {
  "\u001b[<65;" + x.to_string() + ";" + y.to_string() + "M"
}
