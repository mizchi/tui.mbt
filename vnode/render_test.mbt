///|
test "to_crater_node: simple text" {
  let ctx = RenderContext::new()
  let node = text("Hello")
  let crater = to_crater_node(ctx, node)
  assert_eq(crater.id, "v1")
  assert_eq(ctx.texts.get("v1"), Some("Hello"))
}

///|
test "to_crater_node: row with children" {
  let ctx = RenderContext::new()
  let node = row([text("A"), text("B")])
  let crater = to_crater_node(ctx, node)
  assert_eq(crater.children.length(), 2)
  assert_eq(ctx.texts.get("v2"), Some("A"))
  assert_eq(ctx.texts.get("v3"), Some("B"))
}

///|
test "to_crater_node: column with gap" {
  let ctx = RenderContext::new()
  let node = column(gap=1.0, [text("Line 1"), text("Line 2")])
  let crater = to_crater_node(ctx, node)
  assert_eq(crater.children.length(), 2)
}

///|
test "to_crater_node: styled text" {
  let ctx = RenderContext::new()
  let node = text("Red", fg="red", bold=true)
  let crater = to_crater_node(ctx, node)
  // Text with style wraps in a text element
  let style = ctx.styles.get(crater.id)
  assert_true(style is Some(_))
}

///|
test "to_crater_node: show conditional" {
  let ctx = RenderContext::new()
  let visible = show(fn() { true }, fn() { text("Visible") })
  let _crater = to_crater_node(ctx, visible)
  // Should have text content
  assert_eq(ctx.texts.get("v1"), Some("Visible"))
}

///|
test "to_crater_node: show conditional hidden" {
  let ctx = RenderContext::new()
  let hidden = show(fn() { false }, fn() { text("Hidden") })
  let crater = to_crater_node(ctx, hidden)
  // Should be empty node
  assert_eq(crater.children.length(), 0)
  // No text content for hidden node
  assert_eq(ctx.texts.get("v1"), None)
}

///|
test "to_crater_node: for_each" {
  let ctx = RenderContext::new()
  let list = for_each(fn() { [text("Item 1"), text("Item 2"), text("Item 3")] })
  let crater = to_crater_node(ctx, list)
  assert_eq(crater.children.length(), 3)
}

///|
test "to_crater_node: spacer" {
  let ctx = RenderContext::new()
  let node = row([text("Left"), spacer(), text("Right")])
  let crater = to_crater_node(ctx, node)
  assert_eq(crater.children.length(), 3)
}

///|
test "to_crater_node: border" {
  let ctx = RenderContext::new()
  let node = row(border="single", [text("Bordered")])
  let crater = to_crater_node(ctx, node)
  let style = ctx.styles.get(crater.id)
  assert_true(style is Some(_))
  assert_true(style.unwrap().border is Some(_))
}
