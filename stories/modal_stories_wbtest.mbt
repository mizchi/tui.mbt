///|
/// Whitebox tests for modal stories centering

///|
test "centering layout calculates correct positions" {
  let component = @core.box(
    [
      @core.box(
        [@components.text("CENTER")],
        justify_content=@types.Alignment::Center,
        align_items=@types.Alignment::Center,
        flex_grow=1.0,
      ),
    ],
    width=@components.dim_percent(100.0),
    height=@components.dim_percent(100.0),
  )
  let layout = @render.compute_layout(component.node, 17, 5)
  // Root should be 17x5
  inspect(layout.width, content="17")
  inspect(layout.height, content="5")
  // Child box should fill parent
  let child = layout.children[0]
  inspect(child.width, content="17")
  inspect(child.height, content="5")
  // Grandchild (text "CENTER") should be centered
  // x = (17 - 6) / 2 = 5.5, y = (5 - 1) / 2 = 2
  let text_layout = child.children[0]
  inspect(text_layout.x, content="5.5")
  inspect(text_layout.y, content="2")
  inspect(text_layout.width, content="6")
  inspect(text_layout.height, content="1")
}

///|
test "centered_modal layout has correct vertical centering" {
  // Simulate the centered_modal story structure
  let stories = modal_stories()
  for s in stories {
    if s.name == "centered_modal" {
      let component = (s.render)()
      let layout = @render.compute_layout(component.node, s.width, s.height)
      // viewport: 21x9
      inspect(layout.width, content="21")
      inspect(layout.height, content="9")
      // center wrapper should fill
      let center = layout.children[0]
      inspect(center.width, content="21")
      inspect(center.height, content="9")
      // Modal box: border(1) + padding(1) + text(1) = 5 height, 9 width
      // y = (9 - 5) / 2 = 2
      // x = (21 - 9) / 2 = 6
      let modal = center.children[0]
      println(
        "Modal: x=\{modal.x}, y=\{modal.y}, w=\{modal.width}, h=\{modal.height}",
      )
      inspect(modal.y, content="2")
      return
    }
  }
}
