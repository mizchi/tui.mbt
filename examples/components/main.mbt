///|
/// Component Gallery - Interactive demo of all TUI components

///|
fn main {
  let (cols, rows) = @io.get_terminal_size()
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
  let app = @render.App::new(width, height)

  // Available demos
  let demos = [
    "tabs", "accordion", "radio", "switch", "listbox", "combobox", "splitter", "menubar",
  ]
  fn render_ui() -> @core.Component {
    let tab = current_tab.get()

    // Demo content based on current tab
    let demo_content : @core.Component = match tab {
      "tabs" => render_tabs_demo(tab_selection)
      "accordion" => render_accordion_demo(accordion_expanded)
      "radio" => render_radio_demo(radio_selection)
      "switch" => render_switch_demo(switch_on, checkbox_checked)
      "listbox" => render_listbox_demo(listbox_selection)
      "combobox" => render_combobox_demo(combobox_open, combobox_selection)
      "splitter" => render_splitter_demo(splitter_position, splitter_focused)
      "menubar" => render_menubar_demo(menubar_open, menubar_focused_item)
      _ => @c.text("Unknown demo")
    }

    // Build navigation tabs
    let nav_items : Array[@core.Component] = []
    for d in demos {
      let is_current = d == tab
      let (fg, bg) = if is_current {
        (@core.Color::black(), @core.Color::cyan())
      } else {
        (@core.Color::white(), @core.Color::rgb(50, 50, 60))
      }
      nav_items.push(
        @c.row(
          [@c.text(" " + d + " ", fg~)],
          id=d,
          bg~,
          padding_x=1.0,
          align=@types.Alignment::Center,
        ),
      )
    }
    @c.column(
      [
        // Header
        @c.row(
          [@c.text("Component Gallery", fg=@core.Color::yellow(), bold=true)],
          justify=@types.Alignment::Center,
          padding_y=1.0,
        ),
        // Navigation
        @c.row(nav_items, justify=@types.Alignment::Center, gap=1.0),
        @c.vspace(1.0),
        // Demo content
        @c.row(
          [demo_content],
          flex_grow=1.0,
          padding=1.0,
          border=Some(@core.BorderChars::rounded()),
          border_color=@core.Color::rgb(80, 80, 100),
        ),
        // Footer
        @c.row(
          [@c.text(message.get(), fg=@core.Color::rgb(120, 120, 120))],
          justify=@types.Alignment::Center,
          padding_y=1.0,
        ),
      ],
      width=@types.Dimension::Length(width.to_double()),
      height=@types.Dimension::Length(height.to_double()),
    )
  }

  fn do_render() -> Unit {
    @io.print_raw(app.render_frame(render_ui()))
  }

  fn do_quit() -> Unit {
    running.set(false)
    @io.stop_keypress_listener()
    @io.print_raw(@render.disable_mouse())
    @io.cleanup_stdin()
    @io.print_raw(@render.App::restore_terminal())
    println("Goodbye!")
  }

  fn handle_key(key : String) -> Unit {
    if key.length() == 0 {
      return
    }
    let event = @events.parse_input(key)
    let mut need_render = true
    match event {
      @events.InputEvent::Key(key_event) =>
        match key_event {
          @events.KeyEvent::Char('q', @events.KeyModifier::None) => {
            do_quit()
            return
          }
          @events.KeyEvent::Char('c', @events.KeyModifier::Ctrl) => {
            do_quit()
            return
          }
          @events.KeyEvent::Special(@events.SpecialKey::Escape, _) => {
            do_quit()
            return
          }
          // Navigate demos
          @events.KeyEvent::Special(@events.SpecialKey::Right, _) => {
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
          @events.KeyEvent::Special(@events.SpecialKey::Left, _) => {
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
          @events.KeyEvent::Special(@events.SpecialKey::Up, _) =>
            handle_demo_key(
              "up", current_tab, tab_selection, accordion_expanded, radio_selection,
              switch_on, checkbox_checked, listbox_selection, combobox_open, combobox_selection,
              splitter_position, splitter_focused, menubar_open, menubar_focused_item,
              message,
            )
          @events.KeyEvent::Special(@events.SpecialKey::Down, _) =>
            handle_demo_key(
              "down", current_tab, tab_selection, accordion_expanded, radio_selection,
              switch_on, checkbox_checked, listbox_selection, combobox_open, combobox_selection,
              splitter_position, splitter_focused, menubar_open, menubar_focused_item,
              message,
            )
          @events.KeyEvent::Char(' ', _) =>
            handle_demo_key(
              "space", current_tab, tab_selection, accordion_expanded, radio_selection,
              switch_on, checkbox_checked, listbox_selection, combobox_open, combobox_selection,
              splitter_position, splitter_focused, menubar_open, menubar_focused_item,
              message,
            )
          @events.KeyEvent::Special(@events.SpecialKey::Enter, _) =>
            handle_demo_key(
              "enter", current_tab, tab_selection, accordion_expanded, radio_selection,
              switch_on, checkbox_checked, listbox_selection, combobox_open, combobox_selection,
              splitter_position, splitter_focused, menubar_open, menubar_focused_item,
              message,
            )
          @events.KeyEvent::Char('1', _) =>
            handle_demo_key(
              "1", current_tab, tab_selection, accordion_expanded, radio_selection,
              switch_on, checkbox_checked, listbox_selection, combobox_open, combobox_selection,
              splitter_position, splitter_focused, menubar_open, menubar_focused_item,
              message,
            )
          @events.KeyEvent::Char('2', _) =>
            handle_demo_key(
              "2", current_tab, tab_selection, accordion_expanded, radio_selection,
              switch_on, checkbox_checked, listbox_selection, combobox_open, combobox_selection,
              splitter_position, splitter_focused, menubar_open, menubar_focused_item,
              message,
            )
          @events.KeyEvent::Char('3', _) =>
            handle_demo_key(
              "3", current_tab, tab_selection, accordion_expanded, radio_selection,
              switch_on, checkbox_checked, listbox_selection, combobox_open, combobox_selection,
              splitter_position, splitter_focused, menubar_open, menubar_focused_item,
              message,
            )
          _ => need_render = false
        }
      @events.InputEvent::Mouse(mouse_event) =>
        match (mouse_event.event_type, mouse_event.button) {
          (@events.MouseEventType::Drag, _) =>
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
          (@events.MouseEventType::Press, @events.MouseButton::Left) =>
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
          (@events.MouseEventType::Release, _) =>
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
  @io.print_raw(@render.App::init_terminal())
  @io.print_raw(@render.enable_mouse())
  do_render()
  @io.start_keypress_listener(handle_key)
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
fn render_tabs_demo(selection : @signals.Signal[String]) -> @core.Component {
  let items = [
    @c.TabItem::{ id: "tab1", label: "Home" },
    @c.TabItem::{ id: "tab2", label: "Profile" },
    @c.TabItem::{ id: "tab3", label: "Settings" },
  ]
  let sel = selection.get()
  let content = match sel {
    "tab1" => @c.text("Welcome to the Home tab!")
    "tab2" => @c.text("Your profile information here.")
    "tab3" => @c.text("Application settings.")
    _ => @c.text("Select a tab")
  }
  // Use boxed style for clearer tab boundaries
  let tabs_bar = @c.tabs_boxed(items, sel)
  let panel = @c.tab_panel(content)
  @c.column(
    [
      @c.text("Tabs Demo (1/2/3 or click)", fg=@core.Color::cyan()),
      @c.vspace(1.0),
      tabs_bar,
      panel,
      @c.vspace(0.5),
      @c.text("Selected: " + sel, fg=@core.Color::green()),
    ],
    gap=0.5,
  )
}

///|
fn render_accordion_demo(expanded : @signals.Signal[String]) -> @core.Component {
  let exp = expanded.get()
  let items = [
    @c.AccordionItem::{
      id: "sec1",
      title: "Section 1: Introduction",
      content: @c.text("This is the introduction content."),
      expanded: exp == "sec1",
    },
    @c.AccordionItem::{
      id: "sec2",
      title: "Section 2: Features",
      content: @c.text("Feature list goes here."),
      expanded: exp == "sec2",
    },
    @c.AccordionItem::{
      id: "sec3",
      title: "Section 3: FAQ",
      content: @c.text("Frequently asked questions."),
      expanded: exp == "sec3",
    },
  ]
  @c.column(
    [
      @c.text("Accordion Demo (press 1/2/3)", fg=@core.Color::cyan()),
      @c.vspace(1.0),
      @c.accordion(items),
    ],
    gap=0.5,
  )
}

///|
fn render_radio_demo(selection : @signals.Signal[String]) -> @core.Component {
  let options = [
    @c.RadioOption::{ id: "opt1", label: "Option 1: Fast" },
    @c.RadioOption::{ id: "opt2", label: "Option 2: Balanced" },
    @c.RadioOption::{ id: "opt3", label: "Option 3: Power Saver" },
  ]
  @c.column(
    [
      @c.text("Radio Group Demo (↑/↓ to navigate)", fg=@core.Color::cyan()),
      @c.vspace(1.0),
      @c.text("Select mode:"),
      @c.radiogroup(options, selection.get()),
      @c.vspace(1.0),
      @c.text("Selected: " + selection.get(), fg=@core.Color::green()),
    ],
    gap=0.5,
  )
}

///|
fn render_switch_demo(
  switch_on : @signals.Signal[Bool],
  checkbox_checked : @signals.Signal[Bool],
) -> @core.Component {
  @c.column(
    [
      @c.text("Switch & Checkbox Demo", fg=@core.Color::cyan()),
      @c.vspace(1.0),
      @c.text("Space/Enter to toggle switch, 1 to toggle checkbox"),
      @c.vspace(1.0),
      @c.labeled_switch("Dark Mode", switch_on.get(), id="switch-darkmode"),
      @c.vspace(0.5),
      @c.labeled_switch(
        "Notifications",
        not(switch_on.get()),
        label_position=@c.LabelPosition::Right,
      ),
      @c.vspace(1.0),
      @c.labeled_checkbox(
        "Accept Terms",
        checkbox_checked.get(),
        id="checkbox-terms",
      ),
      @c.labeled_checkbox(
        "Subscribe to newsletter",
        not(checkbox_checked.get()),
      ),
    ],
    gap=0.5,
  )
}

///|
fn render_listbox_demo(selection : @signals.Signal[String]) -> @core.Component {
  let options = [
    @c.listbox_option("apple", "🍎 Apple"),
    @c.listbox_option("banana", "🍌 Banana"),
    @c.listbox_option("cherry", "🍒 Cherry"),
    @c.listbox_option("date", "📅 Date"),
    @c.listbox_option("elderberry", "🫐 Elderberry"),
  ]
  @c.column(
    [
      @c.text("Listbox Demo (↑/↓ to navigate)", fg=@core.Color::cyan()),
      @c.vspace(1.0),
      @c.text("Choose a fruit:"),
      @c.listbox(options, selection.get(), focused_id=selection.get()),
      @c.vspace(1.0),
      @c.text("Selected: " + selection.get(), fg=@core.Color::green()),
    ],
    gap=0.5,
  )
}

///|
fn render_combobox_demo(
  open : @signals.Signal[Bool],
  selection : @signals.Signal[String],
) -> @core.Component {
  let options = [
    @c.ComboboxOption::{ id: "js", label: "JavaScript" },
    @c.ComboboxOption::{ id: "ts", label: "TypeScript" },
    @c.ComboboxOption::{ id: "py", label: "Python" },
    @c.ComboboxOption::{ id: "rs", label: "Rust" },
    @c.ComboboxOption::{ id: "go", label: "Go" },
  ]
  let state = if open.get() {
    @c.ComboboxState::Open
  } else {
    @c.ComboboxState::Closed
  }
  @c.column(
    [
      @c.text(
        "Combobox Demo (Space to open, ↑/↓ to select)",
        fg=@core.Color::cyan(),
      ),
      @c.vspace(1.0),
      @c.text("Select language:"),
      @c.combobox(options, selection.get(), state~),
      @c.vspace(1.0),
      @c.text("Selected: " + selection.get(), fg=@core.Color::green()),
    ],
    gap=0.5,
  )
}

///|
fn render_splitter_demo(
  position : @signals.Signal[Int],
  focused : @signals.Signal[Bool],
) -> @core.Component {
  let state : @c.SplitterState = {
    position: position.get(),
    collapsed: false,
    prev_position: position.get(),
    focused: focused.get(),
  }
  let primary = @c.column(
    [
      @c.text("Left Pane", fg=@core.Color::cyan()),
      @c.text("Resize with ↑/↓"),
    ],
    padding=1.0,
    bg=@core.Color::rgb(40, 40, 50),
  )
  let secondary = @c.column(
    [
      @c.text("Right Pane", fg=@core.Color::yellow()),
      @c.text("Position: " + position.get().to_string() + "%"),
    ],
    padding=1.0,
    bg=@core.Color::rgb(50, 40, 40),
  )
  @c.column(
    [
      @c.text(
        "Window Splitter Demo (Drag divider with mouse, ↑/↓ to resize)",
        fg=@core.Color::cyan(),
      ),
      @c.vspace(1.0),
      @c.window_splitter(
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
) -> @core.Component {
  let items = [
    @c.MenubarItem::{
      id: "file",
      label: "File",
      items: [
        @c.menu_item("new", "New"),
        @c.menu_item("open", "Open"),
        @c.menu_item("save", "Save"),
        @c.menu_separator(),
        @c.menu_item("exit", "Exit"),
      ],
    },
    @c.MenubarItem::{
      id: "edit",
      label: "Edit",
      items: [
        @c.menu_item("cut", "Cut"),
        @c.menu_item("copy", "Copy"),
        @c.menu_item("paste", "Paste"),
      ],
    },
    @c.MenubarItem::{
      id: "view",
      label: "View",
      items: [
        @c.menu_checkbox("toolbar", "Toolbar", true),
        @c.menu_checkbox("statusbar", "Status Bar", false),
        @c.menu_separator(),
        @c.menu_radio("normal", "Normal", true),
        @c.menu_radio("compact", "Compact", false),
      ],
    },
  ]
  let state : @c.MenubarState = {
    open_menu_id: open_menu.get(),
    focused_item_id: menubar_focused_item.get(),
    open_submenu_path: [],
  }
  @c.column(
    [
      @c.text(
        "Menubar Demo (1/2/3 to open, ←/→ to switch menus, ↑/↓ to select items, Space to close)",
        fg=@core.Color::cyan(),
      ),
      @c.vspace(1.0),
      @c.menubar(items, state),
      @c.vspace(1.0),
      @c.text(
        "Open: " +
        (if open_menu.get().length() > 0 { open_menu.get() } else { "none" }) +
        " | Focused: " +
        (if menubar_focused_item.get().length() > 0 {
          menubar_focused_item.get()
        } else {
          "none"
        }),
        fg=@core.Color::green(),
      ),
    ],
    gap=0.5,
  )
}
