///|
/// Generic completion popup helpers (rendering + layout)

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
fn clamp_min(value : Int, min_value : Int) -> Int {
  if value < min_value {
    min_value
  } else {
    value
  }
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
fn take_display_width(text : String, max_width : Int) -> String {
  if max_width <= 0 {
    return ""
  }
  let chars = text.to_array()
  let buf = StringBuilder::new()
  let mut used = 0
  for i = 0; i < chars.length(); i = i + 1 {
    let c = chars[i]
    let w = @core.string_display_width(c.to_string())
    if used + w > max_width {
      return buf.to_string()
    }
    buf.write_char(c)
    used = used + w
  }
  buf.to_string()
}

///|
fn more_label(more_count : Int) -> String {
  "..." + more_count.to_string() + " more"
}

///|
/// Public helper for "more" row label
pub fn completion_popup_more_label(more_count : Int) -> String {
  more_label(more_count)
}

///|
/// Compute popup width/height from items and label function.
/// Use with completion_popup_rect for placement.
pub fn[T] completion_popup_metrics(
  items : Array[T],
  label_fn : (T) -> String,
  max_items? : Int = 6,
  min_width? : Int = 4,
  show_more? : Bool = false,
) -> (Int, Int) {
  let len = items.length()
  if len == 0 {
    return (0, 0)
  }
  let safe_max = clamp_min(max_items, 1)
  let safe_min_width = clamp_min(min_width, 1)
  let visible = if len > safe_max { safe_max } else { len }
  let has_more = show_more && len > safe_max
  let mut width = safe_min_width
  for item in items {
    let w = @core.string_display_width(label_fn(item))
    if w > width {
      width = w
    }
  }
  if has_more {
    let label = completion_popup_more_label(len - safe_max)
    let w = @core.string_display_width(label)
    if w > width {
      width = w
    }
  }
  let height = visible + (if has_more { 1 } else { 0 })
  (width, height)
}

///|
fn render_item(
  idx : Int,
  selected_idx : Int,
  prefix : String,
  width : Int,
  label : String,
  item_id : String,
  item_role : String,
  style : CompletionPopupStyle,
) -> @vnode.TuiNode {
  let is_selected = idx == selected_idx
  let bg = if is_selected { style.selected_bg } else { style.normal_bg }
  let display_label = take_display_width(label, width)
  let prefix_len = prefix.to_array().length()
  let (head, tail) = split_by_chars(display_label, prefix_len)
  let suffix_width = width - @core.string_display_width(head)
  let suffix = pad_to_width(tail, suffix_width)
  let fg_suffix = if is_selected {
    style.selected_suffix_fg
  } else {
    style.normal_suffix_fg
  }
  @vnode.row(
    id=item_id,
    role=item_role,
    bg~,
    [
      @vnode.text(head, fg=style.prefix_fg, bold=is_selected),
      @vnode.text(suffix, fg=fg_suffix),
    ],
  )
}

///|
fn render_more_row(
  more_count : Int,
  width : Int,
  style : CompletionPopupStyle,
  item_id : String,
  item_role : String,
) -> @vnode.TuiNode {
  let label = take_display_width(completion_popup_more_label(more_count), width)
  let padding = pad_to_width("", width - @core.string_display_width(label))
  @vnode.row(id=item_id, role=item_role, bg=style.normal_bg, [
    @vnode.text(label + padding, fg=style.normal_suffix_fg),
  ])
}

///|
/// Low-level helper to build list nodes from items.
/// Prefer completion_popup_node for standard popups.
pub fn[T] completion_popup_list_nodes(
  items : Array[T],
  selected_idx : Int,
  width : Int,
  render_item : (T, Int, Int, Int) -> @vnode.TuiNode,
  max_items? : Int = 6,
  show_more? : Bool = false,
  render_more? : (Int, Int) -> @vnode.TuiNode = fn(_, _) { @vnode.text("") },
) -> Array[@vnode.TuiNode] {
  if items.length() == 0 || width <= 0 {
    return []
  }
  let safe_max = clamp_min(max_items, 1)
  let count = if items.length() > safe_max { safe_max } else { items.length() }
  let nodes : Array[@vnode.TuiNode] = []
  for i = 0; i < count; i = i + 1 {
    nodes.push(render_item(items[i], i, selected_idx, width))
  }
  if show_more && items.length() > safe_max {
    nodes.push(render_more(items.length() - safe_max, width))
  }
  nodes
}

///|
/// Build a standard completion popup list.
/// For a11y, provide item_id_prefix to avoid id collisions.
///
/// # Example
/// ```mbt nocheck
/// let items = ["apple", "apricot", "avocado"]
///
/// let node = @components.completion_popup_node(
///   items,
///   fn(item) { item },
///   0,
///   "ap",
///   10,
///   max_items=5,
///   show_more=true,
///   item_id_prefix="completion-item-",
/// )
/// ```
pub fn[T] completion_popup_node(
  items : Array[T],
  label_fn : (T) -> String,
  selected_idx : Int,
  prefix : String,
  width : Int,
  max_items? : Int = 6,
  show_more? : Bool = false,
  style? : CompletionPopupStyle = CompletionPopupStyle::default(),
  item_id_prefix? : String = "",
  item_role? : String = "option",
  more_id? : String = "",
  more_role? : String = "status",
) -> @vnode.TuiNode {
  if items.length() == 0 || width <= 0 {
    return @vnode.text("")
  }
  let nodes = completion_popup_list_nodes(
    items,
    selected_idx,
    width,
    fn(item, idx, selected_idx, width) {
      let label = label_fn(item)
      let item_id = if item_id_prefix.length() > 0 {
        item_id_prefix + idx.to_string()
      } else {
        ""
      }
      render_item(
        idx, selected_idx, prefix, width, label, item_id, item_role, style,
      )
    },
    max_items~,
    show_more~,
    render_more=fn(more_count, width) {
      let more_item_id = if more_id.length() > 0 {
        more_id
      } else if item_id_prefix.length() > 0 {
        item_id_prefix + "more"
      } else {
        ""
      }
      render_more_row(more_count, width, style, more_item_id, more_role)
    },
  )
  @vnode.column(nodes)
}

///|
pub fn completion_popup_rect(
  anchor_row : Int,
  anchor_col : Int,
  anchor_height : Int,
  viewport_width : Int,
  viewport_height : Int,
  popup_width : Int,
  popup_height : Int,
  prefer_below? : Bool = true,
) -> PopupRect {
  let safe_width = if popup_width < 0 { 0 } else { popup_width }
  let safe_height = if popup_height < 0 { 0 } else { popup_height }
  let below = anchor_row + anchor_height
  let above = anchor_row - safe_height
  let row = if prefer_below {
    if below + safe_height <= viewport_height {
      below
    } else {
      above
    }
  } else if above >= 0 {
    above
  } else {
    below
  }
  let col = if anchor_col + safe_width <= viewport_width {
    anchor_col
  } else {
    viewport_width - safe_width
  }
  let safe_row = if row < 0 { 0 } else { row }
  let safe_col = if col < 0 { 0 } else { col }
  { row: safe_row, col: safe_col, width: safe_width, height: safe_height }
}
