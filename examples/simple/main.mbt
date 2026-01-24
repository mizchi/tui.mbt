///|
/// Simple TUI Starter Template
/// Run with: moon run examples/simple --target js

///|
fn main {
  // Get terminal size
  let (width, height) = @io.get_terminal_size()

  // Create reactive state
  let count = @signals.signal(0)
  let running = @signals.signal(true)

  // Create the app renderer
  let app = @render.App::new(width, height)

  // Build the UI component tree
  fn render_ui() -> @core.Component {
    @c.column(
      [
        // Header
        @c.title_bar("Simple TUI App"),
        // Main content
        @c.column(
          flex_grow=1.0,
          justify=@c.align_center(),
          align=@c.align_center(),
          [
            @c.text("Press +/- to change count, q to quit"),
            @c.row(
              [
                @c.text("Count: "),
                @c.text(
                  count.get().to_string(),
                  fg=if count.get() >= 0 {
                    @core.Color::green()
                  } else {
                    @core.Color::red()
                  },
                  bold=true,
                ),
              ],
              justify=@c.align_center(),
            ),
          ],
        ),
        // Footer
        @c.footer([@c.text("q: quit | +/-: change count")]),
      ],
      width=@c.dim_length(width.to_double()),
      height=@c.dim_length(height.to_double()),
      border=Some(@core.BorderChars::rounded()),
      border_color=@core.Color::cyan(),
    )
  }

  // Render helper
  fn do_render() {
    @io.print_raw(app.render_frame(render_ui()))
  }

  // Cleanup and quit
  fn do_quit() {
    running.set(false)
    @io.stop_keypress_listener()
    @io.cleanup_stdin()
    @io.print_raw(@render.App::restore_terminal())
    println("Goodbye!")
  }

  // Handle keyboard input
  fn handle_key(key : String) {
    if key.length() == 0 || not(running.get()) {
      return
    }
    let event = @events.parse_input(key)

    // Quit on q, Ctrl+C, or Escape
    if event.is_quit() {
      do_quit()
      return
    }

    // Handle +/- keys
    if event.is_char('+') || event.is_char('=') {
      count.set(count.get() + 1)
    } else if event.is_char('-') {
      count.set(count.get() - 1)
    }
    do_render()
  }

  // Initialize terminal (alt screen + hide cursor)
  @io.print_raw(@render.App::init_terminal())

  // Initial render
  do_render()

  // Start event loop
  @io.start_keypress_listener(handle_key)
}
