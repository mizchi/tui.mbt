///|
/// Tooltip API surface for editor integrations (e.g. LSP hover)

///|
pub(all) enum TooltipContent {
  Plain(String)
  Markdown(String)
}

///|
pub(all) struct Tooltip {
  title : String?
  content : TooltipContent
}

///|
pub(all) struct TooltipAnchor {
  line : Int
  col : Int
  prefer_below : Bool
}

///|
pub(all) struct TooltipRect {
  row : Int
  col : Int
}

///|
pub fn tooltip_position(
  state : EditorState,
  width : Int,
  height : Int,
  anchor : TooltipAnchor,
  tooltip_width : Int,
  tooltip_height : Int,
) -> TooltipRect {
  let (anchor_row, anchor_col) = editor_position_for(
    state,
    width,
    height,
    anchor.line,
    anchor.col,
  )
  let below = anchor_row + 1
  let above = anchor_row - tooltip_height
  let row = if anchor.prefer_below {
    if below + tooltip_height <= height { below } else { above }
  } else {
    if above >= 0 { above } else { below }
  }
  let col = if anchor_col + tooltip_width <= width {
    anchor_col
  } else {
    width - tooltip_width
  }
  let safe_row = if row < 0 { 0 } else { row }
  let safe_col = if col < 0 { 0 } else { col }
  { row: safe_row, col: safe_col }
}
