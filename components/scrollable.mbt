///|
/// ScrollableList - Scrollable list component with auto-scroll support

///|
/// Scroll state for managing scrollable content
pub(all) struct ScrollState {
  /// Current scroll offset (0 = top)
  offset : @signals.Signal[Int]
  /// Auto-scroll enabled (follows new content when at bottom)
  auto_scroll : @signals.Signal[Bool]
}

///|
/// Create a new scroll state
pub fn ScrollState::new() -> ScrollState {
  { offset: @signals.signal(0), auto_scroll: @signals.signal(true) }
}

///|
/// Create scroll state with initial values
pub fn ScrollState::with_values(
  offset : Int,
  auto_scroll : Bool,
) -> ScrollState {
  { offset: @signals.signal(offset), auto_scroll: @signals.signal(auto_scroll) }
}

///|
/// Calculate max scroll offset
/// total_lines: total number of content lines
/// visible_height: number of visible lines (excluding scroll indicator)
/// reserve_indicator: whether to reserve 1 line for scroll indicator
pub fn calc_max_scroll(
  total_lines : Int,
  visible_height : Int,
  reserve_indicator? : Bool = true,
) -> Int {
  let content_height = if reserve_indicator && total_lines > visible_height {
    visible_height - 1
  } else {
    visible_height
  }
  if total_lines > content_height {
    total_lines - content_height
  } else {
    0
  }
}

///|
/// Check if scroll is at bottom
pub fn ScrollState::is_at_bottom(
  self : ScrollState,
  total_lines : Int,
  visible_height : Int,
) -> Bool {
  let max = calc_max_scroll(total_lines, visible_height)
  self.offset.get() >= max
}

///|
/// Scroll up by given amount
/// Returns true if scroll position changed
pub fn ScrollState::scroll_up(self : ScrollState, amount : Int) -> Bool {
  let current = self.offset.get()
  if current > 0 {
    let new_offset = if current >= amount { current - amount } else { 0 }
    self.offset.set(new_offset)
    self.auto_scroll.set(false) // Disable auto-scroll when user scrolls up
    true
  } else {
    false
  }
}

///|
/// Scroll down by given amount
/// Returns true if scroll position changed
pub fn ScrollState::scroll_down(
  self : ScrollState,
  amount : Int,
  total_lines : Int,
  visible_height : Int,
) -> Bool {
  let max = calc_max_scroll(total_lines, visible_height)
  let current = self.offset.get()
  if current < max {
    let new_offset = if current + amount > max { max } else { current + amount }
    self.offset.set(new_offset)
    // Re-enable auto-scroll if at bottom
    if new_offset >= max {
      self.auto_scroll.set(true)
    }
    true
  } else {
    false
  }
}

///|
/// Scroll to bottom
pub fn ScrollState::scroll_to_bottom(
  self : ScrollState,
  total_lines : Int,
  visible_height : Int,
) -> Unit {
  let max = calc_max_scroll(total_lines, visible_height)
  self.offset.set(max)
  self.auto_scroll.set(true)
}

///|
/// Auto-scroll to bottom if enabled
/// Call this when new content is added
pub fn ScrollState::auto_scroll_to_bottom(
  self : ScrollState,
  total_lines : Int,
  visible_height : Int,
) -> Unit {
  if self.auto_scroll.get() {
    let max = calc_max_scroll(total_lines, visible_height)
    self.offset.set(max)
  }
}

///|
/// Reset scroll state (scroll to top, enable auto-scroll)
pub fn ScrollState::reset(self : ScrollState) -> Unit {
  self.offset.set(0)
  self.auto_scroll.set(true)
}

///|
/// Scroll indicator type
pub(all) enum ScrollIndicator {
  None
  Up
  Down
  Both
} derive(Show)

///|
/// Get scroll indicator based on current position
pub fn ScrollState::get_indicator(
  self : ScrollState,
  total_lines : Int,
  visible_height : Int,
) -> ScrollIndicator {
  let max = calc_max_scroll(total_lines, visible_height)
  if max == 0 {
    ScrollIndicator::None
  } else {
    let offset = self.offset.get()
    if offset > 0 && offset < max {
      ScrollIndicator::Both
    } else if offset > 0 {
      ScrollIndicator::Up
    } else {
      ScrollIndicator::Down
    }
  }
}

