///|
/// Edit action for text input

///|
/// Actions that can be performed on text input
pub(all) enum EditAction {
  Insert(String)
  DeleteBackward // Backspace
  DeleteForward // Delete
  DeleteToLineStart // Ctrl+U
  DeleteToLineEnd // Ctrl+K
  MoveCursorLeft
  MoveCursorRight
  MoveCursorUp
  MoveCursorDown
  MoveToLineStart // Ctrl+A / Home
  MoveToLineEnd // Ctrl+E / End
  Confirm // Enter (single-line) or Shift+Enter (multiline)
  Cancel // Escape
  Tab
  BackTab // Shift+Tab
  ForceQuit // Ctrl+C
  NewLine // Enter (multiline mode)
  None
} derive(Debug, Eq)

///|
fn[T : Debug] show_debug(value : T, logger : &Logger) -> Unit {
  value.to_repr().output(logger)
}

///|
pub impl Show for EditAction with output(self : EditAction, logger : &Logger) -> Unit {
  show_debug(self, logger)
}

///|
/// Line info for text wrapping and rendering
pub(all) struct LineInfo {
  start_idx : Int
  chars : Array[Char]
} derive(Debug, Eq)

///|
pub impl Show for LineInfo with output(self : LineInfo, logger : &Logger) -> Unit {
  show_debug(self, logger)
}

///|
/// Display state for rendering
pub(all) struct DisplayState {
  lines : Array[LineInfo]
  cursor_line : Int
  cursor_col : Int
  scroll_offset : Int
  has_more_above : Bool
  has_more_below : Bool
  total_lines : Int
} derive(Debug)

///|
pub impl Show for DisplayState with output(
  self : DisplayState,
  logger : &Logger,
) -> Unit {
  show_debug(self, logger)
}

///|
/// Configuration for text input
pub(all) struct TextInputConfig {
  mut width : Int
  mut height : Int
  multiline : Bool
  confirm_on_shift_enter : Bool
  esc_cancels : Bool
} derive(Debug)

///|
pub impl Show for TextInputConfig with output(
  self : TextInputConfig,
  logger : &Logger,
) -> Unit {
  show_debug(self, logger)
}

///|
/// Create default config
pub fn TextInputConfig::new(
  width : Int,
  height : Int,
  multiline? : Bool = false,
  confirm_on_shift_enter? : Bool = false,
  esc_cancels? : Bool = true,
) -> TextInputConfig {
  { width, height, multiline, confirm_on_shift_enter, esc_cancels }
}
