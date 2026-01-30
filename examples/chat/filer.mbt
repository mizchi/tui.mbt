///|
/// Filer view - file tree rendering

// =============================================================================
// Rendering
// =============================================================================

///|
/// Render the filer component
fn render_filer(
  state : FilerState,
  filer_width : Int,
  filer_height : Int,
  is_focused : Bool,
) -> TuiNode {
  let border_color = if is_focused {
    "rgb(100,150,255)"
  } else {
    "rgb(60,60,60)"
  }
  let border_char = "\u{2502}"
  let content_width = filer_width - 1
  let lines : Array[TuiNode] = []
  fn make_row(content : String, fg : String) -> TuiNode {
    let padded = content +
      " ".repeat(content_width - @core.string_display_width(content))
    let truncated = truncate_filer_text(padded, content_width)
    @vnode.row(min_width=filer_width.to_double(), height=1.0, [
      @vnode.text(truncated, fg~),
      @vnode.text(border_char, fg=border_color),
    ])
  }

  // Header
  let dir_name = @ai.js_path_basename(state.current_dir)
  let header = if dir_name.length() > 0 { dir_name } else { "/" }
  let mode_indicator = if state.git_only_mode { " [G]" } else { "" }
  let git_indicator = if state.is_git_repo { "*" } else { "" }
  lines.push(
    make_row(
      " [" + header + "]" + git_indicator + mode_indicator,
      "rgb(200,200,100)",
    ),
  )

  // Parent directory entry
  lines.push(make_row(" ..", "rgb(120,120,120)"))

  // Tree items
  let visible_height = filer_height - 2
  let start_idx = state.scroll_offset
  for i = 0; i < visible_height; i = i + 1 {
    let item_idx = start_idx + i
    if item_idx < state.visible_items.length() {
      let item = state.visible_items[item_idx]
      let is_selected = item_idx == state.selected_idx && is_focused

      // Build prefix with indentation
      let indent = "  ".repeat(item.depth)
      let selector = if is_selected { ">" } else { " " }
      let git_char = item.git_status.to_char()

      // Directory indicator: [+] collapsed, [-] expanded, or just /
      let dir_indicator = if item.is_dir {
        if item.is_expanded {
          "[-]"
        } else {
          "[+]"
        }
      } else {
        "   "
      }
      let suffix = if item.is_dir { "/" } else { "" }

      // Color
      let fg = if is_selected {
        "rgb(255,255,100)"
      } else {
        match item.git_status {
          GitStatus::None =>
            if item.is_dir {
              "rgb(100,180,255)"
            } else {
              "rgb(180,180,180)"
            }
          _ => item.git_status.color()
        }
      }
      let display = selector +
        git_char +
        indent +
        dir_indicator +
        item.name +
        suffix
      lines.push(make_row(display, fg))
    } else {
      lines.push(make_row("", "rgb(60,60,60)"))
    }
  }
  @vnode.column(
    min_width=filer_width.to_double(),
    height=filer_height.to_double(),
    lines,
  )
}

// =============================================================================
// Utilities
// =============================================================================

///|
fn truncate_filer_text(text : String, max_width : Int) -> String {
  let buf = StringBuilder::new()
  let mut current_width = 0
  for c in text {
    let char_width = @core.char_display_width(c)
    if current_width + char_width > max_width {
      break
    }
    buf.write_char(c)
    current_width = current_width + char_width
  }
  buf.to_string()
}
