///|
/// Component Gallery - Interactive demo of all TUI components

///|
fn main {
  let (cols, rows) = @tui.get_terminal_size()
  let width = cols
  let height = rows

  // State
  let running = @signals.signal(true)
  let current_tab = @signals.signal("tabs")
  let tab_selection = @signals.signal("tab1")
  let accordion_expanded = @signals.signal("sec1")
  let radio_selection = @signals.signal("opt2")
  let switch_on = @signals.signal(true)
  let checkbox_checked = @signals.signal(true)
  let listbox_selection = @signals.signal("apple")
  let combobox_open = @signals.signal(false)
  let combobox_selection = @signals.signal("js")
  let splitter_dragging = @signals.signal(false)
  let splitter_position = @signals.signal(50)
  let splitter_focused = @signals.signal(false)
  let menubar_open = @signals.signal("")
  let menubar_focused_item = @signals.signal("")
  let message = @signals.signal("← → to switch demos | q to quit")
  let app = @tui.App::new(width, height)

  // Available demos
  let demos = [
    "tabs", "accordion", "radio", "switch", "listbox", "combobox", "splitter", "menubar",
  ]
  fn render_ui() -> @tui.Component {
    let tab = current_tab.get()

    // Demo content based on current tab
    let demo_content : @tui.Component = match tab {
      "tabs" => render_tabs_demo(tab_selection)
      "accordion" => render_accordion_demo(accordion_expanded)
      "radio" => render_radio_demo(radio_selection)
      "switch" => render_switch_demo(switch_on, checkbox_checked)
      "listbox" => render_listbox_demo(listbox_selection)
      "combobox" => render_combobox_demo(combobox_open, combobox_selection)
      "splitter" => render_splitter_demo(splitter_position, splitter_focused)
      "menubar" => render_menubar_demo(menubar_open, menubar_focused_item)
      _ => @tui.text("Unknown demo")
    }

    // Build navigation tabs
    let nav_items : Array[@tui.Component] = []
    for d in demos {
      let is_current = d == tab
      let (fg, bg) = if is_current {
        (@tui.Color::black(), @tui.Color::cyan())
      } else {
        (@tui.Color::white(), @tui.Color::rgb(50, 50, 60))
      }
      nav_items.push(
        @tui.row(
          [@tui.text(" " + d + " ", fg~)],
          id=d,
          bg~,
          padding_x=1.0,
          align=@tui.align_center(),
        ),
      )
    }
    @tui.column(
      [
        // Header
        @tui.row(
          [@tui.text("Component Gallery", fg=@tui.Color::yellow(), bold=true)],
          justify=@tui.align_center(),
          padding_y=1.0,
        ),
        // Navigation
        @tui.row(nav_items, justify=@tui.align_center(), gap=1.0),
        @tui.vspace(1.0),
        // Demo content
        @tui.row(
          [demo_content],
          flex_grow=1.0,
          padding=1.0,
          border=Some(@tui.BorderChars::rounded()),
          border_color=@tui.Color::rgb(80, 80, 100),
        ),
        // Footer
        @tui.row(
          [@tui.text(message.get(), fg=@tui.Color::rgb(120, 120, 120))],
          justify=@tui.align_center(),
          padding_y=1.0,
        ),
      ],
      width=width.to_double(),
      height=height.to_double(),
    )
  }

  fn do_render() -> Unit {
    @tui.print_raw(app.render_frame(render_ui()))
  }

  fn do_quit() -> Unit {
    running.set(false)
    @tui.stop_keypress_listener()
    @tui.print_raw(@tui.disable_mouse())
    @tui.cleanup_stdin()
    @tui.print_raw(@tui.App::restore_terminal())
    println("Goodbye!")
  }

  fn handle_key(key : String) -> Unit {
    if key.length() == 0 {
      return
    }
    let event = @tui.parse_input(key)
    let mut need_render = true
    match event {
      @tui.InputEvent::Key(key_event) =>
        match key_event {
          @tui.KeyEvent::Char('q', @tui.KeyModifier::None) => {
            do_quit()
            return
          }
          @tui.KeyEvent::Char('c', @tui.KeyModifier::Ctrl) => {
            do_quit()
            return
          }
          @tui.KeyEvent::Special(@tui.SpecialKey::Escape, _) => {
            do_quit()
            return
          }
          // Navigate demos
          @tui.KeyEvent::Special(@tui.SpecialKey::Right, _) => {
            let cur = current_tab.get()
            if cur == "menubar" && menubar_open.get().length() > 0 {
              handle_demo_key(
                "right", current_tab, tab_selection, accordion_expanded, radio_selection,
                switch_on, checkbox_checked, listbox_selection, combobox_open, combobox_selection,
                splitter_position, splitter_focused, menubar_open, menubar_focused_item,
                message,
              )
            } else {
              for i = 0; i < demos.length(); i = i + 1 {
                if demos[i] == cur && i < demos.length() - 1 {
                  current_tab.set(demos[i + 1])
                  message.set("Demo: " + demos[i + 1])
                  break
                }
              }
            }
          }
          @tui.KeyEvent::Special(@tui.SpecialKey::Left, _) => {
            let cur = current_tab.get()
            if cur == "menubar" && menubar_open.get().length() > 0 {
              handle_demo_key(
                "left", current_tab, tab_selection, accordion_expanded, radio_selection,
                switch_on, checkbox_checked, listbox_selection, combobox_open, combobox_selection,
                splitter_position, splitter_focused, menubar_open, menubar_focused_item,
                message,
              )
            } else {
              for i = 0; i < demos.length(); i = i + 1 {
                if demos[i] == cur && i > 0 {
                  current_tab.set(demos[i - 1])
                  message.set("Demo: " + demos[i - 1])
                  break
                }
              }
            }
          }
          // Demo-specific keys
          @tui.KeyEvent::Special(@tui.SpecialKey::Up, _) =>
            handle_demo_key(
              "up", current_tab, tab_selection, accordion_expanded, radio_selection,
              switch_on, checkbox_checked, listbox_selection, combobox_open, combobox_selection,
              splitter_position, splitter_focused, menubar_open, menubar_focused_item,
              message,
            )
          @tui.KeyEvent::Special(@tui.SpecialKey::Down, _) =>
            handle_demo_key(
              "down", current_tab, tab_selection, accordion_expanded, radio_selection,
              switch_on, checkbox_checked, listbox_selection, combobox_open, combobox_selection,
              splitter_position, splitter_focused, menubar_open, menubar_focused_item,
              message,
            )
          @tui.KeyEvent::Char(' ', _) =>
            handle_demo_key(
              "space", current_tab, tab_selection, accordion_expanded, radio_selection,
              switch_on, checkbox_checked, listbox_selection, combobox_open, combobox_selection,
              splitter_position, splitter_focused, menubar_open, menubar_focused_item,
              message,
            )
          @tui.KeyEvent::Special(@tui.SpecialKey::Enter, _) =>
            handle_demo_key(
              "enter", current_tab, tab_selection, accordion_expanded, radio_selection,
              switch_on, checkbox_checked, listbox_selection, combobox_open, combobox_selection,
              splitter_position, splitter_focused, menubar_open, menubar_focused_item,
              message,
            )
          @tui.KeyEvent::Char('1', _) =>
            handle_demo_key(
              "1", current_tab, tab_selection, accordion_expanded, radio_selection,
              switch_on, checkbox_checked, listbox_selection, combobox_open, combobox_selection,
              splitter_position, splitter_focused, menubar_open, menubar_focused_item,
              message,
            )
          @tui.KeyEvent::Char('2', _) =>
            handle_demo_key(
              "2", current_tab, tab_selection, accordion_expanded, radio_selection,
              switch_on, checkbox_checked, listbox_selection, combobox_open, combobox_selection,
              splitter_position, splitter_focused, menubar_open, menubar_focused_item,
              message,
            )
          @tui.KeyEvent::Char('3', _) =>
            handle_demo_key(
              "3", current_tab, tab_selection, accordion_expanded, radio_selection,
              switch_on, checkbox_checked, listbox_selection, combobox_open, combobox_selection,
              splitter_position, splitter_focused, menubar_open, menubar_focused_item,
              message,
            )
          _ => need_render = false
        }
      @tui.InputEvent::Mouse(mouse_event) =>
        match (mouse_event.event_type, mouse_event.button) {
          (@tui.MouseEventType::Drag, _) =>
            if current_tab.get() == "splitter" && splitter_dragging.get() {
              let width = 80
              let divider_width = 2
              // x is 1-indexed, divider is at splitter_position + divider_width/2
              let x = mouse_event.x - 1
              let ratio = x * 100 / (width - divider_width)
              let new_pos = ratio.clamp(min=10, max=90)
              splitter_position.set(new_pos)
              message.set("Splitter: " + new_pos.to_string() + "%")
            }
          (@tui.MouseEventType::Press, @tui.MouseButton::Left) =>
            match app.hit_test(mouse_event.x, mouse_event.y) {
              Some(hit) => {
                let mut found = false
                // Check if clicked on nav
                for d in demos {
                  if hit.id == d || hit.id.has_prefix(d) {
                    current_tab.set(d)
                    message.set("Demo: " + d)
                    found = true
                    break
                  }
                }
                // Handle demo-specific clicks
                if not(found) {
                  // Switch demo - click on switch/checkbox
                  if current_tab.get() == "switch" {
                    if hit.id == "switch-darkmode" ||
                      hit.id.has_prefix("switch-darkmode") {
                      let new_state = not(switch_on.get())
                      switch_on.set(new_state)
                      message.set(
                        "Switch: " + (if new_state { "ON" } else { "OFF" }),
                      )
                      found = true
                    } else if hit.id == "checkbox-terms" ||
                      hit.id.has_prefix("checkbox-terms") {
                      let new_checked = not(checkbox_checked.get())
                      checkbox_checked.set(new_checked)
                      message.set(
                        "Checkbox: " +
                        (if new_checked { "checked" } else { "unchecked" }),
                      )
                      found = true
                    }
                  }
                  // Start dragging splitter
                  if current_tab.get() == "splitter" &&
                    not(found) &&
                    (hit.id == "splitter" || hit.id == "splitter-divider") {
                    splitter_dragging.set(true)
                    splitter_focused.set(true)
                    message.set("Splitter dragging")
                    found = true
                  }
                  // Tabs demo - click on tab1/tab2/tab3
                  if current_tab.get() == "tabs" && not(found) {
                    if hit.id == "tab1" || hit.id.has_prefix("tab1") {
                      tab_selection.set("tab1")
                      message.set("Tab: tab1 selected")
                      found = true
                    } else if hit.id == "tab2" || hit.id.has_prefix("tab2") {
                      tab_selection.set("tab2")
                      message.set("Tab: tab2 selected")
                      found = true
                    } else if hit.id == "tab3" || hit.id.has_prefix("tab3") {
                      tab_selection.set("tab3")
                      message.set("Tab: tab3 selected")
                      found = true
                    }
                  }
                  // Accordion demo - click on section headers
                  if current_tab.get() == "accordion" && not(found) {
                    if hit.id.has_prefix("sec1") {
                      accordion_expanded.set("sec1")
                      message.set("Section 1 expanded")
                      found = true
                    } else if hit.id.has_prefix("sec2") {
                      accordion_expanded.set("sec2")
                      message.set("Section 2 expanded")
                      found = true
                    } else if hit.id.has_prefix("sec3") {
                      accordion_expanded.set("sec3")
                      message.set("Section 3 expanded")
                      found = true
                    }
                  }
                  if not(found) {
                    message.set("Clicked: " + hit.id)
                  }
                }
              }
              None => need_render = false
            }
          (@tui.MouseEventType::Release, _) =>
            if splitter_dragging.get() {
              splitter_dragging.set(false)
              message.set("Splitter released")
            }
          _ => need_render = false
        }
      _ => need_render = false
    }
    if need_render && running.get() {
      do_render()
    }
  }

  // Initialize
  @tui.print_raw(@tui.App::init_terminal())
  @tui.print_raw(@tui.enable_mouse())
  do_render()
  @tui.start_keypress_listener(handle_key)
}

