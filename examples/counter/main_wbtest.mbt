///|
/// Tests for vnode-counter components

///|
test "vnode_button renders with label" {
  let button = vnode_button("Test", "btn-test", 10.0)
  let output = @vnode.render_vnode_once(15, 3, button)
  inspect(output.contains("Test"), content="true")
}

///|
test "render_counter_ui shows title" {
  let output = @vnode.render_vnode_once(60, 15, render_counter_ui(60, 15, 0))
  inspect(output.contains("Counter Demo"), content="true")
}

///|
test "render_counter_ui has buttons" {
  let output = @vnode.render_vnode_once(60, 15, render_counter_ui(60, 15, 0))
  // Output should contain button borders
  inspect(output.length() > 100, content="true")
}

///|
test "render_counter_ui renders with different counts" {
  let output_zero = @vnode.render_vnode_once(
    60,
    15,
    render_counter_ui(60, 15, 0),
  )
  let output_pos = @vnode.render_vnode_once(
    60,
    15,
    render_counter_ui(60, 15, 10),
  )
  let output_neg = @vnode.render_vnode_once(
    60,
    15,
    render_counter_ui(60, 15, -5),
  )
  inspect(output_zero.length() > 0, content="true")
  inspect(output_pos.length() > 0, content="true")
  inspect(output_neg.length() > 0, content="true")
}
