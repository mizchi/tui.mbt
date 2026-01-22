///|
/// Inline completion like IDE/zsh
/// Shows suggestions below cursor, selecting updates input in real-time
/// Space/Enter confirms current word and starts new completion

// Completion candidates
let candidates : Array[String] = [
  "apple", "apricot", "avocado", "banana", "blueberry", "blackberry", "cherry",
  "coconut", "cranberry", "date", "elderberry", "fig", "grape", "grapefruit",
  "guava", "kiwi", "lemon", "lime", "mango", "melon", "nectarine", "orange",
  "papaya", "peach", "pear", "pineapple", "plum", "pomegranate", "raspberry",
  "strawberry", "tangerine", "watermelon",
]

///|
/// Completion state
struct CompletionState {
  // Full text (confirmed words + spaces)
  confirmed_text : @signals.Signal[String]
  // Current word being typed (for completion matching)
  current_word : @signals.Signal[String]
  // Popup state
  popup_visible : @signals.Signal[Bool]
  selected_idx : @signals.Signal[Int]
  filtered : @signals.Signal[Array[String]]
  running : @signals.Signal[Bool]
  // Cursor row for popup positioning
  cursor_row : Int
  cursor_col : Int
}

///|
fn CompletionState::new(start_row : Int, start_col : Int) -> CompletionState {
  {
    confirmed_text: @signals.signal(""),
    current_word: @signals.signal(""),
    popup_visible: @signals.signal(false),
    selected_idx: @signals.signal(0),
    filtered: @signals.signal([]),
    running: @signals.signal(true),
    cursor_row: start_row,
    cursor_col: start_col,
  }
}

///|
/// Get full display text
fn get_full_text(state : CompletionState) -> String {
  state.confirmed_text.get() + state.current_word.get()
}

///|
/// Filter candidates based on input prefix
fn filter_candidates(input : String) -> Array[String] {
  if input.length() == 0 {
    return []
  }
  let lower_input = input.to_lower()
  candidates.iter().filter(fn(c) { c.to_lower().has_prefix(lower_input) }).collect()
}

///|
fn pr(s : String) -> Unit {
  @io.print_raw(s)
}

// ANSI helpers
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
fn show_cursor() -> String {
  @render.ansi_show_cursor()
}

///|
fn hide_cursor() -> String {
  @render.ansi_hide_cursor()
}

///|
/// Dark background for popup
fn bg_dark() -> String {
  "\u001b[48;5;238m"
}

///|
/// Highlight background for selected item
fn bg_highlight() -> String {
  "\u001b[48;5;24m"
}

///|
/// Enter alternate screen buffer
fn enter_alt_screen() -> String {
  "\u001b[?1049h"
}

///|
/// Exit alternate screen buffer
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

let max_popup_items : Int = 5
let popup_width : Int = 20

///|
/// Pad string to fixed width
fn pad_right(s : String, width : Int) -> String {
  if s.length() >= width {
    s
  } else {
    s + " ".repeat(width - s.length())
  }
}

///|
/// Render input line with completion ghost text
fn render_input(state : CompletionState) -> Unit {
  let confirmed = state.confirmed_text.get()
  let current = state.current_word.get()
  let filtered = state.filtered.get()
  let selected = state.selected_idx.get()
  let popup_visible = state.popup_visible.get()

  // Move to input position and clear
  pr(move_to(state.cursor_row, state.cursor_col))
  pr(clear_to_end())

  // Show confirmed text (white) + current word (white)
  if confirmed.length() > 0 {
    pr(white() + confirmed + reset())
  }
  pr(white() + current + reset())

  // Show completion suffix as ghost text (dimmed)
  if popup_visible && selected < filtered.length() {
    let completion = filtered[selected]
    if completion.length() > current.length() {
      let suffix_start = current.length()
      let chars : Array[Char] = completion.iter().collect()
      let suffix : Array[Char] = []
      for i = suffix_start; i < chars.length(); i = i + 1 {
        suffix.push(chars[i])
      }
      pr(dim() + String::from_array(suffix) + reset())
    }
  }

  // Position cursor at end of input
  let full_len = confirmed.length() + current.length()
  pr(move_to(state.cursor_row, state.cursor_col + full_len))
}

