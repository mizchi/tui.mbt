///|
/// Filer - File tree browser component

///|
typealias TuiNode = @vnode.TuiNode

// =============================================================================
// Types
// =============================================================================

///|
struct FileEntry {
  name : String
  is_dir : Bool
}

///|
struct FilerState {
  mut current_dir : String
  entries : Array[FileEntry]
  mut selected_idx : Int
  mut scroll_offset : Int
}

// =============================================================================
// FilerState Methods
// =============================================================================

///|
fn FilerState::new(initial_dir : String) -> FilerState {
  { current_dir: initial_dir, entries: [], selected_idx: 0, scroll_offset: 0 }
}

///|
fn FilerState::refresh(self : FilerState) -> Unit {
  self.entries.clear()
  let json = @ai.js_list_dir_json(self.current_dir)
  parse_file_entries(json, self.entries)
  if self.selected_idx >= self.entries.length() {
    self.selected_idx = if self.entries.length() > 0 {
      self.entries.length() - 1
    } else {
      0
    }
  }
}

///|
/// Enter the selected directory or return file path if file is selected
fn FilerState::enter_selected(self : FilerState) -> String? {
  if self.selected_idx < self.entries.length() {
    let entry = self.entries[self.selected_idx]
    if entry.is_dir {
      self.current_dir = @ai.js_path_join(self.current_dir, entry.name)
      self.refresh()
      self.selected_idx = 0
      self.scroll_offset = 0
      None
    } else {
      Some(@ai.js_path_join(self.current_dir, entry.name))
    }
  } else {
    None
  }
}

///|
/// Navigate to parent directory
fn FilerState::go_up(self : FilerState) -> Unit {
  let parent = @ai.js_path_dirname(self.current_dir)
  if parent != self.current_dir {
    self.current_dir = parent
    self.refresh()
    self.selected_idx = 0
    self.scroll_offset = 0
  }
}

///|
/// Move selection by delta (-1 for up, +1 for down)
fn FilerState::move_selection(self : FilerState, delta : Int) -> Unit {
  let new_idx = self.selected_idx + delta
  if new_idx >= 0 && new_idx < self.entries.length() {
    self.selected_idx = new_idx
  }
}

///|
/// Adjust scroll to keep selection visible
fn FilerState::adjust_scroll(self : FilerState, visible_height : Int) -> Unit {
  if self.selected_idx < self.scroll_offset {
    self.scroll_offset = self.selected_idx
  } else if self.selected_idx >= self.scroll_offset + visible_height {
    self.scroll_offset = self.selected_idx - visible_height + 1
  }
}

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

  // Helper to create a row with border
  fn make_row(content : String, fg : String) -> TuiNode {
    let padded = content +
      " ".repeat(content_width - @core.string_display_width(content))
    let truncated = truncate_filer_text(padded, content_width)
    @vnode.row(min_width=filer_width.to_double(), height=1.0, [
      @vnode.text(truncated, fg~),
      @vnode.text(border_char, fg=border_color),
    ])
  }

  // Header with current directory
  let dir_name = @ai.js_path_basename(state.current_dir)
  let header = if dir_name.length() > 0 { dir_name } else { "/" }
  lines.push(make_row(" [" + header + "]", "rgb(200,200,100)"))

  // Parent directory entry
  lines.push(make_row(" ..", "rgb(120,120,120)"))

  // File entries
  let visible_height = filer_height - 2 // header + parent
  let start_idx = state.scroll_offset
  for i = 0; i < visible_height; i = i + 1 {
    let entry_idx = start_idx + i
    if entry_idx < state.entries.length() {
      let entry = state.entries[entry_idx]
      let is_selected = entry_idx == state.selected_idx && is_focused
      let prefix = if is_selected { "> " } else { "  " }
      let suffix = if entry.is_dir { "/" } else { "" }
      let fg = if is_selected {
        "rgb(255,255,100)"
      } else if entry.is_dir {
        "rgb(100,180,255)"
      } else {
        "rgb(180,180,180)"
      }
      lines.push(make_row(prefix + entry.name + suffix, fg))
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
/// Truncate text to fit within max_width (display width)
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

///|
/// Parse JSON array of file entries
fn parse_file_entries(json : String, entries : Array[FileEntry]) -> Unit {
  let chars : Array[Char] = json.iter().collect()
  let mut i = 0
  let len = chars.length()

  fn skip_ws() -> Unit {
    while i < len &&
      (chars[i] == ' ' || chars[i] == '\n' || chars[i] == '\r' || chars[i] == '\t') {
      i = i + 1
    }
  }

  fn parse_string() -> String {
    let buf = StringBuilder::new()
    if i < len && chars[i] == '"' {
      i = i + 1
      while i < len && chars[i] != '"' {
        if chars[i] == '\\' && i + 1 < len {
          i = i + 1
        }
        buf.write_char(chars[i])
        i = i + 1
      }
      if i < len {
        i = i + 1
      }
    }
    buf.to_string()
  }

  fn parse_bool() -> Bool {
    if i + 4 <= len &&
      chars[i] == 't' &&
      chars[i + 1] == 'r' &&
      chars[i + 2] == 'u' &&
      chars[i + 3] == 'e' {
      i = i + 4
      return true
    }
    if i + 5 <= len &&
      chars[i] == 'f' &&
      chars[i + 1] == 'a' &&
      chars[i + 2] == 'l' &&
      chars[i + 3] == 's' &&
      chars[i + 4] == 'e' {
      i = i + 5
      return false
    }
    false
  }

  skip_ws()
  if i < len && chars[i] == '[' {
    i = i + 1
    while i < len {
      skip_ws()
      if chars[i] == ']' {
        break
      }
      if chars[i] == ',' {
        i = i + 1
        continue
      }
      if chars[i] == '{' {
        i = i + 1
        let mut name = ""
        let mut is_dir = false
        while i < len && chars[i] != '}' {
          skip_ws()
          if chars[i] == '"' {
            let key = parse_string()
            skip_ws()
            if i < len && chars[i] == ':' {
              i = i + 1
            }
            skip_ws()
            if key == "name" {
              name = parse_string()
            } else if key == "is_dir" {
              is_dir = parse_bool()
            }
          }
          skip_ws()
          if i < len && chars[i] == ',' {
            i = i + 1
          }
        }
        if i < len {
          i = i + 1
        }
        entries.push({ name, is_dir })
      }
    }
  }
}
