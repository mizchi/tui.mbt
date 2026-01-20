///|
/// Input handling for TUI applications
/// Re-exports functions from events subpackage for backwards compatibility

///|
/// Parse escape sequence
pub fn parse_input(input : String) -> @events.InputEvent {
  @events.parse_input(input)
}

///|
/// Check if key matches a specific character with optional modifier
pub fn key_is_char(event : @events.KeyEvent, c : Char) -> Bool {
  @events.key_is_char(event, c)
}

///|
/// Check if key matches a special key
pub fn key_is_special(
  event : @events.KeyEvent,
  special : @events.SpecialKey,
) -> Bool {
  @events.key_is_special(event, special)
}

///|
/// Check if key is Ctrl+C
pub fn key_is_ctrl_c(event : @events.KeyEvent) -> Bool {
  @events.key_is_ctrl_c(event)
}

///|
/// Check if key is Ctrl+Q (common quit)
pub fn key_is_ctrl_q(event : @events.KeyEvent) -> Bool {
  @events.key_is_ctrl_q(event)
}
