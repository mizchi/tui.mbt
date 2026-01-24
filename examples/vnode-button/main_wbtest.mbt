///|
/// Tests for vnode-button components

///|
test "vnode_button renders with border" {
  let button = vnode_button("Click", "btn-test")
  let output = @vnode.render_vnode_once(12, 3, button)
  inspect(output.contains("Click"), content="true")
}

///|
test "render_button_ui shows title" {
  let output = @vnode.render_vnode_once(
    60,
    15,
    render_button_ui(60, 15, 0, "Hello"),
  )
  inspect(output.contains("Button Demo"), content="true")
}

///|
test "render_button_ui shows message" {
  let output = @vnode.render_vnode_once(
    60,
    15,
    render_button_ui(60, 15, 0, "Test Message"),
  )
  inspect(output.contains("Test Message"), content="true")
}

///|
test "render_button_ui renders buttons" {
  let output = @vnode.render_vnode_once(60, 15, render_button_ui(60, 15, 0, ""))
  // Output should have substantial content
  inspect(output.length() > 100, content="true")
}
