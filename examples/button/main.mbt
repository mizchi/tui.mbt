///|
/// Button example - demonstrates interactive buttons with on_click handlers

///|
fn main {
  let (width, height) = @tui.get_terminal_size()

  // Create reactive state
  let count = @signals.signal(0)
  let message = @signals.signal("Click a button!")

  // Run the app - on_click handlers are auto-dispatched by run()
  @tui.run(
    fn() {
      let current_count = count.get()
      let current_message = message.get()
      @tui.column(
        [
          // Title
          @tui.title_bar("Button Demo"),
          // Message display
          @tui.row(
            [@tui.text(current_message, fg=@tui.Color::cyan())],
            justify=@tui.align_center(),
          ),
          // Count display
          @tui.row(
            [
              @tui.text("Count: "),
              @tui.text(
                current_count.to_string(),
                fg=if current_count >= 0 {
                  @tui.Color::green()
                } else {
                  @tui.Color::red()
                },
                bold=true,
              ),
            ],
            justify=@tui.align_center(),
            margin_y=1.0,
          ),
          // Buttons row with on_click handlers
          @tui.row(
            [
              @tui.button(
                "[ - ]",
                id="btn-minus",
                on_click=Some(fn() {
                  count.set(count.get() - 1)
                  message.set("Decremented!")
                }),
              ),
              @tui.hspace(2.0),
              @tui.button(
                "[ Reset ]",
                id="btn-reset",
                on_click=Some(fn() {
                  count.set(0)
                  message.set("Reset!")
                }),
              ),
              @tui.hspace(2.0),
              @tui.button(
                "[ + ]",
                id="btn-plus",
                on_click=Some(fn() {
                  count.set(count.get() + 1)
                  message.set("Incremented!")
                }),
              ),
            ],
            justify=@tui.align_center(),
          ),
          // Spacer
          @tui.spacer(),
          // Instructions
          @tui.footer([
            @tui.text("Click buttons or use: +/- keys | r: reset | q: quit"),
          ]),
        ],
        width=width.to_double(),
        height=height.to_double(),
        padding=1.0,
        border=Some(@tui.BorderChars::rounded()),
        border_color=@tui.Color::cyan(),
      )
    },
    fn(event) {
      // Quit on q, Ctrl+C, or Escape
      if event.is_quit() {
        return false
      }
      // Handle keyboard shortcuts
      if event.is_char('+') || event.is_char('=') {
        count.set(count.get() + 1)
        message.set("Incremented!")
      } else if event.is_char('-') {
        count.set(count.get() - 1)
        message.set("Decremented!")
      } else if event.is_char('r') {
        count.set(0)
        message.set("Reset!")
      }
      true
    },
  )
  println("Goodbye! Final count: " + count.get().to_string())
}
