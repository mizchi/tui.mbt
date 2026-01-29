///|
/// Syntree-based syntax highlighting for preview

// =============================================================================
// Types
// =============================================================================

///|
struct SyntreeSegment {
  text : String
  tag : @syntree.HighlightTag
}

///|
struct SyntreeLine {
  segments : Array[SyntreeSegment]
}

// =============================================================================
// JS helpers
// =============================================================================

///|
extern "js" fn js_string_slice_local(
  input : String,
  start : Int,
  end_ : Int,
) -> String =
  #| (input, start, end) => {
  #|   try {
  #|     return input.slice(start, end);
  #|   } catch (e) {
  #|     return '';
  #|   }
  #| }

// =============================================================================
// Utilities
// =============================================================================

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
fn hex_value(c : Char) -> Int? {
  if c >= '0' && c <= '9' {
    return Some(c.to_int() - '0'.to_int())
  }
  if c >= 'a' && c <= 'f' {
    return Some(10 + (c.to_int() - 'a'.to_int()))
  }
  if c >= 'A' && c <= 'F' {
    return Some(10 + (c.to_int() - 'A'.to_int()))
  }
  None
}

///|
fn hex_pair(a : Char, b : Char) -> Int? {
  match (hex_value(a), hex_value(b)) {
    (Some(x), Some(y)) => Some(x * 16 + y)
    _ => None
  }
}

///|
fn truncate_by_width(text : String, max_width : Int) -> (String, Int) {
  let buf = StringBuilder::new()
  let mut width = 0
  for c in text {
    let w = @core.char_display_width(c)
    if width + w > max_width {
      break
    }
    buf.write_char(c)
    width = width + w
  }
  (buf.to_string(), width)
}

// =============================================================================
// Tokenization
// =============================================================================

///|
fn syntree_tokens_for_extension(
  ext : String,
  text : String,
) -> Array[@syntree.HighlightToken]? {
  match ext {
    "mbt" => Some(@syn_moonbit.highlight_moonbit(text))
    "ts" => Some(@syn_ts.highlight_typescript(text))
    "tsx" => Some(@syn_ts.highlight_typescript(text))
    "js" => Some(@syn_ts.highlight_javascript(text))
    "jsx" => Some(@syn_ts.highlight_javascript(text))
    "json" => Some(@syn_json.highlight_json(text))
    "html" => Some(@syn_html.highlight_html(text))
    "htm" => Some(@syn_html.highlight_html(text))
    "css" => Some(@syn_css.highlight_css(text))
    "rs" => Some(@syn_rust.highlight_rust(text))
    "sh" => Some(@syn_bash.highlight_bash(text))
    "bash" => Some(@syn_bash.highlight_bash(text))
    "zsh" => Some(@syn_bash.highlight_bash(text))
    "md" => Some(@syn_mdx.highlight_mdx(text))
    "mdx" => Some(@syn_mdx.highlight_mdx(text))
    _ => None
  }
}

///|
fn tokens_to_segments(
  text : String,
  tokens : Array[@syntree.HighlightToken],
) -> Array[SyntreeSegment] {
  let segments : Array[SyntreeSegment] = []
  let mut pos = 0
  for token in tokens {
    if token.from > pos {
      segments.push(
        {
          text: js_string_slice_local(text, pos, token.from),
          tag: @syntree.HighlightTag::None,
        },
      )
    }
    if token.to > token.from {
      segments.push(
        {
          text: js_string_slice_local(text, token.from, token.to),
          tag: token.tag,
        },
      )
    }
    pos = token.to
  }
  if pos < text.length() {
    segments.push(
      {
        text: js_string_slice_local(text, pos, text.length()),
        tag: @syntree.HighlightTag::None,
      },
    )
  }
  segments
}

///|
fn split_segments_to_lines(
  segments : Array[SyntreeSegment],
  expected_lines : Int,
) -> Array[SyntreeLine] {
  let lines : Array[SyntreeLine] = [{ segments: [] }]

  for seg in segments {
    let buf = StringBuilder::new()
    let mut has_text = false
    for c in seg.text {
      if c == '\n' {
        if has_text {
          lines[lines.length() - 1].segments.push(
            { text: buf.to_string(), tag: seg.tag },
          )
          buf.reset()
          has_text = false
        }
        lines.push({ segments: [] })
      } else {
        buf.write_char(c)
        has_text = true
      }
    }
    if has_text {
      lines[lines.length() - 1].segments.push(
        { text: buf.to_string(), tag: seg.tag },
      )
    }
  }

  while lines.length() < expected_lines {
    lines.push({ segments: [] })
  }
  while lines.length() > expected_lines {
    let _ = lines.pop()
  }
  lines
}

///|
fn syntree_highlight_lines(
  lines : Array[String],
  file_path : String,
) -> Array[SyntreeLine]? {
  let ext = file_extension(file_path)
  let text = lines.join("\n")
  match syntree_tokens_for_extension(ext, text) {
    Some(tokens) => {
      let segments = tokens_to_segments(text, tokens)
      Some(split_segments_to_lines(segments, lines.length()))
    }
    None => None
  }
}

// =============================================================================
// Rendering
// =============================================================================

///|
fn syntree_theme() -> @syn_highlight.HighlightTheme {
  @syn_highlight.github_dark()
}

///|
fn render_syntree_line(
  line : SyntreeLine,
  theme : @syn_highlight.HighlightTheme,
  max_width : Int,
) -> Array[TuiNode] {
  let nodes : Array[TuiNode] = []
  let default_color = normalize_color(theme.get_color(@syntree.HighlightTag::None))
  if default_color.length() > 0 {
    nodes.push(@vnode.text(" ", fg=default_color))
  } else {
    nodes.push(@vnode.text(" "))
  }
  let mut width = 1
  for seg in line.segments {
    if width >= max_width {
      break
    }
    let (part, consumed) = truncate_by_width(seg.text, max_width - width)
    if part.length() == 0 {
      continue
    }
    let color = normalize_color(theme.get_color(seg.tag))
    if color.length() > 0 {
      nodes.push(@vnode.text(part, fg=color))
    } else {
      nodes.push(@vnode.text(part))
    }
    width = width + consumed
  }
  nodes
}
