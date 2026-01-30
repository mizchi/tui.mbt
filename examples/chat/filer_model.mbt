///|
/// Filer model - file tree state and data operations

// =============================================================================
// Types
// =============================================================================

///|
/// Git status indicator
enum GitStatus {
  None // Not tracked or unchanged
  Modified // M - modified
  Added // A - added/staged
  Deleted // D - deleted
  Untracked // ? - untracked
  Renamed // R - renamed
}

///|
fn GitStatus::to_char(self : GitStatus) -> String {
  match self {
    None => " "
    Modified => "M"
    Added => "A"
    Deleted => "D"
    Untracked => "?"
    Renamed => "R"
  }
}

///|
fn GitStatus::color(self : GitStatus) -> String {
  match self {
    None => "rgb(180,180,180)"
    Modified => "rgb(255,200,100)" // Yellow/orange
    Added => "rgb(100,255,100)" // Green
    Deleted => "rgb(255,100,100)" // Red
    Untracked => "rgb(150,150,150)" // Gray
    Renamed => "rgb(100,200,255)" // Cyan
  }
}

///|
/// Visible tree item (used for rendering)
struct TreeItem {
  path : String // Full path
  name : String // Display name
  is_dir : Bool
  git_status : GitStatus
  depth : Int // Indentation level
  is_expanded : Bool // For directories
}

///|
struct FilerState {
  mut current_dir : String
  visible_items : Array[TreeItem] // Flat list for rendering
  expanded_dirs : Map[String, Bool] // Tracks expanded directories
  git_status : Map[String, String] // path -> status code
  mut selected_idx : Int
  mut scroll_offset : Int
  mut git_only_mode : Bool
  mut is_git_repo : Bool
  mut preview_file : String
  mut preview_content : String
  mut preview_is_diff : Bool
  mut preview_scroll_offset : Int
}

// =============================================================================
// FilerState Methods
// =============================================================================

///|
fn FilerState::new(initial_dir : String) -> FilerState {
  {
    current_dir: initial_dir,
    visible_items: [],
    expanded_dirs: {},
    git_status: {},
    selected_idx: 0,
    scroll_offset: 0,
    git_only_mode: false,
    is_git_repo: false,
    preview_file: "",
    preview_content: "",
    preview_is_diff: false,
    preview_scroll_offset: 0,
  }
}

///|
fn FilerState::refresh(self : FilerState) -> Unit {
  // Load git status first
  self.load_git_status()
  // Rebuild visible items
  self.build_visible_items()
  // Adjust selection
  if self.selected_idx >= self.visible_items.length() {
    self.selected_idx = if self.visible_items.length() > 0 {
      self.visible_items.length() - 1
    } else {
      0
    }
  }
}

///|
/// Build the flat list of visible items by walking the tree
fn FilerState::build_visible_items(self : FilerState) -> Unit {
  self.visible_items.clear()
  self.build_items_recursive(self.current_dir, 0)
}

///|
fn is_filtered_entry(name : String) -> Bool {
  name == ".gitignore" || name == "_build"
}

///|
/// Recursively build visible items
fn FilerState::build_items_recursive(
  self : FilerState,
  dir_path : String,
  depth : Int,
) -> Unit {
  let json = @ai.js_list_dir_json(dir_path)
  let entries : Array[(String, Bool, GitStatus)] = [] // (name, is_dir, git_status)
  parse_dir_entries(json, entries, self.git_status)
  for entry in entries {
    let (name, is_dir, git_status) = entry
    if is_filtered_entry(name) {
      continue
    }

    // Filter by git status if in git_only_mode
    if self.git_only_mode && self.is_git_repo {
      match git_status {
        GitStatus::None =>
          if not(is_dir) {
            continue // Skip unchanged files
          }
        _ => ()
      }
    }
    let full_path = @ai.js_path_join(dir_path, name)
    let is_expanded = self.expanded_dirs.get(full_path).unwrap_or(false)
    self.visible_items.push({
      path: full_path,
      name,
      is_dir,
      git_status,
      depth,
      is_expanded,
    })

    // If directory is expanded, add its children
    if is_dir && is_expanded {
      self.build_items_recursive(full_path, depth + 1)
    }
  }
}

