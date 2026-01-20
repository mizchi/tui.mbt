///|
/// Switch - Toggle switch component

///|
/// Switch state
pub(all) enum SwitchState {
  Off
  On
  Disabled
}

///|
/// Create a switch component
pub fn switch(
  on : Bool,
  id? : String = "",
  state? : SwitchState = SwitchState::Off,
  // Style
  on_fg? : @core.Color = @core.Color::green(),
  off_fg? : @core.Color = @core.Color::rgb(100, 100, 100),
  on_bg? : @core.Color = @core.Color::rgb(30, 80, 30),
  off_bg? : @core.Color = @core.Color::rgb(60, 60, 60),
  disabled_fg? : @core.Color = @core.Color::rgb(80, 80, 80),
  disabled_bg? : @core.Color = @core.Color::rgb(40, 40, 40),
  // Icons
  track_on? : String = "━━●",
  track_off? : String = "○━━",
) -> @core.Component {
  let actual_on = match state {
    SwitchState::On => true
    SwitchState::Off => false
    SwitchState::Disabled => on
  }
  let (fg, bg, track) = match state {
    SwitchState::Disabled =>
      (disabled_fg, disabled_bg, if on { track_on } else { track_off })
    _ =>
      if actual_on {
        (on_fg, on_bg, track_on)
      } else {
        (off_fg, off_bg, track_off)
      }
  }
  row([text(track, fg~)], id~, bg~, padding_x=1.0)
}

///|
/// Switch with label
pub fn labeled_switch(
  label : String,
  on : Bool,
  id? : String = "",
  state? : SwitchState = SwitchState::Off,
  label_position? : LabelPosition = LabelPosition::Left,
  // Style
  label_fg? : @core.Color = @core.Color::white(),
  on_fg? : @core.Color = @core.Color::green(),
  off_fg? : @core.Color = @core.Color::rgb(100, 100, 100),
  on_bg? : @core.Color = @core.Color::rgb(30, 80, 30),
  off_bg? : @core.Color = @core.Color::rgb(60, 60, 60),
  gap? : Double = 1.0,
) -> @core.Component {
  let switch_component = switch(on, state~, on_fg~, off_fg~, on_bg~, off_bg~)
  let label_component = text(label, fg=label_fg)
  match label_position {
    LabelPosition::Left =>
      row([label_component, hspace(gap), switch_component], id~)
    LabelPosition::Right =>
      row([switch_component, hspace(gap), label_component], id~)
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
  fg? : @core.Color = @core.Color::white(),
  checked_fg? : @core.Color = @core.Color::green(),
  checked_icon? : String = "[✓]",
  unchecked_icon? : String = "[ ]",
) -> @core.Component {
  let (icon, color) = if checked {
    (checked_icon, checked_fg)
  } else {
    (unchecked_icon, fg)
  }
  text(icon, fg=color)
}

///|
/// Checkbox with label
pub fn labeled_checkbox(
  label : String,
  checked : Bool,
  id? : String = "",
  label_position? : LabelPosition = LabelPosition::Right,
  fg? : @core.Color = @core.Color::white(),
  checked_fg? : @core.Color = @core.Color::green(),
  gap? : Double = 1.0,
) -> @core.Component {
  let checkbox_component = checkbox(checked, fg~, checked_fg~)
  let label_component = text(label, fg~)
  match label_position {
    LabelPosition::Left =>
      row([label_component, hspace(gap), checkbox_component], id~)
    LabelPosition::Right =>
      row([checkbox_component, hspace(gap), label_component], id~)
  }
}
