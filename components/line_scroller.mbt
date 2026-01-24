///|
/// Line-based scroller - scrolls by actual line count, not item count
///
/// Unlike ItemScroller which assumes fixed item heights,
/// LineScroller calculates actual line heights for each item

///|
/// Line scroller state
pub(all) struct LineScroller {
  /// Current scroll offset in lines (0 = top)
  offset : @signals.Signal[Int]
  /// Auto-scroll to bottom when new content added
  auto_scroll : @signals.Signal[Bool]
}

///|
pub fn LineScroller::new() -> LineScroller {
  { offset: @signals.signal(0), auto_scroll: @signals.signal(true) }
}

///|
/// Calculate max line scroll offset
fn line_scroller_max_offset(total_lines : Int, visible_height : Int) -> Int {
  if total_lines > visible_height {
    total_lines - visible_height
  } else {
    0
  }
}

///|
/// Scroll up by n lines
pub fn LineScroller::up(self : LineScroller, n : Int) -> Bool {
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
/// Scroll down by n lines
pub fn LineScroller::down(
  self : LineScroller,
  n : Int,
  total_lines : Int,
  visible_height : Int,
) -> Bool {
  let max = line_scroller_max_offset(total_lines, visible_height)
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
pub fn LineScroller::to_bottom(
  self : LineScroller,
  total_lines : Int,
  visible_height : Int,
) -> Unit {
  let max = line_scroller_max_offset(total_lines, visible_height)
  self.offset.set(max)
  self.auto_scroll.set(true)
}

///|
/// Auto-scroll to bottom if enabled
pub fn LineScroller::follow_bottom(
  self : LineScroller,
  total_lines : Int,
  visible_height : Int,
) -> Unit {
  if self.auto_scroll.get() {
    self.to_bottom(total_lines, visible_height)
  }
}

///|
/// Check if can scroll up
pub fn LineScroller::can_scroll_up(self : LineScroller) -> Bool {
  self.offset.get() > 0
}

///|
/// Check if can scroll down
pub fn LineScroller::can_scroll_down(
  self : LineScroller,
  total_lines : Int,
  visible_height : Int,
) -> Bool {
  self.offset.get() < line_scroller_max_offset(total_lines, visible_height)
}

///|
/// Get visible slice of items based on line offset
/// Returns (items_to_show, skip_lines_in_first_item)
/// heights: array of line heights for each item
/// visible_height: number of lines to show
pub fn[T] LineScroller::slice_with_offset(
  self : LineScroller,
  items : Array[T],
  heights : Array[Int],
  visible_height : Int,
) -> (Array[T], Int) {
  let offset = self.offset.get()
  let result : Array[T] = []

  // Find first visible item
  let mut line_count = 0
  let mut start_idx = 0
  let mut skip_lines = 0

  // Find which item contains the offset line
  for i, h in heights {
    if line_count + h > offset {
      start_idx = i
      skip_lines = offset - line_count
      break
    }
    line_count = line_count + h
    start_idx = i + 1
  }

  // Collect items that fit in visible_height
  let mut visible_lines = 0
  for i = start_idx
      i < items.length() && visible_lines < visible_height
      i = i + 1 {
    result.push(items[i])
    let h = if i < heights.length() { heights[i] } else { 1 }
    visible_lines = visible_lines + h
  }
  (result, skip_lines)
}

///|
/// Simpler slice that returns just the visible items
/// (without partial item handling)
pub fn[T] LineScroller::slice(
  self : LineScroller,
  items : Array[T],
  heights : Array[Int],
  visible_height : Int,
) -> Array[T] {
  let (result, _) = self.slice_with_offset(items, heights, visible_height)
  result
}

///|
/// Calculate line height for text content
/// width: available width for text
/// text: the text content
pub fn calc_text_lines(text : String, width : Int) -> Int {
  if width <= 0 {
    return 1
  }
  let mut lines = 1
  let mut col = 0
  for c in text {
    if c == '\n' {
      lines = lines + 1
      col = 0
    } else {
      let w = @core.char_display_width(c)
      if col + w > width {
        lines = lines + 1
        col = w
      } else {
        col = col + w
      }
    }
  }
  lines
}

///|
/// Calculate height for a labeled block (icon + label + content)
/// indent: indentation string (e.g. "   ")
pub fn calc_labeled_block_lines(
  content : String,
  width : Int,
  indent : String,
) -> Int {
  let indent_width = @core.string_display_width(indent)
  let content_width = width - indent_width
  // 1 line for label + lines for content
  1 + calc_text_lines(content, content_width)
}
