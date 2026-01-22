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

  // Click handlers map
  let click_handlers : Map[String, () -> Unit] = {
    "btn-plus": fn() {
      count.set(count.get() + 1)
      message.set("Incremented!")
    },
    "btn-minus": fn() {
      count.set(count.get() - 1)
      message.set("Decremented!")
    },
    "btn-reset": fn() {
      count.set(0)
      message.set("Reset!")
    },
  }

  // Render function
  fn render_ui() -> @core.Component {
    let current_count = count.get()
    let current_message = message.get()
    @c.column(
      [
        // Title
        @c.title_bar("Button Demo"),
        // Message display
        @c.row(
          [@c.text(current_message, fg=@core.Color::cyan())],
          justify=@c.align_center(),
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
          justify=@c.align_center(),
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
          justify=@c.align_center(),
        ),
        // Spacer
        @c.spacer(),
        // Instructions
        @c.footer([
          @c.text("Click buttons or use: +/- keys | r: reset | q: quit"),
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

    // Handle quit keys
    if @events.is_quit(event) {
      do_quit()
      return
    }

    // Handle keyboard shortcuts
    if @events.is_char(event, '+') || @events.is_char(event, '=') {
      count.set(count.get() + 1)
      message.set("Incremented!")
    } else if @events.is_char(event, '-') {
      count.set(count.get() - 1)
      message.set("Decremented!")
    } else if @events.is_char(event, 'r') {
      count.set(0)
      message.set("Reset!")
    } else {
      // Handle mouse clicks with dispatch
      match event {
        @events.InputEvent::Mouse(mouse_event) =>
          match app.dispatch_click(mouse_event, click_handlers) {
            Some(_) => ()
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
