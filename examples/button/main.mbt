///|
/// VNode Button example - demonstrates interactive buttons with click handlers

///|
/// Button component
fn vnode_button(label : String, id : String) -> @vnode.TuiNode {
  @vnode.row(
    [@vnode.text(label)],
    id~,
    border="rounded",
    padding_x=1.0,
    height=3.0,
    justify="center",
    align="center",
    border_color="cyan",
  )
}

///|
/// Render the button demo UI
fn render_button_ui(
  width : Int,
  height : Int,
  count : Int,
  message : String,
) -> @vnode.TuiNode {
  @vnode.column(
    [
      // Title - matches @tui.title_bar
      @vnode.row(
        [@vnode.text("Button Demo", fg="yellow", bold=true)],
        justify="center",
        margin_y=1.0,
      ),
      // Message display
      @vnode.row([@vnode.text(message, fg="cyan")], justify="center"),
      // Main content area
      @vnode.column(
        [
          // Count display
          @vnode.row(
            [
              @vnode.text("Count: "),
              @vnode.text(
                count.to_string(),
                fg=if count >= 0 { "green" } else { "red" },
                bold=true,
              ),
            ],
            justify="center",
          ),
          @vnode.spacer(),
          // Buttons row
          @vnode.row(
            [
              vnode_button("[ - ]", "btn-minus"),
              @vnode.hspace(2.0),
              vnode_button("[ Reset ]", "btn-reset"),
              @vnode.hspace(2.0),
              vnode_button("[ + ]", "btn-plus"),
            ],
            justify="center",
          ),
        ],
        flex_grow=1.0,
        justify="center",
      ),
      // Footer - matches @tui.footer
      @vnode.row(
        [
          @vnode.text(
            "Click buttons or: +/- keys | r: reset | q: quit",
            fg="rgb(128,128,128)",
          ),
        ],
        justify="center",
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
  let (width, height) = @tui.get_terminal_size()

  // Create reactive state
  let count = @signals.signal(0)
  let message = @signals.signal("Click a button!")

  // Create the vnode app
  let app = @vnode.VNodeApp::new(width, height)

  // Render function
  fn render_ui() -> @vnode.TuiNode {
    render_button_ui(width, height, count.get(), message.get())
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
          // Quit
          @tui.KeyEvent::Char('q', @tui.KeyModifier::None) => running = false
          @tui.KeyEvent::Char('c', @tui.KeyModifier::Ctrl) => running = false
          @tui.KeyEvent::Special(@tui.SpecialKey::Escape, _) => running = false
          // Increment
          @tui.KeyEvent::Char('+', _) => {
            count.set(count.get() + 1)
            message.set("Incremented!")
          }
          @tui.KeyEvent::Char('=', _) => {
            count.set(count.get() + 1)
            message.set("Incremented!")
          }
          // Decrement
          @tui.KeyEvent::Char('-', _) => {
            count.set(count.get() - 1)
            message.set("Decremented!")
          }
          // Reset
          @tui.KeyEvent::Char('r', @tui.KeyModifier::None) => {
            count.set(0)
            message.set("Reset!")
          }
          _ => need_render = false
        }
      @tui.InputEvent::Mouse(mouse_event) =>
        match (mouse_event.event_type, mouse_event.button) {
          (@tui.MouseEventType::Press, @tui.MouseButton::Left) => {
            let x = mouse_event.x
            let y = mouse_event.y
            let mut clicked = false

            // Helper function to check if point is inside bounds
            fn is_inside(
              px : Int,
              py : Int,
              bx : Int,
              by : Int,
              bw : Int,
              bh : Int,
            ) -> Bool {
              px >= bx && px < bx + bw && py >= by && py < by + bh
            }

            // Try each button
            match app.find_by_id("btn-minus") {
              Some(btn) =>
                if is_inside(x, y, btn.x, btn.y, btn.width, btn.height) {
                  count.set(count.get() - 1)
                  message.set("Decremented!")
                  clicked = true
                }
              None => ()
            }
            if not(clicked) {
              match app.find_by_id("btn-plus") {
                Some(btn) =>
                  if is_inside(x, y, btn.x, btn.y, btn.width, btn.height) {
                    count.set(count.get() + 1)
                    message.set("Incremented!")
                    clicked = true
                  }
                None => ()
              }
            }
            if not(clicked) {
              match app.find_by_id("btn-reset") {
                Some(btn) =>
                  if is_inside(x, y, btn.x, btn.y, btn.width, btn.height) {
                    count.set(0)
                    message.set("Reset!")
                    clicked = true
                  }
                None => ()
              }
            }
            // Debug: show click position and button positions
            if not(clicked) {
              let btn_info = match app.find_by_id("btn-minus") {
                Some(b) =>
                  " (" +
                  b.x.to_string() +
                  "," +
                  b.y.to_string() +
                  ")-(" +
                  (b.x + b.width).to_string() +
                  "," +
                  (b.y + b.height).to_string() +
                  ")"
                None => " NOT FOUND"
              }
              let debug_msg = "Click: " +
                x.to_string() +
                "," +
                y.to_string() +
                " | btn-minus:" +
                btn_info
              message.set(debug_msg)
            }
          }
          _ => need_render = false
        }
      _ => need_render = false
    }
    // Re-render
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
