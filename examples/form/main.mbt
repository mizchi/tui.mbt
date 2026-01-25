///|
/// VNode Form - demonstrates input components with cooked mode editing

///|
using @vnode {
  type TuiNode,
  type InputState,
  type VNodeApp,
  view,
  row,
  grid,
  text,
  input,
  textarea,
  vspace,
  form_edit_config,
  start_edit_inplace_in_bounds,
  start_edit,
}

///|
fn main {
  let (width, height) = @tui.get_terminal_size()

  // Form state
  let name = @signals.signal("")
  let email = @signals.signal("")
  let message = @signals.signal("")
  let focus_index = @signals.signal(0)
  let editing = @signals.signal(false)
  let running = @signals.signal(true)

  // Field configurations
  let field_ids = ["name", "email", "message"]
  let field_configs : Map[String, (String, @signals.Signal[String], Bool)] = {
    "name": ("Name", name, false),
    "email": ("Email", email, false),
    "message": ("Message", message, true), // multiline
  }

  // Create the vnode app
  let app = VNodeApp::new(width, height)

  // Get input state based on focus and editing
  fn get_input_state(index : Int) -> InputState {
    if editing.get() && focus_index.get() == index {
      InputState::Editing
    } else if focus_index.get() == index {
      InputState::Focused
    } else {
      InputState::Idle
    }
  }

  // Render function
  fn render_ui() -> TuiNode {
    let focus = focus_index.get()
    view(
      [
        // Header
        row(
          [text("VNode Form Demo", fg="yellow", bold=true)],
          justify="center",
          padding_y=0.5,
        ),
        // Form content - use grid for label/input alignment
        view(
          [
            grid(
              [
                // Row 1: Name
                text("Name:", fg="cyan"),
                input(
                  name.get(),
                  id="name",
                  placeholder="Enter your name",
                  state=get_input_state(0),
                ),
                // Row 2: Email
                text("Email:", fg="cyan"),
                input(
                  email.get(),
                  id="email",
                  placeholder="user@example.com",
                  state=get_input_state(1),
                ),
              ],
              columns=[10.0, 40.0],
              gap=1.0,
            ),
            vspace(1.0),
            // Message field (full width, separate from grid)
            text("Message:", fg="cyan"),
            textarea(
              message.get(),
              id="message",
              placeholder="Enter your message...",
              state=get_input_state(2),
              rows=3,
              min_width=50.0,
            ),
            vspace(1.0),
            // Submit button
            row([
              {
                let is_focused = focus == 3
                let bg = if is_focused { "cyan" } else { "rgb(60,60,70)" }
                let fg = if is_focused { "black" } else { "white" }
                row(
                  [text("  Submit  ", fg~, bold=is_focused)],
                  id="submit",
                  bg~,
                  padding_x=1.0,
                  padding_y=0.5,
                )
              },
            ]),
          ],
          padding=2.0,
          border="rounded",
          border_color="rgb(80,80,100)",
          flex_grow=1.0,
        ),
        // Footer
        row(
          [
            text(
              "Tab/↑↓: navigate | Enter: edit | Esc: cancel | q: quit",
              fg="rgb(100,100,100)",
            ),
          ],
          justify="center",
          padding_y=0.5,
        ),
      ],
      width=width.to_double(),
      height=height.to_double(),
    )
  }

  // Render helper
  fn do_render() -> Unit {
    @tui.print_raw(app.render_frame(render_ui()))
  }

  // Handle quit
  fn do_quit() -> Unit {
    running.set(false)
    @io.stop_keypress_listener()
    @tui.print_raw(VNodeApp::restore_terminal())
    println("Cancelled.")
  }

  // Handle submit
  fn do_submit() -> Unit {
    running.set(false)
    @io.stop_keypress_listener()
    @tui.print_raw(VNodeApp::restore_terminal())
    println("Form submitted!")
    println("Name: " + name.get())
    println("Email: " + email.get())
    println("Message: " + message.get())
  }

  // Mutually recursive functions for editing
  letrec restore_tui: () -> Unit = fn() {
    @tui.print_raw(@render.ansi_full_reset())
    app.clear_prev_buffer()
    editing.set(false)
    do_render()
    @io.start_keypress_listener(handle_key)
  }
  and start_editing: (String) -> Unit = fn(id) {
    match field_configs.get(id) {
      Some((field_name, signal, multiline)) =>
        match app.find_by_id(id) {
          Some(bounds) => {
            let config = form_edit_config(
              field_name,
              signal,
              on_edit_start=Some(fn() {
                @io.stop_keypress_listener()
                editing.set(true)
              }),
              on_force_quit=Some(fn() { do_quit() }),
            )
            start_edit_inplace_in_bounds(
              config,
              signal.get(),
              bounds,
              multiline,
              restore_tui,
            )
          }
          None => {
            // Fallback to simple edit if bounds not found
            let config = form_edit_config(
              field_name,
              signal,
              on_edit_start=Some(fn() {
                @io.stop_keypress_listener()
                editing.set(true)
              }),
              on_force_quit=Some(fn() { do_quit() }),
            )
            start_edit(config, signal.get(), restore_tui)
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
    let focus = focus_index.get()
    let field_count = 4 // name, email, message, submit
    match event {
      @tui.InputEvent::Key(key_event) =>
        match key_event {
          // Quit
          @tui.KeyEvent::Char('c', @tui.KeyModifier::Ctrl) => {
            do_quit()
            return
          }
          @tui.KeyEvent::Char('q', @tui.KeyModifier::None) => {
            do_quit()
            return
          }
          // Navigation
          @tui.KeyEvent::Char('\t', _)
          | @tui.KeyEvent::Special(@tui.SpecialKey::Down, _) =>
            focus_index.set((focus + 1) % field_count)
          @tui.KeyEvent::Special(@tui.SpecialKey::Up, _) =>
            focus_index.set(if focus > 0 { focus - 1 } else { field_count - 1 })
          // Enter - edit or submit
          @tui.KeyEvent::Special(@tui.SpecialKey::Enter, _) =>
            if focus == 3 {
              do_submit()
              return
            } else if focus < field_ids.length() {
              start_edit_id = field_ids[focus]
              need_render = false
            }
          _ => need_render = false
        }
      _ => need_render = false
    }

    // Start editing if requested
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
  @tui.print_raw(VNodeApp::init_terminal())
  @tui.enable_raw_mode()

  // Initial render
  do_render()

  // Start event-driven keypress listener
  @io.start_keypress_listener(handle_key)
}
