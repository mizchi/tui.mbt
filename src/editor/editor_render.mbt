using @vnode { type TuiNode, column, row, text }

///|
priv struct RenderSegment {
  text : String
  tag : @syntree.HighlightTag
  is_caret : Bool
}

///|
fn truncate_spans(
  spans : Array[HighlightSpan],
  max_width : Int,
) -> Array[HighlightSpan] {
  if max_width <= 0 {
    return []
  }
  let result : Array[HighlightSpan] = []
  let mut remaining = max_width
  for span in spans {
    if remaining <= 0 {
      break
    }
    let span_width = @core.string_display_width(span.text)
    if span_width <= remaining {
      result.push(span)
      remaining = remaining - span_width
    } else {
      let text = take_display_width(span.text, remaining)
      if text.length() > 0 {
        result.push({ text, tag: span.tag })
      }
      break
    }
  }
  result
}

///|
fn take_display_width(text : String, max_width : Int) -> String {
  if max_width <= 0 {
    return ""
  }
  let sb = StringBuilder::new()
  let mut width = 0
  for c in text {
    let w = @core.char_display_width(c)
    if width + w > max_width {
      break
    }
    sb.write_char(c)
    width = width + w
  }
  sb.to_string()
}

///|
fn display_width_prefix(text : String, char_count : Int) -> Int {
  if char_count <= 0 {
    return 0
  }
  let chars = text.to_array()
  let limit = if char_count > chars.length() { chars.length() } else { char_count }
  let mut width = 0
  for i in 0..<limit {
    width = width + @core.char_display_width(chars[i])
  }
  width
}

///|
fn apply_caret(
  spans : Array[HighlightSpan],
  caret_col : Int,
  line_length : Int,
) -> Array[RenderSegment] {
  let result : Array[RenderSegment] = []
  let mut pos = 0
  for span in spans {
    let len = span.text.length()
    let start = pos
    let end = pos + len
    if caret_col < start || caret_col >= end {
      result.push({ text: span.text, tag: span.tag, is_caret: false })
    } else {
      let before_len = caret_col - start
      let after_len = end - caret_col - 1
      if before_len > 0 {
        let text = span.text.unsafe_substring(start=0, end=before_len)
        result.push({ text, tag: span.tag, is_caret: false })
      }
      let caret_text = span.text.unsafe_substring(start=before_len, end=before_len + 1)
      result.push({ text: caret_text, tag: span.tag, is_caret: true })
      if after_len > 0 {
        let text = span.text.unsafe_substring(start=before_len + 1, end=len)
        result.push({ text, tag: span.tag, is_caret: false })
      }
    }
    pos = end
  }
  if caret_col >= line_length {
    result.push({ text: " ", tag: @syntree.HighlightTag::None, is_caret: true })
  }
  result
}

///|
fn render_segments(
  segments : Array[RenderSegment],
  theme : @syn_highlight.HighlightTheme,
) -> Array[TuiNode] {
  let nodes : Array[TuiNode] = []
  for seg in segments {
    let fg = highlight_color(theme, seg.tag)
    if seg.is_caret {
      nodes.push(
        @vnode.row(bg="rgb(220,220,220)", [
          text(seg.text, fg="rgb(20,20,20)"),
        ]),
      )
    } else {
      nodes.push(text(seg.text, fg=fg))
    }
  }
  if nodes.length() == 0 {
    nodes.push(text(" "))
  }
  nodes
}

///|
fn pad_left(text_ : String, width : Int) -> String {
  let len = text_.length()
  if len >= width {
    text_
  } else {
    " ".repeat(width - len) + text_
  }
}

///|
fn render_line(
  line_idx : Int,
  line_text : String,
  spans : Array[HighlightSpan],
  caret : Position,
  theme : @syn_highlight.HighlightTheme,
  gutter_width : Int,
  content_width : Int,
) -> TuiNode {
  let truncated = truncate_spans(spans, content_width)
  let mut segments : Array[RenderSegment] = []
  if caret.line == line_idx {
    segments = apply_caret(truncated, caret.col, line_text.length())
  } else {
    for span in truncated {
      segments.push({ text: span.text, tag: span.tag, is_caret: false })
    }
  }
  let gutter_text = pad_left((line_idx + 1).to_string(), gutter_width)
  row(
    height=1.0,
    gap=0.0,
    [
      text(gutter_text + " ", fg="rgb(120,120,120)"),
      row(gap=0.0, render_segments(segments, theme)),
    ],
  )
}

