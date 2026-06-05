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
fn layout_dimension_to_crater(d : @ltypes.Dimension) -> @values.Dimension {
  match d {
    @ltypes.Dimension::Auto => @values.Dimension::Auto
    @ltypes.Dimension::Length(v) => @values.Dimension::Length(v)
    @ltypes.Dimension::Percent(v) => @values.Dimension::Percent(v)
    @ltypes.Dimension::MinContent => @values.Dimension::MinContent
    @ltypes.Dimension::MaxContent => @values.Dimension::MaxContent
    @ltypes.Dimension::FitContent(v) => @values.Dimension::FitContent(v)
  }
}

///|
fn layout_alignment_to_crater(a : @ltypes.Alignment) -> @values.Alignment {
  match a {
    @ltypes.Alignment::Start => @values.Alignment::Start
    @ltypes.Alignment::Center => @values.Alignment::Center
    @ltypes.Alignment::End => @values.Alignment::End
    @ltypes.Alignment::Stretch => @values.Alignment::Stretch
    @ltypes.Alignment::SpaceBetween => @values.Alignment::SpaceBetween
    @ltypes.Alignment::SpaceAround => @values.Alignment::SpaceAround
    @ltypes.Alignment::SpaceEvenly => @values.Alignment::SpaceEvenly
    @ltypes.Alignment::FlexStart => @values.Alignment::FlexStart
    @ltypes.Alignment::FlexEnd => @values.Alignment::FlexEnd
    @ltypes.Alignment::Baseline => @values.Alignment::Baseline
  }
}

///|
fn layout_flex_direction_to_crater(
  d : @ltypes.FlexDirection,
) -> @values.FlexDirection {
  match d {
    @ltypes.FlexDirection::Row => @values.FlexDirection::Row
    @ltypes.FlexDirection::Column => @values.FlexDirection::Column
    @ltypes.FlexDirection::RowReverse => @values.FlexDirection::RowReverse
    @ltypes.FlexDirection::ColumnReverse => @values.FlexDirection::ColumnReverse
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
pub fn DimensionValue::to_dimension(self : DimensionValue) -> @values.Dimension {
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
pub fn AlignmentValue::to_alignment(self : AlignmentValue) -> @values.Alignment {
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
) -> @values.FlexDirection {
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
pub fn DisplayValue::to_display(self : DisplayValue) -> @values.Display {
  match self {
    Flex => @values.Display::Flex
    Grid => @values.Display::Grid
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
) -> @values.GridAutoFlow {
  match self {
    Row => @values.GridAutoFlow::Row
    Column => @values.GridAutoFlow::Column
    RowDense => @values.GridAutoFlow::RowDense
    ColumnDense => @values.GridAutoFlow::ColumnDense
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
  GridTemplateColumns(Array[@values.TrackSizingFunction])
  GridTemplateRows(Array[@values.TrackSizingFunction])
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
