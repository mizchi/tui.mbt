///|
/// Filer highlight - minimal syntax highlighter for preview


// =============================================================================
// Highlight Config
// =============================================================================

///|
struct HighlightConfig {
  line_comment_patterns : Array[Array[Char]]
  block_comment_start : Array[Char]?
  block_comment_end : Array[Char]?
  keywords : Array[String]
  constants : Array[String]
  string_delims : Array[Char]
}

///|
struct TokenizerState {
  mut in_block_comment : Bool
  mut string_delim : Char?
}

///|
enum PreviewHighlight {
  Syntree(Array[SyntreeLine])
  Tm(Array[@tm_tui.TermLine])
}

///|
fn TokenizerState::new() -> TokenizerState {
  { in_block_comment: false, string_delim: None }
}

///|
fn chars_from_string(s : String) -> Array[Char] {
  s.iter().collect()
}

///|
fn match_pattern(chars : Array[Char], start : Int, pattern : Array[Char]) -> Bool {
  let len = chars.length()
  let plen = pattern.length()
  if start + plen > len {
    return false
  }
  for i = 0; i < plen; i = i + 1 {
    if chars[start + i] != pattern[i] {
      return false
    }
  }
  true
}

///|
fn match_any_pattern(
  chars : Array[Char],
  start : Int,
  patterns : Array[Array[Char]],
) -> Int? {
  for pattern in patterns {
    if match_pattern(chars, start, pattern) {
      return Some(pattern.length())
    }
  }
  None
}

