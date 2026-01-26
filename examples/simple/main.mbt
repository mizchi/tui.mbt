///|
/// Simple VNode TUI Starter Template
/// Run with: moon run examples/vnode-simple

///|
using @vnode {type TuiNode, type VNodeApp, view, row, text}

///|
/// Render the simple counter UI
fn render_simple_ui(width : Int, height : Int, count : Int) -> TuiNode {
  view(
    width=width.to_double(),
    height=height.to_double(),
    border="rounded",
    border_color="cyan",
    [
      // Header - matches @tui.title_bar (margin_y=1.0, fg=yellow, bold)
      row(justify="center", margin_y=1.0, [
        text("Simple TUI App", fg="yellow", bold=true),
      ]),
      // Main content area - centered both ways
      view(flex_grow=1.0, justify="center", align="center", [
        text("Press +/- to change count, q to quit"),
        row(justify="center", [
          text("Count: "),
          text(
            count.to_string(),
            fg=if count >= 0 { "green" } else { "red" },
            bold=true,
          ),
        ]),
      ]),
      // Footer - matches @tui.footer (justify=center, fg=gray)
      row(justify="center", [
        text("q: quit | +/-: change count", fg="rgb(128,128,128)"),
      ]),
    ],
  )
}

///|
async fn main {
  // Get terminal size
  let (width, height) = @tui.get_terminal_size()

  // Create reactive state
  let count = @signals.signal(0)

  // Create the vnode app
  let app = VNodeApp::new(width, height)

  // Render function wrapper
  fn render_ui() -> TuiNode {
    render_simple_ui(width, height, count.get())
  }

  // Initialize terminal
  @tui.print_raw(VNodeApp::init_terminal())
  @tui.enable_raw_mode()

  // Initial render
  @tui.print_raw(app.render_frame(render_ui()))

  // Event loop
  let mut running = true
  while running {
    let key = @tui.read_key()
    if key.length() == 0 {
      continue
    }
    let event = @tui.parse_input(key)
    let mut need_render = true
    match event {
      @tui.InputEvent::Key(key_event) =>
        match key_event {
          // Quit on 'q' or Ctrl+C or Escape
          @tui.KeyEvent::Char('q', @tui.KeyModifier::None) => running = false
          @tui.KeyEvent::Char('c', @tui.KeyModifier::Ctrl) => running = false
          @tui.KeyEvent::Special(@tui.SpecialKey::Escape, _) => running = false
          // Increment
          @tui.KeyEvent::Char('+', _) => count.set(count.get() + 1)
          @tui.KeyEvent::Char('=', _) => count.set(count.get() + 1)
          // Decrement
          @tui.KeyEvent::Char('-', _) => count.set(count.get() - 1)
          @tui.KeyEvent::Char('_', _) => count.set(count.get() - 1)
          _ => need_render = false
        }
      _ => need_render = false
    }
    // Re-render only when state changed
    if need_render && running {
      @tui.print_raw(app.render_frame(render_ui()))
    }
  }

  // Restore terminal
  @tui.cleanup_stdin()
  @tui.print_raw(VNodeApp::restore_terminal())
  println("Goodbye!")
}