///|
fn handle_demo_key(
  key : String,
  current_tab : @signals.Signal[String],
  tab_selection : @signals.Signal[String],
  accordion_expanded : @signals.Signal[String],
  radio_selection : @signals.Signal[String],
  switch_on : @signals.Signal[Bool],
  checkbox_checked : @signals.Signal[Bool],
  listbox_selection : @signals.Signal[String],
  combobox_open : @signals.Signal[Bool],
  combobox_selection : @signals.Signal[String],
  splitter_position : @signals.Signal[Int],
  splitter_focused : @signals.Signal[Bool],
  menubar_open : @signals.Signal[String],
  menubar_focused_item : @signals.Signal[String],
  message : @signals.Signal[String],
) -> Unit {
  let tab = current_tab.get()
  match tab {
    "tabs" =>
      if key == "1" {
        tab_selection.set("tab1")
        message.set("Tab 1 selected")
      } else if key == "2" {
        tab_selection.set("tab2")
        message.set("Tab 2 selected")
      } else if key == "3" {
        tab_selection.set("tab3")
        message.set("Tab 3 selected")
      }
    "accordion" =>
      if key == "1" {
        accordion_expanded.set("sec1")
        message.set("Section 1 expanded")
      } else if key == "2" {
        accordion_expanded.set("sec2")
        message.set("Section 2 expanded")
      } else if key == "3" {
        accordion_expanded.set("sec3")
        message.set("Section 3 expanded")
      }
    "radio" =>
      if key == "up" {
        let options = ["opt1", "opt2", "opt3"]
        let cur = radio_selection.get()
        for i = 0; i < options.length(); i = i + 1 {
          if options[i] == cur && i > 0 {
            radio_selection.set(options[i - 1])
            message.set("Selected: " + options[i - 1])
            break
          }
        }
      } else if key == "down" {
        let options = ["opt1", "opt2", "opt3"]
        let cur = radio_selection.get()
        for i = 0; i < options.length(); i = i + 1 {
          if options[i] == cur && i < options.length() - 1 {
            radio_selection.set(options[i + 1])
            message.set("Selected: " + options[i + 1])
            break
          }
        }
      }
    "switch" =>
      if key == "space" || key == "enter" {
        let new_state = not(switch_on.get())
        switch_on.set(new_state)
        message.set("Switch: " + (if new_state { "ON" } else { "OFF" }))
      } else if key == "1" {
        let new_checked = not(checkbox_checked.get())
        checkbox_checked.set(new_checked)
        message.set(
          "Checkbox: " + (if new_checked { "checked" } else { "unchecked" }),
        )
      }
    "listbox" => {
      let options = ["apple", "banana", "cherry", "date", "elderberry"]
      let cur = listbox_selection.get()
      if key == "up" {
        for i = 0; i < options.length(); i = i + 1 {
          if options[i] == cur && i > 0 {
            listbox_selection.set(options[i - 1])
            message.set("Selected: " + options[i - 1])
            break
          }
        }
      } else if key == "down" {
        for i = 0; i < options.length(); i = i + 1 {
          if options[i] == cur && i < options.length() - 1 {
            listbox_selection.set(options[i + 1])
            message.set("Selected: " + options[i + 1])
            break
          }
        }
      }
    }
    "combobox" => {
      let options = ["js", "ts", "py", "rs", "go"]
      let labels = ["JavaScript", "TypeScript", "Python", "Rust", "Go"]
      let cur = combobox_selection.get()
      if key == "space" || key == "enter" {
        combobox_open.set(not(combobox_open.get()))
        message.set(
          "Combobox: " + (if combobox_open.get() { "open" } else { "closed" }),
        )
      } else if key == "up" {
        for i = 0; i < options.length(); i = i + 1 {
          if options[i] == cur && i > 0 {
            combobox_selection.set(options[i - 1])
            message.set("Selected: " + labels[i - 1])
            break
          }
        }
      } else if key == "down" {
        for i = 0; i < options.length(); i = i + 1 {
          if options[i] == cur && i < options.length() - 1 {
            combobox_selection.set(options[i + 1])
            message.set("Selected: " + labels[i + 1])
            break
          }
        }
      }
    }
    "splitter" =>
      if key == "up" || key == "down" {
        splitter_focused.set(true)
        let delta = if key == "up" { -5 } else { 5 }
        let new_pos = (splitter_position.get() + delta).clamp(min=10, max=90)
        splitter_position.set(new_pos)
        message.set("Splitter: " + new_pos.to_string() + "%")
      } else if key == "space" {
        splitter_focused.set(not(splitter_focused.get()))
        message.set(
          "Splitter focus: " +
          (if splitter_focused.get() { "on" } else { "off" }),
        )
      }
    "menubar" => {
      let menus = ["file", "edit", "view"]
      let cur = menubar_open.get()
      fn get_menu_items(menu_id : String) -> Array[String] {
        match menu_id {
          "file" => ["new", "open", "save", "exit"]
          "edit" => ["cut", "copy", "paste"]
          "view" => ["toolbar", "statusbar", "normal", "compact"]
          _ => []
        }
      }

      if key == "1" {
        menubar_open.set("file")
        menubar_focused_item.set("new")
        message.set("File menu open")
      } else if key == "2" {
        menubar_open.set("edit")
        menubar_focused_item.set("cut")
        message.set("Edit menu open")
      } else if key == "3" {
        menubar_open.set("view")
        menubar_focused_item.set("toolbar")
        message.set("View menu open")
      } else if key == "space" || key == "enter" {
        menubar_open.set("")
        menubar_focused_item.set("")
        message.set("Menu closed")
      } else if key == "left" || key == "right" {
        if cur.length() > 0 {
          for i = 0; i < menus.length(); i = i + 1 {
            if menus[i] == cur {
              let next_idx = if key == "right" {
                (i + 1) % menus.length()
              } else {
                (i + menus.length() - 1) % menus.length()
              }
              menubar_open.set(menus[next_idx])
              let new_menu_items = get_menu_items(menus[next_idx])
              if new_menu_items.length() > 0 {
                menubar_focused_item.set(new_menu_items[0])
              }
              message.set("Menu: " + menus[next_idx])
              break
            }
          }
        }
      } else if (key == "up" || key == "down") && cur.length() > 0 {
        let items = get_menu_items(cur)
        let focused = menubar_focused_item.get()
        if items.length() > 0 {
          let mut idx = 0
          for i = 0; i < items.length(); i = i + 1 {
            if items[i] == focused {
              idx = i
              break
            }
          }
          let next_idx = if key == "down" {
            (idx + 1) % items.length()
          } else {
            (idx + items.length() - 1) % items.length()
          }
          menubar_focused_item.set(items[next_idx])
          message.set("Selected: " + items[next_idx])
        }
      }
    }
    _ => ()
  }
}

