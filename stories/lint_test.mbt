///|
/// Tests for lint utilities

///|
test "lint utilities work correctly" {
  // Test with a story that violates odd-dimensions
  let bad_story = Story::new(
    "tabs",
    "test",
    fn() { @core.text("x") },
    width=20,
    height=10,
  )
  let violations = lint_odd_dimensions([bad_story])
  inspect(violations.length(), content="1")
  inspect(violations[0].rule, content="odd-dimensions")
}

///|
test "lint passes for odd dimensions" {
  let good_story = Story::new(
    "tabs",
    "test",
    fn() { @core.text("x") },
    width=21,
    height=11,
  )
  let violations = lint_odd_dimensions([good_story])
  inspect(violations.length(), content="0")
}

///|
test "current stories pass all lints" {
  // This test verifies current stories are lint-clean
  // If you need to temporarily disable, comment this out
  let violations = lint_all(all_stories())
  inspect(violations.length(), content="0")
}
