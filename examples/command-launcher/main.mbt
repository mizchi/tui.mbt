///|
/// VNode Command Launcher - Raycast-like popup for filtering and executing commands

// Available commands
let commands : Array[Command] = [
  { name: "New File", icon: "+" },
  { name: "Open File", icon: "O" },
  { name: "Save File", icon: "S" },
  { name: "Close File", icon: "X" },
  { name: "Undo", icon: "U" },
  { name: "Redo", icon: "R" },
  { name: "Cut", icon: "✂" },
  { name: "Copy", icon: "C" },
  { name: "Paste", icon: "V" },
  { name: "Find", icon: "F" },
  { name: "Find and Replace", icon: "H" },
  { name: "Zoom In", icon: "+" },
  { name: "Zoom Out", icon: "-" },
  { name: "Toggle Sidebar", icon: "|" },
  { name: "Git Commit", icon: "G" },
  { name: "Git Push", icon: "↑" },
  { name: "Git Pull", icon: "↓" },
  { name: "New Terminal", icon: "T" },
  { name: "About", icon: "i" },
]

///|
struct Command {
  name : String
  icon : String
}

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

///|
fn main {
  let (width, height) = @tui.get_terminal_size()

  // State
  let query = @signals.signal("")
  let selected_idx = @signals.signal(0)
  let launcher_open = @signals.signal(false)
  let last_command = @signals.signal("")
  let running = @signals.signal(true)
  let app = @vnode.VNodeApp::new(width, height)

  // Launcher dimensions
  let launcher_width = 40
  // Calculate max_items based on terminal height to prevent overflow
  // Launcher chrome: input(2) + sep(1) + more(1) + sep(1) + footer(2) + border(2) = 9
  // Layout: top_margin(3) + launcher + bottom_hint(2)
  let launcher_chrome = 9
  let layout_margin = 5 // top(3) + bottom(2)
  let available = height - launcher_chrome - layout_margin
  let max_items = if available > 3 { available } else { 3 }
  let launcher_height = max_items + launcher_chrome
  fn get_filtered_commands() -> Array[Command] {
    filter_commands(query.get())
  }

  fn render_launcher_item(
    cmd : Command,
    idx : Int,
    selected_idx_val : Int,
    _ : Int,
  ) -> @vnode.TuiNode {
    let is_selected = idx == selected_idx_val
    let bg = if is_selected { "rgb(30,80,120)" } else { "rgb(40,40,50)" }
    let fg = if is_selected { "cyan" } else { "white" }
    @vnode.row(bg~, padding_x=0.5, [
      @vnode.text(" " + cmd.icon + " ", fg="cyan"),
      @vnode.text(cmd.name, fg~, bold=is_selected),
    ])
  }

  fn render_launcher() -> @vnode.TuiNode {
    let filtered = get_filtered_commands()
    let visible_nodes = @components.completion_popup_list_nodes(
      filtered,
      selected_idx.get(),
      launcher_width - 2,
      render_launcher_item,
      max_items~,
    )

    // Build item list - always render max_items rows for stable height
    let items = if filtered.length() == 0 {
      [
        @vnode.row(padding_x=1.0, height=1.0, [
          @vnode.text("No matching commands", fg="rgb(100,100,100)"),
        ]),
      ]
    } else {
      visible_nodes
    }
    let filled = items.length()
    for i = filled; i < max_items; i = i + 1 {
      items.push(@vnode.row(height=1.0, []))
    }

    // More indicator (fixed position row)
    let more_row = if filtered.length() > max_items {
      let more_count = filtered.length() - max_items
      let more_text = @components.completion_popup_more_label(more_count)
      let padding_width = launcher_width -
        2 -
        @core.string_display_width(more_text)
      let padding = if padding_width > 0 {
        " ".repeat(padding_width)
      } else {
        ""
      }
      @vnode.row(padding_x=1.0, height=1.0, [
        @vnode.text(more_text + padding, fg="rgb(100,100,100)"),
      ])
    } else {
      @vnode.row(height=1.0, [])
    }

    // Input field
    let input_row = @vnode.row(padding_x=1.0, padding_y=0.5, [
      @vnode.text("> ", fg="yellow", bold=true),
      @vnode.text(
        if query.get().length() > 0 {
          query.get()
        } else {
          "Type to search..."
        },
        fg=if query.get().length() > 0 { "white" } else { "rgb(100,100,100)" },
      ),
      @vnode.text("_", fg="cyan"),
    ])

    // Footer
    let footer = @vnode.row(padding_x=1.0, padding_y=0.5, [
      @vnode.text(
        filtered.length().to_string() + " commands | Enter: run | Esc: close",
        fg="rgb(100,100,100)",
      ),
    ])

    // Launcher box - fixed height
    @vnode.column(
      bg="rgb(30,30,40)",
      border="rounded",
      border_color="cyan",
      min_width=launcher_width.to_double(),
      height=launcher_height.to_double(),
      [
        input_row,
        @vnode.row([
          @vnode.text("─".repeat(launcher_width - 2), fg="rgb(60,60,60)"),
        ]),
      ] +
      items +
      [
        more_row,
        @vnode.row([
          @vnode.text("─".repeat(launcher_width - 2), fg="rgb(60,60,60)"),
        ]),
        footer,
      ],
    )
  }

  fn render_background() -> @vnode.TuiNode {
    let last_cmd = last_command.get()
    @vnode.column(width=width.to_double(), height=height.to_double(), [
      // Header
      @vnode.row(padding=1.0, [
        @vnode.text("Command Launcher Demo", fg="cyan", bold=true),
      ]),
      // Instructions
      @vnode.row(padding_x=1.0, [
        @vnode.text("Press ", fg="rgb(100,100,100)"),
        @vnode.text("Ctrl+P", fg="yellow", bold=true),
        @vnode.text(" to open command palette, ", fg="rgb(100,100,100)"),
        @vnode.text("q", fg="yellow", bold=true),
        @vnode.text(" to quit", fg="rgb(100,100,100)"),
      ]),
      // Last command
      if last_cmd.length() > 0 {
        @vnode.row(padding_x=1.0, padding_y=0.5, [
          @vnode.text("Last command: ", fg="green"),
          @vnode.text(last_cmd, fg="white"),
        ])
      } else {
        @vnode.vspace(1.0)
      },
      // Fake app content
      @vnode.row([
        @vnode.text("─".repeat(launcher_width - 2), fg="rgb(60,60,60)"),
      ]),
      @vnode.row([
        @vnode.text("  [Editor]  ", fg="rgb(80,80,80)"),
        @vnode.text("|", fg="rgb(60,60,60)"),
        @vnode.text("  [Terminal]  ", fg="rgb(80,80,80)"),
        @vnode.text("|", fg="rgb(60,60,60)"),
        @vnode.text("  [Output]  ", fg="rgb(80,80,80)"),
      ]),
      @vnode.row([
        @vnode.text("─".repeat(launcher_width - 2), fg="rgb(60,60,60)"),
      ]),
      @vnode.spacer(),
    ])
  }

  fn render_ui() -> @vnode.TuiNode {
    if launcher_open.get() {
      // Show launcher centered over background
      @vnode.column(
        width=width.to_double(),
        height=height.to_double(),
        bg="rgb(20,20,25)",
        [
          @vnode.vspace(3.0),
          @vnode.row(justify="center", [render_launcher()]),
          @vnode.spacer(),
          // Footer hint
          @vnode.row(justify="center", padding_y=0.5, [
            @vnode.text("Ctrl+P: toggle | Ctrl+C: quit", fg="rgb(80,80,80)"),
          ]),
        ],
      )
    } else {
      render_background()
    }
  }

  fn do_render() -> Unit {
    @tui.print_raw(app.render_frame(render_ui()))
    // Position cursor for IME when launcher is open
    if launcher_open.get() {
      // Row: vspace(3) + border(1) + padding_top(1) = 5 (0-indexed: 4)
      let cursor_row = 4
      // Col: center_x + border(1) + padding(1) + "> "(2) + query_width
      let center_x = (width - launcher_width) / 2
      let query_width = @core.string_display_width(query.get())
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
    println("Bye!")
  }

  fn open_launcher() -> Unit {
    launcher_open.set(true)
    query.set("")
    selected_idx.set(0)
  }

  fn close_launcher() -> Unit {
    launcher_open.set(false)
    query.set("")
  }

  fn execute_selected() -> Unit {
    let filtered = get_filtered_commands()
    let idx = selected_idx.get()
    if idx < filtered.length() {
      last_command.set(filtered[idx].name)
      close_launcher()
    }
  }

  fn handle_key(key : String) -> Unit {
    if key.length() == 0 {
      return
    }

    // Handle multi-character printable input (IME) before parse_input
    // parse_input only returns the first character for multi-char input
    if launcher_open.get() &&
      key.length() > 1 &&
      key[0].to_int() != 0x1b &&
      @tui.is_printable_string(key) {
      // IME input - append entire string
      query.set(query.get() + key)
      selected_idx.set(0)
      do_render()
      return
    }
    let event = @tui.parse_input(key)

    // Ctrl+C: quit
    if event.is_ctrl_c() {
      do_quit()
      return
    }

    // Ctrl+P: toggle launcher
    if event.is_ctrl('p') {
      if launcher_open.get() {
        close_launcher()
      } else {
        open_launcher()
      }
      do_render()
      return
    }
    if launcher_open.get() {
      // Launcher mode
      match event {
        @tui.InputEvent::Key(key_event) =>
          match key_event {
            @tui.KeyEvent::Special(@tui.SpecialKey::Escape, _) => {
              close_launcher()
              do_render()
            }
            @tui.KeyEvent::Special(@tui.SpecialKey::Enter, _) => {
              execute_selected()
              do_render()
            }
            @tui.KeyEvent::Special(@tui.SpecialKey::Up, _) => {
              let idx = selected_idx.get()
              if idx > 0 {
                selected_idx.set(idx - 1)
              }
              do_render()
            }
            @tui.KeyEvent::Special(@tui.SpecialKey::Down, _) => {
              let idx = selected_idx.get()
              let filtered = get_filtered_commands()
              let max_idx = if filtered.length() > max_items {
                max_items - 1
              } else {
                filtered.length() - 1
              }
              if idx < max_idx {
                selected_idx.set(idx + 1)
              }
              do_render()
            }
            @tui.KeyEvent::Special(@tui.SpecialKey::Backspace, _) => {
              let q = query.get()
              if q.length() > 0 {
                let chars : Array[Char] = q.iter().collect()
                let new_len = chars.length() - 1
                let buf = StringBuilder::new()
                for i = 0; i < new_len; i = i + 1 {
                  buf.write_char(chars[i])
                }
                query.set(buf.to_string())
                selected_idx.set(0)
              }
              do_render()
            }
            @tui.KeyEvent::Char(c, @tui.KeyModifier::None)
            | @tui.KeyEvent::Char(c, @tui.KeyModifier::Shift) => {
              query.set(query.get() + c.to_string())
              selected_idx.set(0)
              do_render()
            }
            _ => ()
          }
        _ => ()
      }
    } else {
      // Normal mode
      match event {
        @tui.InputEvent::Key(@tui.KeyEvent::Char('q', @tui.KeyModifier::None)) =>
          do_quit()
        @tui.InputEvent::Key(@tui.KeyEvent::Char('p', @tui.KeyModifier::None)) => {
          open_launcher()
          do_render()
        }
        _ => ()
      }
    }
  }

  // Initialize
  @tui.print_raw(@vnode.VNodeApp::init_terminal())
  @tui.enable_raw_mode()
  do_render()
  @io.start_keypress_listener(handle_key)
}
