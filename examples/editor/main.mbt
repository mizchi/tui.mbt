///|
/// Inplace text editor with command palette (Ctrl+P) and Tab completion

// =============================================================================
// Word Completion
// =============================================================================

///|
let word_candidates : Array[String] = [
  "function", "return", "const", "let", "var", "if", "else", "for", "while", "break",
  "continue", "switch", "case", "default", "try", "catch", "finally", "throw", "class",
  "extends", "implements", "interface", "type", "enum", "import", "export", "from",
  "async", "await", "yield", "new", "this", "super", "static", "public", "private",
  "protected", "readonly", "true", "false", "null", "undefined", "void", "never",
  "any", "unknown", "string", "number", "boolean", "object", "array", "map", "set",
]

///|
/// Extract the current word at cursor position
fn get_current_word(text : String, cursor : Int) -> String {
  let chars : Array[Char] = text.iter().collect()
  let mut start = cursor
  // Walk backwards to find word start
  while start > 0 {
    let c = chars[start - 1]
    if c == ' ' ||
      c == '\n' ||
      c == '\t' ||
      c == '(' ||
      c == ')' ||
      c == '{' ||
      c == '}' ||
      c == '[' ||
      c == ']' ||
      c == ';' ||
      c == ',' {
      break
    }
    start = start - 1
  }
  // Build word
  let buf = StringBuilder::new()
  for i = start; i < cursor; i = i + 1 {
    buf.write_char(chars[i])
  }
  buf.to_string()
}

///|
/// Find completion suffix for current word
fn find_completion(text : String, cursor : Int) -> String? {
  let word = get_current_word(text, cursor)
  if word.length() == 0 {
    return None
  }
  let lower_word = word.to_lower()
  for candidate in word_candidates {
    if candidate.to_lower().has_prefix(lower_word) &&
      candidate.length() > word.length() {
      // Build the suffix to append
      let suffix = StringBuilder::new()
      let chars : Array[Char] = candidate.iter().collect()
      for i = word.length(); i < chars.length(); i = i + 1 {
        suffix.write_char(chars[i])
      }
      return Some(suffix.to_string())
    }
  }
  None
}

// =============================================================================
// Commands
// =============================================================================

///|
let commands : Array[String] = [
  "New File", "Open File", "Save File", "Close File", "Undo", "Redo", "Cut", "Copy",
  "Paste", "Find", "Find and Replace", "Go to Line", "Toggle Word Wrap", "Zoom In",
  "Zoom Out", "Show Settings", "About",
]

///|
fn filter_commands(query : String) -> Array[String] {
  if query.length() == 0 {
    return commands.copy()
  }
  let lower_query = query.to_lower()
  commands.iter().filter(fn(c) { c.to_lower().contains(lower_query) }).collect()
}

// =============================================================================
// Main
// =============================================================================

