///|
/// Simple TUI Starter Template
/// Run with: moon run examples/simple --target js

///|
fn main {
  // Get terminal size
  let (width, height) = @tui.get_terminal_size()

  // Create reactive state
  let count = @signals.signal(0)

  // Run the app with simplified lifecycle
  @tui.run(
    fn() {
      @tui.column(
        [
          // Header
          @tui.title_bar("Simple TUI App"),
          // Main content
          @tui.column(
            flex_grow=1.0,
            justify=@tui.align_center(),
            align=@tui.align_center(),
            [
              @tui.text("Press +/- to change count, q to quit"),
              @tui.row(
                [
                  @tui.text("Count: "),
                  @tui.text(
                    count.get().to_string(),
                    fg=if count.get() >= 0 {
                      @tui.Color::green()
                    } else {
                      @tui.Color::red()
                    },
                    bold=true,
                  ),
                ],
                justify=@tui.align_center(),
              ),
            ],
          ),
          // Footer
          @tui.footer([@tui.text("q: quit | +/-: change count")]),
        ],
        width=width.to_double(),
        height=height.to_double(),
        border=Some(@tui.BorderChars::rounded()),
        border_color=@tui.Color::cyan(),
      )
    },
    fn(event) {
      // Quit on q, Ctrl+C, or Escape
      if event.is_quit() {
        return false
      }
      // Handle +/- keys
      if event.is_char('+') || event.is_char('=') {
        count.set(count.get() + 1)
      } else if event.is_char('-') {
        count.set(count.get() - 1)
      }
      true
    },
  )
  println("Goodbye!")
}
