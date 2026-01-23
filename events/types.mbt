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
} derive(Show)

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
} derive(Show)

///|
/// Keyboard event
pub(all) enum KeyEvent {
  Char(Char, KeyModifier)
  Special(SpecialKey, KeyModifier)
} derive(Show)

///|
/// Mouse button
pub(all) enum MouseButton {
  Left
  Middle
  Right
  ScrollUp
  ScrollDown
  None
} derive(Show)

///|
/// Mouse event type
pub(all) enum MouseEventType {
  Press
  Release
  Move
  Drag
} derive(Show)

///|
/// Mouse event
pub(all) struct MouseEvent {
  button : MouseButton
  event_type : MouseEventType
  x : Int
  y : Int
  modifier : KeyModifier
} derive(Show)

///|
/// Input event
pub(all) enum InputEvent {
  Key(KeyEvent)
  Mouse(MouseEvent)
  Resize(Int, Int)
  Unknown(String)
} derive(Show)

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
