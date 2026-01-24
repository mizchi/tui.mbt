///|
/// Command Launcher - Raycast-like popup for filtering and executing commands
/// Demonstrates modal overlay with async completion

// Available commands
let commands : Array[Command] = [
  { name: "New File", icon: "+" },
  { name: "Open File", icon: "O" },
  { name: "Save File", icon: "S" },
  { name: "Close File", icon: "X" },
  { name: "Undo", icon: "U" },
  { name: "Redo", icon: "R" },
  { name: "Cut", icon: "X" },
  { name: "Copy", icon: "C" },
  { name: "Paste", icon: "V" },
  { name: "Find", icon: "F" },
  { name: "Find and Replace", icon: "H" },
  { name: "Zoom In", icon: "+" },
  { name: "Zoom Out", icon: "-" },
  { name: "Toggle Sidebar", icon: "|" },
  { name: "Git Commit", icon: "G" },
  { name: "Git Push", icon: "P" },
  { name: "Git Pull", icon: "D" },
  { name: "New Terminal", icon: "T" },
  { name: "Clear Terminal", icon: "C" },
  { name: "Open Settings", icon: "*" },
  { name: "Open Documentation", icon: "?" },
  { name: "About", icon: "i" },
]

///|
struct Command {
  name : String
  icon : String
}

///|
/// Filter commands based on query (fuzzy match on name)
fn filter_commands(query : String) -> Array[String] {
  if query.length() == 0 {
    return commands.iter().map(fn(c) { c.name }).collect()
  }
  let lower_query = query.to_lower()
  commands
  .iter()
  .filter(fn(c) { c.name.to_lower().contains(lower_query) })
  .map(fn(c) { c.name })
  .collect()
}

///|
/// Get command by name
fn get_command(name : String) -> Command? {
  for c in commands {
    if c.name == name {
      return Some(c)
    }
  }
  None
}

///|
/// App state
struct AppState {
  manager : @comp.AsyncCompletionManager
  mut input : String
  mut launcher_open : Bool
  running : @signals.Signal[Bool]
  mut last_command : String
  screen_width : Int
  screen_height : Int
}

///|
fn AppState::new(width : Int, height : Int) -> AppState {
  {
    manager: @comp.AsyncCompletionManager::new(
      50, filter_commands, @io.get_time_ms,
    ),
    input: "",
    launcher_open: false,
    running: @signals.signal(true),
    last_command: "",
    screen_width: width,
    screen_height: height,
  }
}

// =============================================================================
// ANSI Helpers
// =============================================================================

///|
fn pr(s : String) -> Unit {
  @io.print_raw(s)
}

///|
fn reset() -> String {
  @render.ansi_reset()
}

///|
fn bold() -> String {
  @render.ansi_bold()
}

///|
fn dim() -> String {
  @render.ansi_dim()
}

///|
fn cyan() -> String {
  @render.ansi_fg_cyan()
}

///|
fn white() -> String {
  @render.ansi_fg_white()
}

///|
fn yellow() -> String {
  @render.ansi_fg_yellow()
}

///|
fn green() -> String {
  @render.ansi_fg_green()
}

///|
fn show_cursor() -> String {
  @render.ansi_show_cursor()
}

///|
fn hide_cursor() -> String {
  @render.ansi_hide_cursor()
}

///|
fn bg_dark() -> String {
  "\u001b[48;5;236m"
}

///|
fn bg_highlight() -> String {
  "\u001b[48;5;24m"
}

///|
fn bg_overlay() -> String {
  "\u001b[48;5;234m"
}

///|
fn enter_alt_screen() -> String {
  "\u001b[?1049h"
}

///|
fn exit_alt_screen() -> String {
  "\u001b[?1049l"
}

///|
fn move_to(row : Int, col : Int) -> String {
  "\u001b[" + row.to_string() + ";" + col.to_string() + "H"
}

///|
fn clear_screen() -> String {
  "\u001b[2J"
}

// =============================================================================
// UI Constants
// =============================================================================

///|
let launcher_width : Int = 50

///|
let max_visible_items : Int = 10

// =============================================================================
// Rendering
// =============================================================================

