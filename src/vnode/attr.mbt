///|
/// Type-safe TUI attribute values
/// This will be used when luna supports Attr[E, A]

///|
/// Dimension value for layout properties
pub(all) enum DimensionValue {
  Auto
  Length(Double)
  Percent(Double)
}

///|
/// Convert to crater Dimension
pub fn DimensionValue::to_dimension(self : DimensionValue) -> @types.Dimension {
  match self {
    Auto => @types.Dimension::Auto
    Length(v) => @types.Dimension::Length(v)
    Percent(v) => @types.Dimension::Percent(v)
  }
}

///|
/// Alignment value
pub(all) enum AlignmentValue {
  Start
  Center
  End
  Stretch
  SpaceBetween
  SpaceAround
  SpaceEvenly
  FlexStart
  FlexEnd
}

///|
/// Convert to crater Alignment
pub fn AlignmentValue::to_alignment(self : AlignmentValue) -> @types.Alignment {
  match self {
    Start => @types.Alignment::Start
    Center => @types.Alignment::Center
    End => @types.Alignment::End
    Stretch => @types.Alignment::Stretch
    SpaceBetween => @types.Alignment::SpaceBetween
    SpaceAround => @types.Alignment::SpaceAround
    SpaceEvenly => @types.Alignment::SpaceEvenly
    FlexStart => @types.Alignment::FlexStart
    FlexEnd => @types.Alignment::FlexEnd
  }
}

///|
/// Flex direction
pub(all) enum DirectionValue {
  Row
  Column
}

///|
/// Convert to crater FlexDirection
pub fn DirectionValue::to_flex_direction(
  self : DirectionValue,
) -> @types.FlexDirection {
  match self {
    Row => @types.FlexDirection::Row
    Column => @types.FlexDirection::Column
  }
}

///|
/// Display value
pub(all) enum DisplayValue {
  Flex
  Grid
}

///|
/// Convert to crater Display
pub fn DisplayValue::to_display(self : DisplayValue) -> @types.Display {
  match self {
    Flex => @types.Display::Flex
    Grid => @types.Display::Grid
  }
}

///|
/// Grid auto-flow value
pub(all) enum GridAutoFlowValue {
  Row
  Column
  RowDense
  ColumnDense
}

///|
/// Convert to crater GridAutoFlow
pub fn GridAutoFlowValue::to_grid_auto_flow(
  self : GridAutoFlowValue,
) -> @types.GridAutoFlow {
  match self {
    Row => @types.GridAutoFlow::Row
    Column => @types.GridAutoFlow::Column
    RowDense => @types.GridAutoFlow::RowDense
    ColumnDense => @types.GridAutoFlow::ColumnDense
  }
}

///|
/// Border style
pub(all) enum BorderValue {
  None
  Single
  Double
  Rounded
  Ascii
}

///|
/// Convert to BorderChars
pub fn BorderValue::to_border_chars(self : BorderValue) -> @core.BorderChars? {
  match self {
    None => Option::None
    Single => Some(@core.BorderChars::single())
    Double => Some(@core.BorderChars::double())
    Rounded => Some(@core.BorderChars::rounded())
    Ascii => Some(@core.BorderChars::ascii())
  }
}

///|
/// Color value
pub(all) enum ColorValue {
  Transparent
  Named(String)
  Rgb(Int, Int, Int)
}

///|
/// Convert to Color
pub fn ColorValue::to_color(self : ColorValue) -> @core.Color {
  match self {
    Transparent => @core.Color::transparent()
    Named(name) =>
      match name {
        "red" => @core.Color::red()
        "green" => @core.Color::green()
        "blue" => @core.Color::blue()
        "yellow" => @core.Color::yellow()
        "cyan" => @core.Color::cyan()
        "magenta" => @core.Color::magenta()
        "white" => @core.Color::white()
        "black" => @core.Color::black()
        _ => @core.Color::white()
      }
    Rgb(r, g, b) => @core.Color::rgb(r, g, b)
  }
}

///|
/// Typed TUI attribute value
/// Will replace String when luna supports Attr[E, A]
pub(all) enum TuiAttrValue {
  // Layout
  Direction(DirectionValue)
  Width(DimensionValue)
  Height(DimensionValue)
  MinWidth(DimensionValue)
  MinHeight(DimensionValue)
  FlexGrow(Double)
  FlexShrink(Double)
  Gap(Double)
  // Display
  Display(DisplayValue)
  // Grid container
  GridTemplateColumns(Array[@types.TrackSizingFunction])
  GridTemplateRows(Array[@types.TrackSizingFunction])
  GridAutoFlow(GridAutoFlowValue)
  // Grid item
  GridColumn(Int) // Column position (1-indexed)
  GridRow(Int) // Row position (1-indexed)
  GridColumnSpan(Int) // Column span
  GridRowSpan(Int) // Row span
  // Grid template areas (for named area layout)
  GridTemplateAreas(Array[String]) // e.g., ["header header", "sidebar main"]
  GridArea(String) // Named area for grid item placement
  // Spacing
  Padding(Double)
  PaddingX(Double)
  PaddingY(Double)
  Margin(Double)
  MarginX(Double)
  MarginY(Double)
  // Alignment
  Justify(AlignmentValue)
  Align(AlignmentValue)
  // Visual
  Border(BorderValue)
  BorderColor(ColorValue)
  Fg(ColorValue)
  Bg(ColorValue)
  Bold(Bool)
  Underline(Bool)
  // Identity
  Id(String)
  // Accessibility
  TabIndex(Int) // Tab order for focus management (-1 = not focusable, 0+ = tab order)
}
