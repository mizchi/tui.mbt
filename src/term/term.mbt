///|
/// Terminal I/O and input event re-exports.
/// Keep this module thin and focused on terminal concerns.

///|
pub using @events {
  type InputEvent,
  type KeyEvent,
  type KeyModifier,
  type SpecialKey,
  type MouseEvent,
  type MouseButton,
  type MouseEventType,
  type HitTestResult,
  parse_input,
}

///|
pub using @io {
  type InputResult,
  get_terminal_size,
  print_raw,
  start_keypress_listener,
  stop_keypress_listener,
  cleanup_stdin,
  read_key,
  enable_raw_mode,
}