// ============================================
// Demo Renderers
// ============================================

///|
fn render_tabs_demo(selection : @signals.Signal[String]) -> @tui.Component {
  let items = [
    @tui.TabItem::{ id: "tab1", label: "Home" },
    @tui.TabItem::{ id: "tab2", label: "Profile" },
    @tui.TabItem::{ id: "tab3", label: "Settings" },
  ]
  let sel = selection.get()
  let content = match sel {
    "tab1" => @tui.text("Welcome to the Home tab!")
    "tab2" => @tui.text("Your profile information here.")
    "tab3" => @tui.text("Application settings.")
    _ => @tui.text("Select a tab")
  }
  // Use boxed style for clearer tab boundaries
  let tabs_bar = @tui.tabs_boxed(items, sel)
  let panel = @tui.tab_panel(content)
  @tui.column(
    [
      @tui.text("Tabs Demo (1/2/3 or click)", fg=@tui.Color::cyan()),
      @tui.vspace(1.0),
      tabs_bar,
      panel,
      @tui.vspace(0.5),
      @tui.text("Selected: " + sel, fg=@tui.Color::green()),
    ],
    gap=0.5,
  )
}

///|
fn render_accordion_demo(expanded : @signals.Signal[String]) -> @tui.Component {
  let exp = expanded.get()
  let items = [
    @tui.AccordionItem::{
      id: "sec1",
      title: "Section 1: Introduction",
      content: @tui.text("This is the introduction content."),
      expanded: exp == "sec1",
    },
    @tui.AccordionItem::{
      id: "sec2",
      title: "Section 2: Features",
      content: @tui.text("Feature list goes here."),
      expanded: exp == "sec2",
    },
    @tui.AccordionItem::{
      id: "sec3",
      title: "Section 3: FAQ",
      content: @tui.text("Frequently asked questions."),
      expanded: exp == "sec3",
    },
  ]
  @tui.column(
    [
      @tui.text("Accordion Demo (press 1/2/3)", fg=@tui.Color::cyan()),
      @tui.vspace(1.0),
      @tui.accordion(items),
    ],
    gap=0.5,
  )
}

