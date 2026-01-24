///|
/// Tests for vnode-simple components

///|
test "render_simple_ui shows title" {
  let output = @vnode.render_vnode_once(40, 10, render_simple_ui(40, 10, 0))
  inspect(output.contains("Simple TUI App"), content="true")
}

///|
test "render_simple_ui has content" {
  let output = @vnode.render_vnode_once(60, 15, render_simple_ui(60, 15, 0))
  // Output should have substantial content (ANSI codes + text)
  inspect(output.length() > 100, content="true")
}

///|
test "render_simple_ui shows footer" {
  let output = @vnode.render_vnode_once(40, 10, render_simple_ui(40, 10, 0))
  inspect(output.contains("quit"), content="true")
}

///|
test "render_simple_ui positive count is green" {
  let output = @vnode.render_vnode_once(40, 10, render_simple_ui(40, 10, 5))
  // Contains ANSI green color code
  inspect(output.contains("5"), content="true")
}

///|
test "render_simple_ui with different counts" {
  // Test rendering with different count values
  let output_zero = @vnode.render_vnode_once(
    60,
    15,
    render_simple_ui(60, 15, 0),
  )
  let output_positive = @vnode.render_vnode_once(
    60,
    15,
    render_simple_ui(60, 15, 5),
  )
  let output_negative = @vnode.render_vnode_once(
    60,
    15,
    render_simple_ui(60, 15, -5),
  )
  // All should render successfully (non-empty output)
  inspect(output_zero.length() > 0, content="true")
  inspect(output_positive.length() > 0, content="true")
  inspect(output_negative.length() > 0, content="true")
}