///|
fn main {
  let (cols, rows) = @tui.get_terminal_size()
  let width : Ref[Int] = { val: cols }
  let height : Ref[Int] = { val: rows }
  let editing = @signals.signal(false)
  let text_value = @signals.signal("")
  let app : Ref[@tui.App] = { val: @tui.App::new(cols, rows) }

  // Command palette state
  let palette_open = @signals.signal(false)
  let palette_input : Ref[String] = { val: "" }
  let completion_manager = @comp.AsyncCompletionManager::new(
    50, filter_commands, @io.get_time_ms,
  )
  let last_command : Ref[String] = { val: "" }
  fn editor_box_size() -> (Int, Int) {
    let header_lines = 2 // header + last command
    let footer_lines = 1
    let raw_height = height.val - header_lines - footer_lines
    let box_height = if raw_height > 1 { raw_height } else { 1 }
    (width.val, box_height)
  }

  // Palette dimensions
  let palette_width = 40
  let palette_max_items = 8
  fn render_palette() -> @core.Component {
    let engine = completion_manager.get_engine()
    let items = engine.get_items()
    let selected = engine.get_selected_idx()

    // Build item list (only show actual items, each with fixed height=1)
    let item_components : Array[@core.Component] = []
    for i = 0; i < items.length() && i < palette_max_items; i = i + 1 {
      let item = items[i]
      let is_selected = i == selected
      let prefix = if is_selected { "› " } else { "  " }
      let fg = if is_selected {
        @tui.Color::cyan()
      } else {
        @tui.Color::rgb(180, 180, 180)
      }
      item_components.push(
        @tui.row([@tui.text(prefix + item, fg~, bold=is_selected)], height=1.0),
      )
    }

    // Show placeholder when no results
    if items.length() == 0 {
      item_components.push(
        @tui.row(
          [@tui.text("  No results", fg=@tui.Color::rgb(100, 100, 100))],
          height=1.0,
        ),
      )
    }

    // Input row
    let input_row = @tui.row(
      [@tui.text("> " + palette_input.val, fg=@tui.Color::yellow(), bold=true)],
      id="palette-input",
      height=1.0,
    )

    // Separator line
    let separator = @tui.row(
      [
        @tui.text(
          "─".repeat(palette_width - 4),
          fg=@tui.Color::rgb(60, 60, 60),
        ),
      ],
      height=1.0,
    )

    // Palette box
    @tui.column(
      [input_row, separator] + item_components,
      border=Some(@tui.BorderChars::rounded()),
      border_color=@tui.Color::cyan(),
      bg=@tui.Color::rgb(25, 25, 35),
      padding=1.0,
    )
  }

  fn render_ui() -> @core.Component {
    let (box_width, box_height) = editor_box_size()
    let fg = @tui.Color::white()
    let value = text_value.get()
    let state = if editing.get() {
      @tui.TextareaState::Editing
    } else {
      @tui.TextareaState::Idle
    }
    // Debug: show palette input in header
    let header_text = if palette_open.get() {
      "Input[" +
      palette_input.val.length().to_string() +
      "]: " +
      palette_input.val
    } else {
      "Editor Prototype"
    }
    let header = @tui.row(
      [@tui.text(header_text, fg=@tui.Color::yellow(), bold=true)],
      justify=@tui.align_center(),
    )
    let last_cmd_row = if last_command.val.length() > 0 {
      @tui.row(
        [
          @tui.text(
            "Last: " + last_command.val,
            fg=@tui.Color::rgb(100, 180, 100),
          ),
        ],
        justify=@tui.align_center(),
      )
    } else {
      @tui.row(
        [@tui.text("Ctrl+P: Command Palette", fg=@tui.Color::rgb(80, 80, 80))],
        justify=@tui.align_center(),
      )
    }
    let editor_box = @tui.multiline_input(
      value,
      id="editor-box",
      rows=box_height,
      placeholder="Press Enter to edit",
      state~,
      width=@tui.dim_length(box_width.to_double()),
      padding_x=1.0,
      padding_y=0.0,
      fg~,
    )
    let footer_text = if editing.get() {
      "Tab: complete | Enter: newline | Shift+Enter: confirm | Esc: cancel"
    } else {
      "Enter: edit | q: quit | p/Ctrl+P: palette"
    }
    let footer = @tui.row(
      [@tui.text(footer_text, fg=@tui.Color::rgb(120, 120, 120))],
      justify=@tui.align_center(),
    )
    let base_ui = @tui.column(
      [header, last_cmd_row, editor_box, footer],
      width=@tui.dim_length(width.val.to_double()),
      height=@tui.dim_length(height.val.to_double()),
      justify=@tui.align_start(),
      align=@tui.align_start(),
    )

    // If palette is open, overlay at center-top (Spotlight-like)
    if palette_open.get() {
      @core.box(
        [
          base_ui,
          // Overlay fills screen, palette positioned at top-center
          @core.box(
            [render_palette()],
            position=@types.Position::Absolute,
            inset_top=@tui.dim_length(3.0), // 3 lines from top
            inset_left=@tui.dim_length(0.0),
            inset_right=@tui.dim_length(0.0),
            inset_bottom=@tui.dim_length(0.0), // Required for align_items to work
            justify_content=@tui.align_center(), // horizontal center
            align_items=@tui.align_start(), // top align
          ),
        ],
        width=@tui.dim_length(width.val.to_double()),
        height=@tui.dim_length(height.val.to_double()),
      )
    } else {
      base_ui
    }
  }

  fn do_render() -> Unit {
    @tui.print_raw(app.val.render_frame(render_ui()))
    // Position cursor for IME when palette is open
    if palette_open.get() {
      // Use find_by_id to get actual rendered position
      match app.val.find_by_id("palette-input") {
        Some(bounds) => {
          // bounds.x/y are 0-indexed, ANSI is 1-indexed
          // Position cursor at the end of the input text
          let input_display_width = @core.string_display_width(
            palette_input.val,
          )
          let cursor_row = bounds.y + 1
          let cursor_col = bounds.x + 1 + 2 + input_display_width // +2 for "> "
          @tui.print_raw(
            "\u001b[" +
            cursor_row.to_string() +
            ";" +
            cursor_col.to_string() +
            "H",
          )
          @tui.print_raw(@render.ansi_show_cursor())
        }
        None => ()
      }
    }
  }

  fn do_quit() -> Unit {
    @tui.stop_keypress_listener()
    @io.stop_resize_listener()
    @tui.cleanup_stdin()
    @tui.print_raw(@tui.App::restore_terminal())
    println("Goodbye!")
  }

  fn handle_resize(new_width : Int, new_height : Int) -> Unit {
    width.val = new_width
    height.val = new_height
    app.val = @tui.App::new(new_width, new_height)
    @tui.print_raw(@render.ansi_clear_screen())
    do_render()
  }

  fn open_palette() -> Unit {
    palette_open.set(true)
    palette_input.val = ""
    completion_manager.get_engine().clear()
    completion_manager.request("")
    do_render()
  }

  fn close_palette() -> Unit {
    palette_open.set(false)
    palette_input.val = ""
    completion_manager.get_engine().clear()
    do_render()
  }

  fn execute_palette_command() -> Unit {
    let engine = completion_manager.get_engine()
    match engine.get_selected_item() {
      Some(name) => {
        last_command.val = name
        // Insert command name into text
        let current = text_value.get()
        let new_text = if current.length() > 0 {
          current + "\n" + name
        } else {
          name
        }
        text_value.set(new_text)
        close_palette()
      }
      None => ()
    }
  }

  letrec restore_tui: () -> Unit = fn() {
    @tui.print_raw(@tui.ansi_full_reset())
    app.val.clear_prev_buffer()
    editing.set(false)
    do_render()
    @io.start_resize_listener(handle_resize)
    @tui.start_keypress_listener(handle_key)
  }
  and start_editing: () -> Unit = fn() {
    editing.set(true)
    do_render()
    match app.val.find_by_id("editor-box") {
      Some(bounds) => {
        let config = @tui.EditConfig::{
          field_name: "Editor",
          on_change: fn(value) { text_value.set(value) },
          on_edit_start: Some(fn() {
            @tui.stop_keypress_listener()
            @io.stop_resize_listener()
          }),
          on_edit_end: Some(fn() { editing.set(false) }),
          on_force_quit: Some(fn() { do_quit() }),
        }
        @tui.start_edit_inplace_in_bounds(
          config,
          text_value.get(),
          bounds,
          true,
          restore_tui,
          confirm_on_shift_enter=true, // Enter=newline, Shift+Enter=confirm
          on_completion=Some(find_completion),
        )
      }
      None => {
        editing.set(false)
        do_render()
      }
    }
  }
  and handle_key: (String) -> Unit = fn(key) {
    if key.length() == 0 {
      return
    }

    // Check for pending completion
    if completion_manager.check_pending() {
      do_render()
    }
    let event = @tui.parse_input(key)

    // Handle palette mode
    if palette_open.get() {
      if event.is_ctrl('c') {
        close_palette()
        do_quit()
        return
      }
      let engine = completion_manager.get_engine()
      // Check for special keys first
      match event {
        @tui.InputEvent::Key(key_event) =>
          match key_event {
            @tui.KeyEvent::Special(@tui.SpecialKey::Escape, _) => {
              close_palette()
              return
            }
            @tui.KeyEvent::Special(@tui.SpecialKey::Enter, _) => {
              execute_palette_command()
              return
            }
            @tui.KeyEvent::Special(@tui.SpecialKey::Up, _) => {
              engine.select_prev()
              do_render()
              return
            }
            @tui.KeyEvent::Special(@tui.SpecialKey::Down, _) => {
              engine.select_next()
              do_render()
              return
            }
            @tui.KeyEvent::Special(@tui.SpecialKey::Backspace, _) => {
              if palette_input.val.length() > 0 {
                let chars : Array[Char] = palette_input.val.iter().collect()
                let new_len = chars.length() - 1
                let buf = StringBuilder::new()
                for i = 0; i < new_len; i = i + 1 {
                  buf.write_char(chars[i])
                }
                palette_input.val = buf.to_string()
                completion_manager.request(palette_input.val)
              }
              do_render()
              return
            }
            _ => ()
          }
        _ => ()
      }
      // Handle printable input (including multi-character IME input)
      // If not an escape sequence, add all characters to input
      if key.length() > 0 && key[0].to_int() != 0x1b {
        // Check if it's a control character (< 0x20) or single printable
        let first_code = key[0].to_int()
        if first_code >= 0x20 {
          // Printable character(s) - add entire string (handles IME)
          palette_input.val = palette_input.val + key
          completion_manager.request(palette_input.val)
          do_render()
        }
      }
      return
    }

    // Normal mode
    if event.is_ctrl('c') {
      do_quit()
      return
    }
    if event.is_ctrl('p') {
      open_palette()
      return
    }
    match event {
      @tui.InputEvent::Key(key_event) =>
        match key_event {
          @tui.KeyEvent::Char('q', @tui.KeyModifier::None) => do_quit()
          @tui.KeyEvent::Char('p', @tui.KeyModifier::None) => open_palette()
          @tui.KeyEvent::Special(@tui.SpecialKey::Enter, _) => start_editing()
          @tui.KeyEvent::Char('e', @tui.KeyModifier::None) => start_editing()
          _ => ()
        }
      _ => ()
    }
  }

  // Set idle handler for async completion
  @io.set_idle_handler(fn() {
    if palette_open.get() && completion_manager.check_pending() {
      do_render()
    }
  })
  @tui.print_raw(@tui.App::init_terminal())
  do_render()
  @io.start_resize_listener(handle_resize)
  @tui.start_keypress_listener(handle_key)
}
