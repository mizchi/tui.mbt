///|
/// ScrollableView - renders content with vertical scrolling
/// Instead of using crater layout, renders content as lines and shows
/// only the visible portion based on scroll offset

///|
/// A line with color styling
pub(all) struct StyledLine {
  content : String
  fg : @core.Color
  bold : Bool
}

///|
pub fn StyledLine::plain(content : String) -> StyledLine {
  { content, fg: @core.Color::white(), bold: false }
}

///|
pub fn StyledLine::new(
  content : String,
  fg? : @core.Color = @core.Color::white(),
  bold? : Bool = false,
) -> StyledLine {
  { content, fg, bold }
}

///|
/// ScrollableView state
pub(all) struct ScrollableView {
  lines : Ref[Array[StyledLine]]
  offset : @signals.Signal[Int]
  auto_scroll : @signals.Signal[Bool]
  width : Ref[Int]
  visible_height : Ref[Int]
}

///|
pub fn ScrollableView::new(width : Int, visible_height : Int) -> ScrollableView {
  {
    lines: { val: [] },
    offset: @signals.signal(0),
    auto_scroll: @signals.signal(true),
    width: { val: width },
    visible_height: { val: visible_height },
  }
}

///|
pub fn ScrollableView::resize(
  self : ScrollableView,
  width : Int,
  visible_height : Int,
) -> Unit {
  self.width.val = width
  self.visible_height.val = visible_height
  // Adjust offset if needed
  let max = self.max_offset()
  if self.offset.get() > max {
    self.offset.set(max)
  }
}

///|
/// Set content lines
pub fn ScrollableView::set_lines(
  self : ScrollableView,
  lines : Array[StyledLine],
) -> Unit {
  self.lines.val = lines
  if self.auto_scroll.get() {
    self.to_bottom()
  }
}

///|
/// Get total line count
pub fn ScrollableView::total_lines(self : ScrollableView) -> Int {
  self.lines.val.length()
}

///|
/// Get max scroll offset
pub fn ScrollableView::max_offset(self : ScrollableView) -> Int {
  let total = self.total_lines()
  let visible = self.visible_height.val
  if total > visible {
    total - visible
  } else {
    0
  }
}

///|
/// Scroll up by n lines
pub fn ScrollableView::up(self : ScrollableView, n : Int) -> Bool {
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
pub fn ScrollableView::down(self : ScrollableView, n : Int) -> Bool {
  let max = self.max_offset()
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
pub fn ScrollableView::to_bottom(self : ScrollableView) -> Unit {
  self.offset.set(self.max_offset())
  self.auto_scroll.set(true)
}

///|
/// Follow bottom (auto-scroll when enabled)
pub fn ScrollableView::follow_bottom(self : ScrollableView) -> Unit {
  if self.auto_scroll.get() {
    self.to_bottom()
  }
}

///|
/// Check if can scroll up
pub fn ScrollableView::can_scroll_up(self : ScrollableView) -> Bool {
  self.offset.get() > 0
}

///|
/// Check if can scroll down
pub fn ScrollableView::can_scroll_down(self : ScrollableView) -> Bool {
  self.offset.get() < self.max_offset()
}

///|
/// Get visible height
pub fn ScrollableView::get_visible_height(self : ScrollableView) -> Int {
  self.visible_height.val
}

///|
/// Get width
pub fn ScrollableView::get_width(self : ScrollableView) -> Int {
  self.width.val
}

///|
/// Wrap text to fit within width, handling newlines
pub fn wrap_text(text : String, width : Int) -> Array[String] {
  let result : Array[String] = []
  if width <= 0 {
    result.push(text)
    return result
  }

  // Split by newlines first
  let paragraphs = text.split("\n").collect()
  for para in paragraphs {
    if para.length() == 0 {
      result.push("")
    } else {
      // Wrap this paragraph
      let line = StringBuilder::new()
      let mut col = 0
      for c in para {
        let cw = @core.char_display_width(c)
        if col + cw > width && col > 0 {
          result.push(line.to_string())
          line.reset()
          col = 0
        }
        line.write_char(c)
        col = col + cw
      }
      if col > 0 {
        result.push(line.to_string())
      }
    }
  }
  if result.is_empty() {
    result.push("")
  }
  result
}
