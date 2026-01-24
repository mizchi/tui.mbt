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
test "AlignmentValue: to_alignment" {
  assert_true(AlignmentValue::Center.to_alignment() == @types.Alignment::Center)
  assert_true(
    AlignmentValue::SpaceBetween.to_alignment() ==
    @types.Alignment::SpaceBetween,
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
