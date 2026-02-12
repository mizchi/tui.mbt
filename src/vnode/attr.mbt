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
fn layout_dimension_to_crater(d : @ltypes.Dimension) -> @types.Dimension {
  match d {
    @ltypes.Dimension::Auto => @types.Dimension::Auto
    @ltypes.Dimension::Length(v) => @types.Dimension::Length(v)
    @ltypes.Dimension::Percent(v) => @types.Dimension::Percent(v)
    @ltypes.Dimension::MinContent => @types.Dimension::MinContent
    @ltypes.Dimension::MaxContent => @types.Dimension::MaxContent
    @ltypes.Dimension::FitContent(v) => @types.Dimension::FitContent(v)
  }
}

///|
fn layout_alignment_to_crater(a : @ltypes.Alignment) -> @types.Alignment {
  match a {
    @ltypes.Alignment::Start => @types.Alignment::Start
    @ltypes.Alignment::Center => @types.Alignment::Center
    @ltypes.Alignment::End => @types.Alignment::End
    @ltypes.Alignment::Stretch => @types.Alignment::Stretch
    @ltypes.Alignment::SpaceBetween => @types.Alignment::SpaceBetween
    @ltypes.Alignment::SpaceAround => @types.Alignment::SpaceAround
    @ltypes.Alignment::SpaceEvenly => @types.Alignment::SpaceEvenly
    @ltypes.Alignment::FlexStart => @types.Alignment::FlexStart
    @ltypes.Alignment::FlexEnd => @types.Alignment::FlexEnd
    @ltypes.Alignment::Baseline => @types.Alignment::Baseline
  }
}

///|
fn layout_flex_direction_to_crater(
  d : @ltypes.FlexDirection,
) -> @types.FlexDirection {
  match d {
    @ltypes.FlexDirection::Row => @types.FlexDirection::Row
    @ltypes.FlexDirection::Column => @types.FlexDirection::Column
    @ltypes.FlexDirection::RowReverse => @types.FlexDirection::RowReverse
    @ltypes.FlexDirection::ColumnReverse => @types.FlexDirection::ColumnReverse
  }
}

///|
/// Convert to layout Dimension
pub fn DimensionValue::to_layout_dimension(
  self : DimensionValue,
) -> @ltypes.Dimension {
  match self {
    Auto => @ltypes.Dimension::Auto
    Length(v) => @ltypes.Dimension::Length(v)
    Percent(v) => @ltypes.Dimension::Percent(v)
  }
}

///|
/// Convert to crater Dimension
pub fn DimensionValue::to_dimension(self : DimensionValue) -> @types.Dimension {
  layout_dimension_to_crater(self.to_layout_dimension())
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
/// Convert to layout Alignment
pub fn AlignmentValue::to_layout_alignment(
  self : AlignmentValue,
) -> @ltypes.Alignment {
  match self {
    Start => @ltypes.Alignment::Start
    Center => @ltypes.Alignment::Center
    End => @ltypes.Alignment::End
    Stretch => @ltypes.Alignment::Stretch
    SpaceBetween => @ltypes.Alignment::SpaceBetween
    SpaceAround => @ltypes.Alignment::SpaceAround
    SpaceEvenly => @ltypes.Alignment::SpaceEvenly
    FlexStart => @ltypes.Alignment::FlexStart
    FlexEnd => @ltypes.Alignment::FlexEnd
  }
}

///|
/// Convert to crater Alignment
pub fn AlignmentValue::to_alignment(self : AlignmentValue) -> @types.Alignment {
  layout_alignment_to_crater(self.to_layout_alignment())
}

///|
/// Flex direction
pub(all) enum DirectionValue {
  Row
  Column
}

///|
/// Convert to layout FlexDirection
pub fn DirectionValue::to_layout_flex_direction(
  self : DirectionValue,
) -> @ltypes.FlexDirection {
  match self {
    Row => @ltypes.FlexDirection::Row
    Column => @ltypes.FlexDirection::Column
  }
}

///|
/// Convert to crater FlexDirection
pub fn DirectionValue::to_flex_direction(
  self : DirectionValue,
) -> @types.FlexDirection {
  layout_flex_direction_to_crater(self.to_layout_flex_direction())
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
  Role(@core.Role)
}
