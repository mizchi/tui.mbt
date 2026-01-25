///|
/// VNode Editor - Text editor with command palette and word completion

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
fn get_current_word(text : String, cursor : Int) -> String {
  let chars : Array[Char] = text.iter().collect()
  let mut start = cursor
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
  let buf = StringBuilder::new()
  for i = start; i < cursor; i = i + 1 {
    buf.write_char(chars[i])
  }
  buf.to_string()
}

///|
fn find_completion(text : String, cursor : Int) -> String? {
  let word = get_current_word(text, cursor)
  if word.length() == 0 {
    return None
  }
  let lower_word = word.to_lower()
  for candidate in word_candidates {
    if candidate.to_lower().has_prefix(lower_word) &&
      candidate.length() > word.length() {
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
struct Command {
  name : String
  icon : String
}

///|
let commands : Array[Command] = [
  { name: "New File", icon: "+" },
  { name: "Save File", icon: "S" },
  { name: "Undo", icon: "U" },
  { name: "Redo", icon: "R" },
  { name: "Cut", icon: "X" },
  { name: "Copy", icon: "C" },
  { name: "Paste", icon: "V" },
  { name: "Find", icon: "F" },
  { name: "Go to Line", icon: "G" },
  { name: "Toggle Word Wrap", icon: "W" },
  { name: "About", icon: "i" },
]

///|
fn filter_commands(query : String) -> Array[Command] {
  if query.length() == 0 {
    return commands.copy()
  }
  let lower_query = query.to_lower()
  commands
  .iter()
  .filter(fn(c) { c.name.to_lower().contains(lower_query) })
  .collect()
}

// =============================================================================
// Main
// =============================================================================

///|
fn main {
  let (width, height) = @tui.get_terminal_size()

  // State
  let text = @signals.signal("")
  let editing = @signals.signal(false)
  let palette_open = @signals.signal(false)
  let palette_query = @signals.signal("")
  let palette_selected = @signals.signal(0)
  let last_command = @signals.signal("")
  let running = @signals.signal(true)
  let app = @vnode.VNodeApp::new(width, height)

  // Palette dimensions
  let palette_width = 40
  let palette_chrome = 9
  let layout_margin = 5
  let available = height - palette_chrome - layout_margin
  let palette_max_items = if available > 3 { available } else { 3 }
  let palette_height = palette_max_items + palette_chrome
  fn get_filtered_commands() -> Array[Command] {
    filter_commands(palette_query.get())
  }

  fn render_palette_item(cmd : Command, idx : Int) -> @vnode.TuiNode {
    let is_selected = idx == palette_selected.get()
    let bg = if is_selected { "rgb(30,80,120)" } else { "rgb(40,40,50)" }
    let fg = if is_selected { "cyan" } else { "white" }
    @vnode.row(
      [
        @vnode.text(" " + cmd.icon + " ", fg="cyan"),
        @vnode.text(cmd.name, fg~, bold=is_selected),
      ],
      bg~,
      padding_x=0.5,
    )
  }

  fn render_palette() -> @vnode.TuiNode {
    let filtered = get_filtered_commands()
    let visible_items = if filtered.length() > palette_max_items {
      filtered.iter().take(palette_max_items).collect()
    } else {
      filtered
    }

    // Build item list - always render palette_max_items rows for stable height
    let items : Array[@vnode.TuiNode] = []
    for i = 0; i < palette_max_items; i = i + 1 {
      if i < visible_items.length() {
        items.push(render_palette_item(visible_items[i], i))
      } else if i == 0 && filtered.length() == 0 {
        items.push(
          @vnode.row(
            [@vnode.text("No matching commands", fg="rgb(100,100,100)")],
            padding_x=1.0,
            height=1.0,
          ),
        )
      } else {
        items.push(@vnode.row([], height=1.0))
      }
    }

    // More indicator
    let more_row = if filtered.length() > palette_max_items {
      let more_count = filtered.length() - palette_max_items
      @vnode.row(
        [
          @vnode.text(
            "..." + more_count.to_string() + " more",
            fg="rgb(100,100,100)",
          ),
        ],
        padding_x=1.0,
        height=1.0,
      )
    } else {
      @vnode.row([], height=1.0)
    }

    // Input field
    let query = palette_query.get()
    let input_row = @vnode.row(
      [
        @vnode.text("> ", fg="yellow", bold=true),
        @vnode.text(
          if query.length() > 0 {
            query
          } else {
            "Type to search..."
          },
          fg=if query.length() > 0 { "white" } else { "rgb(100,100,100)" },
        ),
        @vnode.text("_", fg="cyan"),
      ],
      padding_x=1.0,
      padding_y=0.5,
    )

    // Footer
    let footer = @vnode.row(
      [
        @vnode.text(
          filtered.length().to_string() + " commands | Enter: run | Esc: close",
          fg="rgb(100,100,100)",
        ),
      ],
      padding_x=1.0,
      padding_y=0.5,
    )

    // Palette box
    @vnode.column(
      [
        input_row,
        @vnode.row([
          @vnode.text("─".repeat(palette_width - 2), fg="rgb(60,60,60)"),
        ]),
      ] +
      items +
      [
        more_row,
        @vnode.row([
          @vnode.text("─".repeat(palette_width - 2), fg="rgb(60,60,60)"),
        ]),
        footer,
      ],
      bg="rgb(30,30,40)",
      border="rounded",
      border_color="cyan",
      min_width=palette_width.to_double(),
      height=palette_height.to_double(),
    )
  }

  // Editor rows = total height - header(1) - cmd_row(1) - footer(1) - border(2) - buffer(1)
  let editor_rows = height - 5
  fn render_editor() -> @vnode.TuiNode {
    @vnode.textarea(
      text.get(),
      id="editor",
      placeholder="Press Enter to start editing...",
      rows=editor_rows,
      bg="", // transparent background
      min_width=(width - 4).to_double(),
    )
  }

  fn render_ui() -> @vnode.TuiNode {
    let last_cmd = last_command.get()

    // Header
    let header = @vnode.row(
      [@vnode.text("VNode Editor", fg="cyan", bold=true)],
      justify="center",
    )

    // Last command or hint
    let cmd_row = if last_cmd.length() > 0 {
      @vnode.row(
        [@vnode.text("Last: ", fg="green"), @vnode.text(last_cmd, fg="white")],
        justify="center",
      )
    } else {
      @vnode.row(
        [@vnode.text("Ctrl+P: command palette", fg="rgb(80,80,80)")],
        justify="center",
      )
    }

    // Footer
    let footer_text = if editing.get() {
      "Tab: complete | Shift+Enter: confirm | Esc: cancel"
    } else {
      "Enter: edit | q: quit | Ctrl+P: palette"
    }
    let footer = @vnode.row(
      [@vnode.text(footer_text, fg="rgb(100,100,100)")],
      justify="center",
    )

    // Main layout (height-1 to prevent overflow)
    let main_ui = @vnode.column(
      [header, cmd_row, render_editor(), footer],
      width=width.to_double(),
      height=(height - 1).to_double(),
    )

    // Overlay palette if open
    if palette_open.get() {
      @vnode.column(
        [
          @vnode.vspace(3.0),
          @vnode.row([render_palette()], justify="center"),
          @vnode.spacer(),
        ],
        width=width.to_double(),
        height=(height - 1).to_double(),
        bg="rgb(20,20,25)",
      )
    } else {
      main_ui
    }
  }

  fn do_render() -> Unit {
    @tui.print_raw(app.render_frame(render_ui()))
    // Position cursor for IME when palette is open
    if palette_open.get() {
      let cursor_row = 4
      let center_x = (width - palette_width) / 2
      let query_width = @core.string_display_width(palette_query.get())
      let cursor_col = center_x + 3 + query_width
      @tui.print_raw(
        @render.ansi_move_to(cursor_row, cursor_col) +
        @render.ansi_show_cursor(),
      )
    } else {
      @tui.print_raw(@render.ansi_hide_cursor())
    }
  }

  fn do_quit() -> Unit {
    running.set(false)
    @io.stop_keypress_listener()
    @tui.print_raw(@vnode.VNodeApp::restore_terminal())
    let content = text.get()
    if content.length() > 0 {
      println("--- Content ---")
      println(content)
    }
    println("Goodbye!")
  }

  fn open_palette() -> Unit {
    palette_open.set(true)
    palette_query.set("")
    palette_selected.set(0)
  }

  fn close_palette() -> Unit {
    palette_open.set(false)
    palette_query.set("")
  }

  fn execute_palette_command() -> Unit {
    let filtered = get_filtered_commands()
    let idx = palette_selected.get()
    if idx < filtered.length() {
      last_command.set(filtered[idx].name)
      close_palette()
    }
  }

  // Mutually recursive functions for editing
  letrec restore_tui: () -> Unit = fn() {
    @tui.print_raw(@render.ansi_full_reset())
    app.clear_prev_buffer()
    editing.set(false)
    do_render()
    @io.start_keypress_listener(handle_key)
  }
  and start_editing: () -> Unit = fn() {
    match app.find_by_id("editor") {
      Some(bounds) => {
        let config : @vnode.EditConfig = {
          field_name: "Editor",
          on_change: fn(value) { text.set(value) },
          on_edit_start: Some(fn() {
            @io.stop_keypress_listener()
            editing.set(true)
          }),
          on_edit_end: Some(fn() { editing.set(false) }),
          on_force_quit: Some(fn() { do_quit() }),
        }
        @vnode.start_edit_inplace_in_bounds(
          config,
          text.get(),
          bounds,
          true, // multiline
          restore_tui,
          confirm_on_shift_enter=true,
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

    // Handle palette mode
    if palette_open.get() {
      // Handle multi-character printable input (IME) before parse_input
      if key.length() > 1 &&
        key[0].to_int() != 0x1b &&
        @tui.is_printable_string(key) {
        palette_query.set(palette_query.get() + key)
        palette_selected.set(0)
        do_render()
        return
      }
      let event = @tui.parse_input(key)
      if event.is_ctrl_c() {
        do_quit()
        return
      }
      match event {
        @tui.InputEvent::Key(key_event) =>
          match key_event {
            @tui.KeyEvent::Special(@tui.SpecialKey::Escape, _) => {
              close_palette()
              do_render()
            }
            @tui.KeyEvent::Special(@tui.SpecialKey::Enter, _) => {
              execute_palette_command()
              do_render()
            }
            @tui.KeyEvent::Special(@tui.SpecialKey::Up, _) => {
              let idx = palette_selected.get()
              if idx > 0 {
                palette_selected.set(idx - 1)
              }
              do_render()
            }
            @tui.KeyEvent::Special(@tui.SpecialKey::Down, _) => {
              let idx = palette_selected.get()
              let filtered = get_filtered_commands()
              let max_idx = if filtered.length() > palette_max_items {
                palette_max_items - 1
              } else if filtered.length() > 0 {
                filtered.length() - 1
              } else {
                0
              }
              if idx < max_idx {
                palette_selected.set(idx + 1)
              }
              do_render()
            }
            @tui.KeyEvent::Special(@tui.SpecialKey::Backspace, _) => {
              let q = palette_query.get()
              if q.length() > 0 {
                let chars : Array[Char] = q.iter().collect()
                let new_len = chars.length() - 1
                let buf = StringBuilder::new()
                for i = 0; i < new_len; i = i + 1 {
                  buf.write_char(chars[i])
                }
                palette_query.set(buf.to_string())
                palette_selected.set(0)
              }
              do_render()
            }
            @tui.KeyEvent::Char(c, @tui.KeyModifier::None)
            | @tui.KeyEvent::Char(c, @tui.KeyModifier::Shift) => {
              palette_query.set(palette_query.get() + c.to_string())
              palette_selected.set(0)
              do_render()
            }
            _ => ()
          }
        _ => ()
      }
      return
    }

    // Normal mode
    let event = @tui.parse_input(key)
    if event.is_ctrl_c() {
      do_quit()
      return
    }
    if event.is_ctrl('p') {
      open_palette()
      do_render()
      return
    }
    match event {
      @tui.InputEvent::Key(key_event) =>
        match key_event {
          @tui.KeyEvent::Char('q', @tui.KeyModifier::None) => do_quit()
          @tui.KeyEvent::Char('p', @tui.KeyModifier::None) => {
            open_palette()
            do_render()
          }
          @tui.KeyEvent::Special(@tui.SpecialKey::Enter, _) => start_editing()
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