///|
/// Render popup below input with background
fn render_popup(state : CompletionState) -> Unit {
  let filtered = state.filtered.get()
  let selected = state.selected_idx.get()
  let visible = state.popup_visible.get()
  let current = state.current_word.get()
  let confirmed = state.confirmed_text.get()

  // Popup starts right below the current word position
  let popup_row = state.cursor_row + 1
  let popup_col = state.cursor_col + confirmed.length()

  // Clear popup area
  for i = 0; i < max_popup_items + 2; i = i + 1 {
    pr(move_to(popup_row + i, popup_col))
    pr(clear_to_end())
  }

  if not(visible) || filtered.length() == 0 {
    return
  }

  let item_count = if filtered.length() > max_popup_items {
    max_popup_items
  } else {
    filtered.length()
  }

  // Render each item with background
  for i = 0; i < item_count; i = i + 1 {
    pr(move_to(popup_row + i, popup_col))

    let item = filtered[i]

    if i == selected {
      // Highlight selected item with bright background
      pr(bg_highlight() + bold())
      // Matching prefix in cyan
      pr(cyan() + current + reset())
      pr(bg_highlight())
      // Rest of the word
      if item.length() > current.length() {
        let chars : Array[Char] = item.iter().collect()
        let rest : Array[Char] = []
        for j = current.length(); j < chars.length(); j = j + 1 {
          rest.push(chars[j])
        }
        pr(white() + String::from_array(rest))
      }
      // Pad remaining space
      let item_len = item.length()
      if item_len < popup_width {
        pr(" ".repeat(popup_width - item_len))
      }
      pr(reset())
    } else {
      // Normal item with dark background
      pr(bg_dark())
      // Matching prefix
      pr(white() + current)
      // Rest dimmed
      if item.length() > current.length() {
        let chars : Array[Char] = item.iter().collect()
        let rest : Array[Char] = []
        for j = current.length(); j < chars.length(); j = j + 1 {
          rest.push(chars[j])
        }
        pr(dim() + String::from_array(rest))
      }
      // Pad remaining space
      let item_len = item.length()
      if item_len < popup_width {
        pr(" ".repeat(popup_width - item_len))
      }
      pr(reset())
    }
  }

  // More indicator
  if filtered.length() > max_popup_items {
    pr(move_to(popup_row + item_count, popup_col))
    let more_text = "..." + (filtered.length() - max_popup_items).to_string() + " more"
    pr(bg_dark() + dim() + pad_right(more_text, popup_width) + reset())
  }
}

///|
/// Render help
fn render_help(state : CompletionState) -> Unit {
  let help_row = state.cursor_row + max_popup_items + 3
  pr(move_to(help_row, state.cursor_col))
  pr(dim() + "↑↓: select  Tab: confirm  Space: next word  Ctrl+C: quit" + reset())
}

///|
/// Full render
fn render_all(state : CompletionState) -> Unit {
  pr(hide_cursor())
  render_input(state)
  render_popup(state)
  render_help(state)
  // Keep cursor at input position
  let full_len = state.confirmed_text.get().length() +
    state.current_word.get().length()
  pr(move_to(state.cursor_row, state.cursor_col + full_len))
  pr(show_cursor())
}

///|
/// Update filtered list and show popup
fn update_completion(state : CompletionState) -> Unit {
  let current = state.current_word.get()
  let filtered = filter_candidates(current)
  state.filtered.set(filtered)
  state.selected_idx.set(0)

  if filtered.length() > 0 {
    state.popup_visible.set(true)
  } else {
    state.popup_visible.set(false)
  }
}

///|
/// Select completion and update display
fn select_completion(state : CompletionState, idx : Int) -> Unit {
  let filtered = state.filtered.get()
  if idx >= 0 && idx < filtered.length() {
    state.selected_idx.set(idx)
  }
}

///|
/// Confirm completion (Tab)
fn confirm_completion(state : CompletionState) -> Unit {
  let filtered = state.filtered.get()
  let selected = state.selected_idx.get()
  if selected < filtered.length() {
    state.current_word.set(filtered[selected])
  }
  state.popup_visible.set(false)
  state.filtered.set([])
}

///|
/// Confirm word and start new (Space/Enter)
fn confirm_word(state : CompletionState, separator : String) -> Unit {
  let filtered = state.filtered.get()
  let selected = state.selected_idx.get()
  let current = state.current_word.get()

  // Use selected completion or current word
  let word = if state.popup_visible.get() && selected < filtered.length() {
    filtered[selected]
  } else {
    current
  }

  // Add to confirmed text with separator
  let confirmed = state.confirmed_text.get()
  state.confirmed_text.set(confirmed + word + separator)
  state.current_word.set("")
  state.popup_visible.set(false)
  state.filtered.set([])
  state.selected_idx.set(0)
}

///|
/// Cancel completion
fn cancel_completion(state : CompletionState) -> Unit {
  state.popup_visible.set(false)
  state.filtered.set([])
}

