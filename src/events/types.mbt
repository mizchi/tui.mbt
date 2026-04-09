///|
/// Event types for TUI applications

///|
/// Key modifiers
pub(all) enum KeyModifier {
  None
  Shift
  Ctrl
  Alt
  CtrlShift
  CtrlAlt
  ShiftAlt
  CtrlShiftAlt
} derive(Debug)

///|
fn[T : Debug] show_debug(value : T, logger : &Logger) -> Unit {
  value.to_repr().output(logger)
}

///|
pub impl Show for KeyModifier with output(self : KeyModifier, logger : &Logger) -> Unit {
  show_debug(self, logger)
}

///|
/// Special keys
pub(all) enum SpecialKey {
  Up
  Down
  Left
  Right
  Home
  End
  PageUp
  PageDown
  Insert
  Delete
  Tab
  BackTab
  Backspace
  Enter
  Escape
  F(Int)
} derive(Debug)

///|
pub impl Show for SpecialKey with output(self : SpecialKey, logger : &Logger) -> Unit {
  show_debug(self, logger)
}

///|
/// Keyboard event
pub(all) enum KeyEvent {
  Char(Char, KeyModifier)
  Special(SpecialKey, KeyModifier)
} derive(Debug)

///|
pub impl Show for KeyEvent with output(self : KeyEvent, logger : &Logger) -> Unit {
  show_debug(self, logger)
}

///|
/// Mouse button
pub(all) enum MouseButton {
  Left
  Middle
  Right
  ScrollUp
  ScrollDown
  None
} derive(Debug)

///|
pub impl Show for MouseButton with output(self : MouseButton, logger : &Logger) -> Unit {
  show_debug(self, logger)
}

///|
/// Mouse event type
pub(all) enum MouseEventType {
  Press
  Release
  Move
  Drag
} derive(Debug)

///|
pub impl Show for MouseEventType with output(
  self : MouseEventType,
  logger : &Logger,
) -> Unit {
  show_debug(self, logger)
}

///|
/// Mouse event
pub(all) struct MouseEvent {
  button : MouseButton
  event_type : MouseEventType
  x : Int
  y : Int
  modifier : KeyModifier
} derive(Debug)

///|
pub impl Show for MouseEvent with output(self : MouseEvent, logger : &Logger) -> Unit {
  show_debug(self, logger)
}

///|
/// Input event
pub(all) enum InputEvent {
  Key(KeyEvent)
  Mouse(MouseEvent)
  Resize(Int, Int)
  Unknown(String)
} derive(Debug)

///|
pub impl Show for InputEvent with output(self : InputEvent, logger : &Logger) -> Unit {
  show_debug(self, logger)
}

///|
/// Hit test result
pub(all) struct HitTestResult {
  id : String
  x : Int
  y : Int
  width : Int
  height : Int
  role : @core.Role?
}

///|
/// Focus state for the application
pub(all) enum FocusState {
  None
  Focused(String) // Component ID
}

///|
/// Input mode for the application
pub(all) enum InputMode {
  Normal // Raw mode, full keyboard control
  Editing // Non-raw mode, IME enabled
}
