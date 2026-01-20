///|
/// Button example - demonstrates interactive buttons with mouse support

///|
fn main {
  let (cols, rows) = @io.get_terminal_size()
  let width = cols
  let height = rows

  // Create reactive state
  let count = @signals.signal(0)
  let message = @signals.signal("Click a button!")
  let running = @signals.signal(true)

  // Create the app
  let app = @render.App::new(width, height)

  // Render function
  fn render_ui() -> @core.Component {
    let current_count = count.get()
    let current_message = message.get()
    @c.column(
      [
        // Title
        @c.row(
          [@c.text("Button Demo", fg=@core.Color::yellow(), bold=true)],
          justify=@types.Alignment::Center,
          margin_y=1.0,
        ),
        // Message display
        @c.row(
          [@c.text(current_message, fg=@core.Color::cyan())],
          justify=@types.Alignment::Center,
        ),
        // Count display
        @c.row(
          [
            @c.text("Count: "),
            @c.text(
              current_count.to_string(),
              fg=if current_count >= 0 {
                @core.Color::green()
              } else {
                @core.Color::red()
              },
              bold=true,
            ),
          ],
          justify=@types.Alignment::Center,
          margin_y=1.0,
        ),
        // Buttons row
        @c.row(
          [
            @c.button("[ - ]", bg=@core.Color::rgb(80, 40, 40), id="btn-minus"),
            @c.hspace(2.0),
            @c.button(
              "[ Reset ]",
              bg=@core.Color::rgb(60, 60, 60),
              id="btn-reset",
            ),
            @c.hspace(2.0),
            @c.button("[ + ]", bg=@core.Color::rgb(40, 80, 40), id="btn-plus"),
          ],
          justify=@types.Alignment::Center,
        ),
        // Spacer
        @c.spacer(),
        // Instructions
        @c.row(
          [
            @c.text(
              "Click buttons or use: +/- keys | r: reset | q: quit",
              fg=@core.Color::rgb(100, 100, 100),
            ),
          ],
          justify=@types.Alignment::Center,
          margin_y=1.0,
        ),
      ],
      width=@types.Dimension::Length(width.to_double()),
      height=@types.Dimension::Length(height.to_double()),
      padding=1.0,
      border=Some(@core.BorderChars::rounded()),
      border_color=@core.Color::cyan(),
    )
  }

  // Render helper
  fn do_render() -> Unit {
    @io.print_raw(app.render_frame(render_ui()))
  }

  // Quit helper
  fn do_quit() -> Unit {
    running.set(false)
    @io.stop_keypress_listener()
    @io.print_raw(@render.disable_mouse())
    @io.cleanup_stdin()
    @io.print_raw(@render.App::restore_terminal())
    println("Goodbye! Final count: " + count.get().to_string())
  }

  // Handle key event
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
          @events.KeyEvent::Char('+', _) | @events.KeyEvent::Char('=', _) => {
            count.set(count.get() + 1)
            message.set("Incremented!")
          }
          @events.KeyEvent::Char('-', _) => {
            count.set(count.get() - 1)
            message.set("Decremented!")
          }
          @events.KeyEvent::Char('r', @events.KeyModifier::None) => {
            count.set(0)
            message.set("Reset!")
          }
          _ => need_render = false
        }
      @events.InputEvent::Mouse(mouse_event) =>
        match (mouse_event.event_type, mouse_event.button) {
          (@events.MouseEventType::Press, @events.MouseButton::Left) =>
            // Perform hit test
            match app.hit_test(mouse_event.x, mouse_event.y) {
              Some(hit) =>
                // Handle button clicks
                if hit.id == "btn-plus" {
                  count.set(count.get() + 1)
                  message.set("Incremented!")
                } else if hit.id == "btn-minus" {
                  count.set(count.get() - 1)
                  message.set("Decremented!")
                } else if hit.id == "btn-reset" {
                  count.set(0)
                  message.set("Reset!")
                } else {
                  message.set("Clicked: " + hit.id)
                }
              None =>
                message.set(
                  "Clicked at (" +
                  mouse_event.x.to_string() +
                  "," +
                  mouse_event.y.to_string() +
                  ")",
                )
            }
          _ => need_render = false
        }
      _ => need_render = false
    }
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
