///|
/// Tests for focus management
test "FocusContext basic registration" {
  let ctx = FocusContext::new()
  ctx.register("btn1", 0)
  ctx.register("btn2", 1)
  ctx.register("btn3", 0)
  inspect(ctx.count(), content="3")
}

///|
test "FocusContext ignores negative tab_index" {
  let ctx = FocusContext::new()
  ctx.register("focusable", 0)
  ctx.register("not-focusable", -1)
  inspect(ctx.count(), content="1")
}

///|
test "FocusContext focus_next cycles through elements" {
  let ctx = FocusContext::new()
  ctx.register("first", 0)
  ctx.register("second", 1)
  ctx.register("third", 2)
  // First focus_next should return first element
  inspect(ctx.focus_next(), content="Some(\"first\")")
  // Second should return second element
  inspect(ctx.focus_next(), content="Some(\"second\")")
  // Third should return third element
  inspect(ctx.focus_next(), content="Some(\"third\")")
  // Fourth should cycle back to first
  inspect(ctx.focus_next(), content="Some(\"first\")")
}

///|
test "FocusContext focus_prev cycles backwards" {
  let ctx = FocusContext::new()
  ctx.register("first", 0)
  ctx.register("second", 1)
  ctx.register("third", 2)
  // First focus_prev should return last element
  inspect(ctx.focus_prev(), content="Some(\"third\")")
  // Second should return second element
  inspect(ctx.focus_prev(), content="Some(\"second\")")
  // Third should return first element
  inspect(ctx.focus_prev(), content="Some(\"first\")")
}

///|
test "FocusContext sorts by tab_index" {
  let ctx = FocusContext::new()
  // Register in wrong order
  ctx.register("should-be-last", 2)
  ctx.register("should-be-first", 0)
  ctx.register("should-be-middle", 1)
  // focus_next should return in sorted order
  inspect(ctx.focus_next(), content="Some(\"should-be-first\")")
  inspect(ctx.focus_next(), content="Some(\"should-be-middle\")")
  inspect(ctx.focus_next(), content="Some(\"should-be-last\")")
}

///|
test "FocusContext focus_by_id" {
  let ctx = FocusContext::new()
  ctx.register("btn1", 0)
  ctx.register("btn2", 1)
  ctx.register("btn3", 2)
  // Focus by id
  inspect(ctx.focus_by_id("btn2"), content="true")
  inspect(ctx.current_focus(), content="Some(\"btn2\")")
  // focus_next should continue from btn2
  inspect(ctx.focus_next(), content="Some(\"btn3\")")
}

///|
test "FocusContext focus_by_id returns false for unknown id" {
  let ctx = FocusContext::new()
  ctx.register("btn1", 0)
  inspect(ctx.focus_by_id("unknown"), content="false")
}

///|
test "FocusContext focusable_ids returns sorted ids" {
  let ctx = FocusContext::new()
  ctx.register("c", 2)
  ctx.register("a", 0)
  ctx.register("b", 1)
  inspect(ctx.focusable_ids(), content="[\"a\", \"b\", \"c\"]")
}

///|
test "FocusContext is_focusable" {
  let ctx = FocusContext::new()
  ctx.register("btn1", 0)
  inspect(ctx.is_focusable("btn1"), content="true")
  inspect(ctx.is_focusable("unknown"), content="false")
}

///|
test "FocusContext empty returns None" {
  let ctx = FocusContext::new()
  inspect(ctx.focus_next(), content="None")
  inspect(ctx.focus_prev(), content="None")
  inspect(ctx.current_focus(), content="None")
}

///|
test "FocusContext clear resets state" {
  let ctx = FocusContext::new()
  ctx.register("btn1", 0)
  ctx.register("btn2", 1)
  let _ = ctx.focus_next()
  ctx.clear()
  inspect(ctx.count(), content="0")
  inspect(ctx.current_focus(), content="None")
}
