///|
test "BoxProps: default values" {
  let props = BoxProps::default()
  assert_true(props.direction is DirectionValue::Row)
  assert_eq(props.flex_grow, 0.0)
  assert_eq(props.flex_shrink, 1.0)
}

///|
test "BoxProps: to_attrs includes set values" {
  let props : BoxProps = {
    ..BoxProps::default(),
    direction: DirectionValue::Column,
    width: DimensionValue::Length(100.0),
    padding: 10.0,
    justify: Some(AlignmentValue::Center),
  }
  let attrs = props.to_attrs()
  // Should include direction, width, padding, justify
  assert_true(attrs.length() >= 4)
}

///|
test "DimensionValue: to_dimension" {
  assert_true(DimensionValue::Auto.to_dimension() == @types.Dimension::Auto)
  assert_true(
    DimensionValue::Length(10.0).to_dimension() ==
    @types.Dimension::Length(10.0),
  )
  assert_true(
    DimensionValue::Percent(50.0).to_dimension() ==
    @types.Dimension::Percent(50.0),
  )
}

///|
test "DimensionValue: to_layout_dimension" {
  assert_true(
    DimensionValue::Auto.to_layout_dimension() == @ltypes.Dimension::Auto,
  )
  assert_true(
    DimensionValue::Length(10.0).to_layout_dimension() ==
    @ltypes.Dimension::Length(10.0),
  )
  assert_true(
    DimensionValue::Percent(50.0).to_layout_dimension() ==
    @ltypes.Dimension::Percent(50.0),
  )
}

///|
test "AlignmentValue: to_alignment" {
  assert_true(AlignmentValue::Center.to_alignment() == @types.Alignment::Center)
  assert_true(
    AlignmentValue::SpaceBetween.to_alignment() ==
    @types.Alignment::SpaceBetween,
  )
}

///|
test "AlignmentValue: to_layout_alignment" {
  assert_true(
    AlignmentValue::Center.to_layout_alignment() == @ltypes.Alignment::Center,
  )
  assert_true(
    AlignmentValue::SpaceBetween.to_layout_alignment() ==
    @ltypes.Alignment::SpaceBetween,
  )
}

///|
test "DirectionValue: to_flex_direction" {
  assert_true(
    DirectionValue::Row.to_flex_direction() == @types.FlexDirection::Row,
  )
  assert_true(
    DirectionValue::Column.to_flex_direction() == @types.FlexDirection::Column,
  )
}

///|
test "DirectionValue: to_layout_flex_direction" {
  assert_true(
    DirectionValue::Row.to_layout_flex_direction() == @ltypes.FlexDirection::Row,
  )
  assert_true(
    DirectionValue::Column.to_layout_flex_direction() ==
    @ltypes.FlexDirection::Column,
  )
}

///|
test "BorderValue: to_border_chars" {
  assert_true(BorderValue::None.to_border_chars() is Option::None)
  assert_true(BorderValue::Single.to_border_chars() is Some(_))
  assert_true(BorderValue::Rounded.to_border_chars() is Some(_))
}

///|
test "ColorValue: to_color" {
  let red = ColorValue::Named("red").to_color()
  let rgb = ColorValue::Rgb(255, 0, 0).to_color()
  // Both should produce valid colors
  assert_true(red == @core.Color::red())
  assert_true(rgb == @core.Color::rgb(255, 0, 0))
}

///|
test "attr_to_string: converts typed attrs to string pairs" {
  let (k, v) = attr_to_string(TuiAttrValue::Width(DimensionValue::Length(10.0)))
  assert_eq(k, "width")
  assert_eq(v, "10")
}

///|
test "attr_to_string: alignment" {
  let (k, v) = attr_to_string(TuiAttrValue::Justify(AlignmentValue::Center))
  assert_eq(k, "justify")
  assert_eq(v, "center")
}

///|
test "attr_to_string: border" {
  let (k, v) = attr_to_string(TuiAttrValue::Border(BorderValue::Rounded))
  assert_eq(k, "border")
  assert_eq(v, "rounded")
}

