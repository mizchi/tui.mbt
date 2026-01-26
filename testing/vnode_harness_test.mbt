///|
/// Tests for VNodeTestHarness

///|
test "VNodeTestHarness: basic render" {
  let harness = VNodeTestHarness::new(width=20, height=5)
  let node = @vnode.text("Hello World")
  let _ = harness.render(node)
  assert_true(harness.contains("Hello World"))
}

///|
test "VNodeTestHarness: column layout" {
  let harness = VNodeTestHarness::new(width=20, height=5)
  let node = @vnode.column([@vnode.text("Line 1"), @vnode.text("Line 2")])
  let _ = harness.render(node)
  assert_true(harness.contains("Line 1"))
  assert_true(harness.contains("Line 2"))
}

///|
test "VNodeTestHarness: grid layout" {
  let harness = VNodeTestHarness::new(width=30, height=5)
  let node = @vnode.grid(columns=[1.0, 1.0], [
    @vnode.text("A"),
    @vnode.text("B"),
    @vnode.text("C"),
    @vnode.text("D"),
  ])
  let _ = harness.render(node)
  assert_true(harness.contains("A"))
  assert_true(harness.contains("B"))
  assert_true(harness.contains("C"))
  assert_true(harness.contains("D"))
}

///|
test "VNodeTestHarness: grid_area basic" {
  let harness = VNodeTestHarness::new(width=30, height=8)
  let node = @vnode.grid(areas=["header header", "sidebar main"], gap=1.0, [
    @vnode.grid_area("header", @vnode.text("Header")),
    @vnode.grid_area("sidebar", @vnode.text("Sidebar")),
    @vnode.grid_area("main", @vnode.text("Main")),
  ])
  let _ = harness.render(node)
  assert_true(harness.contains("Header"))
  assert_true(harness.contains("Sidebar"))
  assert_true(harness.contains("Main"))
}

///|
test "VNodeTestHarness: grid_area with span" {
  let harness = VNodeTestHarness::new(width=40, height=10)
  let node = @vnode.grid(
    areas=[
      "header header header", "nav content content", "footer footer footer",
    ],
    [
      @vnode.grid_area("header", @vnode.text("H")),
      @vnode.grid_area("nav", @vnode.text("N")),
      @vnode.grid_area("content", @vnode.text("C")),
      @vnode.grid_area("footer", @vnode.text("F")),
    ],
  )
  let _ = harness.render(node)
  assert_true(harness.contains("H"))
  assert_true(harness.contains("N"))
  assert_true(harness.contains("C"))
  assert_true(harness.contains("F"))
}

///|
test "VNodeTestHarness: find_by_id" {
  let harness = VNodeTestHarness::new(width=30, height=5)
  let node = @vnode.column(id="container", [@vnode.text("Content")])
  let _ = harness.render(node)
  let result = harness.find_by_id("container")
  assert_true(result is Some(_))
}

///|
test "VNodeTestHarness: frame count" {
  let harness = VNodeTestHarness::new()
  assert_eq(harness.frame_count(), 0)
  let _ = harness.render(@vnode.text("A"))
  assert_eq(harness.frame_count(), 1)
  let _ = harness.render(@vnode.text("B"))
  assert_eq(harness.frame_count(), 2)
  harness.clear_frames()
  assert_eq(harness.frame_count(), 0)
}