///|
fn render_radio_demo(selection : @signals.Signal[String]) -> @tui.Component {
  let options = [
    @tui.RadioOption::{ id: "opt1", label: "Option 1: Fast" },
    @tui.RadioOption::{ id: "opt2", label: "Option 2: Balanced" },
    @tui.RadioOption::{ id: "opt3", label: "Option 3: Power Saver" },
  ]
  @tui.column(
    [
      @tui.text("Radio Group Demo (↑/↓ to navigate)", fg=@tui.Color::cyan()),
      @tui.vspace(1.0),
      @tui.text("Select mode:"),
      @tui.radiogroup(options, selection.get()),
      @tui.vspace(1.0),
      @tui.text("Selected: " + selection.get(), fg=@tui.Color::green()),
    ],
    gap=0.5,
  )
}

///|
fn render_switch_demo(
  switch_on : @signals.Signal[Bool],
  checkbox_checked : @signals.Signal[Bool],
) -> @tui.Component {
  @tui.column(
    [
      @tui.text("Switch & Checkbox Demo", fg=@tui.Color::cyan()),
      @tui.vspace(1.0),
      @tui.text("Space/Enter to toggle switch, 1 to toggle checkbox"),
      @tui.vspace(1.0),
      @tui.labeled_switch("Dark Mode", switch_on.get(), id="switch-darkmode"),
      @tui.vspace(0.5),
      @tui.labeled_switch(
        "Notifications",
        not(switch_on.get()),
        label_position=@tui.LabelPosition::Right,
      ),
      @tui.vspace(1.0),
      @tui.labeled_checkbox(
        "Accept Terms",
        checkbox_checked.get(),
        id="checkbox-terms",
      ),
      @tui.labeled_checkbox(
        "Subscribe to newsletter",
        not(checkbox_checked.get()),
      ),
    ],
    gap=0.5,
  )
}