///|
/// Get scroll indicator text
pub fn scroll_indicator_text(indicator : ScrollIndicator) -> String {
  match indicator {
    ScrollIndicator::None => ""
    ScrollIndicator::Up => "↑ scroll"
    ScrollIndicator::Down => "↓ scroll"
    ScrollIndicator::Both => "↑↓ scroll"
  }
}

///|
/// Scroll indicator component
pub fn scroll_indicator(
  indicator : ScrollIndicator,
  fg? : @core.Color = @core.Color::rgb(80, 80, 80),
) -> @core.Component {
  text(scroll_indicator_text(indicator), fg~)
}

///|
/// Apply scroll offset to an array of items
/// Returns the visible slice based on scroll offset and visible height
pub fn[T] apply_scroll(
  items : Array[T],
  offset : Int,
  visible_height : Int,
  reserve_indicator? : Bool = true,
) -> Array[T] {
  let total = items.length()
  let has_scroll = total > visible_height
  let content_height = if reserve_indicator && has_scroll {
    visible_height - 1
  } else {
    visible_height
  }
  let result : Array[T] = []
  let mut added = 0
  for i, item in items {
    if i >= offset && added < content_height {
      result.push(item)
      added = added + 1
    }
  }
  result
}

///|
/// Scrollable list component
/// items: array of components to display
/// state: scroll state
/// visible_height: number of visible lines
/// show_indicator: whether to show scroll indicator
pub fn scrollable_list(
  items : Array[@core.Component],
  state : ScrollState,
  visible_height : Int,
  show_indicator? : Bool = true,
  indicator_fg? : @core.Color = @core.Color::rgb(80, 80, 80),
) -> Array[@core.Component] {
  let total = items.length()
  let offset = state.offset.get()
  let visible = apply_scroll(items, offset, visible_height)
  if show_indicator {
    let indicator = state.get_indicator(total, visible_height)
    match indicator {
      ScrollIndicator::None => visible
      _ => {
        visible.push(scroll_indicator(indicator, fg=indicator_fg))
        visible
      }
    }
  } else {
    visible
  }
}

///|
/// Build a vertical scrollbar string for the given height
/// Returns an array of single-character strings, one per line
pub fn build_scrollbar(
  offset : Int,
  total_items : Int,
  visible_count : Int,
  height : Int,
  track_char? : String = "│",
  thumb_char? : String = "┃",
) -> Array[String] {
  let result : Array[String] = []
  if total_items <= visible_count || height <= 0 {
    // No scrolling needed - return empty track
    for _i = 0; _i < height; _i = _i + 1 {
      result.push(track_char)
    }
    return result
  }

  // Calculate thumb size (minimum 1 line)
  let thumb_height = {
    let h = height * visible_count / total_items
    if h < 1 {
      1
    } else {
      h
    }
  }

  // Calculate thumb position
  let max_offset = total_items - visible_count
  let scrollable_range = height - thumb_height
  let thumb_pos = if max_offset > 0 {
    offset * scrollable_range / max_offset
  } else {
    0
  }

  // Build the scrollbar
  for i = 0; i < height; i = i + 1 {
    if i >= thumb_pos && i < thumb_pos + thumb_height {
      result.push(thumb_char)
    } else {
      result.push(track_char)
    }
  }
  result
}

///|
/// Scrollbar component - renders a vertical scrollbar as a text_box
/// Note: track_color is kept for API compatibility but text_box uses single color
pub fn scrollbar(
  offset : Int,
  total_items : Int,
  visible_count : Int,
  height : Int,
  track_color? : @core.Color = @core.Color::rgb(60, 60, 60),
  thumb_color? : @core.Color = @core.Color::rgb(120, 120, 120),
  track_char? : String = "│",
  thumb_char? : String = "┃",
) -> @core.Component {
  let _ = track_color // Reserved for future per-line coloring
  let lines = build_scrollbar(
    offset,
    total_items,
    visible_count,
    height,
    track_char~,
    thumb_char~,
  )
  // Join lines with newlines to create a multi-line string
  let content = lines
    .iter()
    .fold(init="", fn(acc, s) {
      if acc.length() == 0 {
        s
      } else {
        acc + "\n" + s
      }
    })
  // Use text_box for proper height/width handling
  // Color the whole scrollbar with thumb_color for visibility
  @core.text_box(
    content,
    fg=thumb_color,
    width=@types.Dimension::Length(1.0),
    height=@types.Dimension::Length(height.to_double()),
  )
}
