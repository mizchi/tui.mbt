///|
/// Button - Interactive clickable component

///|
/// Button state for visual feedback
pub(all) enum ButtonState {
  Normal
  Hover
  Pressed
  Focused
  Disabled
}

///|
/// Create a button component with theme support
///
/// Uses border color for state differentiation (not background).
/// - Normal: theme.primary border
/// - Hover: theme.primary border (brighter fg)
/// - Focused: theme.focus (yellow) border
/// - Pressed: theme.primary border (dimmed)
/// - Disabled: theme.disabled border and fg
pub fn button(
  label : String,
  id? : String = "",
  state? : ButtonState = ButtonState::Normal,
  theme? : Theme = Theme::default(),
  // Size
  min_width? : Double = 0.0,
  padding_x? : Double = 1.0,
  padding_y? : Double = 0.0,
  // Event handler
  on_click? : (() -> Unit)? = None,
) -> @core.Component {
  // Determine colors based on state and theme
  let (actual_fg, actual_border) = match state {
    ButtonState::Normal => (theme.fg, theme.primary)
    ButtonState::Hover => (theme.fg, theme.primary)
    ButtonState::Focused => (theme.focus, theme.focus)
    ButtonState::Pressed => (theme.muted, theme.primary)
    ButtonState::Disabled => (theme.disabled, theme.disabled)
  }

  // Build button with border (no background for cleaner look)
  // Note: justify/align with min_width doesn't work correctly in crater,
  // so centering is limited. Use fixed width if centering is critical.
  row(
    [text(label, fg=actual_fg)],
    id~,
    min_width=@types.Dimension::Length(min_width),
    padding_x~,
    padding_y~,
    justify=@types.Alignment::Center,
    align=@types.Alignment::Center,
    border=Some(@core.BorderChars::rounded()),
    border_color=actual_border,
    bg=@core.Color::transparent(),
    on_click~,
    role=Some(@core.Role::Button),
  )
}

///|
/// Simple text button (no border)
pub fn text_button(
  label : String,
  state? : ButtonState = ButtonState::Normal,
  theme? : Theme = Theme::default(),
  underline? : Bool = true,
) -> @core.Component {
  let actual_fg = match state {
    ButtonState::Normal => theme.primary
    ButtonState::Hover => theme.primary
    ButtonState::Focused => theme.focus
    ButtonState::Pressed => theme.muted
    ButtonState::Disabled => theme.disabled
  }
  text(label, fg=actual_fg, underline~)
}

///|
/// Icon button (single character or emoji)
pub fn icon_button(
  icon : String,
  state? : ButtonState = ButtonState::Normal,
  theme? : Theme = Theme::default(),
) -> @core.Component {
  let actual_fg = match state {
    ButtonState::Normal => theme.fg
    ButtonState::Hover => theme.primary
    ButtonState::Focused => theme.focus
    ButtonState::Pressed => theme.muted
    ButtonState::Disabled => theme.disabled
  }
  row([text(icon, fg=actual_fg)], padding_x=1.0)
}