///|
fn is_ascii_alpha(c : Char) -> Bool {
  (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
}

///|
fn is_ascii_digit(c : Char) -> Bool {
  c >= '0' && c <= '9'
}

///|
fn is_ident_start(c : Char) -> Bool {
  is_ascii_alpha(c) || c == '_' || c == '$'
}

///|
fn is_ident_continue(c : Char) -> Bool {
  is_ident_start(c) || is_ascii_digit(c)
}

///|
fn is_in_list(word : String, list : Array[String]) -> Bool {
  for item in list {
    if item == word {
      return true
    }
  }
  false
}

///|
fn is_char_in_list(c : Char, list : Array[Char]) -> Bool {
  for item in list {
    if item == c {
      return true
    }
  }
  false
}

// =============================================================================
// Config Selection
// =============================================================================

///|
fn keyword_list_c_like() -> Array[String] {
  [
    "if",
    "else",
    "for",
    "while",
    "switch",
    "case",
    "break",
    "continue",
    "return",
    "class",
    "struct",
    "enum",
    "import",
    "export",
    "fn",
    "let",
    "mut",
    "const",
    "var",
    "pub",
    "priv",
    "protected",
    "static",
    "async",
    "await",
    "try",
    "catch",
    "finally",
    "throw",
    "new",
    "extends",
    "implements",
    "interface",
    "type",
    "yield",
    "match",
    "derive",
    "where",
    "raise",
    "suberror",
    "noraise",
    "test",
    "using",
  ]
}

///|
fn constants_default() -> Array[String] {
  ["true", "false", "null", "None", "Some", "Ok", "Err"]
}

///|
fn config_for_extension(ext : String) -> HighlightConfig {
  let c_like = HighlightConfig::{
    line_comment_patterns: [chars_from_string("//")],
    block_comment_start: Some(chars_from_string("/*")),
    block_comment_end: Some(chars_from_string("*/")),
    keywords: keyword_list_c_like(),
    constants: constants_default(),
    string_delims: ['"', '\'', '`'],
  }
  let hash_like = HighlightConfig::{
    line_comment_patterns: [chars_from_string("#")],
    block_comment_start: None,
    block_comment_end: None,
    keywords: keyword_list_c_like(),
    constants: constants_default(),
    string_delims: ['"', '\''],
  }
  let json_like = HighlightConfig::{
    line_comment_patterns: [],
    block_comment_start: None,
    block_comment_end: None,
    keywords: [],
    constants: ["true", "false", "null"],
    string_delims: ['"'],
  }
  match ext {
    "mbt" => c_like
    "js" => c_like
    "jsx" => c_like
    "ts" => c_like
    "tsx" => c_like
    "json" => json_like
    "yml" => hash_like
    "yaml" => hash_like
    "toml" => hash_like
    "py" => hash_like
    "rb" => hash_like
    "sh" => hash_like
    "bash" => hash_like
    "zsh" => hash_like
    _ => c_like
  }
}

///|
fn file_extension(path : String) -> String {
  let base = @ai.js_path_basename(path)
  let chars : Array[Char] = base.iter().collect()
  let mut last_dot = -1
  for i, c in chars {
    if c == '.' {
      last_dot = i
    }
  }
  if last_dot < 0 {
    ""
  } else {
    let buf = StringBuilder::new()
    for i = last_dot + 1; i < chars.length(); i = i + 1 {
      buf.write_char(chars[i])
    }
    buf.to_string()
  }
}

// =============================================================================
// Tokenization
// =============================================================================

///|
fn push_token(
  tokens : Array[@tm_tui.TermToken],
  content : String,
  scopes : Array[String],
) -> Unit {
  if content.length() == 0 {
    return
  }
  tokens.push(@tm_tui.TermToken::new(content, scopes~))
}

///|
fn tokenize_line(
  line : String,
  config : HighlightConfig,
  state : TokenizerState,
) -> Array[@tm_tui.TermToken] {
  let tokens : Array[@tm_tui.TermToken] = []
  let chars : Array[Char] = line.iter().collect()
  let len = chars.length()
  let plain = StringBuilder::new()
  let mut plain_len = 0

  fn flush_plain() -> Unit {
    if plain_len == 0 {
      return
    }
    let text = plain.to_string()
    plain.reset()
    plain_len = 0
    push_token(tokens, text, [])
  }

  let mut i = 0
  while i < len {
    match state.string_delim {
      Some(delim) => {
        let sb = StringBuilder::new()
        let mut closed = false
        while i < len {
          let c = chars[i]
          sb.write_char(c)
          i = i + 1
          if c == '\\' && i < len {
            sb.write_char(chars[i])
            i = i + 1
            continue
          }
          if c == delim {
            closed = true
            break
          }
        }
        if closed {
          state.string_delim = None
        }
        push_token(tokens, sb.to_string(), ["string"])
        continue
      }
      None => ()
    }

    if state.in_block_comment {
      let sb = StringBuilder::new()
      let mut closed = false
      while i < len {
        if config.block_comment_end is Some(end_pat) &&
          match_pattern(chars, i, end_pat) {
          for j = 0; j < end_pat.length(); j = j + 1 {
            sb.write_char(chars[i + j])
          }
          i = i + end_pat.length()
          closed = true
          break
        }
        sb.write_char(chars[i])
        i = i + 1
      }
      if closed {
        state.in_block_comment = false
      }
      push_token(tokens, sb.to_string(), ["comment"])
      continue
    }

    // Line comments
    match match_any_pattern(chars, i, config.line_comment_patterns) {
      Some(_) => {
        flush_plain()
        let sb = StringBuilder::new()
        for j = i; j < len; j = j + 1 {
          sb.write_char(chars[j])
        }
        push_token(tokens, sb.to_string(), ["comment"])
        break
      }
      None => ()
    }

    // Block comment start
    if config.block_comment_start is Some(start_pat) &&
      match_pattern(chars, i, start_pat) {
      flush_plain()
      let sb = StringBuilder::new()
      for j = 0; j < start_pat.length(); j = j + 1 {
        sb.write_char(chars[i + j])
      }
      i = i + start_pat.length()
      let mut closed = false
      while i < len {
        if config.block_comment_end is Some(end_pat) &&
          match_pattern(chars, i, end_pat) {
          for j = 0; j < end_pat.length(); j = j + 1 {
            sb.write_char(chars[i + j])
          }
          i = i + end_pat.length()
          closed = true
          break
        }
        sb.write_char(chars[i])
        i = i + 1
      }
      if not(closed) {
        state.in_block_comment = true
      }
      push_token(tokens, sb.to_string(), ["comment"])
      continue
    }

    // String start
    let c = chars[i]
    if is_char_in_list(c, config.string_delims) {
      flush_plain()
      let sb = StringBuilder::new()
      sb.write_char(c)
      i = i + 1
      let mut closed = false
      while i < len {
        let ch = chars[i]
        sb.write_char(ch)
        i = i + 1
        if ch == '\\' && i < len {
          sb.write_char(chars[i])
          i = i + 1
          continue
        }
        if ch == c {
          closed = true
          break
        }
      }
      if not(closed) {
        state.string_delim = Some(c)
      }
      push_token(tokens, sb.to_string(), ["string"])
      continue
    }

    // Number
    if is_ascii_digit(c) {
      flush_plain()
      let sb = StringBuilder::new()
      while i < len {
        let ch = chars[i]
        if is_ascii_digit(ch) || ch == '.' {
          sb.write_char(ch)
          i = i + 1
        } else {
          break
        }
      }
      push_token(tokens, sb.to_string(), ["constant.numeric"])
      continue
    }

    // Identifier
    if is_ident_start(c) {
      flush_plain()
      let sb = StringBuilder::new()
      while i < len && is_ident_continue(chars[i]) {
        sb.write_char(chars[i])
        i = i + 1
      }
      let word = sb.to_string()
      if is_in_list(word, config.constants) {
        push_token(tokens, word, ["constant.language"])
      } else if is_in_list(word, config.keywords) {
        push_token(tokens, word, ["keyword"])
      } else {
        push_token(tokens, word, [])
      }
      continue
    }

    // Plain char
    plain.write_char(c)
    plain_len = plain_len + 1
    i = i + 1
  }

  flush_plain()
  tokens
}

///|
fn tokenize_lines(
  lines : Array[String],
  config : HighlightConfig,
) -> Array[@tm_tui.TermLine] {
  let result : Array[@tm_tui.TermLine] = []
  let state = TokenizerState::new()
  for line in lines {
    let tokens = tokenize_line(line, config, state)
    result.push(@tm_tui.TermLine::new(tokens))
  }
  result
}

///|
fn highlight_lines_for_preview(
  lines : Array[String],
  file_path : String,
) -> PreviewHighlight {
  match syntree_highlight_lines(lines, file_path) {
    Some(result) => PreviewHighlight::Syntree(result)
    None =>
      match tmgrammar_highlight_lines(lines, file_path) {
        Some(result) => PreviewHighlight::Tm(result)
        None => {
          let ext = file_extension(file_path)
          let config = config_for_extension(ext)
          PreviewHighlight::Tm(tokenize_lines(lines, config))
        }
      }
  }
}

// =============================================================================
// Rendering helpers
// =============================================================================

///|
fn ansi_color_to_rgb(color : @tm_tui.AnsiColor) -> String? {
  match color {
    @tm_tui.AnsiColor::Black => Some("rgb(0,0,0)")
    @tm_tui.AnsiColor::Red => Some("rgb(205,49,49)")
    @tm_tui.AnsiColor::Green => Some("rgb(13,188,121)")
    @tm_tui.AnsiColor::Yellow => Some("rgb(229,229,16)")
    @tm_tui.AnsiColor::Blue => Some("rgb(36,114,200)")
    @tm_tui.AnsiColor::Magenta => Some("rgb(188,63,188)")
    @tm_tui.AnsiColor::Cyan => Some("rgb(17,168,205)")
    @tm_tui.AnsiColor::White => Some("rgb(229,229,229)")
    @tm_tui.AnsiColor::BrightBlack => Some("rgb(102,102,102)")
    @tm_tui.AnsiColor::BrightRed => Some("rgb(241,76,76)")
    @tm_tui.AnsiColor::BrightGreen => Some("rgb(35,209,139)")
    @tm_tui.AnsiColor::BrightYellow => Some("rgb(245,245,67)")
    @tm_tui.AnsiColor::BrightBlue => Some("rgb(59,142,234)")
    @tm_tui.AnsiColor::BrightMagenta => Some("rgb(214,112,214)")
    @tm_tui.AnsiColor::BrightCyan => Some("rgb(41,184,219)")
    @tm_tui.AnsiColor::BrightWhite => Some("rgb(255,255,255)")
    @tm_tui.AnsiColor::Rgb(r, g, b) => Some("rgb(\{r},\{g},\{b})")
    @tm_tui.AnsiColor::Color256(n) => {
      if n < 16 {
        ansi_color_to_rgb(match n {
          0 => @tm_tui.AnsiColor::Black
          1 => @tm_tui.AnsiColor::Red
          2 => @tm_tui.AnsiColor::Green
          3 => @tm_tui.AnsiColor::Yellow
          4 => @tm_tui.AnsiColor::Blue
          5 => @tm_tui.AnsiColor::Magenta
          6 => @tm_tui.AnsiColor::Cyan
          7 => @tm_tui.AnsiColor::White
          8 => @tm_tui.AnsiColor::BrightBlack
          9 => @tm_tui.AnsiColor::BrightRed
          10 => @tm_tui.AnsiColor::BrightGreen
          11 => @tm_tui.AnsiColor::BrightYellow
          12 => @tm_tui.AnsiColor::BrightBlue
          13 => @tm_tui.AnsiColor::BrightMagenta
          14 => @tm_tui.AnsiColor::BrightCyan
          _ => @tm_tui.AnsiColor::BrightWhite
        })
      } else if n <= 231 {
        let idx = n - 16
        let r = idx / 36
        let g = (idx / 6) % 6
        let b = idx % 6
        let steps = [0, 95, 135, 175, 215, 255]
        Some("rgb(\{steps[r]},\{steps[g]},\{steps[b]})")
      } else if n <= 255 {
        let gray = 8 + (n - 232) * 10
        Some("rgb(\{gray},\{gray},\{gray})")
      } else {
        None
      }
    }
    @tm_tui.AnsiColor::Default => None
  }
}

///|
fn term_color_to_style(
  color : @tm_tui.TermColor,
  theme : @tm_tui.TermTheme,
) -> (String?, Bool) {
  let fg = match color.fg {
    Some(c) => ansi_color_to_rgb(c)
    None => ansi_color_to_rgb(theme.default_fg)
  }
  let bold = match color.style {
    Some(@tm_tui.AnsiStyle::Bold) => true
    _ => false
  }
  (fg, bold)
}

///|
fn truncate_term_tokens(
  tokens : Array[@tm_tui.TermToken],
  max_width : Int,
) -> Array[@tm_tui.TermToken] {
  let out : Array[@tm_tui.TermToken] = []
  let mut width = 0
  for token in tokens {
    if width >= max_width {
      break
    }
    let buf = StringBuilder::new()
    for c in token.content {
      let w = @core.char_display_width(c)
      if width + w > max_width {
        break
      }
      buf.write_char(c)
      width = width + w
    }
    let chunk = buf.to_string()
    if chunk.length() > 0 {
      out.push(@tm_tui.TermToken::new(chunk, scopes=token.scopes))
    }
  }
  out
}

///|
fn render_highlight_line(
  line : @tm_tui.TermLine,
  theme : @tm_tui.TermTheme,
  max_width : Int,
) -> Array[TuiNode] {
  let nodes : Array[TuiNode] = []
  let tokens = truncate_term_tokens(line.tokens, max_width)
  let default_fg = ansi_color_to_rgb(theme.default_fg)
  match default_fg {
    Some(fg) => nodes.push(@vnode.text(" ", fg~))
    None => nodes.push(@vnode.text(" "))
  }
  for token in tokens {
    let color = theme.get_color(token.scopes)
    let (fg, bold) = term_color_to_style(color, theme)
    match fg {
      Some(color_str) => nodes.push(
        @vnode.text(token.content, fg=color_str, bold=bold),
      )
      None => nodes.push(@vnode.text(token.content, bold=bold))
    }
  }
  nodes
}

///|
fn preview_theme() -> @tm_tui.TermTheme {
  @tm_tui.monokai_theme()
}
