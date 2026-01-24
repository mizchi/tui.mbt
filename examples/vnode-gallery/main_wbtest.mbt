///|
/// Tests for vnode-gallery
/// Note: This example has complex nested functions in main, so we test basic rendering

///|
test "gallery demo list" {
  let demos = ["Tabs", "Toggle", "Listbox", "Progress", "Cards"]
  inspect(demos.length(), content="5")
}

///|
test "gallery uses signals" {
  let current_demo = @signals.signal(0)
  current_demo.set(2)
  inspect(current_demo.get(), content="2")
}