///|
fn render_background(state : AppState) -> Unit {
  // Draw background app UI
  pr(move_to(1, 2))
  pr(bold() + cyan() + "Command Launcher Demo" + reset())
  pr(move_to(3, 2))
  pr(
    dim() +
    "Press " +
    reset() +
    yellow() +
    "Ctrl+P" +
    reset() +
    dim() +
    " to open command palette" +
    reset(),
  )
  pr(move_to(4, 2))
  pr(
    dim() +
    "Press " +
    reset() +
    yellow() +
    "Ctrl+C" +
    reset() +
    dim() +
    " to quit" +
    reset(),
  )
  // Show last executed command
  if state.last_command.length() > 0 {
    pr(move_to(6, 2))
    pr(
      green() +
      "Last command: " +
      reset() +
      white() +
      state.last_command +
      reset(),
    )
  }
  // Draw fake app content
  pr(move_to(8, 2))
  pr(dim() + "─".repeat(state.screen_width - 4) + reset())
  pr(move_to(9, 2))
  pr(dim() + "  [Editor]  |  [Terminal]  |  [Output]" + reset())
  pr(move_to(10, 2))
  pr(dim() + "─".repeat(state.screen_width - 4) + reset())
  for i = 11; i < state.screen_height - 2; i = i + 1 {
    pr(move_to(i, 2))
    pr(dim() + "│" + reset())
    pr(move_to(i, state.screen_width - 2))
    pr(dim() + "│" + reset())
  }
  pr(move_to(state.screen_height - 2, 2))
  pr(dim() + "─".repeat(state.screen_width - 4) + reset())
}

///|
fn render_launcher(state : AppState) -> Unit {
  if not(state.launcher_open) {
    return
  }
  let engine = state.manager.get_engine()
  let items = engine.get_items()
  let selected = engine.get_selected_idx()
  let loading = engine.is_loading()
  // Calculate launcher position (centered)
  let launcher_left = (state.screen_width - launcher_width) / 2
  let launcher_top = 4
  // Draw overlay background
  for row = launcher_top - 1
      row <= launcher_top + max_visible_items + 4
      row = row + 1 {
    pr(move_to(row, launcher_left - 1))
    pr(bg_overlay() + " ".repeat(launcher_width + 2) + reset())
  }
  // Draw launcher border
  pr(move_to(launcher_top - 1, launcher_left))
  pr(cyan() + "╭" + "─".repeat(launcher_width - 2) + "╮" + reset())
  // Draw search input
  pr(move_to(launcher_top, launcher_left))
  pr(cyan() + "│" + reset())
  pr(bg_dark())
  pr(" > " + white() + state.input + reset() + bg_dark())
  if loading {
    pr(dim() + " ..." + reset() + bg_dark())
  }
  let input_len = 3 + state.input.length() + (if loading { 4 } else { 0 })
  if input_len < launcher_width - 2 {
    pr(" ".repeat(launcher_width - 2 - input_len))
  }
  pr(reset())
  pr(cyan() + "│" + reset())
  // Draw separator
  pr(move_to(launcher_top + 1, launcher_left))
  pr(cyan() + "├" + "─".repeat(launcher_width - 2) + "┤" + reset())
  // Draw items
  let item_count = if items.length() > max_visible_items {
    max_visible_items
  } else {
    items.length()
  }
  for i = 0; i < max_visible_items; i = i + 1 {
    let row = launcher_top + 2 + i
    pr(move_to(row, launcher_left))
    pr(cyan() + "│" + reset())
    if i < item_count {
      let item = items[i]
      let cmd = get_command(item)
      let icon = match cmd {
        Some(c) => c.icon
        None => " "
      }
      if i == selected {
        pr(bg_highlight())
        pr(" " + cyan() + icon + " " + reset() + bg_highlight())
        pr(bold() + white() + item + reset() + bg_highlight())
        let len = 3 + item.length()
        if len < launcher_width - 2 {
          pr(" ".repeat(launcher_width - 2 - len))
        }
        pr(reset())
      } else {
        pr(bg_dark())
        pr(" " + dim() + icon + " " + reset() + bg_dark())
        pr(white() + item + reset() + bg_dark())
        let len = 3 + item.length()
        if len < launcher_width - 2 {
          pr(" ".repeat(launcher_width - 2 - len))
        }
        pr(reset())
      }
    } else {
      pr(bg_dark() + " ".repeat(launcher_width - 2) + reset())
    }
    pr(cyan() + "│" + reset())
  }
  // Draw footer with count
  pr(move_to(launcher_top + 2 + max_visible_items, launcher_left))
  pr(cyan() + "├" + "─".repeat(launcher_width - 2) + "┤" + reset())
  pr(move_to(launcher_top + 3 + max_visible_items, launcher_left))
  pr(cyan() + "│" + reset())
  pr(bg_dark())
  let count_text = " " + items.length().to_string() + " commands"
  pr(dim() + count_text + reset() + bg_dark())
  let hint = "Enter: run  Esc: close"
  let footer_len = count_text.length() + hint.length()
  if footer_len < launcher_width - 2 {
    pr(" ".repeat(launcher_width - 2 - footer_len))
  }
  pr(dim() + hint + reset() + bg_dark())
  pr(reset())
  pr(cyan() + "│" + reset())
  // Draw bottom border
  pr(move_to(launcher_top + 4 + max_visible_items, launcher_left))
  pr(cyan() + "╰" + "─".repeat(launcher_width - 2) + "╯" + reset())
}

