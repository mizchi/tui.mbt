///|
enum HighlightKind {
  TypeScript
}

///|
struct HighlightSpan {
  text : String
  tag : @syntree.HighlightTag
}

///|
struct HighlightState {
  kind : HighlightKind
  mut line_cache : @syntree.LineCache?
  mut spans : Array[Array[HighlightSpan]]
}

///|
fn highlight_theme() -> @syn_highlight.HighlightTheme {
  @syn_highlight.one_dark_pro()
}

///|
fn hex_value(c : Char) -> Int? {
  if c.is_ascii_digit() {
    Some(c.to_int() - '0'.to_int())
  } else if c.is_ascii_lowercase() {
    Some(c.to_int() - 'a'.to_int() + 10)
  } else if c.is_ascii_uppercase() {
    Some(c.to_int() - 'A'.to_int() + 10)
  } else {
    None
  }
}

///|
fn hex_pair(a : Char, b : Char) -> Int? {
  match (hex_value(a), hex_value(b)) {
    (Some(hi), Some(lo)) => Some(hi * 16 + lo)
    _ => None
  }
}

///|
fn normalize_color(color : String) -> String {
  if color.length() == 0 {
    return ""
  }
  if color.has_prefix("#") {
    let chars : Array[Char] = color.iter().collect()
    if chars.length() == 4 {
      let r = hex_value(chars[1]).unwrap_or(0)
      let g = hex_value(chars[2]).unwrap_or(0)
      let b = hex_value(chars[3]).unwrap_or(0)
      return "rgb(\{r * 17},\{g * 17},\{b * 17})"
    }
    if chars.length() == 7 {
      let r = hex_pair(chars[1], chars[2]).unwrap_or(0)
      let g = hex_pair(chars[3], chars[4]).unwrap_or(0)
      let b = hex_pair(chars[5], chars[6]).unwrap_or(0)
      return "rgb(\{r},\{g},\{b})"
    }
  }
  color
}

///|
fn highlight_color(
  theme : @syn_highlight.HighlightTheme,
  tag : @syntree.HighlightTag,
) -> String {
  let raw = theme.get_color(tag)
  let color = normalize_color(raw)
  if color.length() == 0 {
    "white"
  } else {
    color
  }
}

///|
fn HighlightState::new(kind : HighlightKind, doc : Document) -> HighlightState {
  let text = doc.to_text()
  let cache = match kind {
    TypeScript => Some(@syntree.LineCache::new(text, @syn_ts.highlight_typescript))
  }
  let state : HighlightState = { kind, line_cache: cache, spans: [] }
  state.rebuild(doc)
  state
}

///|
fn HighlightState::line_spans(
  self : HighlightState,
  line : Int,
) -> Array[HighlightSpan] {
  if line >= 0 && line < self.spans.length() {
    self.spans[line]
  } else {
    []
  }
}

///|
fn HighlightState::update(
  self : HighlightState,
  doc : Document,
  edit_line : Int,
) -> Unit {
  match self.kind {
    TypeScript => {
      match self.line_cache {
        Some(cache) => {
          let _ = cache.update(doc.to_text(), edit_line, @syn_ts.highlight_typescript)
          ()
        }
        None => {
          self.line_cache = Some(
            @syntree.LineCache::new(doc.to_text(), @syn_ts.highlight_typescript),
          )
        }
      }
    }
  }
  self.rebuild(doc)
}

///|
fn HighlightState::rebuild(self : HighlightState, doc : Document) -> Unit {
  match self.kind {
    TypeScript => {
      match self.line_cache {
        Some(cache) => {
          let tokens = cache.all_tokens()
          self.spans = build_highlight_line_spans(doc, tokens)
        }
        None => {
          self.spans = build_plain_spans(doc)
        }
      }
    }
  }
}

///|
fn build_plain_spans(doc : Document) -> Array[Array[HighlightSpan]] {
  let result : Array[Array[HighlightSpan]] = []
  for line in doc.lines {
    let span : HighlightSpan = { text: line, tag: @syntree.HighlightTag::None }
    result.push([span])
  }
  result
}

///|
fn compute_line_starts(lines : Array[String]) -> Array[Int] {
  let starts : Array[Int] = []
  let mut offset = 0
  for i, line in lines {
    starts.push(offset)
    offset = offset + line.length()
    if i + 1 < lines.length() {
      offset = offset + 1
    }
  }
  starts
}

///|
fn build_char_offsets(text : String) -> Array[Int] {
  let offsets : Array[Int] = []
  let mut pos = 0
  offsets.push(0)
  for c in text {
    pos = pos + c.utf16_len()
    offsets.push(pos)
  }
  offsets
}

///|
fn to_utf16_offset(offsets : Array[Int], pos : Int, text_len : Int) -> Int {
  if pos <= 0 {
    0
  } else if pos >= offsets.length() {
    text_len
  } else {
    offsets[pos]
  }
}

///|
///|
fn build_highlight_line_spans(
  doc : Document,
  tokens : Array[@syntree.HighlightToken],
) -> Array[Array[HighlightSpan]] {
  let lines = doc.lines
  let starts = compute_line_starts(lines)
  let text = doc.to_text()
  let text_len = text.length()
  let offsets = build_char_offsets(text)
  let result : Array[Array[HighlightSpan]] = []
  let mut token_idx = 0
  for line_idx in 0..<lines.length() {
    let line_text = lines[line_idx]
    let line_start = starts[line_idx]
    let line_end = line_start + line_text.length()
    let spans : Array[HighlightSpan] = []
    let mut cursor = 0
    while token_idx < tokens.length() {
      let token = tokens[token_idx]
      let token_to = to_utf16_offset(offsets, token.to, text_len)
      if token_to <= line_start {
        token_idx = token_idx + 1
      } else {
        break
      }
    }
    let mut idx = token_idx
    while idx < tokens.length() {
      let token = tokens[idx]
      let token_from = to_utf16_offset(offsets, token.from, text_len)
      let token_to = to_utf16_offset(offsets, token.to, text_len)
      if token_from >= line_end {
        break
      }
      let start_col = if token_from < line_start {
        0
      } else {
        token_from - line_start
      }
      let end_col = if token_to > line_end {
        line_end - line_start
      } else {
        token_to - line_start
      }
      if end_col <= cursor {
        idx = idx + 1
        continue
      }
      let safe_start = if start_col < cursor { cursor } else { start_col }
      if safe_start > cursor {
        let text = line_text.unsafe_substring(start=cursor, end=safe_start)
        spans.push({ text, tag: @syntree.HighlightTag::None })
      }
      if end_col > safe_start {
        let text = line_text.unsafe_substring(start=safe_start, end=end_col)
        spans.push({ text, tag: token.tag })
        cursor = end_col
      }
      if token_to > line_end {
        break
      }
      idx = idx + 1
    }
    if cursor < line_text.length() {
      let text = line_text.unsafe_substring(start=cursor, end=line_text.length())
      spans.push({ text, tag: @syntree.HighlightTag::None })
    }
    result.push(spans)
    token_idx = idx
  }
  result
}
