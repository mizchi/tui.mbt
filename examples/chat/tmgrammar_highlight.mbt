///|
/// TextMate-based highlighter using tmgrammar JSON

// =============================================================================
// JS helpers
// =============================================================================

///|
extern "js" fn js_read_file(path : String) -> String =
  #| (path) => {
  #|   try {
  #|     const fs = require('fs');
  #|     return fs.readFileSync(path, 'utf8');
  #|   } catch (e) {
  #|     return '';
  #|   }
  #| }

///|
extern "js" fn js_regex_find_groups(
  pattern : String,
  flags : String,
  input : String,
  start : Int,
) -> String =
  #| (pattern, flags, input, start) => {
  #|   try {
  #|     let f = flags || '';
  #|     if (!f.includes('g')) f += 'g';
  #|     if (!f.includes('d')) f += 'd';
  #|     const re = new RegExp(pattern, f);
  #|     re.lastIndex = start;
  #|     const m = re.exec(input);
  #|     if (!m) return '{"index":-1,"length":0,"groups":[]}';
  #|     const indices = m.indices || [];
  #|     const groups = [];
  #|     for (let i = 1; i < indices.length; i++) {
  #|       const it = indices[i];
  #|       if (!it) {
  #|         groups.push([-1, 0]);
  #|       } else {
  #|         groups.push([it[0], Math.max(0, it[1] - it[0])]);
  #|       }
  #|     }
  #|     return JSON.stringify({ index: m.index, length: m[0].length, groups });
  #|   } catch (e) {
  #|     return '{"index":-1,"length":0,"groups":[]}';
  #|   }
  #| }

