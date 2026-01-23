///|
/// LabeledBlock - A generic block component with icon, label header and content

///|
/// Create a labeled block with icon, label, and content
/// icon: single character icon (e.g., "◆", "✦", "◇")
/// label: text label (e.g., "You", "Assistant")
/// content: the main content text
/// label_color: color for icon and label
/// content_color: color for content text
/// width: component width
/// height: optional fixed height
/// indent: content indentation (default: "   ")
pub fn labeled_block(
  icon : String,
  label : String,
  content : String,
  label_color? : @core.Color = @core.Color::white(),
  content_color? : @core.Color = @core.Color::rgb(220, 220, 220),
  bold_label? : Bool = true,
  width? : Int = 80,
  height? : Int = 0,
  indent? : String = "   ",
) -> @core.Component {
  let items : Array[@core.Component] = [
    text(icon + " " + label, fg=label_color, bold=bold_label),
    text(indent + content, fg=content_color),
  ]
  if height > 0 {
    column(
      items,
      gap=0.0,
      width=@types.Dimension::Length(width.to_double()),
      height=@types.Dimension::Length(height.to_double()),
    )
  } else {
    column(items, gap=0.0, width=@types.Dimension::Length(width.to_double()))
  }
}

///|
/// Preset colors for common use cases
pub fn labeled_block_user_color() -> @core.Color {
  @core.Color::cyan()
}

///|
pub fn labeled_block_assistant_color() -> @core.Color {
  @core.Color::rgb(255, 150, 100)
}

///|
pub fn labeled_block_pending_color() -> @core.Color {
  @core.Color::rgb(100, 100, 100)
}

///|
pub fn labeled_block_success_color() -> @core.Color {
  @core.Color::green()
}

///|
pub fn labeled_block_error_color() -> @core.Color {
  @core.Color::red()
}
