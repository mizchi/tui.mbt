///|
/// Multiline input - text box with input-like states and placeholder

///|
/// Create a multiline input component that wraps text within its bounds.
pub fn multiline_input(
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
  let (actual_fg, actual_bg, border_color) = textarea_palette(
    value, fg, bg, placeholder_fg, focus_border_color, edit_border_color, disabled_fg,
    disabled_bg, state,
  )
  @core.text_box(
    display_text,
    id~,
    width~,
    height=@types.Dimension::Length(rows.to_double()),
    min_width=@types.Dimension::Length(min_width),
    min_height=@types.Dimension::Length(rows.to_double()),
    padding_x~,
    padding_y~,
    border=Some(@core.BorderChars::rounded()),
    border_color~,
    fg=actual_fg,
    bg=actual_bg,
  )
}