///|
pub fn render_editor(
  state : EditorState,
  width : Int,
  height : Int,
  show_header~ : Bool = true,
  show_footer~ : Bool = true,
  title~ : String = "",
) -> TuiNode {
  let header_height = if show_header { 1 } else { 0 }
  let footer_height = if show_footer { 1 } else { 0 }
  let content_height = if height - header_height - footer_height > 0 {
    height - header_height - footer_height
  } else {
    1
  }
  let total_lines = state.doc.line_count()
  let gutter_width = total_lines.to_string().length()
  // gutter takes gutter_width + 1 characters (line number + space)
  let content_width = if width - gutter_width - 1 > 0 {
    width - gutter_width - 1
  } else {
    1
  }
  let (start, end) = state.viewport.range(total_lines)
  let theme = highlight_theme()
  let rows : Array[TuiNode] = []
  for line_idx in start..<end {
    let line_text = state.doc.line(line_idx)
    let spans = state.highlight.line_spans(line_idx)
    rows.push(
      render_line(
        line_idx,
        line_text,
        spans,
        state.selection.active,
        theme,
        gutter_width,
        content_width,
      ),
    )
  }
  while rows.length() < content_height {
    rows.push(row(height=1.0, [text(" ")]))
  }
  let result : Array[TuiNode] = []
  if show_header {
    let header_text = if title.length() > 0 { " " + title + " " } else { " editor " }
    result.push(
      row(
        bg="rgb(30,30,40)",
        height=1.0,
        [text(header_text, fg="rgb(180,180,180)", bold=true)],
      ),
    )
  }
  result.push(column(rows))
  if show_footer {
    let caret = state.selection.active
    let status = "Ln \{caret.line + 1}, Col \{caret.col + 1}"
    result.push(
      row(
        bg="rgb(30,30,40)",
        height=1.0,
        [text(" " + status, fg="rgb(160,160,160)")],
      ),
    )
  }
  column(result)
}

///|
pub fn editor_cursor_position(
  state : EditorState,
  width : Int,
  height : Int,
  show_header~ : Bool = true,
  show_footer~ : Bool = true,
) -> (Int, Int) {
  let caret = state.selection.active
  editor_position_for(state, width, height, caret.line, caret.col, show_header~, show_footer~)
}

///|
pub fn editor_position_for(
  state : EditorState,
  width : Int,
  height : Int,
  line : Int,
  col : Int,
  show_header~ : Bool = true,
  show_footer~ : Bool = true,
) -> (Int, Int) {
  let header_height = if show_header { 1 } else { 0 }
  let footer_height = if show_footer { 1 } else { 0 }
  let content_height = if height - header_height - footer_height > 0 {
    height - header_height - footer_height
  } else {
    1
  }
  let total_lines = state.doc.line_count()
  let gutter_width = total_lines.to_string().length()
  // gutter takes gutter_width + 1 characters (line number + space)
  let content_width = if width - gutter_width - 1 > 0 {
    width - gutter_width - 1
  } else {
    1
  }
  let (start, end) = state.viewport.range(total_lines)
  let target_line = if line < start {
    start
  } else if line >= end {
    end - 1
  } else {
    line
  }
  let row = header_height + (target_line - start)
  let line_text = state.doc.line(target_line)
  let display_col = display_width_prefix(line_text, col)
  let col_in_line = if display_col < content_width {
    display_col
  } else {
    content_width - 1
  }
  let col = gutter_width + 1 + col_in_line
  let max_row = header_height + content_height - 1
  let safe_row = if row < 0 { 0 } else if row > max_row { max_row } else { row }
  let safe_col = if col < 0 { 0 } else if col >= width { width - 1 } else { col }
  (safe_row, safe_col)
}
