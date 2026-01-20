///|
/// Item-based scroller - simpler concept for scrolling through items
///
/// Concepts:
/// - total_items: number of items in the list
/// - visible_count: maximum number of items to display at once
/// - offset: index of the first visible item (0 = top)

///|
/// Simple item scroller state
pub(all) struct ItemScroller {
  /// Current offset (index of first visible item)
  offset : @signals.Signal[Int]
  /// Auto-scroll to bottom when new items added
  auto_scroll : @signals.Signal[Bool]
}

///|
pub fn ItemScroller::new() -> ItemScroller {
  { offset: @signals.signal(0), auto_scroll: @signals.signal(true) }
}

///|
/// Calculate max offset
/// total_items: number of items
/// visible_count: number of items that can be displayed
fn calc_max_offset(total_items : Int, visible_count : Int) -> Int {
  if total_items > visible_count {
    total_items - visible_count
  } else {
    0
  }
}

///|
/// Scroll up by n items
pub fn ItemScroller::up(self : ItemScroller, n : Int) -> Bool {
  let current = self.offset.get()
  if current > 0 {
    let new_offset = if current >= n { current - n } else { 0 }
    self.offset.set(new_offset)
    self.auto_scroll.set(false)
    true
  } else {
    false
  }
}

///|
/// Scroll down by n items
pub fn ItemScroller::down(
  self : ItemScroller,
  n : Int,
  total_items : Int,
  visible_count : Int,
) -> Bool {
  let max = calc_max_offset(total_items, visible_count)
  let current = self.offset.get()
  if current < max {
    let new_offset = if current + n > max { max } else { current + n }
    self.offset.set(new_offset)
    if new_offset >= max {
      self.auto_scroll.set(true)
    }
    true
  } else {
    false
  }
}

///|
/// Jump to bottom
pub fn ItemScroller::to_bottom(
  self : ItemScroller,
  total_items : Int,
  visible_count : Int,
) -> Unit {
  let max = calc_max_offset(total_items, visible_count)
  self.offset.set(max)
  self.auto_scroll.set(true)
}

///|
/// Auto-scroll to bottom if enabled
pub fn ItemScroller::follow_bottom(
  self : ItemScroller,
  total_items : Int,
  visible_count : Int,
) -> Unit {
  if self.auto_scroll.get() {
    self.to_bottom(total_items, visible_count)
  }
}

///|
/// Check if can scroll up
pub fn ItemScroller::can_scroll_up(self : ItemScroller) -> Bool {
  self.offset.get() > 0
}

///|
/// Check if can scroll down
pub fn ItemScroller::can_scroll_down(
  self : ItemScroller,
  total_items : Int,
  visible_count : Int,
) -> Bool {
  self.offset.get() < calc_max_offset(total_items, visible_count)
}

///|
/// Get visible slice of items
pub fn[T] ItemScroller::slice(
  self : ItemScroller,
  items : Array[T],
  visible_count : Int,
) -> Array[T] {
  let offset = self.offset.get()
  let result : Array[T] = []
  for i, item in items {
    if i >= offset && result.length() < visible_count {
      result.push(item)
    }
  }
  result
}

///|
/// Scroll indicator for item scroller
pub fn ItemScroller::indicator(
  self : ItemScroller,
  total_items : Int,
  visible_count : Int,
) -> ScrollIndicator {
  let can_up = self.can_scroll_up()
  let can_down = self.can_scroll_down(total_items, visible_count)
  if can_up && can_down {
    ScrollIndicator::Both
  } else if can_up {
    ScrollIndicator::Up
  } else if can_down {
    ScrollIndicator::Down
  } else {
    ScrollIndicator::None
  }
}
