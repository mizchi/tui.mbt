///|
/// VNode Components - Complete component gallery using @components
/// Demonstrates all major UI patterns with pre-built styled components

// Demo indices
let demo_tabs : Int = 0

///|
let demo_accordion : Int = 1

///|
let demo_radio : Int = 2

///|
let demo_switch : Int = 3

///|
let demo_listbox : Int = 4

///|
let demo_combobox : Int = 5

///|
let demo_splitter : Int = 6

///|
let demo_menubar : Int = 7

///|
async fn main {
  let (width, height) = @tui.get_terminal_size()

  // State
  let current_demo = @signals.signal(0)
  let tab_selected = @signals.signal(0)
  let accordion_expanded = @signals.signal(0)
  let radio_selected = @signals.signal(1)
  let switch_on = @signals.signal(true)
  let checkbox_checked = @signals.signal(true)
  let listbox_selected = @signals.signal(0)
  let combobox_open = @signals.signal(false)
  let combobox_selected = @signals.signal(0)
  let splitter_pos = @signals.signal(50)
  let menubar_open = @signals.signal(-1)
  let menubar_item = @signals.signal(0)
  let message = @signals.signal("←/→: demos | q: quit")

  // Demo names
  let demos = [
    "Tabs", "Accordion", "Radio", "Switch", "Listbox", "Combobox", "Splitter",
    "Menubar",
  ]

  // Create the vnode app
  let app = @vnode.VNodeApp::new(width, height)

  // ==========================================================================
  // Demo Renderers
  // ==========================================================================

  fn render_tabs_demo() -> @vnode.TuiNode {
    let tabs = ["Home", "Profile", "Settings"]
    let selected = tab_selected.get()
    let tab_items : Array[@vnode.TuiNode] = []
    for i, t in tabs {
      tab_items.push(@ui.tab(t, selected == i, id="tab-" + i.to_string()))
    }
    let content = match selected {
      0 => "Welcome to the Home tab! This is the main dashboard area."
      1 => "User profile information and account settings."
      2 => "Application configuration and preferences."
      _ => "Unknown tab"
    }
    @vnode.column(
      [
        @vnode.text("Tabs Component", fg="yellow", bold=true),
        @vnode.text("Press 1/2/3 or click", fg="rgb(128,128,128)"),
        @vnode.vspace(1.0),
        @vnode.row(tab_items, gap=0.5),
        @vnode.column(
          [@vnode.text(content)],
          padding=1.0,
          border="single",
          border_color="rgb(80,80,80)",
        ),
        @vnode.vspace(0.5),
        @vnode.text("Selected: Tab " + (selected + 1).to_string(), fg="green"),
      ],
      gap=0.5,
    )
  }

  fn render_accordion_demo() -> @vnode.TuiNode {
    let sections = [
      (
        "Introduction",
        "Welcome to the accordion demo. Click headers to expand.",
      ),
      ("Features", "Supports expand/collapse with smooth state management."),
      ("FAQ", "Q: How does it work? A: Click on section headers!"),
    ]
    let expanded = accordion_expanded.get()
    let section_nodes : Array[@vnode.TuiNode] = []
    for i, s in sections {
      section_nodes.push(
        @ui.accordion_section(
          s.0,
          @vnode.text(s.1, fg="rgb(180,180,180)"),
          expanded == i,
          id="acc-" + i.to_string(),
        ),
      )
    }
    @vnode.column(
      [
        @vnode.text("Accordion Component", fg="yellow", bold=true),
        @vnode.text("Press 1/2/3 to expand sections", fg="rgb(128,128,128)"),
        ..section_nodes,
      ],
    )
  }

  fn render_radio_demo() -> @vnode.TuiNode {
    let options = ["Fast", "Balanced", "Power Saver"]
    let selected = radio_selected.get()
    let option_nodes : Array[@vnode.TuiNode] = []
    for i, opt in options {
      option_nodes.push(
        @ui.radio(opt, selected == i, id="radio-" + i.to_string()),
      )
    }
    @vnode.column(
      [
        @vnode.text("Radio Group", fg="yellow", bold=true),
        @vnode.text("Use ↑/↓ to navigate", fg="rgb(128,128,128)"),
        @vnode.vspace(1.0),
        @vnode.text("Select mode:"),
        @vnode.column(option_nodes, border="single", border_color="rgb(60,60,80)"),
        @vnode.vspace(0.5),
        @vnode.text("Selected: " + options[selected], fg="green"),
      ],
      gap=0.5,
    )
  }

  fn render_switch_demo() -> @vnode.TuiNode {
    let sw = switch_on.get()
    let cb = checkbox_checked.get()
    @vnode.column(
      [
        @vnode.text("Switch & Checkbox", fg="yellow", bold=true),
        @vnode.text(
          "Space: toggle switch, 1: toggle checkbox",
          fg="rgb(128,128,128)",
        ),
        @vnode.vspace(1.0),
        @ui.switch(sw, "Dark Mode", id="switch-dark"),
        @ui.switch(not(sw), "Notifications", id="switch-notif"),
        @vnode.vspace(0.5),
        @ui.checkbox("Accept Terms", cb, id="cb-terms"),
        @ui.checkbox("Subscribe to Newsletter", not(cb), id="cb-news"),
      ],
      gap=0.5,
    )
  }

  fn render_listbox_demo() -> @vnode.TuiNode {
    let items = ["Apple", "Banana", "Cherry", "Grape", "Orange"]
    let selected = listbox_selected.get()
    let list_nodes : Array[@vnode.TuiNode] = []
    for i, item in items {
      list_nodes.push(
        @ui.listbox_item(
          item,
          selected == i,
          id="list-" + i.to_string(),
        ),
      )
    }
    @vnode.column(
      [
        @vnode.text("Listbox", fg="yellow", bold=true),
        @vnode.text("Use ↑/↓ to navigate", fg="rgb(128,128,128)"),
        @vnode.vspace(1.0),
        @vnode.text("Choose a fruit:"),
        @vnode.column(list_nodes, border="single", border_color="rgb(60,60,80)"),
        @vnode.vspace(0.5),
        @vnode.text("Selected: " + items[selected], fg="green"),
      ],
      gap=0.5,
    )
  }

  fn render_combobox_demo() -> @vnode.TuiNode {
    let options = ["JavaScript", "TypeScript", "Python", "Rust", "Go"]
    let selected = combobox_selected.get()
    let open = combobox_open.get()
    // Dropdown items (only shown when open)
    let dropdown_items : Array[@vnode.TuiNode] = if open {
      let items : Array[@vnode.TuiNode] = []
      for i, opt in options {
        items.push(
          @ui.combobox_item(
            opt,
            selected == i,
            id="combo-" + i.to_string(),
          ),
        )
      }
      [
        @vnode.column(
          items,
          id="combo-dropdown",
          border="single",
          border_color="cyan",
          bg="rgb(40,40,50)",
        ),
      ]
    } else {
      []
    }
    // Show selected text only when dropdown is closed
    let status_text : Array[@vnode.TuiNode] = if open {
      []
    } else {
      [@vnode.text("Selected: " + options[selected], fg="green")]
    }
    @vnode.column(
      [
        @vnode.text("Combobox (Dropdown)", fg="yellow", bold=true),
        @vnode.text("Space: open/close, ↑/↓: select", fg="rgb(128,128,128)"),
        @vnode.text("Select language:"),
        @ui.combobox_trigger(options[selected], open, id="combo-trigger"),
        ..dropdown_items,
        ..status_text,
      ],
    )
  }

  fn render_splitter_demo() -> @vnode.TuiNode {
    let pos = splitter_pos.get()
    let left_width = pos * 60 / 100
    let right_width = 60 - left_width - 1
    // Splitter divider (custom, not in components yet)
    fn splitter_divider(focused : Bool, id : String) -> @vnode.TuiNode {
      let color = if focused { "cyan" } else { "rgb(80,80,80)" }
      @vnode.column(
        [@vnode.text("|", fg=color)],
        id~,
        width=1.0,
        justify="center",
        align="center",
        bg="rgb(40,40,50)",
      )
    }

    @vnode.column(
      [
        @vnode.text("Window Splitter", fg="yellow", bold=true),
        @vnode.text("Use ↑/↓ to resize", fg="rgb(128,128,128)"),
        @vnode.vspace(1.0),
        @vnode.row(
          [
            // Left pane
            @vnode.column(
              [
                @vnode.text("Left Pane", fg="cyan"),
                @vnode.text("Width: " + left_width.to_string()),
              ],
              width=left_width.to_double(),
              height=8.0,
              padding=1.0,
              border="single",
              border_color="rgb(60,60,80)",
              bg="rgb(40,40,50)",
            ),
            // Divider
            splitter_divider(true, "splitter-div"),
            // Right pane
            @vnode.column(
              [
                @vnode.text("Right Pane", fg="yellow"),
                @vnode.text("Width: " + right_width.to_string()),
              ],
              width=right_width.to_double(),
              height=8.0,
              padding=1.0,
              border="single",
              border_color="rgb(60,60,80)",
              bg="rgb(50,40,40)",
            ),
          ],
          id="splitter",
        ),
        @vnode.vspace(0.5),
        @vnode.text("Position: " + pos.to_string() + "%", fg="green"),
      ],
      gap=0.5,
    )
  }

  fn render_menubar_demo() -> @vnode.TuiNode {
    let menus = ["File", "Edit", "View"]
    let file_items = ["New", "Open", "Save", "Exit"]
    let edit_items = ["Cut", "Copy", "Paste"]
    let view_items = ["Toolbar", "Status Bar", "Zoom In", "Zoom Out"]
    let open_menu = menubar_open.get()
    let selected_item = menubar_item.get()

    // Helper to get menu items
    fn get_menu_items(idx : Int) -> Array[String] {
      match idx {
        0 => file_items
        1 => edit_items
        2 => view_items
        _ => []
      }
    }

    // Menu bar
    let menu_bar_items : Array[@vnode.TuiNode] = []
    for i, m in menus {
      menu_bar_items.push(
        @ui.menubar_item(m, open_menu == i, id="menu-" + i.to_string()),
      )
    }

    // Dropdown (if open) - use same structure for both states
    // Fixed height for dropdown area
    let dropdown_height = 10.0
    let dropdown : @vnode.TuiNode = if open_menu >= 0 {
      let items = get_menu_items(open_menu)
      let item_nodes : Array[@vnode.TuiNode] = []
      for i, item in items {
        item_nodes.push(
          @ui.menu_item(
            item,
            selected_item == i,
            id="menuitem-" + i.to_string(),
          ),
        )
      }
      @vnode.column(
        item_nodes,
        id="dropdown",
        border="single",
        border_color="cyan",
        bg="rgb(50,50,60)",
        height=dropdown_height,
      )
    } else {
      // Use same column structure as placeholder to keep layout stable
      @vnode.column([], id="dropdown", height=dropdown_height)
    }

    // Get current item name
    let current_item_name = if open_menu >= 0 {
      let items = get_menu_items(open_menu)
      if selected_item < items.length() {
        items[selected_item]
      } else {
        "none"
      }
    } else {
      "none"
    }
    @vnode.column([
      @vnode.text("Menubar", fg="yellow", bold=true),
      @vnode.text(
        "1/2/3: open menu, ↑/↓: select, Space: close",
        fg="rgb(128,128,128)",
      ),
      @vnode.vspace(1.0),
      @vnode.row(
        menu_bar_items,
        bg="rgb(40,40,50)",
        border="single",
        border_color="rgb(60,60,80)",
      ),
      dropdown,
      @vnode.spacer(),
      @vnode.text(
        "Menu: " +
        (if open_menu >= 0 { menus[open_menu] } else { "none" }) +
        " | Item: " +
        current_item_name,
        fg="green",
      ),
    ])
  }

  // ==========================================================================
  // Main Render
  // ==========================================================================

  fn render_ui() -> @vnode.TuiNode {
    let current = current_demo.get()

    // Navigation tabs
    let nav_items : Array[@vnode.TuiNode] = []
    for i, d in demos {
      nav_items.push(@ui.tab(d, current == i, id="nav-" + i.to_string()))
    }

    // Demo content
    let demo_content = match current {
      _ if current == demo_tabs => render_tabs_demo()
      _ if current == demo_accordion => render_accordion_demo()
      _ if current == demo_radio => render_radio_demo()
      _ if current == demo_switch => render_switch_demo()
      _ if current == demo_listbox => render_listbox_demo()
      _ if current == demo_combobox => render_combobox_demo()
      _ if current == demo_splitter => render_splitter_demo()
      _ if current == demo_menubar => render_menubar_demo()
      _ => @vnode.text("Unknown demo")
    }
    @vnode.column(
      [
        // Header
        @vnode.row(
          [@vnode.text("VNode Component Gallery", fg="yellow", bold=true)],
          justify="center",
          padding_y=0.5,
        ),
        // Navigation
        @vnode.row(nav_items, justify="center", gap=0.5),
        // Demo content
        @vnode.column(
          [demo_content],
          flex_grow=1.0,
          padding_x=1.0,
          padding_y=0.5,
          border="rounded",
          border_color="rgb(80,80,100)",
        ),
        // Footer
        @vnode.row(
          [@vnode.text(message.get(), fg="rgb(100,100,100)")],
          justify="center",
          padding_y=1.0,
        ),
      ],
      width=width.to_double(),
      height=height.to_double(),
    )
  }

  // ==========================================================================
  // Event Handling
  // ==========================================================================

  // Helper function for hit testing
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
              message.set("Demo: " + demos[current - 1])
            }
          @tui.KeyEvent::Special(@tui.SpecialKey::Right, _) =>
            if current < demos.length() - 1 {
              current_demo.set(current + 1)
              message.set("Demo: " + demos[current + 1])
            }
          // Demo-specific: Up
          @tui.KeyEvent::Special(@tui.SpecialKey::Up, _) =>
            match current {
              _ if current == demo_radio => {
                let sel = radio_selected.get()
                if sel > 0 {
                  radio_selected.set(sel - 1)
                  message.set("Radio: " + (sel - 1).to_string())
                }
              }
              _ if current == demo_listbox => {
                let sel = listbox_selected.get()
                if sel > 0 {
                  listbox_selected.set(sel - 1)
                }
              }
              _ if current == demo_combobox =>
                if combobox_open.get() {
                  let sel = combobox_selected.get()
                  if sel > 0 {
                    combobox_selected.set(sel - 1)
                  }
                }
              _ if current == demo_splitter => {
                let pos = splitter_pos.get()
                if pos > 10 {
                  splitter_pos.set(pos - 5)
                  message.set("Splitter: " + (pos - 5).to_string() + "%")
                }
              }
              _ if current == demo_menubar =>
                if menubar_open.get() >= 0 {
                  let sel = menubar_item.get()
                  if sel > 0 {
                    menubar_item.set(sel - 1)
                  }
                }
              _ => need_render = false
            }
          // Demo-specific: Down
          @tui.KeyEvent::Special(@tui.SpecialKey::Down, _) =>
            match current {
              _ if current == demo_radio => {
                let sel = radio_selected.get()
                if sel < 2 {
                  radio_selected.set(sel + 1)
                  message.set("Radio: " + (sel + 1).to_string())
                }
              }
              _ if current == demo_listbox => {
                let sel = listbox_selected.get()
                if sel < 4 {
                  listbox_selected.set(sel + 1)
                }
              }
              _ if current == demo_combobox =>
                if combobox_open.get() {
                  let sel = combobox_selected.get()
                  if sel < 4 {
                    combobox_selected.set(sel + 1)
                  }
                }
              _ if current == demo_splitter => {
                let pos = splitter_pos.get()
                if pos < 90 {
                  splitter_pos.set(pos + 5)
                  message.set("Splitter: " + (pos + 5).to_string() + "%")
                }
              }
              _ if current == demo_menubar =>
                if menubar_open.get() >= 0 {
                  let menu_idx = menubar_open.get()
                  let items = match menu_idx {
                    0 => 4
                    1 => 3
                    2 => 4
                    _ => 0
                  }
                  let sel = menubar_item.get()
                  if sel < items - 1 {
                    menubar_item.set(sel + 1)
                  }
                }
              _ => need_render = false
            }
          // Space toggle
          @tui.KeyEvent::Char(' ', _) =>
            match current {
              _ if current == demo_switch => {
                switch_on.set(not(switch_on.get()))
                message.set(
                  "Switch: " + (if switch_on.get() { "ON" } else { "OFF" }),
                )
              }
              _ if current == demo_combobox =>
                combobox_open.set(not(combobox_open.get()))
              _ if current == demo_menubar => {
                menubar_open.set(-1)
                menubar_item.set(0)
              }
              _ => need_render = false
            }
          // Number keys
          @tui.KeyEvent::Char('1', _) =>
            match current {
              _ if current == demo_tabs => tab_selected.set(0)
              _ if current == demo_accordion => accordion_expanded.set(0)
              _ if current == demo_switch =>
                checkbox_checked.set(not(checkbox_checked.get()))
              _ if current == demo_menubar => {
                menubar_open.set(0)
                menubar_item.set(0)
              }
              _ => need_render = false
            }
          @tui.KeyEvent::Char('2', _) =>
            match current {
              _ if current == demo_tabs => tab_selected.set(1)
              _ if current == demo_accordion => accordion_expanded.set(1)
              _ if current == demo_menubar => {
                menubar_open.set(1)
                menubar_item.set(0)
              }
              _ => need_render = false
            }
          @tui.KeyEvent::Char('3', _) =>
            match current {
              _ if current == demo_tabs => tab_selected.set(2)
              _ if current == demo_accordion => accordion_expanded.set(2)
              _ if current == demo_menubar => {
                menubar_open.set(2)
                menubar_item.set(0)
              }
              _ => need_render = false
            }
          _ => need_render = false
        }
      @tui.InputEvent::Mouse(mouse_event) =>
        match (mouse_event.event_type, mouse_event.button) {
          (@tui.MouseEventType::Press, @tui.MouseButton::Left) => {
            let mx = mouse_event.x
            let my = mouse_event.y
            let mut clicked = false

            // Check navigation
            for i in 0..<demos.length() {
              match app.find_by_id("nav-" + i.to_string()) {
                Some(hit) =>
                  if is_inside(mx, my, hit.x, hit.y, hit.width, hit.height) {
                    current_demo.set(i)
                    message.set("Demo: " + demos[i])
                    clicked = true
                    break
                  }
                None => ()
              }
            }

            // Demo-specific clicks
            if not(clicked) {
              match current {
                _ if current == demo_tabs =>
                  for i in 0..<3 {
                    match app.find_by_id("tab-" + i.to_string()) {
                      Some(hit) =>
                        if is_inside(
                            mx,
                            my,
                            hit.x,
                            hit.y,
                            hit.width,
                            hit.height,
                          ) {
                          tab_selected.set(i)
                          clicked = true
                          break
                        }
                      None => ()
                    }
                  }
                _ if current == demo_accordion =>
                  for i in 0..<3 {
                    match app.find_by_id("acc-" + i.to_string()) {
                      Some(hit) =>
                        if is_inside(
                            mx,
                            my,
                            hit.x,
                            hit.y,
                            hit.width,
                            hit.height,
                          ) {
                          accordion_expanded.set(i)
                          clicked = true
                          break
                        }
                      None => ()
                    }
                  }
                _ => ()
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
