///|
/// Inline completion demo using AsyncCompletionManager
/// Demonstrates word-based input with async completion

// Completion candidates
let candidates : Array[String] = [
  "apple", "apricot", "avocado", "banana", "blueberry", "blackberry", "cherry", "coconut",
  "cranberry", "date", "elderberry", "fig", "grape", "grapefruit", "guava", "kiwi",
  "lemon", "lime", "mango", "melon", "nectarine", "orange", "papaya", "peach", "pear",
  "pineapple", "plum", "pomegranate", "raspberry", "strawberry", "tangerine", "watermelon",
]

///|
/// Filter candidates based on prefix
fn filter_candidates(input : String) -> Array[String] {
  if input.length() == 0 {
    return []
  }
  let lower_input = input.to_lower()
  candidates
  .iter()
  .filter(fn(c) { c.to_lower().has_prefix(lower_input) })
  .collect()
}

///|
/// Demo state using shared completion components
struct DemoState {
  manager : @comp.AsyncCompletionManager
  input : @comp.WordInputState
  running : @signals.Signal[Bool]
  cursor_row : Int
  cursor_col : Int
}

///|
fn DemoState::new(start_row : Int, start_col : Int) -> DemoState {
  {
    manager: @comp.AsyncCompletionManager::new(
      100, filter_candidates, @io.get_time_ms,
    ),
    input: @comp.WordInputState::new(),
    running: @signals.signal(true),
    cursor_row: start_row,
    cursor_col: start_col,
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
fn show_cursor() -> String {
  @render.ansi_show_cursor()
}

///|
fn hide_cursor() -> String {
  @render.ansi_hide_cursor()
}

///|
fn bg_dark() -> String {
  "\u001b[48;5;238m"
}

///|
fn bg_highlight() -> String {
  "\u001b[48;5;24m"
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
fn clear_to_end() -> String {
  "\u001b[K"
}

// =============================================================================
// UI Constants
// =============================================================================

///|
let max_popup_items : Int = 5

///|
let popup_width : Int = 20

///|
fn pad_right(s : String, width : Int) -> String {
  if s.length() >= width {
    s
  } else {
    s + " ".repeat(width - s.length())
  }
}

// =============================================================================
// Rendering
// =============================================================================

///|
fn render_input(state : DemoState) -> Unit {
  let engine = state.manager.get_engine()
  let confirmed = state.input.get_confirmed()
  let current = state.input.get_current()
  let items = engine.get_items()
  let selected = engine.get_selected_idx()
  let visible = engine.is_visible()
  let loading = engine.is_loading()
  pr(move_to(state.cursor_row, state.cursor_col))
  pr(clear_to_end())

  // Show confirmed text + current word
  if confirmed.length() > 0 {
    pr(white() + confirmed + reset())
  }
  pr(white() + current + reset())

  // Show loading indicator or ghost text
  if loading {
    pr(dim() + " ..." + reset())
  } else if visible && selected < items.length() {
    let completion = items[selected]
    if completion.length() > current.length() {
      let suffix = completion.unsafe_substring(
        start=current.length(),
        end=completion.length(),
      )
      pr(dim() + suffix + reset())
    }
  }
  let full_len = confirmed.length() + current.length()
  pr(move_to(state.cursor_row, state.cursor_col + full_len))
}

///|
fn render_popup(state : DemoState) -> Unit {
  let engine = state.manager.get_engine()
  let items = engine.get_items()
  let selected = engine.get_selected_idx()
  let visible = engine.is_visible()
  let query = engine.get_input()
  let confirmed = state.input.get_confirmed()
  let loading = engine.is_loading()
  let current = state.input.get_current()
  let popup_row = state.cursor_row + 1
  let popup_col = state.cursor_col + confirmed.length()

  // Clear popup area
  for i = 0; i < max_popup_items + 2; i = i + 1 {
    pr(move_to(popup_row + i, popup_col))
    pr(clear_to_end())
  }

  // Show loading indicator
  if loading && current.length() > 0 {
    pr(move_to(popup_row, popup_col))
    pr(bg_dark() + yellow() + pad_right(" Loading...", popup_width) + reset())
    return
  }
  if not(visible) || items.length() == 0 {
    return
  }
  let item_count = if items.length() > max_popup_items {
    max_popup_items
  } else {
    items.length()
  }
  for i = 0; i < item_count; i = i + 1 {
    pr(move_to(popup_row + i, popup_col))
    let item = items[i]
    if i == selected {
      pr(bg_highlight() + bold() + cyan() + query + reset() + bg_highlight())
      if item.length() > query.length() {
        pr(
          white() +
          item.unsafe_substring(start=query.length(), end=item.length()),
        )
      }
      if item.length() < popup_width {
        pr(" ".repeat(popup_width - item.length()))
      }
      pr(reset())
    } else {
      pr(bg_dark() + white() + query)
      if item.length() > query.length() {
        pr(
          dim() + item.unsafe_substring(start=query.length(), end=item.length()),
        )
      }
      if item.length() < popup_width {
        pr(" ".repeat(popup_width - item.length()))
      }
      pr(reset())
    }
  }
  if items.length() > max_popup_items {
    pr(move_to(popup_row + item_count, popup_col))
    let more_text = "..." +
      (items.length() - max_popup_items).to_string() +
      " more"
    pr(bg_dark() + dim() + pad_right(more_text, popup_width) + reset())
  }
}

///|
fn render_help(state : DemoState) -> Unit {
  let help_row = state.cursor_row + max_popup_items + 3
  pr(move_to(help_row, state.cursor_col))
  pr(
    dim() +
    "↑↓: select  Tab: confirm  Space: next word  Ctrl+C: quit" +
    reset(),
  )
}

///|
fn render_all(state : DemoState) -> Unit {
  pr(hide_cursor())
  render_input(state)
  render_popup(state)
  render_help(state)
  let full_len = state.input.get_full_text().length()
  pr(move_to(state.cursor_row, state.cursor_col + full_len))
  pr(show_cursor())
}

// =============================================================================
// Actions
// =============================================================================

///|
fn confirm_completion(state : DemoState) -> Unit {
  let engine = state.manager.get_engine()
  match engine.get_selected_item() {
    Some(item) => state.input.set_current(item)
    None => ()
  }
  engine.hide()
  state.manager.clear_pending()
}

///|
fn confirm_word(state : DemoState, separator : String) -> Unit {
  let engine = state.manager.get_engine()
  let current = state.input.get_current()
  let word = match engine.get_selected_item() {
    Some(item) if engine.is_visible() => item
    _ => current
  }
  state.input.confirm_word(word, separator)
  engine.clear()
  state.manager.clear_pending()
}

///|
fn clear_popup_area(state : DemoState, col_offset : Int) -> Unit {
  let popup_row = state.cursor_row + 1
  let popup_col = state.cursor_col + col_offset
  for i = 0; i < max_popup_items + 2; i = i + 1 {
    pr(move_to(popup_row + i, popup_col))
    pr(clear_to_end())
  }
}

// =============================================================================
// Event Handling
// =============================================================================

///|
fn handle_key(key : String, state : DemoState) -> Unit {
  if key.length() == 0 || not(state.running.get()) {
    return
  }

  // Check for pending completion
  if state.manager.check_pending() {
    render_all(state)
  }
  let event = @events.parse_input(key)
  let engine = state.manager.get_engine()
  if event.is_ctrl_c() {
    @io.stop_keypress_listener()
    pr(show_cursor())
    pr(exit_alt_screen())
    let result = state.input.get_full_text()
    if result.length() > 0 {
      pr("Result: " + result + "\n")
    } else {
      pr("Cancelled\n")
    }
    state.running.set(false)
    return
  }
  if event.is_escape() {
    if engine.is_visible() {
      engine.hide()
      render_all(state)
    }
    return
  }

  // Arrow keys for navigation
  if engine.is_visible() && engine.get_items().length() > 0 {
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
  }

  // Tab to confirm completion
  if event.is_tab() {
    if engine.is_visible() {
      confirm_completion(state)
      render_all(state)
    }
    return
  }

  // Enter to confirm word
  if event.is_enter() {
    if state.input.get_current().length() > 0 ||
      state.input.get_confirmed().length() > 0 {
      confirm_word(state, " ")
      clear_popup_area(state, 0)
      render_all(state)
    }
    return
  }

  // Character input
  match event {
    @events.InputEvent::Key(@events.KeyEvent::Char(c, _)) =>
      if c == ' ' {
        if state.input.get_current().length() > 0 {
          confirm_word(state, " ")
          clear_popup_area(state, state.input.get_confirmed().length())
        } else {
          state.input.confirm_word("", " ")
        }
        render_all(state)
      } else {
        state.input.append_char(c)
        state.manager.request(state.input.get_current())
        render_all(state)
      }
    @events.InputEvent::Key(
      @events.KeyEvent::Special(@events.SpecialKey::Backspace, _)
    ) => {
      if not(state.input.delete_char()) {
        // Current was empty, try to restore previous word
        ignore(state.input.restore_previous_word())
      }
      // Hide completion on delete (don't trigger new completion)
      state.manager.get_engine().clear()
      state.manager.clear_pending()
      // Clear popup area before re-render
      let popup_row = state.cursor_row + 1
      for i = 0; i < max_popup_items + 3; i = i + 1 {
        pr(move_to(popup_row + i, 1))
        pr(clear_to_end())
      }
      render_all(state)
    }
    _ => ()
  }
}

// =============================================================================
// Main
// =============================================================================

///|
fn main {
  let start_row = 3
  let start_col = 3
  let state = DemoState::new(start_row, start_col)
  pr(enter_alt_screen())
  pr(hide_cursor())
  pr("\u001b[2J")
  pr(move_to(1, start_col))
  pr(bold() + cyan() + "◆ Async Completion Demo" + reset())
  pr(move_to(2, start_col))
  pr(
    dim() +
    "Type to search fruits - completion appears after 100ms delay" +
    reset(),
  )
  render_all(state)

  // Set idle handler for async completion checks
  @io.set_idle_handler(fn() {
    if state.manager.check_pending() {
      render_all(state)
    }
  })
  @io.start_keypress_listener(fn(key) { handle_key(key, state) })
}
