///|
/// Search-related components

///|
/// Search input field with prompt, cursor, and placeholder
pub fn search_input(
  query : String,
  id? : String = "",
  prompt? : String = "> ",
  placeholder? : String = "Type to search...",
  prompt_fg? : String = "yellow",
  text_fg? : String = "white",
  placeholder_fg? : String = "rgb(100,100,100)",
  cursor_fg? : String = "cyan",
  show_cursor? : Bool = true,
) -> @vnode.TuiNode {
  let display_text = if query.length() > 0 { query } else { placeholder }
  let text_color = if query.length() > 0 { text_fg } else { placeholder_fg }
  let children : Array[@vnode.TuiNode] = [
    @vnode.text(prompt, fg=prompt_fg, bold=true),
    @vnode.text(display_text, fg=text_color),
  ]
  if show_cursor {
    children.push(@vnode.text("_", fg=cursor_fg))
  }
  @vnode.row(id~, padding_x=1.0, padding_y=0.5, children~)
}

///|
/// Text with highlighted prefix (for search results)
pub fn highlight_text(
  text : String,
  highlight_len : Int,
  id? : String = "",
  highlight_fg? : String = "cyan",
  text_fg? : String = "white",
  highlight_bold? : Bool = true,
) -> @vnode.TuiNode {
  if highlight_len <= 0 || highlight_len > text.length() {
    return @vnode.row(id~, children=[@vnode.text(text, fg=text_fg)])
  }
  let prefix = text.unsafe_substring(start=0, end=highlight_len)
  let suffix = text.unsafe_substring(start=highlight_len, end=text.length())
  @vnode.row(id~, children=[
    @vnode.text(prefix, fg=highlight_fg, bold=highlight_bold),
    @vnode.text(suffix, fg=text_fg),
  ])
}

///|
/// Selectable list item with highlight support
pub fn search_result_item(
  text : String,
  selected : Bool,
  highlight_len? : Int = 0,
  id? : String = "",
  icon? : String = "",
  selected_bg? : String = "rgb(30,80,120)",
  normal_bg? : String = "rgb(40,40,50)",
  selected_fg? : String = "cyan",
  normal_fg? : String = "white",
  icon_fg? : String = "cyan",
) -> @vnode.TuiNode {
  let bg = if selected { selected_bg } else { normal_bg }
  let fg = if selected { selected_fg } else { normal_fg }
  let children : Array[@vnode.TuiNode] = []
  if icon.length() > 0 {
    children.push(@vnode.text(" " + icon + " ", fg=icon_fg))
  }
  if highlight_len > 0 {
    children.push(
      highlight_text(
        text,
        highlight_len,
        highlight_fg=selected_fg,
        text_fg=fg,
        highlight_bold=selected,
      ),
    )
  } else {
    children.push(@vnode.text(text, fg~, bold=selected))
  }
  @vnode.row(id~, bg~, padding_x=0.5, children~)
}
