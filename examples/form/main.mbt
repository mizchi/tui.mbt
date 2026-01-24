///|
/// Form example - demonstrates input components with IME support
/// Focus = Navigate, Enter = Edit (cooked mode with IME)

///|
fn main {
  // Get terminal size
  let (cols, rows) = @io.get_terminal_size()
  let width = cols
  let height = rows

  // Create reactive state
  let name = @signals.signal("")
  let email = @signals.signal("")
  let message = @signals.signal("")
  let running = @signals.signal(true)

  // Focus navigation with FocusNav utility
  let input_ids = ["name-input", "email-input", "message-textarea"]
  let focus = @c.FocusNav::new([
    "name-input", "email-input", "message-textarea", "submit-btn",
  ])

  // Create the app
  let app = @render.App::new(width, height)

  // Field configurations for editing
  let field_configs : Map[String, (String, @signals.Signal[String])] = {
    "name-input": ("Name", name),
    "email-input": ("Email", email),
    "message-textarea": ("Message", message),
  }

  // Render function
  fn render_ui() -> @core.Component {
    @c.column(
      [
        // Title
        @c.title_bar("Form Demo"),
        // Form fields
        @c.column(
          [
            // Name field
            @c.row(
              [
                @c.text("Name:    "),
                @c.input(
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
            @c.row(
              [
                @c.text("Email:   "),
                @c.input(
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
            @c.row(
              [
                @c.text("Message: "),
                @c.textarea(
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
            @c.row(
              [
                @c.hspace(9.0),
                @c.button(
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
        @c.footer([
          @c.text(
            "Tab: next | Enter: edit/confirm | Shift+Enter/Ctrl+D: newline | Esc: cancel",
          ),
        ]),
      ],
      width=@c.dim_length(width.to_double()),
      height=@c.dim_length(height.to_double()),
      padding=1.0,
      border=Some(@core.BorderChars::rounded()),
      border_color=@core.Color::cyan(),
    )
  }

  // Render helper
  fn do_render() -> Unit {
    @io.print_raw(app.render_frame(render_ui()))
  }

  // Handle quit
  fn do_quit() -> Unit {
    running.set(false)
    @io.stop_keypress_listener()
    @io.print_raw(@render.disable_mouse())
    @io.cleanup_stdin()
    @io.print_raw(@render.App::restore_terminal())
    println("Cancelled.")
  }

  // Handle submit
  fn do_submit() -> Unit {
    running.set(false)
    @io.stop_keypress_listener()
    @io.print_raw(@render.disable_mouse())
    @io.cleanup_stdin()
    @io.print_raw(@render.App::restore_terminal())
    println("Form submitted!")
    println("Name: " + name.get())
    println("Email: " + email.get())
    println("Message: " + message.get())
  }

  // Mutually recursive functions: restore_tui <-> start_editing <-> handle_key
  letrec restore_tui: () -> Unit = fn() {
    @io.print_raw(@render.ansi_full_reset())
    @io.print_raw(@render.enable_mouse())
    app.clear_prev_buffer()
    do_render()
    @io.start_keypress_listener(handle_key)
  }
  and start_editing: (String) -> Unit = fn(id) {
    match field_configs.get(id) {
      Some((field_name, signal)) =>
        // Get the element bounds for inplace editing
        match app.find_by_id(id) {
          Some(bounds) => {
            let config = @c.form_edit_config(
              field_name,
              signal,
              on_edit_start=Some(fn() {
                @io.stop_keypress_listener()
                @io.print_raw(@render.disable_mouse())
              }),
              on_force_quit=Some(fn() { do_quit() }),
            )
            // Determine if this is a multiline textarea
            let multiline = id == "message-textarea"
            @c.start_edit_inplace_in_bounds(
              config,
              signal.get(),
              bounds,
              multiline,
              restore_tui,
            )
          }
          None => {
            // Fallback to cooked mode if bounds not found
            let config = @c.form_edit_config(
              field_name,
              signal,
              on_edit_start=Some(fn() {
                @io.stop_keypress_listener()
                @io.print_raw(@render.disable_mouse())
              }),
              on_force_quit=Some(fn() { do_quit() }),
            )
            @c.start_edit(config, signal.get(), restore_tui)
          }
        }
      None => ()
    }
  }
  and handle_key: (String) -> Unit = fn(key) {
    if key.length() == 0 {
      return
    }
    let event = @events.parse_input(key)
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
        @events.InputEvent::Mouse(mouse_event) =>
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
  @io.print_raw(@render.App::init_terminal())
  @io.print_raw(@render.enable_mouse())

  // Initial render
  do_render()

  // Start event-driven keypress listener
  @io.start_keypress_listener(handle_key)
}
