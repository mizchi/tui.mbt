///|
/// Whitebox tests for modal stories - VNode version

///|
test "centering layout renders correctly" {
  let node = @vnode.column(
    [@vnode.row([@vnode.text("CENTER")], justify="center")],
    width=17.0,
    height=5.0,
    justify="center",
    align="center",
  )
  let output = @vnode.render_vnode_once(17, 5, node)
  // Verify the text "CENTER" is rendered
  assert_true(output.contains("CENTER"))
}

///|
test "centered_modal renders" {
  // Verify the centered_modal story renders without error
  let stories = modal_stories()
  for s in stories {
    if s.name == "centered_modal" {
      let output = s.to_plain()
      // Should contain "Modal" text
      assert_true(output.contains("Modal"))
      return
    }
  }
}
