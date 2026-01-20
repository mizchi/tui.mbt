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
/// Horizontal divider line
pub fn hdivider(
  char? : Char = '-',
  fg? : @core.Color = @core.Color::white(),
) -> @core.Component {
  @core.box(
    [],
    flex_grow=1.0,
    height=@types.Dimension::Length(1.0),
    border=Some({
      top_left: char,
      top_right: char,
      bottom_left: char,
      bottom_right: char,
      horizontal: char,
      vertical: char,
    }),
    border_color=fg,
  )
}

///|
/// Vertical divider line
pub fn vdivider(
  char? : Char = '|',
  fg? : @core.Color = @core.Color::white(),
) -> @core.Component {
  @core.box(
    [],
    flex_grow=1.0,
    width=@types.Dimension::Length(1.0),
    border=Some({
      top_left: char,
      top_right: char,
      bottom_left: char,
      bottom_right: char,
      horizontal: char,
      vertical: char,
    }),
    border_color=fg,
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
/// Center content
pub fn center(children : Array[@core.Component]) -> @core.Component {
  @core.box(
    children,
    justify_content=@types.Alignment::Center,
    align_items=@types.Alignment::Center,
  )
}

///|
/// Fill available space
pub fn fill(children : Array[@core.Component]) -> @core.Component {
  @core.box(children, flex_grow=1.0)
}
