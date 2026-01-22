///|
/// Shared helpers for textarea-like inputs

///|
fn textarea_display_text(
  value : String,
  placeholder : String,
  state : TextareaState,
) -> String {
  if value.length() == 0 {
    match state {
      TextareaState::Editing => ""
      _ => placeholder
    }
  } else {
    value
  }
}

///|
fn textarea_palette(
  value : String,
  fg : @core.Color,
  bg : @core.Color,
  placeholder_fg : @core.Color,
  focus_border_color : @core.Color,
  edit_border_color : @core.Color,
  disabled_fg : @core.Color,
  disabled_bg : @core.Color,
  state : TextareaState,
) -> (@core.Color, @core.Color, @core.Color) {
  match state {
    TextareaState::Idle =>
      (
        if value.length() == 0 {
          placeholder_fg
        } else {
          fg
        },
        bg,
        @core.Color::rgb(80, 80, 80),
      )
    TextareaState::Focused =>
      (
        if value.length() == 0 {
          placeholder_fg
        } else {
          fg
        },
        bg,
        focus_border_color,
      )
    TextareaState::Editing => (fg, bg, edit_border_color)
    TextareaState::Disabled =>
      (disabled_fg, disabled_bg, @core.Color::rgb(60, 60, 60))
  }
}