///|
fn render_listbox_demo(selection : @signals.Signal[String]) -> @tui.Component {
  let options = [
    @tui.listbox_option("apple", "🍎 Apple"),
    @tui.listbox_option("banana", "🍌 Banana"),
    @tui.listbox_option("cherry", "🍒 Cherry"),
    @tui.listbox_option("date", "📅 Date"),
    @tui.listbox_option("elderberry", "🫐 Elderberry"),
  ]
  @tui.column(
    [
      @tui.text("Listbox Demo (↑/↓ to navigate)", fg=@tui.Color::cyan()),
      @tui.vspace(1.0),
      @tui.text("Choose a fruit:"),
      @tui.listbox(options, selection.get(), focused_id=selection.get()),
      @tui.vspace(1.0),
      @tui.text("Selected: " + selection.get(), fg=@tui.Color::green()),
    ],
    gap=0.5,
  )
}

///|
fn render_combobox_demo(
  open : @signals.Signal[Bool],
  selection : @signals.Signal[String],
) -> @tui.Component {
  let options = [
    @tui.ComboboxOption::{ id: "js", label: "JavaScript" },
    @tui.ComboboxOption::{ id: "ts", label: "TypeScript" },
    @tui.ComboboxOption::{ id: "py", label: "Python" },
    @tui.ComboboxOption::{ id: "rs", label: "Rust" },
    @tui.ComboboxOption::{ id: "go", label: "Go" },
  ]
  let state = if open.get() {
    @tui.ComboboxState::Open
  } else {
    @tui.ComboboxState::Closed
  }
  @tui.column(
    [
      @tui.text(
        "Combobox Demo (Space to open, ↑/↓ to select)",
        fg=@tui.Color::cyan(),
      ),
      @tui.vspace(1.0),
      @tui.text("Select language:"),
      @tui.combobox(options, selection.get(), state~),
      @tui.vspace(1.0),
      @tui.text("Selected: " + selection.get(), fg=@tui.Color::green()),
    ],
    gap=0.5,
  )
}