///|
extern "js" fn js_string_slice(
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
// Types
// =============================================================================

///|
struct GrammarRule {
  match_ : String?
  begin : String?
  end : String?
  name : String?
  content_name : String?
  patterns : Array[GrammarRule]
  include_ref : String?
  captures : Array[(Int, String)]
  begin_captures : Array[(Int, String)]
  end_captures : Array[(Int, String)]
}

///|
struct Grammar {
  scope_name : String
  patterns : Array[GrammarRule]
  repository : Map[String, GrammarRule]
}

///|
enum RuleKind {
  Match
  BeginEnd
}

///|
struct CompiledRegex {
  pattern : String
  flags : String
}

///|
struct CompiledRule {
  kind : RuleKind
  name : String?
  content_name : String?
  match_rx : CompiledRegex?
  begin_rx : CompiledRegex?
  end_rx : CompiledRegex?
  patterns : Array[CompiledRule]
  captures : Array[(Int, String)]
  begin_captures : Array[(Int, String)]
  end_captures : Array[(Int, String)]
  order : Int
}

///|
struct MatchResult {
  index : Int
  length : Int
  groups : Array[(Int, Int)]
}

///|
struct Frame {
  patterns : Array[CompiledRule]
  end_rx : CompiledRegex?
  name : String?
  content_name : String?
  end_captures : Array[(Int, String)]
}

// =============================================================================
// JSON helpers
// =============================================================================

///|
fn json_get_string(obj : Map[String, Json], key : String) -> String? {
  match obj.get(key) {
    Some(Json::String(s)) => Some(s)
    _ => None
  }
}

///|
fn json_get_int(obj : Map[String, Json], key : String, default : Int) -> Int {
  match obj.get(key) {
    Some(Json::Number(n, ..)) => n.to_int()
    _ => default
  }
}

///|
fn json_get_object(obj : Map[String, Json], key : String) -> Map[String, Json]? {
  match obj.get(key) {
    Some(Json::Object(v)) => Some(v)
    _ => None
  }
}

///|
fn json_get_array(obj : Map[String, Json], key : String) -> Array[Json]? {
  match obj.get(key) {
    Some(Json::Array(v)) => Some(v)
    _ => None
  }
}

///|
fn parse_capture_map_obj(obj : Map[String, Json]) -> Array[(Int, String)] {
  let out : Array[(Int, String)] = []
  for key, v in obj {
    match parse_int_opt(key) {
      Some(i) =>
        match v {
          Json::Object(cap) =>
            match json_get_string(cap, "name") {
              Some(name) => out.push((i, name))
              None => ()
            }
          _ => ()
        }
      None => ()
    }
  }
  out
}

///|
fn parse_int_opt(s : String) -> Int? {
  if s.length() == 0 {
    return None
  }
  let chars : Array[Char] = s.iter().collect()
  let mut i = 0
  let mut sign = 1
  if chars[0] == '-' {
    sign = -1
    i = 1
  }
  if i >= chars.length() {
    return None
  }
  let mut value = 0
  while i < chars.length() {
    let c = chars[i]
    if c < '0' || c > '9' {
      return None
    }
    value = value * 10 + (c.to_int() - '0'.to_int())
    i = i + 1
  }
  Some(value * sign)
}

// =============================================================================
// Grammar parsing
// =============================================================================

///|
fn parse_rule(value : Json) -> GrammarRule? {
  match value {
    Json::Object(obj) => {
      let match_ = json_get_string(obj, "match")
      let begin = json_get_string(obj, "begin")
      let end = json_get_string(obj, "end")
      let name = json_get_string(obj, "name")
      let content_name = json_get_string(obj, "contentName")
      let include_ref = json_get_string(obj, "include")

      let patterns : Array[GrammarRule] = []
      match json_get_array(obj, "patterns") {
        Some(items) =>
          for it in items {
            match parse_rule(it) {
              Some(rule) => patterns.push(rule)
              None => ()
            }
          }
        None => ()
      }

      let captures : Array[(Int, String)] = []
      let begin_captures : Array[(Int, String)] = []
      let end_captures : Array[(Int, String)] = []

      match json_get_object(obj, "captures") {
        Some(caps) => captures.append(parse_capture_map_obj(caps))
        None => ()
      }
      match json_get_object(obj, "beginCaptures") {
        Some(caps) => begin_captures.append(parse_capture_map_obj(caps))
        None => ()
      }
      match json_get_object(obj, "endCaptures") {
        Some(caps) => end_captures.append(parse_capture_map_obj(caps))
        None => ()
      }

      Some({
        match_,
        begin,
        end,
        name,
        content_name,
        patterns,
        include_ref,
        captures,
        begin_captures,
        end_captures,
      })
    }
    _ => None
  }
}

///|
fn parse_grammar(json_str : String) -> Grammar? {
  let parsed : Result[Json, @json.ParseError] = try? @json.parse(json_str)
  match parsed {
    Ok(Json::Object(obj)) => {
      let scope = match json_get_string(obj, "scopeName") {
        Some(s) => s
        None => ""
      }
      let patterns : Array[GrammarRule] = []
      match json_get_array(obj, "patterns") {
        Some(items) =>
          for it in items {
            match parse_rule(it) {
              Some(rule) => patterns.push(rule)
              None => ()
            }
          }
        None => ()
      }
      let repository : Map[String, GrammarRule] = {}
      match json_get_object(obj, "repository") {
        Some(repo_obj) =>
          for key, v in repo_obj {
            match parse_rule(v) {
              Some(rule) => repository[key] = rule
              None => ()
            }
          }
        None => ()
      }
      let grammar = { scope_name: scope, patterns, repository }
      let _ = grammar.scope_name
      Some(grammar)
    }
    _ => None
  }
}

// =============================================================================
// Compilation
// =============================================================================

///|
fn compile_regex(pattern : String) -> CompiledRegex? {
  match @tm_onig.to_regexp_details(pattern, flags="m") {
    Ok(details) => Some({ pattern: details.pattern, flags: details.flags })
    Err(_) => None
  }
}

///|
fn compile_rules(
  patterns : Array[GrammarRule],
  grammar : Grammar,
  visited : Map[String, Bool],
  counter : Ref[Int],
) -> Array[CompiledRule] {
  let out : Array[CompiledRule] = []

  fn compile_rule(rule : GrammarRule) -> Unit {
    match rule.include_ref {
      Some(ref_name) => {
        if visited.get(ref_name).unwrap_or(false) {
          return
        }
        visited[ref_name] = true
        if ref_name == "$self" || ref_name == "$base" {
          out.append(compile_rules(grammar.patterns, grammar, visited, counter))
        } else if ref_name.length() > 1 && ref_name[0] == '#' {
          let key = js_string_slice(ref_name, 1, ref_name.length())
          match grammar.repository.get(key) {
            Some(r) => out.append(compile_rules([r], grammar, visited, counter))
            None => ()
          }
        }
      }
      None => {
        let sub_patterns = compile_rules(rule.patterns, grammar, visited, counter)
        let order = counter.val
        counter.val = counter.val + 1
        let match_rx = match rule.match_ {
          Some(p) => compile_regex(p)
          None => None
        }
        let begin_rx = match rule.begin {
          Some(p) => compile_regex(p)
          None => None
        }
        let end_rx = match rule.end {
          Some(p) => compile_regex(p)
          None => None
        }
        let kind = if begin_rx is Some(_) && end_rx is Some(_) {
          RuleKind::BeginEnd
        } else {
          RuleKind::Match
        }
        out.push({
          kind,
          name: rule.name,
          content_name: rule.content_name,
          match_rx,
          begin_rx,
          end_rx,
          patterns: sub_patterns,
          captures: rule.captures,
          begin_captures: rule.begin_captures,
          end_captures: rule.end_captures,
          order,
        })
      }
    }
  }

  for rule in patterns {
    compile_rule(rule)
  }

  out
}

// =============================================================================
// Regex matching + captures
// =============================================================================

///|
fn regex_find_groups(
  regex : CompiledRegex,
  text : String,
  start : Int,
) -> MatchResult? {
  let json_str = js_regex_find_groups(regex.pattern, regex.flags, text, start)
  let parsed : Result[Json, @json.ParseError] = try? @json.parse(json_str)
  match parsed {
    Ok(Json::Object(obj)) => {
      let index = json_get_int(obj, "index", -1)
      if index < 0 {
        None
      } else {
        let length = json_get_int(obj, "length", 0)
        let groups : Array[(Int, Int)] = []
        match json_get_array(obj, "groups") {
          Some(items) =>
            for item in items {
              match item {
                Json::Array(pair) =>
                  if pair.length() >= 2 {
                    match (pair[0], pair[1]) {
                      (Json::Number(a, ..), Json::Number(b, ..)) =>
                        groups.push((a.to_int(), b.to_int()))
                      _ => ()
                    }
                  }
                _ => ()
              }
            }
          None => ()
        }
        Some({ index, length, groups })
      }
    }
    _ => None
  }
}

///|
fn slice_string(s : String, start : Int, end_ : Int) -> String {
  js_string_slice(s, start, end_)
}

///|
fn push_scoped_token(
  tokens : Array[@tm_tui.TermToken],
  text : String,
  scope : String?,
) -> Unit {
  if text.length() == 0 {
    return
  }
  let scopes = match scope {
    Some(s) => [s]
    None => []
  }
  tokens.push(@tm_tui.TermToken::new(text, scopes~))
}

///|
fn apply_captures(
  tokens : Array[@tm_tui.TermToken],
  line : String,
  match_start : Int,
  match_len : Int,
  base_scope : String?,
  captures : Array[(Int, String)],
  groups : Array[(Int, Int)],
) -> Unit {
  if captures.is_empty() || groups.is_empty() {
    push_scoped_token(
      tokens,
      slice_string(line, match_start, match_start + match_len),
      base_scope,
    )
    return
  }

  let ranges : Array[(Int, Int, String)] = []
  for cap in captures {
    let (idx, scope) = cap
    if idx > 0 && idx <= groups.length() {
      let (g_start, g_len) = groups[idx - 1]
      if g_start >= 0 && g_len > 0 {
        ranges.push((g_start, g_len, scope))
      }
    }
  }
  if ranges.is_empty() {
    push_scoped_token(
      tokens,
      slice_string(line, match_start, match_start + match_len),
      base_scope,
    )
    return
  }

  // sort by start (simple insertion)
  let ordered : Array[(Int, Int, String)] = []
  for r in ranges {
    let mut inserted = false
    for i, v in ordered {
      if r.0 < v.0 {
        ordered.insert(i, r)
        inserted = true
        break
      }
    }
    if not(inserted) {
      ordered.push(r)
    }
  }

  let mut cursor = match_start
  let match_end = match_start + match_len
  for r in ordered {
    let (start, len, scope) = r
    if start < match_start || start >= match_end {
      continue
    }
    let end_ = start + len
    if start > cursor {
      push_scoped_token(tokens, slice_string(line, cursor, start), base_scope)
    }
    let safe_end = if end_ > match_end { match_end } else { end_ }
    push_scoped_token(tokens, slice_string(line, start, safe_end), Some(scope))
    cursor = safe_end
  }
  if cursor < match_end {
    push_scoped_token(tokens, slice_string(line, cursor, match_end), base_scope)
  }
}

// =============================================================================
// Tokenization
// =============================================================================

///|
fn find_best_match(
  rules : Array[CompiledRule],
  line : String,
  pos : Int,
) -> (MatchResult, CompiledRule)? {
  let mut best : (MatchResult, CompiledRule)? = None
  for rule in rules {
    let rx = match rule.match_rx {
      Some(r) => Some(r)
      None => rule.begin_rx
    }
    match rx {
      Some(regex) =>
        match regex_find_groups(regex, line, pos) {
          Some(m) =>
            if m.index >= pos {
              match best {
                Some((prev, prev_rule)) => {
                  if m.index < prev.index ||
                    (m.index == prev.index && rule.order < prev_rule.order) {
                    best = Some((m, rule))
                  }
                }
                None => best = Some((m, rule))
              }
            }
          None => ()
        }
      None => ()
    }
  }
  best
}

///|
fn tokenize_line_with_rules(
  line : String,
  root_rules : Array[CompiledRule],
  stack : Array[Frame],
) -> Array[@tm_tui.TermToken] {
  let tokens : Array[@tm_tui.TermToken] = []
  let mut pos = 0
  let line_len = line.length()

  while pos < line_len {
    let active_rules = if stack.length() > 0 {
      stack[stack.length() - 1].patterns
    } else {
      root_rules
    }

    let end_match = if stack.length() > 0 {
      match stack[stack.length() - 1].end_rx {
        Some(rx) => regex_find_groups(rx, line, pos)
        None => None
      }
    } else {
      None
    }

    let best = find_best_match(active_rules, line, pos)
    let choose_end = match (end_match, best) {
      (Some(e), Some((m, _))) =>
        if e.index < m.index {
          true
        } else if e.index == m.index {
          true
        } else {
          false
        }
      (Some(_), None) => true
      _ => false
    }

    if choose_end {
      let frame = stack[stack.length() - 1]
      match end_match {
        Some(e) => {
          let content_scope = match frame.content_name {
            Some(s) => Some(s)
            None => frame.name
          }
          if e.index > pos {
            push_scoped_token(tokens, slice_string(line, pos, e.index), content_scope)
          }
          apply_captures(
            tokens,
            line,
            e.index,
            e.length,
            frame.name,
            frame.end_captures,
            e.groups,
          )
          let advance = if e.length > 0 { e.length } else { 1 }
          pos = e.index + advance
          let _ = stack.pop()
        }
        None => {
          push_scoped_token(tokens, slice_string(line, pos, line_len), None)
          pos = line_len
        }
      }
    } else {
      match best {
        Some((m, rule)) => {
          if m.index > pos {
            push_scoped_token(tokens, slice_string(line, pos, m.index), None)
          }
          match rule.kind {
            RuleKind::BeginEnd => {
              apply_captures(
                tokens,
                line,
                m.index,
                m.length,
                rule.name,
                rule.begin_captures,
                m.groups,
              )
              let advance = if m.length > 0 { m.length } else { 1 }
              pos = m.index + advance
              let frame = Frame::{
                patterns: rule.patterns,
                end_rx: rule.end_rx,
                name: rule.name,
                content_name: rule.content_name,
                end_captures: rule.end_captures,
              }
              stack.push(frame)
            }
            RuleKind::Match => {
              apply_captures(
                tokens,
                line,
                m.index,
                m.length,
                rule.name,
                rule.captures,
                m.groups,
              )
              let advance = if m.length > 0 { m.length } else { 1 }
              pos = m.index + advance
            }
          }
        }
        None => {
          push_scoped_token(tokens, slice_string(line, pos, line_len), None)
          pos = line_len
        }
      }
    }
  }

  tokens
}

///|
fn tokenize_lines_with_rules(
  lines : Array[String],
  rules : Array[CompiledRule],
) -> Array[@tm_tui.TermLine] {
  let result : Array[@tm_tui.TermLine] = []
  let stack : Array[Frame] = []
  for line in lines {
    let tokens = tokenize_line_with_rules(line, rules, stack)
    result.push(@tm_tui.TermLine::new(tokens))
  }
  result
}

// =============================================================================
// Public entry (package-local)
// =============================================================================

///|
fn grammar_json_path_for_extension(ext : String) -> String? {
  let root = @ai.js_path_join(@ai.js_get_cwd(), ".mooncakes/mizchi/tmgrammar/grammars")
  fn path(dir : String, file : String) -> String {
    @ai.js_path_join(@ai.js_path_join(root, dir), file)
  }
  match ext {
    "mbt" => Some(path("moonbit", "moonbit.tmLanguage.json"))
    "js" => Some(path("javascript", "javascript.tmLanguage.json"))
    "jsx" => Some(path("javascript", "javascript.tmLanguage.json"))
    "ts" => Some(path("typescript", "typescript.tmLanguage.json"))
    "tsx" => Some(path("typescript", "typescript.tmLanguage.json"))
    "json" => Some(path("json", "json.tmLanguage.json"))
    "yaml" => Some(path("yaml", "yaml.tmLanguage.json"))
    "yml" => Some(path("yaml", "yaml.tmLanguage.json"))
    "toml" => Some(path("toml", "toml.tmLanguage.json"))
    "md" => Some(path("markdown", "markdown.tmLanguage.json"))
    "markdown" => Some(path("markdown", "markdown.tmLanguage.json"))
    "rs" => Some(path("rust", "rust.tmLanguage.json"))
    "py" => Some(path("python", "python.tmLanguage.json"))
    "rb" => Some(path("ruby", "ruby.tmLanguage.json"))
    "sh" => Some(path("bash", "bash.tmLanguage.json"))
    "bash" => Some(path("bash", "bash.tmLanguage.json"))
    "zsh" => Some(path("bash", "bash.tmLanguage.json"))
    "go" => Some(path("go", "go.tmLanguage.json"))
    "c" => Some(path("c", "c.tmLanguage.json"))
    "h" => Some(path("c", "c.tmLanguage.json"))
    "cpp" => Some(path("cpp", "cpp.tmLanguage.json"))
    "cc" => Some(path("cpp", "cpp.tmLanguage.json"))
    "cxx" => Some(path("cpp", "cpp.tmLanguage.json"))
    "hpp" => Some(path("cpp", "cpp.tmLanguage.json"))
    "html" => Some(path("html", "html.tmLanguage.json"))
    "css" => Some(path("css", "css.tmLanguage.json"))
    "scss" => Some(path("scss", "scss.tmLanguage.json"))
    "sql" => Some(path("sql", "sql.tmLanguage.json"))
    "proto" => Some(path("protobuf", "protobuf.tmLanguage.json"))
    _ => None
  }
}

///|
let tmgrammar_cache : Map[String, Array[CompiledRule]] = {}

///|
fn get_compiled_rules(ext : String, json_path : String) -> Array[CompiledRule] {
  match tmgrammar_cache.get(ext) {
    Some(rules) => rules
    None => {
      let json_str = js_read_file(json_path)
      match parse_grammar(json_str) {
        Some(grammar) => {
          let counter = Ref::new(0)
          let visited : Map[String, Bool] = {}
          let compiled = compile_rules(grammar.patterns, grammar, visited, counter)
          tmgrammar_cache[ext] = compiled
          compiled
        }
        None => []
      }
    }
  }
}

///|
fn tmgrammar_highlight_lines(
  lines : Array[String],
  file_path : String,
) -> Array[@tm_tui.TermLine]? {
  let ext = file_extension(file_path)
  match grammar_json_path_for_extension(ext) {
    Some(json_path) => {
      let rules = get_compiled_rules(ext, json_path)
      if rules.is_empty() {
        None
      } else {
        Some(tokenize_lines_with_rules(lines, rules))
      }
    }
    None => None
  }
}
