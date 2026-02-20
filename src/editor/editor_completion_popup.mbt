///|
/// Completion popup UI component

///|
pub using @components {
  type PopupRect,
  type CompletionPopupStyle,
  type PopupDirection,
}

///|
pub struct CompletionPopup {
  session : CompletionSession
  max_items : Int
  style : CompletionPopupStyle
  direction : @components.PopupDirection
}

///|
pub fn CompletionPopup::new(
  session : CompletionSession,
  max_items? : Int = 6,
  style? : CompletionPopupStyle = CompletionPopupStyle::default(),
  direction? : @components.PopupDirection = Auto,
) -> CompletionPopup {
  { session, max_items, style, direction }
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
  let (raw_width, popup_h) = @components.completion_popup_metrics(
    items,
    fn(item) { item.label },
    max_items=self.max_items,
  )
  if popup_h == 0 {
    return None
  }
  let popup_w = if raw_width > viewport_width {
    viewport_width
  } else {
    raw_width
  }
  let (rect, _) = @components.completion_popup_rect_directed(
    anchor_row,
    anchor_col,
    1,
    viewport_width,
    viewport_height,
    popup_w,
    popup_h,
    direction=self.direction,
  )
  Some(rect)
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
      let node = @components.completion_popup_node(
        items,
        fn(item) { item.label },
        self.session.get_selected_index(),
        prefix,
        rect.width,
        max_items=self.max_items,
        style=self.style,
        item_id_prefix="editor-completion-item-",
        more_id="editor-completion-more",
      )
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
