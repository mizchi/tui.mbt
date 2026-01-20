///|
/// Tests for ItemScroller

///|
test "ItemScroller::new: initial state" {
  let scroller = ItemScroller::new()
  inspect(scroller.offset.get(), content="0")
  inspect(scroller.auto_scroll.get(), content="true")
}

///|
test "ItemScroller::up: scroll up from offset" {
  let scroller = ItemScroller::new()
  scroller.offset.set(5)
  let changed = scroller.up(2)
  inspect(changed, content="true")
  inspect(scroller.offset.get(), content="3")
  inspect(scroller.auto_scroll.get(), content="false")
}

///|
test "ItemScroller::up: cannot scroll up from zero" {
  let scroller = ItemScroller::new()
  let changed = scroller.up(1)
  inspect(changed, content="false")
  inspect(scroller.offset.get(), content="0")
}

///|
test "ItemScroller::up: clamp to zero" {
  let scroller = ItemScroller::new()
  scroller.offset.set(2)
  let changed = scroller.up(5)
  inspect(changed, content="true")
  inspect(scroller.offset.get(), content="0")
}

///|
test "ItemScroller::down: scroll down" {
  let scroller = ItemScroller::new()
  let total = 10
  let visible = 5
  let changed = scroller.down(2, total, visible)
  inspect(changed, content="true")
  inspect(scroller.offset.get(), content="2")
}

///|
test "ItemScroller::down: clamp to max" {
  let scroller = ItemScroller::new()
  let total = 10
  let visible = 5
  // max_offset = 10 - 5 = 5
  let changed = scroller.down(10, total, visible)
  inspect(changed, content="true")
  inspect(scroller.offset.get(), content="5")
  inspect(scroller.auto_scroll.get(), content="true") // Auto-scroll enabled at bottom
}

///|
test "ItemScroller::down: cannot scroll when already at bottom" {
  let scroller = ItemScroller::new()
  let total = 10
  let visible = 5
  scroller.offset.set(5) // Already at max
  let changed = scroller.down(1, total, visible)
  inspect(changed, content="false")
}

///|
test "ItemScroller::down: no scroll needed when items fit" {
  let scroller = ItemScroller::new()
  let total = 5
  let visible = 10
  // max_offset = 0 (all items fit)
  let changed = scroller.down(1, total, visible)
  inspect(changed, content="false")
  inspect(scroller.offset.get(), content="0")
}

///|
test "ItemScroller::to_bottom: jump to bottom" {
  let scroller = ItemScroller::new()
  scroller.to_bottom(15, 5)
  inspect(scroller.offset.get(), content="10") // 15 - 5 = 10
  inspect(scroller.auto_scroll.get(), content="true")
}

///|
test "ItemScroller::follow_bottom: auto-scroll when enabled" {
  let scroller = ItemScroller::new()
  scroller.auto_scroll.set(true)
  scroller.follow_bottom(10, 5)
  inspect(scroller.offset.get(), content="5")
}

///|
test "ItemScroller::follow_bottom: no scroll when disabled" {
  let scroller = ItemScroller::new()
  scroller.offset.set(2)
  scroller.auto_scroll.set(false)
  scroller.follow_bottom(10, 5)
  inspect(scroller.offset.get(), content="2") // Unchanged
}

///|
test "ItemScroller::can_scroll_up" {
  let scroller = ItemScroller::new()
  inspect(scroller.can_scroll_up(), content="false")
  scroller.offset.set(1)
  inspect(scroller.can_scroll_up(), content="true")
}

///|
test "ItemScroller::can_scroll_down" {
  let scroller = ItemScroller::new()
  let total = 10
  let visible = 5
  inspect(scroller.can_scroll_down(total, visible), content="true")
  scroller.offset.set(5) // At max
  inspect(scroller.can_scroll_down(total, visible), content="false")
}

///|
test "ItemScroller::slice: returns visible items" {
  let scroller = ItemScroller::new()
  let items = ["a", "b", "c", "d", "e"]
  scroller.offset.set(1)
  let visible = scroller.slice(items, 3)
  inspect(visible, content="[\"b\", \"c\", \"d\"]")
}

///|
test "ItemScroller::slice: clamps to available items" {
  let scroller = ItemScroller::new()
  let items = ["a", "b", "c"]
  scroller.offset.set(0)
  let visible = scroller.slice(items, 10)
  inspect(visible, content="[\"a\", \"b\", \"c\"]")
}

///|
test "ItemScroller::slice: offset beyond items" {
  let scroller = ItemScroller::new()
  let items = ["a", "b"]
  scroller.offset.set(5)
  let visible = scroller.slice(items, 3)
  inspect(visible, content="[]")
}

///|
test "ItemScroller::indicator: no scroll needed" {
  let scroller = ItemScroller::new()
  let indicator = scroller.indicator(5, 10)
  inspect(indicator, content="None")
}

///|
test "ItemScroller::indicator: can scroll down only" {
  let scroller = ItemScroller::new()
  let indicator = scroller.indicator(10, 5)
  inspect(indicator, content="Down")
}

///|
test "ItemScroller::indicator: can scroll both ways" {
  let scroller = ItemScroller::new()
  scroller.offset.set(2)
  let indicator = scroller.indicator(10, 5)
  inspect(indicator, content="Both")
}

///|
test "ItemScroller::indicator: can scroll up only" {
  let scroller = ItemScroller::new()
  scroller.offset.set(5) // At max (10 - 5)
  let indicator = scroller.indicator(10, 5)
  inspect(indicator, content="Up")
}
