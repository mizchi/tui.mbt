///|
/// Tests for LineScroller - line-based scrolling

///|
test "LineScroller: initial state" {
  let scroller = LineScroller::new()
  inspect(scroller.offset.get(), content="0")
  inspect(scroller.auto_scroll.get(), content="true")
}

///|
test "LineScroller: scroll up from top does nothing" {
  let scroller = LineScroller::new()
  let moved = scroller.up(1)
  inspect(moved, content="false")
  inspect(scroller.offset.get(), content="0")
}

///|
test "LineScroller: scroll down when content fits does nothing" {
  let scroller = LineScroller::new()
  // 10 lines of content, 20 lines visible
  let moved = scroller.down(1, 10, 20)
  inspect(moved, content="false")
  inspect(scroller.offset.get(), content="0")
}

///|
test "LineScroller: scroll down when content exceeds visible" {
  let scroller = LineScroller::new()
  // 30 lines of content, 10 lines visible, max_offset = 20
  let moved = scroller.down(5, 30, 10)
  inspect(moved, content="true")
  inspect(scroller.offset.get(), content="5")
}

///|
test "LineScroller: scroll up after scrolling down" {
  let scroller = LineScroller::new()
  // First scroll down
  ignore(scroller.down(10, 30, 10))
  inspect(scroller.offset.get(), content="10")

  // Then scroll up
  let moved = scroller.up(3)
  inspect(moved, content="true")
  inspect(scroller.offset.get(), content="7")
}

///|
test "LineScroller: follow_bottom scrolls to end" {
  let scroller = LineScroller::new()
  scroller.follow_bottom(30, 10)
  // max_offset = 30 - 10 = 20
  inspect(scroller.offset.get(), content="20")
}

///|
test "LineScroller: auto_scroll disabled after manual scroll up" {
  let scroller = LineScroller::new()
  scroller.follow_bottom(30, 10)
  inspect(scroller.auto_scroll.get(), content="true")
  ignore(scroller.up(1))
  inspect(scroller.auto_scroll.get(), content="false")
}

///|
test "LineScroller: auto_scroll re-enabled when reaching bottom" {
  let scroller = LineScroller::new()
  scroller.follow_bottom(30, 10)
  ignore(scroller.up(5))
  inspect(scroller.auto_scroll.get(), content="false")

  // Scroll back down to bottom
  ignore(scroller.down(10, 30, 10))
  inspect(scroller.auto_scroll.get(), content="true")
}

///|
test "LineScroller: can_scroll_up and can_scroll_down" {
  let scroller = LineScroller::new()
  // At top
  inspect(scroller.can_scroll_up(), content="false")
  inspect(scroller.can_scroll_down(30, 10), content="true")

  // Move to middle
  ignore(scroller.down(10, 30, 10))
  inspect(scroller.can_scroll_up(), content="true")
  inspect(scroller.can_scroll_down(30, 10), content="true")

  // Move to bottom
  scroller.to_bottom(30, 10)
  inspect(scroller.can_scroll_up(), content="true")
  inspect(scroller.can_scroll_down(30, 10), content="false")
}

///|
test "LineScroller: slice with heights" {
  let scroller = LineScroller::new()
  let items = ["A", "B", "C", "D", "E"]
  let heights = [3, 2, 4, 2, 3] // total = 14 lines
  let visible_height = 6

  // At offset 0, should get first items that fit in 6 lines
  let result1 = scroller.slice(items, heights, visible_height)
  // A (3) + B (2) = 5 lines, adding C (4) would be 9, so we get A, B, C
  inspect(result1.length(), content="3")

  // Scroll down 5 lines
  ignore(scroller.down(5, 14, visible_height))
  let result2 = scroller.slice(items, heights, visible_height)
  // At offset 5: A ends at 3, B ends at 5, so C starts at offset 5
  // Should get C (4) + D (2) = 6, then E would overflow
  inspect(result2.length() >= 2, content="true")
}

///|
test "calc_text_lines: single line" {
  inspect(calc_text_lines("Hello", 80), content="1")
}

///|
test "calc_text_lines: multiple lines from newlines" {
  inspect(calc_text_lines("Line1\nLine2\nLine3", 80), content="3")
}

///|
test "calc_text_lines: wrapping" {
  // 10 char line, width 5 -> wraps to 2 lines
  inspect(calc_text_lines("1234567890", 5), content="2")
}

///|
test "calc_text_lines: CJK wrapping" {
  // 5 CJK chars (10 display width), width 6 -> wraps
  // あ(2) + い(2) + う(2) = 6, wraps
  // え(2) + お(2) = 4
  inspect(calc_text_lines("あいうえお", 6), content="2")
}

///|
test "calc_labeled_block_lines: simple content" {
  // Label (1 line) + content (1 line) = 2 lines
  inspect(calc_labeled_block_lines("Hello", 80, "   "), content="2")
}

///|
test "calc_labeled_block_lines: multiline content" {
  // Label (1 line) + content (2 lines from newline) = 3 lines
  inspect(calc_labeled_block_lines("Line1\nLine2", 80, "   "), content="3")
}
