///|
/// Input components for vnode

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
