///|
/// Input components for vnode

// =============================================================================
// Input Utilities
// =============================================================================

///|
/// Check if a character is printable (for IME input detection)
pub fn is_printable_char(c : Char) -> Bool {
  let code = c.to_int()
  (code >= 32 && code < 127) || code >= 128
}

///|
/// Check if a string is all printable characters (for IME input detection)
pub fn is_printable_string(s : String) -> Bool {
  for c in s {
    if not(is_printable_char(c)) {
      return false
    }
  }
  true
}

// =============================================================================
// Input Components
// =============================================================================

///|
/// Input state for visual feedback
pub(all) enum InputState {
  Idle
  Focused
  Editing
  Disabled
}

///|
/// Create an input component
pub fn input(
  value : String,
  id? : String = "",
  placeholder? : String = "",
  state? : InputState = InputState::Idle,
  // Style
  fg? : String = "white",
  bg? : String = "rgb(40,40,50)",
  placeholder_fg? : String = "rgb(100,100,100)",
  focus_border_color? : String = "cyan",
  edit_border_color? : String = "green",
  disabled_fg? : String = "rgb(80,80,80)",
  disabled_bg? : String = "rgb(30,30,35)",
  // Size
  width? : Double = 0.0,
  min_width? : Double = 20.0,
  padding_x? : Double = 1.0,
  padding_y? : Double = 0.0,
) -> TuiNode {
  // Determine display text
  let display_text = if value.length() == 0 {
    match state {
      InputState::Editing => ""
      _ => placeholder
    }
  } else {
    value
  }

  // Determine colors based on state
  let (actual_fg, actual_bg, border_color) = match state {
    InputState::Idle =>
      (
        if value.length() == 0 {
          placeholder_fg
        } else {
          fg
        },
        bg,
        "rgb(80,80,80)",
      )
    InputState::Focused =>
      (
        if value.length() == 0 {
          placeholder_fg
        } else {
          fg
        },
        bg,
        focus_border_color,
      )
    InputState::Editing => (fg, bg, edit_border_color)
    InputState::Disabled => (disabled_fg, disabled_bg, "rgb(60,60,60)")
  }

  // Add cursor indicator when editing
  let text_with_cursor = if state is InputState::Editing {
    display_text + "_"
  } else {
    display_text
  }

  // Build input field with border
  let w = if width > 0.0 { width } else { 0.0 }
  column(
    [text(text_with_cursor, fg=actual_fg)],
    id~,
    bg=actual_bg,
    border="rounded",
    border_color~,
    min_width~,
    width=w,
    padding_x~,
    padding_y~,
  )
}

///|
/// Create an input field without border (inline style)
pub fn input_plain(
  value : String,
  placeholder? : String = "",
  state? : InputState = InputState::Idle,
  fg? : String = "white",
  placeholder_fg? : String = "rgb(100,100,100)",
) -> TuiNode {
  let display_text = if value.length() == 0 {
    match state {
      InputState::Editing => ""
      _ => placeholder
    }
  } else {
    value
  }
  let actual_fg = if value.length() == 0 && not(state is InputState::Editing) {
    placeholder_fg
  } else {
    fg
  }
  let text_with_cursor = if state is InputState::Editing {
    display_text + "_"
  } else {
    display_text
  }
  text(text_with_cursor, fg=actual_fg)
}

// =============================================================================
// Edit functionality
// =============================================================================

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
          match config.on_force_quit {
            Some(f) => f()
            None => ()
          }
          return
        }
        _ => ()
      }
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
  match config.on_edit_start {
    Some(f) => f()
    None => ()
  }
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
          match config.on_force_quit {
            Some(f) => f()
            None => ()
          }
          return
        }
        _ => ()
      }
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
fn bounds_to_inplace_area(
  bounds : @events.HitTestResult,
  border : Int,
) -> (Int, Int, Int, Int) {
  let border_size = if border < 0 { 0 } else { border }
  let row = bounds.y + 1 + border_size
  let col = bounds.x + 1 + border_size
  let width = (bounds.width - border_size * 2).max(1)
  let height = (bounds.height - border_size * 2).max(1)
  (row, col, width, height)
}

///|
/// Start editing within bounds (HitTestResult) with border adjustment.
/// bounds.x/y are 0-indexed; row/col for ANSI are 1-indexed.
/// on_completion: optional callback (text, cursor_pos) -> completion_suffix for Tab completion
pub fn start_edit_inplace_in_bounds(
  config : EditConfig,
  current_value : String,
  bounds : @events.HitTestResult,
  multiline : Bool,
  on_complete : () -> Unit,
  confirm_on_shift_enter? : Bool = false,
  esc_cancels? : Bool = true,
  border? : Int = 1,
  on_lines_change? : ((Int) -> Int)? = None,
  on_completion? : ((String, Int) -> String?)? = None,
) -> Unit {
  let (row, col, width, height) = bounds_to_inplace_area(bounds, border)
  start_edit_inplace(
    config,
    current_value,
    row,
    col,
    width,
    height,
    multiline,
    on_complete,
    confirm_on_shift_enter~,
    esc_cancels~,
    on_lines_change~,
    on_completion~,
  )
}

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

// =============================================================================
// Textarea
// =============================================================================

///|
/// Create a textarea component (multi-line input)
pub fn textarea(
  value : String,
  id? : String = "",
  placeholder? : String = "",
  state? : InputState = InputState::Idle,
  rows? : Int = 3,
  // Style
  fg? : String = "white",
  bg? : String = "rgb(40,40,50)",
  placeholder_fg? : String = "rgb(100,100,100)",
  focus_border_color? : String = "cyan",
  edit_border_color? : String = "green",
  // Size
  min_width? : Double = 20.0,
  padding_x? : Double = 1.0,
  padding_y? : Double = 0.0,
) -> TuiNode {
  // Determine display text
  let display_text = if value.length() == 0 {
    match state {
      InputState::Editing => ""
      _ => placeholder
    }
  } else {
    value
  }

  // Determine colors based on state
  let (actual_fg, actual_bg, border_color) = match state {
    InputState::Idle =>
      (
        if value.length() == 0 {
          placeholder_fg
        } else {
          fg
        },
        bg,
        "rgb(80,80,80)",
      )
    InputState::Focused =>
      (
        if value.length() == 0 {
          placeholder_fg
        } else {
          fg
        },
        bg,
        focus_border_color,
      )
    InputState::Editing => (fg, bg, edit_border_color)
    InputState::Disabled => ("rgb(80,80,80)", "rgb(30,30,35)", "rgb(60,60,60)")
  }

  // Add cursor indicator when editing
  let text_with_cursor = if state is InputState::Editing {
    display_text + "_"
  } else {
    display_text
  }

  // Build textarea with border
  column(
    [text(text_with_cursor, fg=actual_fg)],
    id~,
    bg=actual_bg,
    border="rounded",
    border_color~,
    min_width~,
    min_height=rows.to_double() + 2.0, // +2 for border
    padding_x~,
    padding_y~,
  )
}
