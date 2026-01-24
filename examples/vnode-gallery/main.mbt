///|
/// VNode Gallery - Component patterns demonstration
/// Shows common UI patterns implemented with vnode

///|
async fn main {
  let (width, height) = @tui.get_terminal_size()

  // State
  let current_demo = @signals.signal(0)
  let tab_selected = @signals.signal(0)
  let toggle_on = @signals.signal(true)
  let listbox_selected = @signals.signal(0)
  let progress = @signals.signal(0)

  // Demo names
  let demos = ["Tabs", "Toggle", "Listbox", "Progress", "Cards"]

  // Create the vnode app
  let app = @vnode.VNodeApp::new(width, height)

  // Helper: Tab component
  fn vnode_tab(label : String, selected : Bool, id : String) -> @vnode.TuiNode {
    let fg = if selected { "black" } else { "white" }
    let bg = if selected { "cyan" } else { "rgb(60,60,70)" }
    @vnode.row([@vnode.text(" " + label + " ", fg~)], id~, bg~, padding_x=1.0)
  }

  // Helper: Toggle switch
  fn vnode_toggle(on : Bool) -> @vnode.TuiNode {
    let track_bg = if on { "green" } else { "rgb(80,80,80)" }
    let label = if on { "[●━━]" } else { "[━━●]" }
    @vnode.text(label, fg=track_bg)
  }

  // Helper: Listbox option
  fn vnode_listbox_item(
    label : String,
    selected : Bool,
    index : Int,
  ) -> @vnode.TuiNode {
    let prefix = if selected { "▸ " } else { "  " }
    let fg = if selected { "cyan" } else { "white" }
    let bg = if selected { "rgb(40,60,90)" } else { "" }
    @vnode.row(
      [@vnode.text(prefix + label, fg~, bold=selected)],
      id="listbox-" + index.to_string(),
      bg~,
      padding_x=1.0,
    )
  }

  // Helper: Progress bar
  fn vnode_progress(
    value : Int,
    max_val : Int,
    bar_width : Int,
  ) -> @vnode.TuiNode {
    let filled = value * bar_width / max_val
    let empty = bar_width - filled
    let filled_str = "█".repeat(filled)
    let empty_str = "░".repeat(empty)
    @vnode.row([
      @vnode.text("["),
      @vnode.text(filled_str, fg="green"),
      @vnode.text(empty_str, fg="rgb(60,60,60)"),
      @vnode.text("] " + value.to_string() + "%"),
    ])
  }

  // Helper: Card component
  fn vnode_card(
    title : String,
    content : String,
    color : String,
  ) -> @vnode.TuiNode {
    @vnode.column(
      [
        @vnode.text(title, fg=color, bold=true),
        @vnode.text(content, fg="rgb(180,180,180)"),
      ],
      padding=1.0,
      border="rounded",
      border_color=color,
    )
  }

  // Render demos
  fn render_tabs_demo() -> @vnode.TuiNode {
    let tabs = ["Home", "Profile", "Settings"]
    let selected = tab_selected.get()
    let tab_items : Array[@vnode.TuiNode] = []
    for i, t in tabs {
      tab_items.push(vnode_tab(t, selected == i, "tab-" + i.to_string()))
    }
    let content = match selected {
      0 => "Welcome to the Home tab! This is the main dashboard."
      1 => "User profile information and settings."
      2 => "Application configuration options."
      _ => "Unknown tab"
    }
    @vnode.column(
      [
        @vnode.text("Tabs Component", fg="yellow", bold=true),
        @vnode.text("Press 1/2/3 or click tabs", fg="rgb(128,128,128)"),
        @vnode.vspace(1.0),
        @vnode.row(tab_items, gap=0.5),
        @vnode.column(
          [@vnode.text(content)],
          padding=1.0,
          border="single",
          border_color="rgb(80,80,80)",
        ),
      ],
      gap=0.5,
    )
  }

  fn render_toggle_demo() -> @vnode.TuiNode {
    let on = toggle_on.get()
    @vnode.column(
      [
        @vnode.text("Toggle Switch", fg="yellow", bold=true),
        @vnode.text("Press Space to toggle", fg="rgb(128,128,128)"),
        @vnode.vspace(1.0),
        @vnode.row(
          [
            @vnode.text("Dark Mode: "),
            vnode_toggle(on),
            @vnode.text(
              if on {
                " ON"
              } else {
                " OFF"
              },
              fg=if on { "green" } else { "rgb(128,128,128)" },
            ),
          ],
          id="toggle-dark",
        ),
        @vnode.vspace(0.5),
        @vnode.row([
          @vnode.text("Notifications: "),
          vnode_toggle(not(on)),
          @vnode.text(
            if not(on) {
              " ON"
            } else {
              " OFF"
            },
            fg=if not(on) { "green" } else { "rgb(128,128,128)" },
          ),
        ]),
      ],
      gap=0.5,
    )
  }

  fn render_listbox_demo() -> @vnode.TuiNode {
    let items = [
      "🍎 Apple", "🍌 Banana", "🍒 Cherry", "🍇 Grape", "🍊 Orange",
    ]
    let selected = listbox_selected.get()
    let list_items : Array[@vnode.TuiNode] = []
    for i, item in items {
      list_items.push(vnode_listbox_item(item, selected == i, i))
    }
    @vnode.column(
      [
        @vnode.text("Listbox", fg="yellow", bold=true),
        @vnode.text("Use ↑/↓ to navigate", fg="rgb(128,128,128)"),
        @vnode.vspace(1.0),
        @vnode.column(list_items, border="single", border_color="rgb(80,80,80)"),
        @vnode.vspace(0.5),
        @vnode.text("Selected: " + items[selected], fg="green"),
      ],
      gap=0.5,
    )
  }

  fn render_progress_demo() -> @vnode.TuiNode {
    let p = progress.get()
    @vnode.column(
      [
        @vnode.text("Progress Bars", fg="yellow", bold=true),
        @vnode.text("Press +/- to change", fg="rgb(128,128,128)"),
        @vnode.vspace(1.0),
        @vnode.row([@vnode.text("Download: "), vnode_progress(p, 100, 20)]),
        @vnode.row([
          @vnode.text("Upload:   "),
          vnode_progress((p + 30) % 101, 100, 20),
        ]),
        @vnode.row([
          @vnode.text("Process:  "),
          vnode_progress((p + 60) % 101, 100, 20),
        ]),
      ],
      gap=0.5,
    )
  }

  fn render_cards_demo() -> @vnode.TuiNode {
    @vnode.column(
      [
        @vnode.text("Card Components", fg="yellow", bold=true),
        @vnode.text("Bordered containers", fg="rgb(128,128,128)"),
        @vnode.vspace(1.0),
        @vnode.row([
          vnode_card("Users", "1,234 active", "green"),
          @vnode.hspace(1.0),
          vnode_card("Revenue", "$5.6K", "yellow"),
          @vnode.hspace(1.0),
          vnode_card("Orders", "89 pending", "cyan"),
        ]),
        @vnode.vspace(1.0),
        vnode_card(
          "Status", "All systems operational. Last updated: just now.", "magenta",
        ),
      ],
      gap=0.5,
    )
  }

  // Main render function
  fn render_ui() -> @vnode.TuiNode {
    let current = current_demo.get()

    // Navigation tabs
    let nav_items : Array[@vnode.TuiNode] = []
    for i, d in demos {
      let is_current = current == i
      let fg = if is_current { "black" } else { "white" }
      let bg = if is_current { "cyan" } else { "rgb(50,50,60)" }
      nav_items.push(
        @vnode.row(
          [@vnode.text(" " + d + " ", fg~)],
          id="nav-" + i.to_string(),
          bg~,
          padding_x=0.5,
        ),
      )
    }

    // Demo content
    let demo_content = match current {
      0 => render_tabs_demo()
      1 => render_toggle_demo()
      2 => render_listbox_demo()
      3 => render_progress_demo()
      4 => render_cards_demo()
      _ => @vnode.text("Unknown demo")
    }
    @vnode.column(
      [
        // Header
        @vnode.row(
          [@vnode.text("VNode Component Gallery", fg="yellow", bold=true)],
          justify="center",
          padding_y=1.0,
        ),
        // Navigation
        @vnode.row(nav_items, justify="center", gap=1.0),
        @vnode.vspace(1.0),
        // Demo content
        @vnode.row(
          [demo_content],
          flex_grow=1.0,
          padding=1.0,
          border="rounded",
          border_color="rgb(80,80,100)",
        ),
        // Footer
        @vnode.row(
          [
            @vnode.text(
              "←/→: demos | ↑/↓: navigate | Space: toggle | q: quit",
              fg="rgb(100,100,100)",
            ),
          ],
          justify="center",
          padding_y=1.0,
        ),
      ],
      width=width.to_double(),
      height=height.to_double(),
    )
  }

  // Initialize terminal
  @tui.print_raw(@vnode.VNodeApp::init_terminal())
  @tui.enable_raw_mode()
  @tui.print_raw(@tui.enable_mouse())

  // Initial render
  @tui.print_raw(app.render_frame(render_ui()))

  // Event loop
  let mut running = true
  while running {
    let key = @tui.read_key()
    if key.length() == 0 {
      continue
    }
    let event = @tui.parse_input(key)
    let mut need_render = true
    let current = current_demo.get()
    match event {
      @tui.InputEvent::Key(key_event) =>
        match key_event {
          // Quit
          @tui.KeyEvent::Char('q', @tui.KeyModifier::None) => running = false
          @tui.KeyEvent::Char('c', @tui.KeyModifier::Ctrl) => running = false
          @tui.KeyEvent::Special(@tui.SpecialKey::Escape, _) => running = false
          // Navigate demos
          @tui.KeyEvent::Special(@tui.SpecialKey::Left, _) =>
            if current > 0 {
              current_demo.set(current - 1)
            }
          @tui.KeyEvent::Special(@tui.SpecialKey::Right, _) =>
            if current < demos.length() - 1 {
              current_demo.set(current + 1)
            }
          // Demo-specific keys
          @tui.KeyEvent::Special(@tui.SpecialKey::Up, _) =>
            match current {
              2 => {
                // Listbox
                let sel = listbox_selected.get()
                if sel > 0 {
                  listbox_selected.set(sel - 1)
                }
              }
              _ => need_render = false
            }
          @tui.KeyEvent::Special(@tui.SpecialKey::Down, _) =>
            match current {
              2 => {
                // Listbox
                let sel = listbox_selected.get()
                if sel < 4 {
                  listbox_selected.set(sel + 1)
                }
              }
              _ => need_render = false
            }
          @tui.KeyEvent::Char(' ', _) =>
            match current {
              1 => toggle_on.set(not(toggle_on.get())) // Toggle
              _ => need_render = false
            }
          @tui.KeyEvent::Char('+', _) | @tui.KeyEvent::Char('=', _) =>
            match current {
              3 => {
                // Progress
                let p = progress.get()
                if p < 100 {
                  progress.set(p + 10)
                }
              }
              _ => need_render = false
            }
          @tui.KeyEvent::Char('-', _) =>
            match current {
              3 => {
                // Progress
                let p = progress.get()
                if p > 0 {
                  progress.set(p - 10)
                }
              }
              _ => need_render = false
            }
          @tui.KeyEvent::Char('1', _) => if current == 0 { tab_selected.set(0) }
          @tui.KeyEvent::Char('2', _) => if current == 0 { tab_selected.set(1) }
          @tui.KeyEvent::Char('3', _) => if current == 0 { tab_selected.set(2) }
          _ => need_render = false
        }
      @tui.InputEvent::Mouse(mouse_event) =>
        match (mouse_event.event_type, mouse_event.button) {
          (@tui.MouseEventType::Press, @tui.MouseButton::Left) => {
            // Helper function to check if point is inside bounds
            fn is_inside(
              px : Int,
              py : Int,
              bx : Int,
              by : Int,
              bw : Int,
              bh : Int,
            ) -> Bool {
              px >= bx && px < bx + bw && py >= by && py < by + bh
            }

            // Check each nav item
            let mx = mouse_event.x
            let my = mouse_event.y
            let mut clicked = false
            for i = 0; i < demos.length(); i = i + 1 {
              match app.find_by_id("nav-" + i.to_string()) {
                Some(hit) =>
                  if is_inside(mx, my, hit.x, hit.y, hit.width, hit.height) {
                    current_demo.set(i)
                    clicked = true
                    break
                  }
                None => ()
              }
            }
            if not(clicked) {
              need_render = false
            }
          }
          _ => need_render = false
        }
      _ => need_render = false
    }

    // Re-render
    if need_render && running {
      @tui.print_raw(app.render_frame(render_ui()))
    }
  }

  // Restore terminal
  @tui.print_raw(@tui.disable_mouse())
  @tui.cleanup_stdin()
  @tui.print_raw(@vnode.VNodeApp::restore_terminal())
  println("Goodbye!")
}
