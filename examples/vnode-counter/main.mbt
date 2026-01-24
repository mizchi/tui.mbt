///|
/// VNode Counter example - demonstrates vnode-based TUI with reactive state

///|
/// Button component
fn vnode_button(
  label : String,
  id : String,
  min_width : Double,
) -> @vnode.TuiNode {
  @vnode.row(
    [@vnode.text(label)],
    id~,
    border="rounded",
    padding_x=1.0,
    min_width~,
    justify="center",
    align="center",
    border_color="cyan",
  )
}

///|
/// Render the counter UI
fn render_counter_ui(width : Int, height : Int, count : Int) -> @vnode.TuiNode {
  @vnode.column(
    [
      // Title
      @vnode.row(
        [@vnode.text("Counter Demo", fg="yellow", bold=true)],
        justify="center",
        margin_y=1.0,
      ),
      // Count display
      @vnode.column(
        [
          @vnode.text("Count:"),
          @vnode.spacer(),
          @vnode.text(
            count.to_string(),
            fg=if count >= 0 { "green" } else { "red" },
            bold=true,
          ),
        ],
        flex_grow=1.0,
        justify="center",
        align="center",
      ),
      // Buttons row - inner row with align center from parent
      @vnode.row(
        [
          @vnode.row([
            vnode_button(" - ", "btn-dec", 7.0),
            @vnode.hspace(2.0),
            vnode_button("Reset", "btn-reset", 9.0),
            @vnode.hspace(2.0),
            vnode_button(" + ", "btn-inc", 7.0),
          ]),
        ],
        justify="center",
      ),
      // Instructions
      @vnode.row(
        [
          @vnode.text(
            "Click buttons or: q=quit | +/-=count | r=reset",
            fg="rgb(128,128,128)",
          ),
        ],
        justify="center",
        margin_y=1.0,
      ),
    ],
    width=width.to_double(),
    height=height.to_double(),
    padding=1.0,
    border="rounded",
    border_color="cyan",
  )
}

///|
async fn main {
  // Get terminal size
  let (cols, rows) = @tui.get_terminal_size()
  let width = cols
  let height = rows

  // Create reactive state
  let count = @signals.signal(0)

  // Create the vnode app
  let app = @vnode.VNodeApp::new(width, height)

  // Render function
  fn render_ui() -> @vnode.TuiNode {
    render_counter_ui(width, height, count.get())
  }

  // Initialize terminal
  @tui.print_raw(@vnode.VNodeApp::init_terminal())
  @tui.enable_raw_mode()
  @tui.print_raw(@tui.enable_mouse())

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
          @tui.KeyEvent::Char('k', @tui.KeyModifier::None) =>
            count.set(count.get() + 1)
          @tui.KeyEvent::Special(@tui.SpecialKey::Up, _) =>
            count.set(count.get() + 1)
          // Decrement
          @tui.KeyEvent::Char('-', _) => count.set(count.get() - 1)
          @tui.KeyEvent::Char('_', _) => count.set(count.get() - 1)
          @tui.KeyEvent::Char('j', @tui.KeyModifier::None) =>
            count.set(count.get() - 1)
          @tui.KeyEvent::Special(@tui.SpecialKey::Down, _) =>
            count.set(count.get() - 1)
          // Reset
          @tui.KeyEvent::Char('r', @tui.KeyModifier::None) => count.set(0)
          _ => need_render = false
        }
      @tui.InputEvent::Mouse(mouse_event) =>
        match (mouse_event.event_type, mouse_event.button) {
          (@tui.MouseEventType::Press, @tui.MouseButton::Left) => {
            let x = mouse_event.x
            let y = mouse_event.y
            // Check if click is within each button's bounds
            let mut clicked = false
            // Check btn-dec
            match app.find_by_id("btn-dec") {
              Some(btn) =>
                if x >= btn.x &&
                  x < btn.x + btn.width &&
                  y >= btn.y &&
                  y < btn.y + btn.height {
                  count.set(count.get() - 1)
                  clicked = true
                }
              None => ()
            }
            // Check btn-inc
            if not(clicked) {
              match app.find_by_id("btn-inc") {
                Some(btn) =>
                  if x >= btn.x &&
                    x < btn.x + btn.width &&
                    y >= btn.y &&
                    y < btn.y + btn.height {
                    count.set(count.get() + 1)
                    clicked = true
                  }
                None => ()
              }
            }
            // Check btn-reset
            if not(clicked) {
              match app.find_by_id("btn-reset") {
                Some(btn) =>
                  if x >= btn.x &&
                    x < btn.x + btn.width &&
                    y >= btn.y &&
                    y < btn.y + btn.height {
                    count.set(0)
                    clicked = true
                  }
                None => ()
              }
            }
            if not(clicked) {
              need_render = false
            }
          }
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
  @tui.print_raw(@tui.disable_mouse())
  @tui.cleanup_stdin()
  @tui.print_raw(@vnode.VNodeApp::restore_terminal())
  println("Goodbye! Final count: " + count.get().to_string())
}
