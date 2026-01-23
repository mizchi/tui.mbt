///|
/// Tests for chat scrollbar visibility conditions

///|
test "scrollbar visibility: not shown when items fit" {
  let total = 3
  let visible_count = 5
  let is_streaming = false
  let show_scrollbar = total > visible_count && not(is_streaming)
  inspect(show_scrollbar, content="false")
}

///|
test "scrollbar visibility: shown when items exceed visible" {
  let total = 10
  let visible_count = 5
  let is_streaming = false
  let show_scrollbar = total > visible_count && not(is_streaming)
  inspect(show_scrollbar, content="true")
}

///|
test "scrollbar visibility: not shown during streaming" {
  let total = 10
  let visible_count = 5
  let is_streaming = true
  let show_scrollbar = total > visible_count && not(is_streaming)
  inspect(show_scrollbar, content="false")
}

///|
test "scrollbar visibility: not shown during streaming even with many items" {
  let total = 100
  let visible_count = 5
  let is_streaming = true
  let show_scrollbar = total > visible_count && not(is_streaming)
  inspect(show_scrollbar, content="false")
}

///|
test "content width: full width when no scrollbar" {
  let w = 80
  let total = 3
  let visible_count = 5
  let is_streaming = false
  let show_scrollbar = total > visible_count && not(is_streaming)
  let content_width = if show_scrollbar { w - 1 } else { w }
  inspect(content_width, content="80")
}

///|
test "content width: reduced width when scrollbar shown" {
  let w = 80
  let total = 10
  let visible_count = 5
  let is_streaming = false
  let show_scrollbar = total > visible_count && not(is_streaming)
  let content_width = if show_scrollbar { w - 1 } else { w }
  inspect(content_width, content="79")
}

///|
test "content width: full width during streaming" {
  let w = 80
  let total = 10
  let visible_count = 5
  let is_streaming = true
  let show_scrollbar = total > visible_count && not(is_streaming)
  let content_width = if show_scrollbar { w - 1 } else { w }
  inspect(content_width, content="80")
}

///|
test "ItemScroller with scrollbar: thumb position changes on scroll" {
  let scroller = ItemScroller::new()
  let total = 20
  let visible = 5
  let height = 10

  // Start at bottom
  scroller.to_bottom(total, visible)
  let offset1 = scroller.offset.get()
  inspect(offset1, content="15")

  // Build scrollbar at bottom
  let bar1 = build_scrollbar(offset1, total, visible, height)
  // At max offset, thumb should be at bottom
  inspect(bar1[8], content="┃")
  inspect(bar1[9], content="┃")

  // Scroll up
  ignore(scroller.up(5))
  let offset2 = scroller.offset.get()
  inspect(offset2, content="10")

  // Build scrollbar after scroll
  let bar2 = build_scrollbar(offset2, total, visible, height)
  // Thumb position = 10 * 8 / 15 = 5
  inspect(bar2[5], content="┃")
  inspect(bar2[6], content="┃")
}
