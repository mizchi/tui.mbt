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
    let len = span.text.length()
    if len <= remaining {
      result.push(span)
      remaining = remaining - len
    } else {
      let text = span.text.unsafe_substring(start=0, end=remaining)
      result.push({ text, tag: span.tag })
      break
    }
  }
  result
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
pub fn render_editor(state : EditorState, width : Int, height : Int) -> TuiNode {
  let header_height = 1
  let footer_height = 1
  let content_height = if height - header_height - footer_height > 0 {
    height - header_height - footer_height
  } else {
    1
  }
  let total_lines = state.doc.line_count()
  let gutter_width = total_lines.to_string().length()
  let content_width = if width - gutter_width - 2 > 0 {
    width - gutter_width - 2
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
  let caret = state.selection.active
  let status = "Ln \{caret.line + 1}, Col \{caret.col + 1}"
  column([
    row(
      bg="rgb(30,30,40)",
      height=1.0,
      [text(" examples/editor ", fg="rgb(180,180,180)", bold=true)],
    ),
    column(rows),
    row(
      bg="rgb(30,30,40)",
      height=1.0,
      [text(" " + status, fg="rgb(160,160,160)")],
    ),
  ])
}
