///|
/// Utility components - Text, Spacer, Divider, etc.

///|
/// Text component
pub fn text(
  content : String,
  fg? : @core.Color = @core.Color::white(),
  bg? : @core.Color = @core.Color::transparent(),
  bold? : Bool = false,
  underline? : Bool = false,
) -> @core.Component {
  @core.styled_text(content, fg~, bg~, bold~, underline~)
}

///|
/// Bold text
pub fn bold(content : String) -> @core.Component {
  @core.styled_text(content, bold=true)
}

///|
/// Colored text
pub fn colored(content : String, fg : @core.Color) -> @core.Component {
  @core.styled_text(content, fg~)
}

///|
/// Flexible spacer
pub fn spacer(flex_grow? : Double = 1.0) -> @core.Component {
  @core.spacer(flex_grow~)
}

///|
/// Fixed-width horizontal spacer
pub fn hspace(width : Double) -> @core.Component {
  @core.box([], width=@types.Dimension::Length(width))
}

///|
/// Fixed-height vertical spacer
pub fn vspace(height : Double) -> @core.Component {
  @core.box([], height=@types.Dimension::Length(height))
}

///|
/// Horizontal divider line (1 row height, fills width)
pub fn hdivider(
  char? : Char = '─',
  fg? : @core.Color = @core.Color::white(),
  width? : Int = 40,
) -> @core.Component {
  text(char.to_string().repeat(width), fg~)
}

///|
/// Vertical divider line (1 column width, fills height)
pub fn vdivider(
  char? : Char = '│',
  fg? : @core.Color = @core.Color::white(),
) -> @core.Component {
  // Use a box with flex_grow to fill vertical space, render char in each row
  @core.box(
    [@core.styled_text(char.to_string(), fg~)],
    flex_grow=1.0,
    width=@types.Dimension::Length(1.0),
  )
}

///|
/// Box with border
pub fn bordered(
  children : Array[@core.Component],
  style? : @core.BorderChars = @core.BorderChars::single(),
  color? : @core.Color = @core.Color::white(),
) -> @core.Component {
  @core.box(children, border=Some(style), border_color=color)
}

///|
/// Box with padding
pub fn padded(
  children : Array[@core.Component],
  padding? : Double = 1.0,
) -> @core.Component {
  @core.box(children, padding~)
}

///|
/// Center content within available space
/// Uses flex_grow=1.0 to fill parent container
pub fn center(children : Array[@core.Component]) -> @core.Component {
  @core.box(
    children,
    justify_content=@types.Alignment::Center,
    align_items=@types.Alignment::Center,
    flex_grow=1.0,
  )
}

///|
/// Fill available space
pub fn fill(children : Array[@core.Component]) -> @core.Component {
  @core.box(children, flex_grow=1.0)
}

///|
// Preset components - common layout patterns

///|
/// Card - rounded border with padding, commonly used for UI panels
pub fn card(
  children : Array[@core.Component],
  id? : String = "",
  border_color? : @core.Color = @core.Color::white(),
  bg? : @core.Color = @core.Color::transparent(),
  padding? : Double = 1.0,
) -> @core.Component {
  column(
    children,
    id~,
    border=Some(@core.BorderChars::rounded()),
    border_color~,
    bg~,
    padding~,
  )
}

///|
/// Panel - single border without padding, for grouping content
pub fn panel(
  children : Array[@core.Component],
  id? : String = "",
  border_color? : @core.Color = @core.Color::white(),
  bg? : @core.Color = @core.Color::transparent(),
) -> @core.Component {
  column(
    children,
    id~,
    border=Some(@core.BorderChars::single()),
    border_color~,
    bg~,
  )
}

///|
/// Full screen container - fills entire terminal with optional border
pub fn fullscreen(
  children : Array[@core.Component],
  width : Int,
  height : Int,
  border? : @core.BorderChars? = None,
  border_color? : @core.Color = @core.Color::cyan(),
  padding? : Double = 0.0,
) -> @core.Component {
  column(
    children,
    width=@types.Dimension::Length(width.to_double()),
    height=@types.Dimension::Length(height.to_double()),
    border~,
    border_color~,
    padding~,
  )
}

///|
/// Footer - typically at bottom of screen for instructions/hints
pub fn footer(
  children : Array[@core.Component],
  fg? : @core.Color = @core.Color::rgb(128, 128, 128),
) -> @core.Component {
  row(children, justify=@types.Alignment::Center, fg~)
}

///|
/// Title bar - centered bold text with margin
pub fn title_bar(
  title : String,
  fg? : @core.Color = @core.Color::yellow(),
) -> @core.Component {
  row(
    [text(title, fg~, bold=true)],
    justify=@types.Alignment::Center,
    margin_y=1.0,
  )
}

// --- Text utilities ---

///|
/// Text alignment options
pub(all) enum TextAlign {
  Left
  Right
  Center
}

///|
/// Truncate string to given width
pub fn truncate_text(s : String, width : Int) -> String {
  let chars = s.iter().take(width).collect()
  String::from_array(chars)
}

///|
/// Align text within given width
pub fn align_text(
  s : String,
  width : Int,
  align? : TextAlign = TextAlign::Left,
) -> String {
  let len = s.length()
  if len >= width {
    truncate_text(s, width)
  } else {
    let padding = width - len
    match align {
      TextAlign::Left => s + " ".repeat(padding)
      TextAlign::Right => " ".repeat(padding) + s
      TextAlign::Center => {
        let left_pad = padding / 2
        let right_pad = padding - left_pad
        " ".repeat(left_pad) + s + " ".repeat(right_pad)
      }
    }
  }
}