///|
test "attr_to_string: color rgb" {
  let (k, v) = attr_to_string(TuiAttrValue::Fg(ColorValue::Rgb(128, 64, 32)))
  assert_eq(k, "fg")
  assert_eq(v, "rgb(128,64,32)")
}

///|
test "box_node: creates luna node" {
  let props : BoxProps = {
    ..BoxProps::default(),
    direction: DirectionValue::Row,
    padding: 1.0,
  }
  let node = box_node(props, [])
  // Should create an Element node
  assert_true(node is @luna.Node::Element(_))
}

///|
test "text_node: creates text with style" {
  let props : TextProps = {
    ..TextProps::default("Hello"),
    fg: Some(ColorValue::Named("red")),
    bold: true,
  }
  let node = text_node(props)
  // Should create an Element node (styled text)
  assert_true(node is @luna.Node::Element(_))
}

///|
test "text_node: plain text without style" {
  let props = TextProps::default("Hello")
  let node = text_node(props)
  // Should create a Text node (no wrapper needed)
  assert_true(node is @luna.Node::Text(_))
}

// =============================================================================
// Grid and View tests
// =============================================================================

///|
test "DisplayValue: to_display" {
  assert_true(DisplayValue::Flex.to_display() == @types.Display::Flex)
  assert_true(DisplayValue::Grid.to_display() == @types.Display::Grid)
}

///|
test "GridAutoFlowValue: to_grid_auto_flow" {
  assert_true(
    GridAutoFlowValue::Row.to_grid_auto_flow() == @types.GridAutoFlow::Row,
  )
  assert_true(
    GridAutoFlowValue::Column.to_grid_auto_flow() == @types.GridAutoFlow::Column,
  )
  assert_true(
    GridAutoFlowValue::RowDense.to_grid_auto_flow() ==
    @types.GridAutoFlow::RowDense,
  )
  assert_true(
    GridAutoFlowValue::ColumnDense.to_grid_auto_flow() ==
    @types.GridAutoFlow::ColumnDense,
  )
}

///|
test "attr_to_string: display" {
  let (k, v) = attr_to_string(TuiAttrValue::Display(DisplayValue::Grid))
  assert_eq(k, "display")
  assert_eq(v, "grid")
}

///|
test "attr_to_string: grid_auto_flow" {
  let (k, v) = attr_to_string(
    TuiAttrValue::GridAutoFlow(GridAutoFlowValue::ColumnDense),
  )
  assert_eq(k, "grid_auto_flow")
  assert_eq(v, "column-dense")
}

///|
test "attr_to_string: grid_column" {
  let (k, v) = attr_to_string(TuiAttrValue::GridColumn(2))
  assert_eq(k, "grid_column")
  assert_eq(v, "2")
}

///|
test "attr_to_string: grid_template_columns" {
  let tracks = [
    @types.TrackSizingFunction::Fr(1.0),
    @types.TrackSizingFunction::Fr(2.0),
  ]
  let (k, v) = attr_to_string(TuiAttrValue::GridTemplateColumns(tracks))
  assert_eq(k, "grid_template_columns")
  assert_eq(v, "1fr 2fr")
}

///|
test "view: creates column layout by default" {
  let node = view([text("A"), text("B")])
  // Should create an Element node
  assert_true(node is @luna.Node::Element(_))
}

///|
test "view: creates row layout with direction param" {
  let node = view(direction="row", [text("A"), text("B")])
  // Should create an Element node
  assert_true(node is @luna.Node::Element(_))
}

///|
test "grid: creates grid layout" {
  let node = grid(columns=[1.0, 1.0], [text("A"), text("B")])
  // Should create an Element node
  assert_true(node is @luna.Node::Element(_))
}

///|
test "grid_item: creates positioned item" {
  let node = grid_item(column=2, row=1, child=text("A"))
  // Should create an Element node
  assert_true(node is @luna.Node::Element(_))
}

///|
test "grid_item: creates spanned item" {
  let node = grid_item(column_span=3, child=text("Header"))
  // Should create an Element node
  assert_true(node is @luna.Node::Element(_))
}