///|
fn render_splitter_demo(
  position : @signals.Signal[Int],
  focused : @signals.Signal[Bool],
) -> @tui.Component {
  let state : @tui.SplitterState = {
    position: position.get(),
    collapsed: false,
    prev_position: position.get(),
    focused: focused.get(),
  }
  let primary = @tui.column(
    [
      @tui.text("Left Pane", fg=@tui.Color::cyan()),
      @tui.text("Resize with ↑/↓"),
    ],
    padding=1.0,
    bg=@tui.Color::rgb(40, 40, 50),
  )
  let secondary = @tui.column(
    [
      @tui.text("Right Pane", fg=@tui.Color::yellow()),
      @tui.text("Position: " + position.get().to_string() + "%"),
    ],
    padding=1.0,
    bg=@tui.Color::rgb(50, 40, 40),
  )
  @tui.column(
    [
      @tui.text(
        "Window Splitter Demo (Drag divider with mouse, ↑/↓ to resize)",
        fg=@tui.Color::cyan(),
      ),
      @tui.vspace(1.0),
      @tui.window_splitter(
        primary,
        secondary,
        state,
        total_size=80,
        id="splitter",
        divider_width=2.0,
      ),
    ],
    gap=0.5,
  )
}

///|
fn render_menubar_demo(
  open_menu : @signals.Signal[String],
  menubar_focused_item : @signals.Signal[String],
) -> @tui.Component {
  let items = [
    @tui.MenubarItem::{
      id: "file",
      label: "File",
      items: [
        @tui.menu_item("new", "New"),
        @tui.menu_item("open", "Open"),
        @tui.menu_item("save", "Save"),
        @tui.menu_separator(),
        @tui.menu_item("exit", "Exit"),
      ],
    },
    @tui.MenubarItem::{
      id: "edit",
      label: "Edit",
      items: [
        @tui.menu_item("cut", "Cut"),
        @tui.menu_item("copy", "Copy"),
        @tui.menu_item("paste", "Paste"),
      ],
    },
    @tui.MenubarItem::{
      id: "view",
      label: "View",
      items: [
        @tui.menu_checkbox("toolbar", "Toolbar", true),
        @tui.menu_checkbox("statusbar", "Status Bar", false),
        @tui.menu_separator(),
        @tui.menu_radio("normal", "Normal", true),
        @tui.menu_radio("compact", "Compact", false),
      ],
    },
  ]
  let state : @tui.MenubarState = {
    open_menu_id: open_menu.get(),
    focused_item_id: menubar_focused_item.get(),
    open_submenu_path: [],
  }
  @tui.column(
    [
      @tui.text(
        "Menubar Demo (1/2/3 to open, ←/→ to switch menus, ↑/↓ to select items, Space to close)",
        fg=@tui.Color::cyan(),
      ),
      @tui.vspace(1.0),
      @tui.menubar(items, state),
      @tui.vspace(1.0),
      @tui.text(
        "Open: " +
        (if open_menu.get().length() > 0 { open_menu.get() } else { "none" }) +
        " | Focused: " +
        (if menubar_focused_item.get().length() > 0 {
          menubar_focused_item.get()
        } else {
          "none"
        }),
        fg=@tui.Color::green(),
      ),
    ],
    gap=0.5,
  )
}