///|
fn FilerState::load_git_status(self : FilerState) -> Unit {
  self.git_status.clear()
  let json = @ai.js_git_status(self.current_dir)
  let (files, is_repo) = parse_git_status_json(json)
  self.is_git_repo = is_repo
  for k, v in files {
    self.git_status[k] = v
  }
}

///|
/// Toggle git-only mode
fn FilerState::toggle_git_mode(self : FilerState) -> Unit {
  self.git_only_mode = not(self.git_only_mode)
  self.refresh()
}

///|
/// Toggle expand/collapse for selected directory
/// Returns: Some(file_path) if a file was selected, None if directory was toggled
fn FilerState::toggle_selected(self : FilerState) -> String? {
  if self.selected_idx < self.visible_items.length() {
    let item = self.visible_items[self.selected_idx]
    if item.is_dir {
      // Toggle expansion
      let currently_expanded = self.expanded_dirs
        .get(item.path)
        .unwrap_or(false)
      self.expanded_dirs[item.path] = not(currently_expanded)
      self.build_visible_items()
      None
    } else {
      // Return file path
      Some(item.path)
    }
  } else {
    None
  }
}

///|
/// Collapse selected directory (or parent if file/collapsed dir selected)
fn FilerState::collapse_selected(self : FilerState) -> Unit {
  if self.selected_idx < self.visible_items.length() {
    let item = self.visible_items[self.selected_idx]
    if item.is_dir && item.is_expanded {
      // Collapse this directory
      self.expanded_dirs[item.path] = false
      self.build_visible_items()
    } else if item.depth > 0 {
      // Find and select parent directory
      let parent_path = @ai.js_path_dirname(item.path)
      for i, vi in self.visible_items {
        if vi.path == parent_path {
          self.selected_idx = i
          break
        }
      }
    }
  }
}

///|
/// Enter the selected directory (change root) or return file path
fn FilerState::enter_selected(self : FilerState) -> String? {
  if self.selected_idx < self.visible_items.length() {
    let item = self.visible_items[self.selected_idx]
    if item.is_dir {
      // Change to this directory as new root
      self.current_dir = item.path
      self.expanded_dirs.clear()
      self.selected_idx = 0
      self.scroll_offset = 0
      self.refresh()
      None
    } else {
      Some(item.path)
    }
  } else {
    None
  }
}

///|
/// Load file content for preview (shows diff if file has git changes)
fn FilerState::load_preview(self : FilerState, file_path : String) -> Unit {
  self.preview_file = file_path
  self.preview_scroll_offset = 0 // Reset scroll on new file
  if self.is_git_repo {
    let diff = @ai.js_git_diff_file(file_path)
    if diff.length() > 0 {
      self.preview_content = diff
      self.preview_is_diff = true
      return
    }
  }
  self.preview_content = @ai.js_read_file_content(file_path)
  self.preview_is_diff = false
}

///|
/// Clear preview
fn FilerState::clear_preview(self : FilerState) -> Unit {
  self.preview_file = ""
  self.preview_content = ""
  self.preview_is_diff = false
  self.preview_scroll_offset = 0
}

///|
/// Scroll preview by delta lines (positive = down, negative = up)
fn FilerState::scroll_preview(
  self : FilerState,
  delta : Int,
  visible_height : Int,
) -> Unit {
  let total_lines = self.preview_content.split("\n").count()
  let max_offset = if total_lines > visible_height {
    total_lines - visible_height
  } else {
    0
  }
  let new_offset = self.preview_scroll_offset + delta
  self.preview_scroll_offset = if new_offset < 0 {
    0
  } else if new_offset > max_offset {
    max_offset
  } else {
    new_offset
  }
}

///|
/// Load preview for currently selected item (if it's a file)
fn FilerState::load_selected_preview(self : FilerState) -> Unit {
  if self.selected_idx < self.visible_items.length() {
    let item = self.visible_items[self.selected_idx]
    if not(item.is_dir) {
      self.load_preview(item.path)
    } else {
      self.clear_preview()
    }
  } else {
    self.clear_preview()
  }
}

