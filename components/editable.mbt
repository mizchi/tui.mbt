///|
/// Editable components - Integrates display components with editing functionality

///|
/// Configuration for editable input behavior
pub(all) struct EditConfig {
  /// Field name displayed during editing
  field_name : String
  /// Called when value is confirmed
  on_change : (String) -> Unit
  /// Called before editing starts (optional, for setup like disabling mouse)
  on_edit_start : (() -> Unit)?
  /// Called after editing ends (optional, for cleanup like re-enabling mouse)
  on_edit_end : (() -> Unit)?
  /// Called when Ctrl+C is pressed (optional, for force quit)
  on_force_quit : (() -> Unit)?
}

///|
/// Start editing a field with cooked mode (IME support)
/// This exits alternate screen temporarily for proper IME input
/// confirm_on_shift_enter: if true, Shift+Enter confirms and Enter inserts newline
/// esc_cancels: if false, Esc is ignored
pub fn start_edit(
  config : EditConfig,
  current_value : String,
  on_complete : () -> Unit,
  confirm_on_shift_enter? : Bool = false,
  esc_cancels? : Bool = true,
) -> Unit {
  // Call optional setup callback
  match config.on_edit_start {
    Some(f) => f()
    None => ()
  }

  // Start cooked mode input
  @io.start_inline_input_cooked(
    config.field_name,
    current_value,
    fn(result) {
      match result {
        @io.InputResult::Confirmed(new_value) => (config.on_change)(new_value)
        @io.InputResult::Cancelled => ()
        @io.InputResult::ForceQuit => {
          // Call force quit handler if provided
          match config.on_force_quit {
            Some(f) => f()
            None => ()
          }
          // Don't call on_complete - we're quitting
          return
        }
        _ => ()
      }

      // Call optional cleanup callback
      match config.on_edit_end {
        Some(f) => f()
        None => ()
      }
      on_complete()
    },
    confirm_on_shift_enter~,
    esc_cancels~,
  )
}

///|
/// Start editing a field inplace (stays in TUI screen)
/// row/col are 1-indexed ANSI coordinates
/// width/height define the input area (supports multi-line wrapping)
/// multiline: if true, Enter can insert newline when confirm_on_shift_enter is true
/// confirm_on_shift_enter: if true, Shift+Enter confirms
/// esc_cancels: if false, Esc is ignored
/// on_lines_change: optional callback (line_count) -> new_height for dynamic resizing
/// on_completion: optional callback (text, cursor_pos) -> completion_suffix for Tab completion
pub fn start_edit_inplace(
  config : EditConfig,
  current_value : String,
  row : Int,
  col : Int,
  width : Int,
  height : Int,
  multiline : Bool,
  on_complete : () -> Unit,
  confirm_on_shift_enter? : Bool = false,
  esc_cancels? : Bool = true,
  on_lines_change? : ((Int) -> Int)? = None,
  on_completion? : ((String, Int) -> String?)? = None,
) -> Unit {
  // Call optional setup callback
  match config.on_edit_start {
    Some(f) => f()
    None => ()
  }

  // Start inplace input
  @io.start_inplace_input(
    row,
    col,
    width,
    height,
    multiline,
    current_value,
    fn(result) {
      match result {
        @io.InputResult::Confirmed(new_value) => (config.on_change)(new_value)
        @io.InputResult::Cancelled => ()
        @io.InputResult::ForceQuit => {
          // Call force quit handler if provided
          match config.on_force_quit {
            Some(f) => f()
            None => ()
          }
          // Don't call on_complete - we're quitting
          return
        }
        _ => ()
      }

      // Call optional cleanup callback
      match config.on_edit_end {
        Some(f) => f()
        None => ()
      }
      on_complete()
    },
    confirm_on_shift_enter~,
    esc_cancels~,
    on_lines_change~,
    on_completion~,
  )
}

///|
/// Start editing within bounds (HitTestResult) with border adjustment.
/// bounds.x/y are 0-indexed; row/col for ANSI are 1-indexed.

///|
/// Helper to create a standard edit config for form fields
pub fn form_edit_config(
  field_name : String,
  signal : @signals.Signal[String],
  on_edit_start? : (() -> Unit)? = None,
  on_edit_end? : (() -> Unit)? = None,
  on_force_quit? : (() -> Unit)? = None,
) -> EditConfig {
  {
    field_name,
    on_change: fn(value) { signal.set(value) },
    on_edit_start,
    on_edit_end,
    on_force_quit,
  }
}

///|
/// Context for managing multiple editable fields
pub(all) struct EditContext {
  /// Currently focused field ID
  focused_id : @signals.Signal[String]
  /// Map of field ID to edit config
  configs : Map[String, EditConfig]
  /// Called to restore TUI mode after editing
  restore_tui : () -> Unit
}

///|
/// Create a new edit context
pub fn EditContext::new(
  focused_id : @signals.Signal[String],
  restore_tui : () -> Unit,
) -> EditContext {
  { focused_id, configs: {}, restore_tui }
}

///|
/// Register a field with the context
pub fn EditContext::register(
  self : EditContext,
  id : String,
  config : EditConfig,
) -> Unit {
  self.configs[id] = config
}

///|
/// Start editing the currently focused field
pub fn EditContext::edit_focused(self : EditContext) -> Bool {
  let id = self.focused_id.get()
  match self.configs.get(id) {
    Some(config) => {
      // Get current value from signal if available
      let current_value = ""
      start_edit(config, current_value, fn() { (self.restore_tui)() })
      true
    }
    None => false
  }
}

///|
/// Start editing a specific field by ID
pub fn EditContext::edit(
  self : EditContext,
  id : String,
  current_value : String,
) -> Bool {
  match self.configs.get(id) {
    Some(config) => {
      start_edit(config, current_value, fn() { (self.restore_tui)() })
      true
    }
    None => false
  }
}
