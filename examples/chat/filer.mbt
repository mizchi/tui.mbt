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
  let border_color = if is_focused { "rgb(100,150,255)" } else { "rgb(60,60,60)" }
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
        if item.is_expanded { "[-]" } else { "[+]" }
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
            if item.is_dir { "rgb(100,180,255)" } else { "rgb(180,180,180)" }
          _ => item.git_status.color()
        }
      }

      let display = selector + git_char + indent + dir_indicator + item.name + suffix
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

///|
fn get_diff_line_color(line : String) -> String {
  if line.length() == 0 {
    return "rgb(180,180,180)"
  }
  match line[0] {
    '+' => "rgb(100,255,100)"
    '-' => "rgb(255,100,100)"
    '@' => "rgb(100,180,255)"
    _ => "rgb(180,180,180)"
  }
}

///|
fn render_file_preview(
  state : FilerState,
  preview_width : Int,
  preview_height : Int,
) -> TuiNode {
  let lines : Array[TuiNode] = []

  if state.preview_file.length() == 0 {
    lines.push(
      @vnode.row(min_width=preview_width.to_double(), height=1.0, [
        @vnode.text(" [No file selected]", fg="rgb(100,100,100)"),
      ]),
    )
    for i = 1; i < preview_height; i = i + 1 {
      lines.push(@vnode.row(height=1.0, []))
    }
  } else {
    let filename = @ai.js_path_basename(state.preview_file)
    let content_lines : Array[String] = state.preview_content
      .split("\n")
      .map(fn(s) { s.to_string() })
      .collect()
    let highlight_data = if state.preview_is_diff {
      PreviewHighlight::Tm([])
    } else {
      highlight_lines_for_preview(content_lines, state.preview_file)
    }
    let highlight_theme = preview_theme()
    let syntree_theme = syntree_theme()
    let total_lines = content_lines.length()
    let scroll_info = if total_lines > preview_height - 1 {
      " [" +
      (state.preview_scroll_offset + 1).to_string() +
      "-" +
      (state.preview_scroll_offset + preview_height - 1).to_string() +
      "/" +
      total_lines.to_string() +
      "]"
    } else {
      ""
    }
    let header_text = if state.preview_is_diff {
      " [DIFF] " + filename + scroll_info
    } else {
      " " + filename + scroll_info
    }
    let header_color = if state.preview_is_diff {
      "rgb(255,200,100)"
    } else {
      "rgb(200,200,100)"
    }
    lines.push(
      @vnode.row(min_width=preview_width.to_double(), height=1.0, [
        @vnode.text(
          truncate_filer_text(header_text, preview_width - 1),
          fg=header_color,
        ),
      ]),
    )

    let content_height = preview_height - 1
    let scroll_offset = state.preview_scroll_offset
    for i = 0; i < content_height; i = i + 1 {
      let line_idx = scroll_offset + i
      if line_idx < content_lines.length() {
        if state.preview_is_diff {
          let line = truncate_filer_text(content_lines[line_idx], preview_width - 1)
          let fg = get_diff_line_color(content_lines[line_idx])
          lines.push(
            @vnode.row(min_width=preview_width.to_double(), height=1.0, [
              @vnode.text(" " + line, fg~),
            ]),
          )
        } else {
          match highlight_data {
            PreviewHighlight::Syntree(s_lines) => {
              let s_line = s_lines[line_idx]
              let row_nodes = render_syntree_line(
                s_line,
                syntree_theme,
                preview_width - 1,
              )
              lines.push(
                @vnode.row(
                  min_width=preview_width.to_double(),
                  height=1.0,
                  row_nodes,
                ),
              )
            }
            PreviewHighlight::Tm(tm_lines) => {
              let term_line = tm_lines[line_idx]
              let row_nodes = render_highlight_line(
                term_line,
                highlight_theme,
                preview_width - 1,
              )
              lines.push(
                @vnode.row(
                  min_width=preview_width.to_double(),
                  height=1.0,
                  row_nodes,
                ),
              )
            }
          }
        }
      } else {
        lines.push(@vnode.row(height=1.0, []))
      }
    }
  }

  @vnode.column(
    min_width=preview_width.to_double(),
    height=preview_height.to_double(),
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
