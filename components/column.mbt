///|
/// Column - Vertical flex container (like Ink's Box with flexDirection="column")

///|
/// Create a vertical column container
/// Size parameters accept Double, Int, or Dimension directly via ToDimension trait
pub fn column(
  children : Array[@core.Component],
  // ID
  id? : String = "",
  // Size - accepts Double, Int, or Dimension
  width? : &ToDimension = @types.Dimension::Auto,
  height? : &ToDimension = @types.Dimension::Auto,
  min_width? : &ToDimension = @types.Dimension::Auto,
  min_height? : &ToDimension = @types.Dimension::Auto,
  max_width? : &ToDimension = @types.Dimension::Auto,
  max_height? : &ToDimension = @types.Dimension::Auto,
  // Flex item properties
  flex_grow? : Double = 0.0,
  flex_shrink? : Double = 1.0,
  flex_basis? : &ToDimension = @types.Dimension::Auto,
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
    flex_direction=@types.FlexDirection::Column,
    flex_wrap=if wrap { @types.FlexWrap::Wrap } else { @types.FlexWrap::NoWrap },
    width=width.to_dimension(),
    height=height.to_dimension(),
    min_width=min_width.to_dimension(),
    min_height=min_height.to_dimension(),
    max_width=max_width.to_dimension(),
    max_height=max_height.to_dimension(),
    flex_grow~,
    flex_shrink~,
    flex_basis=flex_basis.to_dimension(),
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
