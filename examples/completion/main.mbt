///|
/// VNode Completion Demo - Inline completion with dropdown overlay

// Completion candidates
let candidates : Array[String] = [
  "apple", "apricot", "avocado", "banana", "blueberry", "blackberry", "cherry", "coconut",
  "cranberry", "date", "elderberry", "fig", "grape", "grapefruit", "guava", "kiwi",
  "lemon", "lime", "mango", "melon", "nectarine", "orange", "papaya", "peach", "pear",
  "pineapple", "plum", "pomegranate", "raspberry", "strawberry", "tangerine", "watermelon",
]

///|
fn filter_candidates(query : String) -> Array[String] {
  if query.length() == 0 {
    return []
  }
  let lower_query = query.to_lower()
  candidates
  .iter()
  .filter(fn(c) { c.to_lower().has_prefix(lower_query) })
  .collect()
}

///|
fn main {
  let (width, height) = @tui.get_terminal_size()

  // State
  let input = @signals.signal("")
  let selected_idx = @signals.signal(0)
  let confirmed_words : Array[String] = []
  let app = @vnode.VNodeApp::new(width, height)
  let max_items = 5
  let popup_width = 20

  // Popup suppression flag:
  // - Set to true after Tab confirmation (hide until next typing)
  // - Set to true after Backspace (hide while deleting)
  // - Reset to false when typing new characters
  let suppress_popup : Ref[Bool] = Ref::new(false)
  fn get_matches() -> Array[String] {
    filter_candidates(input.get())
  }

  fn should_show_popup() -> Bool {
    not(suppress_popup.val) && input.get().length() > 0
  }

  fn get_confirmed_text() -> String {
    let buf = StringBuilder::new()
    for word in confirmed_words {
      buf.write_string(word)
      buf.write_string(" ")
    }
    buf.to_string()
  }

  fn get_full_text() -> String {
    get_confirmed_text() + input.get()
  }

  fn render_popup_item(item : String, idx : Int) -> @vnode.TuiNode {
    let is_selected = idx == selected_idx.get()
    let query = input.get()
    let bg = if is_selected { "rgb(30,80,120)" } else { "rgb(60,60,60)" }

    // Highlight matching prefix
    let suffix = if item.length() > query.length() {
      item.unsafe_substring(start=query.length(), end=item.length())
    } else {
      ""
    }
    let fg_suffix = if is_selected { "white" } else { "rgb(150,150,150)" }

    // Pad to popup_width
    let item_len = item.length()
    let padding = if item_len < popup_width {
      " ".repeat(popup_width - item_len)
    } else {
      ""
    }
    @vnode.row(
      [
        @vnode.text(query, fg="cyan", bold=is_selected),
        @vnode.text(suffix + padding, fg=fg_suffix),
      ],
      bg~,
    )
  }

  fn render_popup() -> @vnode.TuiNode {
    let matches = get_matches()
    if matches.length() == 0 {
      return @vnode.text("")
    }
    let visible_count = if matches.length() > max_items {
      max_items
    } else {
      matches.length()
    }
    let items : Array[@vnode.TuiNode] = []
    for i = 0; i < visible_count; i = i + 1 {
      items.push(render_popup_item(matches[i], i))
    }

    // More indicator
    if matches.length() > max_items {
      let more_count = matches.length() - max_items
      let more_text = "..." + more_count.to_string() + " more"
      let padding = " ".repeat(popup_width - more_text.length())
      items.push(
        @vnode.row(
          [@vnode.text(more_text + padding, fg="rgb(100,100,100)")],
          bg="rgb(60,60,60)",
        ),
      )
    }
    @vnode.column(items)
  }

  fn render_ghost_text() -> @vnode.TuiNode {
    // Don't show ghost text when popup is suppressed
    if suppress_popup.val {
      return @vnode.text("")
    }
    let matches = get_matches()
    let idx = selected_idx.get()
    if matches.length() > 0 && idx < matches.length() {
      let completion = matches[idx]
      let query = input.get()
      if completion.length() > query.length() {
        let suffix = completion.unsafe_substring(
          start=query.length(),
          end=completion.length(),
        )
        return @vnode.text(suffix, fg="rgb(80,80,80)")
      }
    }
    @vnode.text("")
  }

  fn render_main_ui() -> @vnode.TuiNode {
    let confirmed = get_confirmed_text()
    let current = input.get()
    @vnode.column(
      [
        // Title
        @vnode.text(" ◆ Inline Completion Demo", fg="cyan", bold=true),
        // Instructions
        @vnode.text(
          " Type to search fruits (e.g., 'ap' for apple/apricot)",
          fg="rgb(100,100,100)",
        ),
        // Input line with id for position lookup
        @vnode.row(
          [
            @vnode.text(confirmed, fg="white"),
            @vnode.text(current, fg="white"),
            render_ghost_text(),
          ],
          id="input-line",
        ),
        // Spacer to push help to bottom
        @vnode.spacer(),
        // Help
        @vnode.text(
          " ↑↓: select | Tab: confirm | Enter/Space: next word | Ctrl+C: quit",
          fg="rgb(100,100,100)",
        ),
      ],
      width=width.to_double(),
      height=height.to_double(),
    )
  }

  // Track previous match count to detect popup visibility changes
  let prev_match_count : Ref[Int] = Ref::new(0)
  fn do_render() -> Unit {
    let matches = get_matches()
    let show_popup = should_show_popup() && matches.length() > 0

    // Force full re-render when popup visibility changes
    let current_visible = if show_popup { matches.length() } else { 0 }
    if (prev_match_count.val > 0 && current_visible == 0) ||
      (prev_match_count.val == 0 && current_visible > 0) {
      app.clear_prev_buffer()
    }
    prev_match_count.val = current_visible

    // Render main UI first
    let main_output = app.render_frame(render_main_ui())
    @tui.print_raw(main_output)

    // Find input line position for cursor and popup
    match app.find_by_id("input-line") {
      Some(input_bounds) => {
        let confirmed = get_confirmed_text()
        let current = input.get()
        let confirmed_width = @core.string_display_width(confirmed)
        let current_width = @core.string_display_width(current)

        // Render popup as overlay if should show
        if show_popup {
          // Popup appears right below input line
          let popup_x = input_bounds.x + confirmed_width
          let popup_y = input_bounds.y + input_bounds.height
          let popup_output = @vnode.render_overlay_at(
            popup_x,
            popup_y,
            render_popup(),
          )
          @tui.print_raw(popup_output)
        }

        // Position cursor at end of input
        let cursor_x = input_bounds.x + confirmed_width + current_width
        let cursor_y = input_bounds.y
        @tui.print_raw(
          @render.ansi_move_to(cursor_y, cursor_x) + @render.ansi_show_cursor(),
        )
      }
      None => ()
    }
  }

  fn do_quit() -> Unit {
    @io.stop_keypress_listener()
    @tui.print_raw(@vnode.VNodeApp::restore_terminal())
    let result = get_full_text()
    if result.length() > 0 {
      println("Result: " + result)
    } else {
      println("Cancelled")
    }
  }

  fn confirm_completion_with_suppress() -> Unit {
    let matches = get_matches()
    let idx = selected_idx.get()
    if matches.length() > 0 && idx < matches.length() {
      input.set(matches[idx])
      suppress_popup.val = true // Hide popup after Tab confirmation
    }
  }

  fn confirm_completion() -> Unit {
    let matches = get_matches()
    let idx = selected_idx.get()
    if matches.length() > 0 && idx < matches.length() {
      input.set(matches[idx])
    }
  }

  fn confirm_word() -> Unit {
    let current = input.get()
    if current.length() > 0 {
      confirmed_words.push(current)
      input.set("")
      selected_idx.set(0)
    }
  }

  fn handle_key(key : String) -> Unit {
    if key.length() == 0 {
      return
    }

    // Handle multi-character printable input (IME) before parse_input
    if key.length() > 1 && key[0].to_int() != 0x1b && @tui.is_printable_string(key) {
      input.set(input.get() + key)
      selected_idx.set(0)
      suppress_popup.val = false // Show popup when typing
      do_render()
      return
    }
    let event = @tui.parse_input(key)
    if event.is_ctrl_c() {
      do_quit()
      return
    }
    let matches = get_matches()
    match event {
      @tui.InputEvent::Key(key_event) =>
        match key_event {
          @tui.KeyEvent::Special(@tui.SpecialKey::Up, _) => {
            let idx = selected_idx.get()
            if idx > 0 {
              selected_idx.set(idx - 1)
            }
            do_render()
          }
          @tui.KeyEvent::Special(@tui.SpecialKey::Down, _) => {
            let idx = selected_idx.get()
            let max_idx = if matches.length() > max_items {
              max_items - 1
            } else if matches.length() > 0 {
              matches.length() - 1
            } else {
              0
            }
            if idx < max_idx {
              selected_idx.set(idx + 1)
            }
            do_render()
          }
          @tui.KeyEvent::Special(@tui.SpecialKey::Tab, _) => {
            confirm_completion_with_suppress()
            do_render()
          }
          @tui.KeyEvent::Special(@tui.SpecialKey::Enter, _) => {
            // If there are matches, confirm the selected completion first
            if matches.length() > 0 {
              confirm_completion()
            }
            confirm_word()
            do_render()
          }
          @tui.KeyEvent::Char(' ', _) => {
            confirm_word()
            do_render()
          }
          @tui.KeyEvent::Special(@tui.SpecialKey::Backspace, _) => {
            let current = input.get()
            if current.length() > 0 {
              let chars : Array[Char] = current.iter().collect()
              let new_len = chars.length() - 1
              let buf = StringBuilder::new()
              for i = 0; i < new_len; i = i + 1 {
                buf.write_char(chars[i])
              }
              input.set(buf.to_string())
              selected_idx.set(0)
            } else if confirmed_words.length() > 0 {
              let last = confirmed_words.pop()
              match last {
                Some(word) => input.set(word)
                None => ()
              }
            }
            suppress_popup.val = true // Hide popup when deleting
            do_render()
          }
          @tui.KeyEvent::Char(c, @tui.KeyModifier::None)
          | @tui.KeyEvent::Char(c, @tui.KeyModifier::Shift) => {
            input.set(input.get() + c.to_string())
            selected_idx.set(0)
            suppress_popup.val = false // Show popup when typing
            do_render()
          }
          _ => ()
        }
      _ => ()
    }
  }

  // Initialize
  @tui.print_raw(@vnode.VNodeApp::init_terminal())
  @tui.enable_raw_mode()
  do_render()
  @io.start_keypress_listener(handle_key)
}
