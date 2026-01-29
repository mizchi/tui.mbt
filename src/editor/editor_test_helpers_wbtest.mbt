///|
fn spans_to_line(spans : Array[HighlightSpan]) -> String {
  let sb = StringBuilder::new()
  for span in spans {
    sb.write_string(span.text)
  }
  sb.to_string()
}

///|
fn spans_signature(spans : Array[HighlightSpan]) -> String {
  let sb = StringBuilder::new()
  for i, span in spans {
    if i > 0 {
      sb.write_char('|')
    }
    sb.write_string(span.tag.to_string())
    sb.write_char(':')
    sb.write_string(span.text)
  }
  sb.to_string()
}

///|
fn assert_spans_match_lines(
  lines : Array[String],
  spans : Array[Array[HighlightSpan]],
) -> Unit raise {
  assert_eq(lines.length(), spans.length())
  for i in 0..<lines.length() {
    let reconstructed = spans_to_line(spans[i])
    assert_eq(reconstructed, lines[i])
  }
}

///|
fn assert_spans_equal(a : Array[Array[HighlightSpan]], b : Array[Array[HighlightSpan]]) -> Unit raise {
  assert_eq(a.length(), b.length())
  for i in 0..<a.length() {
    assert_eq(spans_signature(a[i]), spans_signature(b[i]))
  }
}

///|
fn strip_ansi(s : String) -> String {
  let chars = s.to_array()
  let sb = StringBuilder::new()
  let mut i = 0
  while i < chars.length() {
    if chars[i] == '\u001b' {
      if i + 1 < chars.length() && chars[i + 1] == '[' {
        i = i + 2
        while i < chars.length() && chars[i] != 'm' {
          i = i + 1
        }
        if i < chars.length() {
          i = i + 1
        }
      } else {
        i = i + 1
      }
    } else {
      sb.write_char(chars[i])
      i = i + 1
    }
  }
  sb.to_string()
}

///|
fn render_lines_plain(state : EditorState, width : Int, height : Int) -> Array[String] {
  let node = render_editor(state, width, height)
  let plain = @vnode.render_to_lines(node).map((line) => strip_ansi(line))
  restore_caret_in_lines(plain, state, width)
}

///|
fn render_lines_ansi(state : EditorState, width : Int, height : Int) -> Array[String] {
  let node = render_editor(state, width, height)
  @vnode.render_to_lines(node)
}

///|
fn restore_caret_in_lines(
  lines : Array[String],
  state : EditorState,
  width : Int,
) -> Array[String] {
  let header_height = 1
  let total_lines = state.doc.line_count()
  let gutter_width = total_lines.to_string().length()
  let content_width = if width - gutter_width - 2 > 0 {
    width - gutter_width - 2
  } else {
    1
  }
  let (start, end) = state.viewport.range(total_lines)
  let caret = state.selection.active
  if caret.line < start || caret.line >= end {
    return lines
  }
  if caret.col < 0 || caret.col >= content_width {
    return lines
  }
  let render_idx = header_height + (caret.line - start)
  if render_idx < 0 || render_idx >= lines.length() {
    return lines
  }
  let row_chars = lines[render_idx].to_array()
  let line_text = state.doc.line(caret.line)
  let caret_render_col = gutter_width + 1 +
    display_width_prefix(line_text, caret.col)
  if caret_render_col < 0 || caret_render_col >= row_chars.length() {
    return lines
  }
  let replacement = if caret.col < line_text.length() {
    let text_chars = line_text.to_array()
    text_chars[caret.col]
  } else {
    ' '
  }
  row_chars[caret_render_col] = replacement
  let sb = StringBuilder::new()
  for ch in row_chars {
    sb.write_char(ch)
  }
  lines[render_idx] = sb.to_string()
  lines
}

///|
fn assert_position_in_doc(doc : Document, pos : Position) -> Unit raise {
  let line_count = doc.line_count()
  if pos.line < 0 || pos.line >= line_count {
    fail("position out of range: line=\{pos.line} total=\{line_count}")
  }
  let line_len = doc.line_length(pos.line)
  if pos.col < 0 || pos.col > line_len {
    fail("position out of range: col=\{pos.col} line_len=\{line_len}")
  }
}

///|
fn assert_selection_invariants(state : EditorState) -> Unit raise {
  assert_position_in_doc(state.doc, state.selection.anchor)
  assert_position_in_doc(state.doc, state.selection.active)
  let (start, end) = state.selection.ordered()
  if !position_before_or_equal(start, end) {
    fail("selection order invalid: \{start} > \{end}")
  }
}

///|
fn assert_viewport_invariants(state : EditorState) -> Unit raise {
  let height = state.viewport.height
  if height < 1 {
    fail("viewport height invalid: \{height}")
  }
  let total = state.doc.line_count()
  let max_top = if total > height { total - height } else { 0 }
  let top = state.viewport.top
  if top < 0 || top > max_top {
    fail("viewport top invalid: top=\{top} max=\{max_top}")
  }
}

///|
fn assert_state_invariants(state : EditorState) -> Unit raise {
  assert_selection_invariants(state)
  assert_viewport_invariants(state)
  assert_eq(state.doc.line_count(), state.highlight.spans.length())
  assert_spans_match_lines(state.doc.lines, state.highlight.spans)
}
