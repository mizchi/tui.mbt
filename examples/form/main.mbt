///|
/// Form example - demonstrates input components with IME support
/// Focus = Navigate, Enter = Edit (cooked mode with IME)

///|
fn main {
  // Get terminal size
  let (cols, rows) = @tui.get_terminal_size()
  let width = cols
  let height = rows

  // Create reactive state
  let name = @signals.signal("")
  let email = @signals.signal("")
  let message = @signals.signal("")
  let running = @signals.signal(true)

  // Focus navigation with FocusNav utility
  let input_ids = ["name-input", "email-input", "message-textarea"]
  let focus = @tui.FocusNav::new([
    "name-input", "email-input", "message-textarea", "submit-btn",
  ])

  // Create the app
  let app = @tui.App::new(width, height)

  // Field configurations for editing
  let field_configs : Map[String, (String, @signals.Signal[String])] = {
    "name-input": ("Name", name),
    "email-input": ("Email", email),
    "message-textarea": ("Message", message),
  }

  // Render function
  fn render_ui() -> @tui.Component {
    @tui.column(
      [
        // Title
        @tui.title_bar("Form Demo"),
        // Form fields
        @tui.column(
          [
            // Name field
            @tui.row(
              [
                @tui.text("Name:    "),
                @tui.input(
                  name.get(),
                  id="name-input",
                  placeholder="Enter your name",
                  state=focus.input_state("name-input"),
                  min_width=40.0,
                  min_height=3.0,
                ),
              ],
              margin_y=0.5,
            ),
            // Email field
            @tui.row(
              [
                @tui.text("Email:   "),
                @tui.input(
                  email.get(),
                  id="email-input",
                  placeholder="user@example.com",
                  state=focus.input_state("email-input"),
                  min_width=40.0,
                  min_height=3.0,
                ),
              ],
              margin_y=0.5,
            ),
            // Message field (textarea)
            @tui.row(
              [
                @tui.text("Message: "),
                @tui.textarea(
                  message.get(),
                  id="message-textarea",
                  placeholder="Enter your message...",
                  state=focus.textarea_state("message-textarea"),
                  rows=4,
                  min_width=40.0,
                ),
              ],
              margin_y=0.5,
            ),
            // Submit button
            @tui.row(
              [
                @tui.hspace(9.0),
                @tui.button(
                  "Submit",
                  id="submit-btn",
                  state=focus.button_state("submit-btn"),
                  min_width=12.0,
                ),
              ],
              margin_y=1.0,
            ),
          ],
          padding=2.0,
        ),
        // Status bar
        @tui.footer([
          @tui.text(
            "Tab: next | Enter: edit/confirm | Shift+Enter/Ctrl+D: newline | Esc: cancel",
          ),
        ]),
      ],
      width=width.to_double(),
      height=height.to_double(),
      padding=1.0,
      border=Some(@tui.BorderChars::rounded()),
      border_color=@tui.Color::cyan(),
    )
  }

  // Render helper
  fn do_render() -> Unit {
    @tui.print_raw(app.render_frame(render_ui()))
  }

  // Handle quit
  fn do_quit() -> Unit {
    running.set(false)
    @tui.stop_keypress_listener()
    @tui.print_raw(@tui.disable_mouse())
    @tui.cleanup_stdin()
    @tui.print_raw(@tui.App::restore_terminal())
    println("Cancelled.")
  }

  // Handle submit
  fn do_submit() -> Unit {
    running.set(false)
    @tui.stop_keypress_listener()
    @tui.print_raw(@tui.disable_mouse())
    @tui.cleanup_stdin()
    @tui.print_raw(@tui.App::restore_terminal())
    println("Form submitted!")
    println("Name: " + name.get())
    println("Email: " + email.get())
    println("Message: " + message.get())
  }

  // Mutually recursive functions: restore_tui <-> start_editing <-> handle_key
  letrec restore_tui: () -> Unit = fn() {
    @tui.print_raw(@tui.ansi_full_reset())
    @tui.print_raw(@tui.enable_mouse())
    app.clear_prev_buffer()
    do_render()
    @tui.start_keypress_listener(handle_key)
  }
  and start_editing: (String) -> Unit = fn(id) {
    match field_configs.get(id) {
      Some((field_name, signal)) =>
        // Get the element bounds for inplace editing
        match app.find_by_id(id) {
          Some(bounds) => {
            let config = @tui.form_edit_config(
              field_name,
              signal,
              on_edit_start=Some(fn() {
                @tui.stop_keypress_listener()
                @tui.print_raw(@tui.disable_mouse())
              }),
              on_force_quit=Some(fn() { do_quit() }),
            )
            // Determine if this is a multiline textarea
            let multiline = id == "message-textarea"
            @tui.start_edit_inplace_in_bounds(
              config,
              signal.get(),
              bounds,
              multiline,
              restore_tui,
            )
          }
          None => {
            // Fallback to cooked mode if bounds not found
            let config = @tui.form_edit_config(
              field_name,
              signal,
              on_edit_start=Some(fn() {
                @tui.stop_keypress_listener()
                @tui.print_raw(@tui.disable_mouse())
              }),
              on_force_quit=Some(fn() { do_quit() }),
            )
            @tui.start_edit(config, signal.get(), restore_tui)
          }
        }
      None => ()
    }
  }
  and handle_key: (String) -> Unit = fn(key) {
    if key.length() == 0 {
      return
    }
    let event = @tui.parse_input(key)
    let mut need_render = true
    let mut start_edit_id = ""

    // Handle Ctrl+C - always quit
    if event.is_ctrl_c() {
      do_quit()
      return
    }

    // Handle q to quit when not focused on input
    if event.is_char('q') && not(focus.focused_in(input_ids)) {
      do_quit()
      return
    }

    // Handle Tab navigation using FocusNav
    if focus.handle_tab(event) {
      // Tab was handled
    } else if focus.handle_arrows(event) {
      // Arrow was handled
    } else if event.is_escape() {
      // Escape - unfocus
      focus.blur()
    } else if event.is_enter() {
      // Enter - edit if on input, submit if on button
      let current_focus = focus.get()
      if current_focus == "submit-btn" {
        do_submit()
        return
      } else if input_ids.contains(current_focus) {
        start_edit_id = current_focus
        need_render = false
      } else {
        focus.next()
      }
    } else {
      // Handle mouse clicks
      match event {
        @tui.InputEvent::Mouse(mouse_event) =>
          match app.dispatch_click_with_result(mouse_event) {
            Some(hit) => if focus.ids.contains(hit.id) { focus.set(hit.id) }
            None => ()
          }
        _ => need_render = false
      }
    }

    // Handle editing
    if start_edit_id != "" {
      start_editing(start_edit_id)
      return
    }

    // Re-render if needed
    if need_render && running.get() {
      do_render()
    }
  }

  // Initialize terminal
  @tui.print_raw(@tui.App::init_terminal())
  @tui.print_raw(@tui.enable_mouse())

  // Initial render
  do_render()

  // Start event-driven keypress listener
  @tui.start_keypress_listener(handle_key)
}
