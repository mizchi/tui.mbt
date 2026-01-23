///|
/// Switch - Toggle switch component

///|
/// Switch state
pub(all) enum SwitchState {
  Off
  On
  Focused
  Disabled
}

///|
/// Create a switch component with theme support
pub fn switch(
  on : Bool,
  id? : String = "",
  focused? : Bool = false,
  disabled? : Bool = false,
  theme? : Theme = Theme::default(),
  // Icons
  track_on? : String = "━━●",
  track_off? : String = "○━━",
  // Event handler
  on_click? : (() -> Unit)? = None,
) -> @core.Component {
  let track = if on { track_on } else { track_off }
  let fg = if disabled {
    theme.disabled
  } else if focused {
    theme.focus
  } else if on {
    theme.success
  } else {
    theme.muted
  }
  row(
    [text(track, fg~)],
    id~,
    padding_x=1.0,
    on_click~,
    role=Some(@core.Role::Switch),
  )
}

///|
/// Switch with label
pub fn labeled_switch(
  label : String,
  on : Bool,
  id? : String = "",
  focused? : Bool = false,
  disabled? : Bool = false,
  label_position? : LabelPosition = LabelPosition::Left,
  theme? : Theme = Theme::default(),
  gap? : Double = 1.0,
  // Event handler
  on_click? : (() -> Unit)? = None,
) -> @core.Component {
  let switch_component = switch(on, focused~, disabled~, theme~)
  let label_fg = if disabled { theme.disabled } else { theme.fg }
  let label_component = text(label, fg=label_fg)
  match label_position {
    LabelPosition::Left =>
      row(
        [label_component, hspace(gap), switch_component],
        id~,
        on_click~,
        role=Some(@core.Role::Switch),
      )
    LabelPosition::Right =>
      row(
        [switch_component, hspace(gap), label_component],
        id~,
        on_click~,
        role=Some(@core.Role::Switch),
      )
  }
}

///|
/// Label position for switch
pub(all) enum LabelPosition {
  Left
  Right
}

///|
/// Checkbox-style toggle (square)
pub fn checkbox(
  checked : Bool,
  id? : String = "",
  focused? : Bool = false,
  disabled? : Bool = false,
  theme? : Theme = Theme::default(),
  checked_icon? : String = "[✓]",
  unchecked_icon? : String = "[ ]",
  // Event handler
  on_click? : (() -> Unit)? = None,
) -> @core.Component {
  let icon = if checked { checked_icon } else { unchecked_icon }
  let fg = if disabled {
    theme.disabled
  } else if focused {
    theme.focus
  } else if checked {
    theme.success
  } else {
    theme.fg
  }
  row([text(icon, fg~)], id~, on_click~, role=Some(@core.Role::Checkbox))
}

///|
/// Checkbox with label
pub fn labeled_checkbox(
  label : String,
  checked : Bool,
  id? : String = "",
  focused? : Bool = false,
  disabled? : Bool = false,
  label_position? : LabelPosition = LabelPosition::Right,
  theme? : Theme = Theme::default(),
  gap? : Double = 1.0,
  // Event handler
  on_click? : (() -> Unit)? = None,
) -> @core.Component {
  let checkbox_component = checkbox(checked, focused~, disabled~, theme~)
  let label_fg = if disabled { theme.disabled } else { theme.fg }
  let label_component = text(label, fg=label_fg)
  match label_position {
    LabelPosition::Left =>
      row(
        [label_component, hspace(gap), checkbox_component],
        id~,
        on_click~,
        role=Some(@core.Role::Checkbox),
      )
    LabelPosition::Right =>
      row(
        [checkbox_component, hspace(gap), label_component],
        id~,
        on_click~,
        role=Some(@core.Role::Checkbox),
      )
  }
}
