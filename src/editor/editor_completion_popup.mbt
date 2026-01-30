///|
/// Completion popup UI component

///|
pub struct PopupRect {
  row : Int
  col : Int
  width : Int
  height : Int
}

///|
pub fn PopupRect::eq(self : PopupRect, other : PopupRect) -> Bool {
  self.row == other.row &&
  self.col == other.col &&
  self.width == other.width &&
  self.height == other.height
}

///|
fn split_by_chars(text : String, count : Int) -> (String, String) {
  let chars = text.to_array()
  let limit = if count < 0 {
    0
  } else if count > chars.length() {
    chars.length()
  } else {
    count
  }
  let head = StringBuilder::new()
  let tail = StringBuilder::new()
  for i = 0; i < chars.length(); i = i + 1 {
    if i < limit {
      head.write_char(chars[i])
    } else {
      tail.write_char(chars[i])
    }
  }
  (head.to_string(), tail.to_string())
}

///|
fn pad_to_width(text : String, width : Int) -> String {
  if width <= 0 {
    ""
  } else {
    let w = @core.string_display_width(text)
    if w >= width {
      text
    } else {
      text + " ".repeat(width - w)
    }
  }
}

///|
pub struct CompletionPopupStyle {
  selected_bg : String
  normal_bg : String
  prefix_fg : String
  selected_suffix_fg : String
  normal_suffix_fg : String
}

///|
pub fn CompletionPopupStyle::default() -> CompletionPopupStyle {
  {
    selected_bg: "rgb(30,80,120)",
    normal_bg: "rgb(60,60,60)",
    prefix_fg: "cyan",
    selected_suffix_fg: "white",
    normal_suffix_fg: "rgb(150,150,150)",
  }
}

///|
pub struct CompletionPopup {
  session : CompletionSession
  max_items : Int
  style : CompletionPopupStyle
}

///|
pub fn CompletionPopup::new(
  session : CompletionSession,
  max_items? : Int = 6,
  style? : CompletionPopupStyle = CompletionPopupStyle::default(),
) -> CompletionPopup {
  { session, max_items, style }
}

///|
fn CompletionPopup::popup_width(self : CompletionPopup) -> Int {
  let items = self.session.get_items()
  let mut max_width = 0
  for item in items {
    let w = @core.string_display_width(item.label)
    if w > max_width {
      max_width = w
    }
  }
  if max_width < 4 {
    4
  } else {
    max_width
  }
}

///|
fn CompletionPopup::popup_height(self : CompletionPopup) -> Int {
  let items = self.session.get_items()
  if items.length() > self.max_items {
    self.max_items
  } else {
    items.length()
  }
}

///|
fn CompletionPopup::render_item(
  self : CompletionPopup,
  item : CompletionItem,
  idx : Int,
  prefix : String,
  width : Int,
) -> @vnode.TuiNode {
  let is_selected = idx == self.session.get_selected_index()
  let bg = if is_selected {
    self.style.selected_bg
  } else {
    self.style.normal_bg
  }
  let prefix_len = prefix.to_array().length()
  let label = item.label
  let (head, tail) = split_by_chars(label, prefix_len)
  let suffix_width = width - @core.string_display_width(head)
  let suffix = pad_to_width(tail, suffix_width)
  let fg_suffix = if is_selected {
    self.style.selected_suffix_fg
  } else {
    self.style.normal_suffix_fg
  }
  @vnode.row(bg~, [
    @vnode.text(head, fg=self.style.prefix_fg, bold=is_selected),
    @vnode.text(suffix, fg=fg_suffix),
  ])
}

///|
fn CompletionPopup::render_items(
  self : CompletionPopup,
  prefix : String,
  width : Int,
) -> @vnode.TuiNode {
  let items = self.session.get_items()
  if items.length() == 0 {
    return @vnode.text("")
  }
  let count = if items.length() > self.max_items {
    self.max_items
  } else {
    items.length()
  }
  let nodes : Array[@vnode.TuiNode] = []
  for i = 0; i < count; i = i + 1 {
    nodes.push(self.render_item(items[i], i, prefix, width))
  }
  @vnode.column(nodes)
}

///|
/// Calculate popup position based on anchor and viewport
pub fn CompletionPopup::calculate_rect(
  self : CompletionPopup,
  anchor_row : Int,
  anchor_col : Int,
  viewport_width : Int,
  viewport_height : Int,
) -> PopupRect? {
  let items = self.session.get_items()
  if items.length() == 0 || not(self.session.is_visible()) {
    return None
  }
  let popup_h = self.popup_height()
  let raw_width = self.popup_width()
  let popup_w = if raw_width > viewport_width {
    viewport_width
  } else {
    raw_width
  }
  let below = anchor_row + 1
  let popup_row = if below + popup_h <= viewport_height {
    below
  } else {
    anchor_row - popup_h
  }
  let popup_col = if anchor_col + popup_w <= viewport_width {
    anchor_col
  } else {
    viewport_width - popup_w
  }
  let safe_row = if popup_row < 0 { 0 } else { popup_row }
  let safe_col = if popup_col < 0 { 0 } else { popup_col }
  Some({ row: safe_row, col: safe_col, width: popup_w, height: popup_h })
}

///|
/// Render the popup at calculated position
/// Returns (rendered_node, rect) or None if not visible
pub fn CompletionPopup::render(
  self : CompletionPopup,
  state : EditorState,
  viewport_width : Int,
  viewport_height : Int,
) -> (@vnode.TuiNode, PopupRect)? {
  if not(self.session.is_visible()) {
    return None
  }
  let items = self.session.get_items()
  if items.length() == 0 {
    return None
  }
  let anchor = self.session.get_anchor()
  let (anchor_row, anchor_col) = editor_position_for(
    state,
    viewport_width,
    viewport_height,
    anchor.line,
    anchor.col,
  )
  match
    self.calculate_rect(anchor_row, anchor_col, viewport_width, viewport_height) {
    Some(rect) => {
      let prefix = state.current_word_prefix()
      let node = self.render_items(prefix, rect.width)
      Some((node, rect))
    }
    None => None
  }
}

///|
/// Render popup as overlay at absolute position
pub fn CompletionPopup::render_overlay(
  self : CompletionPopup,
  state : EditorState,
  viewport_width : Int,
  viewport_height : Int,
) -> (String, PopupRect)? {
  match self.render(state, viewport_width, viewport_height) {
    Some((node, rect)) => {
      let overlay = @vnode.render_overlay_at(rect.col, rect.row, node)
      Some((overlay, rect))
    }
    None => None
  }
}
