///|
/// StreamingText - A component for displaying text that is being streamed

///|
/// Create a streaming text display with cursor indicator
/// content: current streamed content
/// is_streaming: whether streaming is active (shows cursor)
/// cursor_char: character to show as cursor (default: "▌")
/// fg: text color
/// width: component width
/// height: optional fixed height
pub fn streaming_text(
  content : String,
  is_streaming? : Bool = true,
  cursor_char? : String = "▌",
  fg? : @core.Color = @core.Color::rgb(220, 220, 220),
  width? : Int = 80,
  height? : Int = 0,
) -> @core.Component {
  let display = if is_streaming { content + cursor_char } else { content }
  if height > 0 {
    @core.text_box(
      display,
      fg~,
      width=@types.Dimension::Length(width.to_double()),
      height=@types.Dimension::Length(height.to_double()),
    )
  } else {
    text(display, fg~)
  }
}

///|
/// Create a labeled streaming text block (combines labeled_block with streaming_text)
/// icon: single character icon
/// label: text label
/// content: current streamed content
/// is_streaming: whether streaming is active
/// label_color: color for icon and label
/// content_color: color for content text
/// width: component width
/// height: optional fixed height for the entire block
/// indent: content indentation
/// cursor_char: character to show as cursor
pub fn streaming_block(
  icon : String,
  label : String,
  content : String,
  is_streaming? : Bool = true,
  label_color? : @core.Color = @core.Color::rgb(255, 150, 100),
  content_color? : @core.Color = @core.Color::rgb(220, 220, 220),
  bold_label? : Bool = true,
  width? : Int = 80,
  height? : Int = 0,
  indent? : String = "   ",
  cursor_char? : String = "▌",
) -> @core.Component {
  let display = if is_streaming { content + cursor_char } else { content }
  let label_component = text(
    icon + " " + label,
    fg=label_color,
    bold=bold_label,
  )
  // When height is specified, constrain content to fit within remaining space
  // Label takes 1 row, so content gets (height - 1) rows
  let content_component = if height > 1 {
    @core.text_box(
      indent + display,
      fg=content_color,
      width=@types.Dimension::Length(width.to_double()),
      height=@types.Dimension::Length((height - 1).to_double()),
    )
  } else {
    text(indent + display, fg=content_color)
  }
  let items : Array[@core.Component] = [label_component, content_component]
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
