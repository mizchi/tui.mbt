///|
/// Textarea - Multi-line text input component

///|
/// Textarea state for visual feedback
pub(all) enum TextareaState {
  Idle
  Focused
  Editing
  Disabled
}

///|
/// Create a textarea component
pub fn textarea(
  value : String,
  id? : String = "",
  rows? : Int = 3,
  placeholder? : String = "",
  state? : TextareaState = TextareaState::Idle,
  // Style
  fg? : @core.Color = @core.Color::white(),
  bg? : @core.Color = @core.Color::transparent(),
  placeholder_fg? : @core.Color = @core.Color::rgb(100, 100, 100),
  focus_border_color? : @core.Color = @core.Color::cyan(),
  edit_border_color? : @core.Color = @core.Color::green(),
  disabled_fg? : @core.Color = @core.Color::rgb(80, 80, 80),
  disabled_bg? : @core.Color = @core.Color::transparent(),
  // Size
  width? : @types.Dimension = @types.Dimension::Auto,
  min_width? : Double = 20.0,
  padding_x? : Double = 1.0,
  padding_y? : Double = 0.0,
) -> @core.Component {
  let display_text = textarea_display_text(value, placeholder, state)
  let display_lines = split_lines(display_text)
  let (actual_fg, actual_bg, border_color) = textarea_palette(
    value, fg, bg, placeholder_fg, focus_border_color, edit_border_color, disabled_fg,
    disabled_bg, state,
  )

  // Build text lines (show cursor on last line when editing)
  let text_components : Array[@core.Component] = []
  for i, line in display_lines {
    let is_last = i == display_lines.length() - 1
    let line_text = if is_last && state is TextareaState::Editing {
      line + "_"
    } else {
      line
    }
    text_components.push(text(line_text, fg=actual_fg))
  }

  // Pad with empty lines to reach minimum rows
  let remaining_rows = rows - text_components.length()
  for _ in 0..<remaining_rows {
    text_components.push(text("", fg=actual_fg))
  }

  // Build textarea with border
  column(
    text_components,
    id~,
    min_width=@types.Dimension::Length(min_width),
    width~,
    height=@types.Dimension::Length(rows.to_double()),
    padding_x~,
    padding_y~,
    justify=@types.Alignment::Start,
    align=@types.Alignment::Start,
    border=Some(@core.BorderChars::rounded()),
    border_color~,
    bg=actual_bg,
    role=Some(@core.Role::Textbox),
  )
}

// split_lines is now defined in streaming.mbt