///|
/// Handle key input
fn handle_key(key : String, state : CompletionState) -> Unit {
  if key.length() == 0 || not(state.running.get()) {
    return
  }

  let event = @events.parse_input(key)

  // Ctrl+C to quit
  if @events.is_ctrl_c(event) {
    @io.stop_keypress_listener()
    pr(show_cursor())
    pr(exit_alt_screen())
    let result = get_full_text(state)
    if result.length() > 0 {
      pr("Result: " + result + "\n")
    } else {
      pr("Cancelled\n")
    }
    state.running.set(false)
    return
  }

  let popup_visible = state.popup_visible.get()
  let filtered = state.filtered.get()
  let selected = state.selected_idx.get()

  // Escape to cancel popup
  if @events.is_escape(event) {
    if popup_visible {
      cancel_completion(state)
      render_all(state)
    }
    return
  }

  // Arrow keys for navigation when popup is visible
  if popup_visible && filtered.length() > 0 {
    let arrow = @events.is_arrow(event)
    match arrow {
      Some(@events.SpecialKey::Up) => {
        let new_idx = if selected > 0 {
          selected - 1
        } else {
          filtered.length() - 1
        }
        select_completion(state, new_idx)
        render_all(state)
        return
      }
      Some(@events.SpecialKey::Down) => {
        let new_idx = if selected < filtered.length() - 1 {
          selected + 1
        } else {
          0
        }
        select_completion(state, new_idx)
        render_all(state)
        return
      }
      _ => ()
    }
  }

  // Tab to confirm completion (keep in same word)
  if @events.is_tab(event) {
    if popup_visible {
      confirm_completion(state)
      render_all(state)
    }
    return
  }

  // Enter to confirm word and start new line (for demo, just confirm word)
  if @events.is_enter(event) {
    let current = state.current_word.get()
    if current.length() > 0 || state.confirmed_text.get().length() > 0 {
      confirm_word(state, " ")
      // Clear popup area before re-render
      let popup_row = state.cursor_row + 1
      let popup_col = state.cursor_col
      for i = 0; i < max_popup_items + 2; i = i + 1 {
        pr(move_to(popup_row + i, popup_col))
        pr(clear_to_end())
      }
      render_all(state)
    }
    return
  }

  // Text input
  match event {
    @events.InputEvent::Key(@events.KeyEvent::Char(c, _)) => {
      // Space confirms current word and starts new
      if c == ' ' {
        let current = state.current_word.get()
        if current.length() > 0 {
          confirm_word(state, " ")
          // Clear popup area
          let confirmed = state.confirmed_text.get()
          let popup_row = state.cursor_row + 1
          let popup_col = state.cursor_col + confirmed.length()
          for i = 0; i < max_popup_items + 2; i = i + 1 {
            pr(move_to(popup_row + i, popup_col))
            pr(clear_to_end())
          }
        } else {
          // Just add space to confirmed if no current word
          let confirmed = state.confirmed_text.get()
          state.confirmed_text.set(confirmed + " ")
        }
        render_all(state)
      } else {
        // Regular character - add to current word
        let current = state.current_word.get()
        state.current_word.set(current + c.to_string())
        update_completion(state)
        render_all(state)
      }
    }
    @events.InputEvent::Key(
      @events.KeyEvent::Special(@events.SpecialKey::Backspace, _),
    ) => {
      let current = state.current_word.get()
      if current.length() > 0 {
        // Remove from current word
        let chars : Array[Char] = current.iter().collect()
        let new_chars : Array[Char] = []
        for i = 0; i < chars.length() - 1; i = i + 1 {
          new_chars.push(chars[i])
        }
        state.current_word.set(String::from_array(new_chars))
        update_completion(state)
      } else {
        // Remove from confirmed text (including separator)
        let confirmed = state.confirmed_text.get()
        if confirmed.length() > 0 {
          let chars : Array[Char] = confirmed.iter().collect()
          // Find last word boundary
          let mut last_space = -1
          for i = 0; i < chars.length() - 1; i = i + 1 {
            if chars[i] == ' ' {
              last_space = i
            }
          }
          if last_space >= 0 {
            // Restore last word to current_word
            let new_confirmed : Array[Char] = []
            for i = 0; i <= last_space; i = i + 1 {
              new_confirmed.push(chars[i])
            }
            let restored_word : Array[Char] = []
            for i = last_space + 1; i < chars.length(); i = i + 1 {
              restored_word.push(chars[i])
            }
            state.confirmed_text.set(String::from_array(new_confirmed))
            state.current_word.set(String::from_array(restored_word))
            update_completion(state)
          } else {
            // No space, restore all to current_word
            state.confirmed_text.set("")
            state.current_word.set(confirmed)
            update_completion(state)
          }
        }
      }
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

///|
fn main {
  // Starting position
  let start_row = 3
  let start_col = 3

  let state = CompletionState::new(start_row, start_col)

  // Enter alternate screen buffer and hide cursor
  pr(enter_alt_screen())
  pr(hide_cursor())

  // Clear screen and show header
  pr("\u001b[2J")
  pr(move_to(1, start_col))
  pr(bold() + cyan() + "◆ Inline Completion Demo" + reset())
  pr(move_to(2, start_col))
  pr(dim() + "Type to search fruits (e.g., 'ap' for apple/apricot)" + reset())

  // Initial render
  render_all(state)

  // Start event loop
  @io.start_keypress_listener(fn(key) { handle_key(key, state) })
}
