///|
/// Counter example - demonstrates reactive TUI with async event loop

///|
async fn main {
  // Get terminal size
  let (cols, rows) = @io.get_terminal_size()
  let width = cols
  let height = rows

  // Create reactive state
  let count = @signals.signal(0)

  // Create the app
  let app = @render.App::new(width, height)

  // Render function that creates the component tree
  fn render_ui() -> @core.Component {
    let current_count = count.get()
    @c.column(
      [
        // Title
        @c.row(
          [@c.text("Counter Demo", fg=@core.Color::yellow(), bold=true)],
          justify=@types.Alignment::Center,
          margin_y=1.0,
        ),
        // Count display
        @c.column(
          [
            @c.text("Count:"),
            @c.spacer(),
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
          flex_grow=1.0,
          justify=@types.Alignment::Center,
          align=@types.Alignment::Center,
        ),
        // Buttons row
        @c.row(
          [
            @c.button(" - ", min_width=7.0),
            @c.hspace(2.0),
            @c.button("Reset", min_width=9.0),
            @c.hspace(2.0),
            @c.button(" + ", min_width=7.0),
          ],
          justify=@types.Alignment::Center,
        ),
        // Instructions
        @c.row(
          [
            @c.text(
              "Click buttons or: q=quit | +/-=count | r=reset",
              fg=@core.Color::rgb(128, 128, 128),
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

  // Initialize terminal
  @io.print_raw(@render.App::init_terminal())
  @io.enable_raw_mode()
  @io.print_raw(@render.enable_mouse())

  // Initial render
  @io.print_raw(app.render_frame(render_ui()))

  // Event loop
  let mut running = true
  while running {
    let key = @io.read_key()
    // Skip empty input
    if key.length() == 0 {
      continue
    }
    let event = @events.parse_input(key)
    let mut need_render = true
    match event {
      @events.InputEvent::Key(key_event) =>
        match key_event {
          // Quit on 'q' or Ctrl+C or Escape
          @events.KeyEvent::Char('q', @events.KeyModifier::None) =>
            running = false
          @events.KeyEvent::Char('c', @events.KeyModifier::Ctrl) =>
            running = false
          @events.KeyEvent::Special(@events.SpecialKey::Escape, _) =>
            running = false
          // Increment
          @events.KeyEvent::Char('+', _) => count.set(count.get() + 1)
          @events.KeyEvent::Char('=', _) => count.set(count.get() + 1)
          @events.KeyEvent::Char('k', @events.KeyModifier::None) =>
            count.set(count.get() + 1)
          @events.KeyEvent::Special(@events.SpecialKey::Up, _) =>
            count.set(count.get() + 1)
          // Decrement
          @events.KeyEvent::Char('-', _) => count.set(count.get() - 1)
          @events.KeyEvent::Char('_', _) => count.set(count.get() - 1)
          @events.KeyEvent::Char('j', @events.KeyModifier::None) =>
            count.set(count.get() - 1)
          @events.KeyEvent::Special(@events.SpecialKey::Down, _) =>
            count.set(count.get() - 1)
          // Reset
          @events.KeyEvent::Char('r', @events.KeyModifier::None) => count.set(0)
          _ => need_render = false
        }
      @events.InputEvent::Mouse(mouse_event) =>
        match (mouse_event.event_type, mouse_event.button) {
          (@events.MouseEventType::Press, @events.MouseButton::Left) => {
            let x = mouse_event.x
            let y = mouse_event.y
            // Use hit_test to find clicked component
            match app.hit_test(x, y) {
              Some(hit) => {
                // Detect button by examining hit result position
                let hit_center_x = hit.x + hit.width / 2
                let screen_center_x = width / 2
                // Button has border (height ~7) and reasonable width
                if hit.width >= 5 && hit.width <= 12 && hit.height >= 3 {
                  // Looks like a button - determine which one by position
                  if hit_center_x < screen_center_x - 8 {
                    count.set(count.get() - 1) // Left button: decrement
                  } else if hit_center_x > screen_center_x + 8 {
                    count.set(count.get() + 1) // Right button: increment
                  } else {
                    count.set(0) // Center button: reset
                  }
                }
              }
              None => ()
            }
          }
          _ => need_render = false
        }
      _ => need_render = false
    }
    // Re-render only when state changed
    if need_render && running {
      @io.print_raw(app.render_frame(render_ui()))
    }
  }

  // Restore terminal
  @io.print_raw(@render.disable_mouse())
  @io.cleanup_stdin()
  @io.print_raw(@render.App::restore_terminal())
  println("Goodbye! Final count: " + count.get().to_string())
}