///|
fn render_all(state : AppState) -> Unit {
  pr(hide_cursor())
  pr(clear_screen())
  render_background(state)
  render_launcher(state)
  if state.launcher_open {
    // Position cursor in input
    let launcher_left = (state.screen_width - launcher_width) / 2
    let cursor_col = launcher_left + 4 + state.input.length()
    pr(move_to(4, cursor_col))
  }
  pr(show_cursor())
}

// =============================================================================
// Actions
// =============================================================================

///|
fn open_launcher(state : AppState) -> Unit {
  state.launcher_open = true
  state.input = ""
  state.manager.get_engine().clear()
  state.manager.request("")
}

///|
fn close_launcher(state : AppState) -> Unit {
  state.launcher_open = false
  state.input = ""
  state.manager.get_engine().clear()
}

///|
fn execute_command(state : AppState) -> Unit {
  let engine = state.manager.get_engine()
  match engine.get_selected_item() {
    Some(name) => {
      state.last_command = name
      close_launcher(state)
    }
    None => ()
  }
}

// =============================================================================
// Event Handling
// =============================================================================

///|
fn handle_key(key : String, state : AppState) -> Unit {
  if key.length() == 0 || not(state.running.get()) {
    return
  }
  // Check for pending completion
  if state.manager.check_pending() {
    render_all(state)
  }
  let event = @events.parse_input(key)
  let engine = state.manager.get_engine()
  // Ctrl+C: quit
  if event.is_ctrl_c() {
    @io.stop_keypress_listener()
    pr(show_cursor())
    pr(exit_alt_screen())
    pr("Bye!\n")
    state.running.set(false)
    return
  }
  // Ctrl+P: toggle launcher
  if event.is_ctrl('p') {
    if state.launcher_open {
      close_launcher(state)
    } else {
      open_launcher(state)
    }
    render_all(state)
    return
  }
  // Launcher-specific keys
  if state.launcher_open {
    // Escape: close launcher
    if event.is_escape() {
      close_launcher(state)
      render_all(state)
      return
    }
    // Arrow keys: navigate
    match event.is_arrow() {
      Some(@events.SpecialKey::Up) => {
        engine.select_prev()
        render_all(state)
        return
      }
      Some(@events.SpecialKey::Down) => {
        engine.select_next()
        render_all(state)
        return
      }
      _ => ()
    }
    // Enter: execute
    if event.is_enter() {
      execute_command(state)
      render_all(state)
      return
    }
    // Tab: select and keep open
    if event.is_tab() {
      match engine.get_selected_item() {
        Some(item) => {
          state.input = item
          state.manager.request(state.input)
        }
        None => ()
      }
      render_all(state)
      return
    }
    // Character input
    match event {
      @events.InputEvent::Key(@events.KeyEvent::Char(c, _)) => {
        state.input = state.input + c.to_string()
        state.manager.request(state.input)
        render_all(state)
      }
      @events.InputEvent::Key(
        @events.KeyEvent::Special(@events.SpecialKey::Backspace, _)
      ) => {
        if state.input.length() > 0 {
          let chars = state.input.iter().collect()
          let new_len = chars.length() - 1
          let buf = StringBuilder::new()
          for i = 0; i < new_len; i = i + 1 {
            buf.write_char(chars[i])
          }
          state.input = buf.to_string()
          state.manager.request(state.input)
        }
        render_all(state)
      }
      _ => ()
    }
  }
}

// =============================================================================
// Main
// =============================================================================

///|
fn main {
  let width = 80
  let height = 24
  let state = AppState::new(width, height)
  pr(enter_alt_screen())
  pr(hide_cursor())
  render_all(state)
  // Set idle handler for async completion
  @io.set_idle_handler(fn() {
    if state.launcher_open && state.manager.check_pending() {
      render_all(state)
    }
  })
  @io.start_keypress_listener(fn(key) { handle_key(key, state) })
}