///|
/// Navigate to parent directory
fn FilerState::go_up(self : FilerState) -> Unit {
  let parent = @ai.js_path_dirname(self.current_dir)
  if parent != self.current_dir {
    self.current_dir = parent
    self.expanded_dirs.clear()
    self.selected_idx = 0
    self.scroll_offset = 0
    self.refresh()
  }
}

///|
/// Move selection by delta (-1 for up, +1 for down)
fn FilerState::move_selection(self : FilerState, delta : Int) -> Unit {
  let new_idx = self.selected_idx + delta
  if new_idx >= 0 && new_idx < self.visible_items.length() {
    self.selected_idx = new_idx
  }
}

///|
/// Handle click at row position (0 = header, 1 = .., 2+ = items)
fn FilerState::handle_click(self : FilerState, row : Int) -> String? {
  if row == 0 {
    None
  } else if row == 1 {
    self.go_up()
    None
  } else {
    let item_idx = self.scroll_offset + (row - 2)
    if item_idx >= 0 && item_idx < self.visible_items.length() {
      self.selected_idx = item_idx
      let item = self.visible_items[item_idx]
      if item.is_dir {
        // Toggle expansion on click
        let currently_expanded = self.expanded_dirs
          .get(item.path)
          .unwrap_or(false)
        self.expanded_dirs[item.path] = not(currently_expanded)
        self.build_visible_items()
        None
      } else {
        Some(item.path)
      }
    } else {
      None
    }
  }
}

// =============================================================================
// Utilities
// =============================================================================

///|
/// Parse directory entries from JSON
fn parse_dir_entries(
  json : String,
  entries : Array[(String, Bool, GitStatus)],
  git_status : Map[String, String],
) -> Unit {
  let chars : Array[Char] = json.iter().collect()
  let mut i = 0
  let len = chars.length()
  fn skip_ws() -> Unit {
    while i < len &&
          (
            chars[i] == ' ' ||
            chars[i] == '\n' ||
            chars[i] == '\r' ||
            chars[i] == '\t'
          ) {
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
        let status = match git_status.get(name) {
          Some(s) => parse_git_status_code(s)
          None => GitStatus::None
        }
        entries.push((name, is_dir, status))
      }
    }
  }
}

///|
fn parse_git_status_code(code : String) -> GitStatus {
  if code.length() == 0 {
    return GitStatus::None
  }
  match code[0] {
    'M' => GitStatus::Modified
    'A' => GitStatus::Added
    'D' => GitStatus::Deleted
    '?' => GitStatus::Untracked
    'R' => GitStatus::Renamed
    _ => GitStatus::None
  }
}

///|
fn parse_git_status_json(json : String) -> (Map[String, String], Bool) {
  let files : Map[String, String] = {}
  let mut is_repo = false
  let chars : Array[Char] = json.iter().collect()
  let mut i = 0
  let len = chars.length()
  fn skip_ws() -> Unit {
    while i < len &&
          (
            chars[i] == ' ' ||
            chars[i] == '\n' ||
            chars[i] == '\r' ||
            chars[i] == '\t'
          ) {
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
  if i < len && chars[i] == '{' {
    i = i + 1
    while i < len && chars[i] != '}' {
      skip_ws()
      if chars[i] == '"' {
        let key = parse_string()
        skip_ws()
        if i < len && chars[i] == ':' {
          i = i + 1
        }
        skip_ws()
        if key == "is_repo" {
          is_repo = parse_bool()
        } else if key == "files" {
          if i < len && chars[i] == '{' {
            i = i + 1
            while i < len && chars[i] != '}' {
              skip_ws()
              if chars[i] == '"' {
                let file_path = parse_string()
                skip_ws()
                if i < len && chars[i] == ':' {
                  i = i + 1
                }
                skip_ws()
                let status = parse_string()
                files[file_path] = status
              }
              skip_ws()
              if i < len && chars[i] == ',' {
                i = i + 1
              }
            }
            if i < len {
              i = i + 1
            }
          }
        }
      }
      skip_ws()
      if i < len && chars[i] == ',' {
        i = i + 1
      }
    }
  }
  (files, is_repo)
}
