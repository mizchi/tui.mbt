///|
fn spans_to_line(spans : Array[HighlightSpan]) -> String {
  let sb = StringBuilder::new()
  for span in spans {
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
fn render_lines(state : EditorState, width : Int, height : Int) -> Array[String] {
  let node = render_editor(state, width, height)
  @vnode.render_to_lines(node).map((line) => strip_ansi(line))
}

///|
test "highlight spans keep line text after edit" {
  let text =
    #|type User = {
    #|  id: number
    #|  name: string
    #|}
    #|
    #|const user: User = { id: 1, name: "mizchi" }
    #|
    #|function greet(name: string): string {
    #|  return `Hello, ${name}`
    #|}
    #|
    #|console.log(greet(user.name))
    #|
  let doc = Document::from_text(text)
  let cache = @syntree.LineCache::new(doc.to_text(), @syn_ts.highlight_typescript)
  let spans = build_highlight_line_spans(doc, cache.all_tokens())
  assert_spans_match_lines(doc.lines, spans)

  let _ = doc.insert_text({ line: 4, col: 2 }, "aaaaaaa")
  let _ = cache.update(doc.to_text(), 4, @syn_ts.highlight_typescript)
  let spans_after = build_highlight_line_spans(doc, cache.all_tokens())
  assert_spans_match_lines(doc.lines, spans_after)
}

///|
test "highlight after edit matches full retokenize" {
  let text =
    #|const value = 1
    #|const name = "editor"
    #|
    #|function greet(msg: string): string {
    #|  return msg + name
    #|}
    #|
    #|console.log(greet("hi"))
    #|
  let doc = Document::from_text(text)
  let cache = @syntree.LineCache::new(doc.to_text(), @syn_ts.highlight_typescript)
  let _ = doc.insert_text({ line: 1, col: 13 }, "`")
  let _ = doc.insert_text({ line: 1, col: 14 }, "value")
  let _ = doc.insert_text({ line: 1, col: 19 }, "`")
  let _ = cache.update(doc.to_text(), 1, @syn_ts.highlight_typescript)
  let spans_updated = build_highlight_line_spans(doc, cache.all_tokens())
  let fresh_cache = @syntree.LineCache::new(doc.to_text(), @syn_ts.highlight_typescript)
  let spans_fresh = build_highlight_line_spans(doc, fresh_cache.all_tokens())
  assert_spans_equal(spans_updated, spans_fresh)
}

///|
test "unchanged lines keep highlight after edit" {
  let text =
    #|type User = {
    #|  id: number
    #|  name: string
    #|}
    #|
    #|const user: User = { id: 1, name: "mizchi" }
    #|
    #|function greet(name: string): string {
    #|  return `Hello, ${name}`
    #|}
    #|
    #|console.log(greet(user.name))
    #|
  let doc = Document::from_text(text)
  let cache = @syntree.LineCache::new(doc.to_text(), @syn_ts.highlight_typescript)
  let spans_before = build_highlight_line_spans(doc, cache.all_tokens())
  let _ = doc.insert_text({ line: 4, col: 2 }, "aaaaaaa")
  let _ = cache.update(doc.to_text(), 4, @syn_ts.highlight_typescript)
  let spans_after = build_highlight_line_spans(doc, cache.all_tokens())
  assert_spans_match_lines(doc.lines, spans_after)
  let line_count = doc.line_count()
  for line_idx in 5..<line_count {
    assert_eq(
      spans_signature(spans_after[line_idx]),
      spans_signature(spans_before[line_idx]),
    )
  }
}

///|
test "rendered lines after edit keep unchanged content" {
  let text =
    #|type User = {
    #|  id: number
    #|  name: string
    #|}
    #|
    #|const user: User = { id: 1, name: "mizchi" }
    #|
    #|function greet(name: string): string {
    #|  return `Hello, ${name}`
    #|}
    #|
    #|console.log(greet(user.name))
    #|
  let height = 15
  let width = 80
  let state = EditorState::new(text, height)
  let before = render_lines(state, width, height)
  state.replace_selection("aaaa")
  let after = render_lines(state, width, height)
  // Skip header/footer; compare visible body lines after the edit line.
  let body_start = 1
  let edit_line = 0
  let total_lines = state.doc.line_count()
  let last_line = if total_lines < height - 1 { total_lines } else { height - 2 }
  for line_idx in (edit_line + 1)..<last_line {
    let render_idx = body_start + line_idx
    assert_eq(after[render_idx], before[render_idx])
  }
}

///|
test "highlight update matches full after varied edits" {
  let text =
    #|type User = {
    #|  id: number
    #|  name: string
    #|}
    #|
    #|const user: User = { id: 1, name: "mizchi" }
    #|
    #|function greet(name: string): string {
    #|  return `Hello, ${name}`
    #|}
    #|
    #|console.log(greet(user.name))
    #|
  let base_doc = Document::from_text(text)
  let line_count = base_doc.line_count()
  for line_idx in 0..<line_count {
    let line_len = base_doc.line_length(line_idx)
    let cols : Array[Int] = [
      0,
      line_len / 2,
      line_len,
    ]
    for col in cols {
      let doc = Document::from_text(text)
      let state = HighlightState::new(HighlightKind::TypeScript, doc)
      let _ = doc.insert_text({ line: line_idx, col }, "x")
      state.update(doc, line_idx)
      let fresh = @syntree.LineCache::new(doc.to_text(), @syn_ts.highlight_typescript)
      let spans_fresh = build_highlight_line_spans(doc, fresh.all_tokens())
      for i in 0..<state.spans.length() {
        let a = spans_signature(state.spans[i])
        let b = spans_signature(spans_fresh[i])
        if a != b {
          fail("mismatch at line \{line_idx} col \{col} => line \{i}: \{a} != \{b}")
        }
      }

      let doc2 = Document::from_text(text)
      let state2 = HighlightState::new(HighlightKind::TypeScript, doc2)
      let _ = doc2.insert_text({ line: line_idx, col }, "\n")
      state2.update(doc2, line_idx)
      let fresh2 = @syntree.LineCache::new(doc2.to_text(), @syn_ts.highlight_typescript)
      let spans_fresh2 = build_highlight_line_spans(doc2, fresh2.all_tokens())
      for i in 0..<state2.spans.length() {
        let a = spans_signature(state2.spans[i])
        let b = spans_signature(spans_fresh2[i])
        if a != b {
          fail("mismatch newline at line \{line_idx} col \{col} => line \{i}: \{a} != \{b}")
        }
      }
    }
  }
}
