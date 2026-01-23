///|
/// Row - Horizontal flex container (like Ink's Box with flexDirection="row")

///|
/// Create a horizontal row container
pub fn row(
  children : Array[@core.Component],
  // ID
  id? : String = "",
  // Size
  width? : @types.Dimension = @types.Dimension::Auto,
  height? : @types.Dimension = @types.Dimension::Auto,
  min_width? : @types.Dimension = @types.Dimension::Auto,
  min_height? : @types.Dimension = @types.Dimension::Auto,
  max_width? : @types.Dimension = @types.Dimension::Auto,
  max_height? : @types.Dimension = @types.Dimension::Auto,
  // Flex item properties
  flex_grow? : Double = 0.0,
  flex_shrink? : Double = 1.0,
  flex_basis? : @types.Dimension = @types.Dimension::Auto,
  // Alignment
  justify? : @types.Alignment = @types.Alignment::FlexStart,
  align? : @types.Alignment = @types.Alignment::Stretch,
  wrap? : Bool = false,
  gap? : Double = 0.0,
  // Spacing
  padding? : Double = 0.0,
  padding_x? : Double = 0.0,
  padding_y? : Double = 0.0,
  margin? : Double = 0.0,
  margin_x? : Double = 0.0,
  margin_y? : Double = 0.0,
  // Style
  border? : @core.BorderChars? = None,
  border_color? : @core.Color = @core.Color::white(),
  bg? : @core.Color = @core.Color::transparent(),
  fg? : @core.Color = @core.Color::white(),
  // Event handler
  on_click? : (() -> Unit)? = None,
  // Accessibility
  role? : @core.Role? = None,
) -> @core.Component {
  @core.box(
    children,
    id~,
    flex_direction=@types.FlexDirection::Row,
    flex_wrap=if wrap { @types.FlexWrap::Wrap } else { @types.FlexWrap::NoWrap },
    width~,
    height~,
    min_width~,
    min_height~,
    max_width~,
    max_height~,
    flex_grow~,
    flex_shrink~,
    flex_basis~,
    justify_content=justify,
    align_items=align,
    gap~,
    padding~,
    padding_x~,
    padding_y~,
    margin~,
    margin_x~,
    margin_y~,
    border~,
    border_color~,
    bg~,
    fg~,
    on_click~,
    role~,
  )
}
