///|
/// Chat example - Claude Code-like chat UI using crater layout
/// Top area shows scrollable message log, bottom has input field

///|
/// Message type for chat
enum MessageRole {
  User
  Assistant
} derive(Eq)

///|
struct Message {
  role : MessageRole
  content : String
}

///|
fn main {
  // Get terminal size (mutable for resize support)
  let (cols, rows) = @tui.get_terminal_size()
  let width : Ref[Int] = { val: cols }
  let height : Ref[Int] = { val: rows }

  // Create reactive state
  let messages : @signals.Signal[Array[Message]] = @signals.signal([])
  let input_value = @signals.signal("")
  let is_editing = @signals.signal(false)
  let running = @signals.signal(true)

  // Forward reference for start_editing (set later in letrec)
  let start_editing_ref : Ref[() -> Unit] = { val: fn() { () } }

  // Item-based scroller for message list
  let scroller = @c.ItemScroller::new()

  // Streaming state using StreamingState component
  let streaming = @c.StreamingState::new()

  // Create the app (mutable for resize support)
  let app : Ref[@tui.App] = { val: @tui.App::new(width.val, height.val) }

  // Build a single message component
  fn build_message(msg : Message) -> @tui.Component {
    let (icon, role_name, color) = match msg.role {
      User => ("◆", "You", @tui.Color::cyan())
      Assistant => ("✦", "Assistant", @tui.Color::rgb(255, 150, 100))
    }
    @c.column(
      [
        @c.text(icon + " " + role_name, fg=color, bold=true),
        @c.text("   " + msg.content, fg=@tui.Color::rgb(220, 220, 220)),
      ],
      gap=0.0,
      width=@types.Dimension::Length(width.val.to_double()),
    )
  }

  // Build streaming message component with fixed height to prevent layout jumps
  fn build_streaming_message() -> @tui.Component {
    let partial = streaming.get_partial()
    let display = if streaming.is_streaming() {
      partial + "▌"
    } else {
      partial
    }
    @c.column(
      [
        @c.text("✦ Assistant", fg=@tui.Color::rgb(255, 150, 100), bold=true),
        @c.text("   " + display, fg=@tui.Color::rgb(220, 220, 220)),
      ],
      gap=0.0,
      width=@types.Dimension::Length(width.val.to_double()),
      height=@types.Dimension::Length(streaming_message_height.to_double()),
    )
  }

  // Get total item count (messages + streaming if any)
  fn get_item_count() -> Int {
    let count = messages.get().length()
    if streaming.has_content() {
      count + 1
    } else {
      count
    }
  }

  // Build message list components
  fn build_message_list() -> Array[@tui.Component] {
    let msgs = messages.get()
    let items : Array[@tui.Component] = []
    for msg in msgs {
      items.push(build_message(msg))
    }
    if streaming.has_content() {
      items.push(build_streaming_message())
    }
    items
  }

  // Calculate visible item count based on terminal height
  // Each message takes roughly 2-3 lines, so we estimate
  fn get_visible_count() -> Int {
    let vh = calc_visible_height(height.val)
    // Estimate: each item takes about 3 lines on average
    let count = vh / 3
    if count < 3 {
      3
    } else {
      count
    }
  }

  // Build the entire UI using crater layout
  fn build_ui() -> @tui.Component {
    let editing = is_editing.get()
    let input_text = input_value.get()
    let w = width.val
    let h = height.val

    // Message area - use ItemScroller to slice visible items
    let all_items = build_message_list()
    let visible_count = get_visible_count()
    let visible_items = scroller.slice(all_items, visible_count)

    // Add scroll indicator if needed
    let indicator = scroller.indicator(get_item_count(), visible_count)
    let display_items : Array[@tui.Component] = []
    for item in visible_items {
      display_items.push(item)
    }
    match indicator {
      @c.ScrollIndicator::None => ()
      _ => display_items.push(@c.scroll_indicator(indicator))
    }
    let visible_height = calc_visible_height(h)
    let message_area = @c.column(
      display_items,
      height=@types.Dimension::Length(visible_height.to_double()),
      justify=@types.Alignment::FlexEnd, // Align messages to bottom
    )

    // Divider - simple text line instead of hdivider (which uses border)
    let divider_color = if editing {
      @tui.Color::rgb(100, 150, 255)
    } else {
      @tui.Color::rgb(60, 60, 60)
    }
    let divider = @c.text("─".repeat(w), fg=divider_color)

    // Input area - fixed height
    let display_text = if input_text.length() == 0 && not(editing) {
      "Type a message... (press Enter to start)"
    } else {
      input_text
    }
    let input_color = if input_text.length() == 0 && not(editing) {
      @tui.Color::rgb(100, 100, 100)
    } else {
      @tui.Color::white()
    }
    let cursor = if editing { "█" } else { "" }
    let status_text = "Enter: send · ↑↓: scroll · Ctrl+C: quit"
    // Input content box (5 lines)
    let input_content = @tui.text_box(
      " " + display_text + cursor,
      fg=input_color,
      height=@types.Dimension::Length(max_input_rows.to_double()),
    )
    let input_area = @c.column(
      [
        input_content,
        @c.text(" " + status_text, fg=@tui.Color::rgb(80, 80, 80)),
      ],
      height=@types.Dimension::Length(input_area_height.to_double()),
    )

    // Buffer line to prevent layout interference
    let buffer = @c.column(
      [],
      height=@types.Dimension::Length(buffer_lines.to_double()),
    )

    // Main layout - vertical split
    @c.column(
      [message_area, divider, buffer, input_area],
      width=@types.Dimension::Length(w.to_double()),
      height=@types.Dimension::Length(h.to_double()),
    )
  }

  // Render helper
  fn do_render() -> Unit {
    let editing = is_editing.get()
    // Save cursor position before rendering if editing
    if editing {
      @tui.print_raw(ansi_save_cursor())
    }
    let ui = build_ui()
    let output = app.val.render_frame(ui)
    @tui.print_raw(output)
    if editing {
      // Restore cursor position and show cursor
      @tui.print_raw(ansi_restore_cursor())
      @tui.print_raw(@tui.ansi_show_cursor())
    } else {
      // Keep cursor in input area when not editing
      @tui.print_raw(ansi_move_to(calc_input_row(height.val), 1))
    }
  }

  // Quit helper
  fn do_quit() -> Unit {
    running.set(false)
    @tui.stop_keypress_listener()
    @tui.stop_resize_listener()
    @tui.print_raw(@tui.disable_mouse())
    @tui.cleanup_stdin()
    @tui.print_raw(@tui.App::restore_terminal())
    println("Goodbye!")
  }

  // Add a message
  fn add_message(role : MessageRole, content : String) -> Unit {
    let current = messages.get()
    current.push({ role, content })
    messages.set(current)
    // Auto-scroll to bottom
    scroller.follow_bottom(get_item_count(), get_visible_count())
  }

  // Complete streaming and add to messages
  fn finish_streaming() -> Unit {
    let text = streaming.take()
    if text.length() > 0 {
      add_message(Assistant, text)
    }
    scroller.follow_bottom(get_item_count(), get_visible_count())
  }

  // Start streaming response
  fn start_streaming(response : String) -> Unit {
    // Force scroll to bottom when starting output
    scroller.to_bottom(get_item_count(), get_visible_count())
    fn on_tick() {
      scroller.follow_bottom(get_item_count(), get_visible_count())
      do_render()
    }

    fn on_complete() {
      finish_streaming()
      do_render()
    }

    let started = streaming.start(response, 200, on_tick, on_complete)
    if not(started) || streaming.ticker_id.val == 0 {
      streaming.clear()
      add_message(Assistant, response)
    }
    do_render()
  }

  // Handle resize event
  fn handle_resize(new_width : Int, new_height : Int) -> Unit {
    width.val = new_width
    height.val = new_height
    // Recreate app with new dimensions
    app.val = @tui.App::new(new_width, new_height)
    // Clear screen and re-render
    @tui.print_raw(@tui.ansi_clear_screen())
    do_render()
  }

  // Input handling - mutually recursive
  letrec restore_tui_and_send: () -> Unit = fn() {
    let raw = input_value.get()
    let text = raw.trim(chars=" \t\n\r").to_string()
    if text.length() > 0 {
      // If streaming, interrupt and discard partial response
      if streaming.is_streaming() {
        streaming.clear()
      }
      scroller.auto_scroll.set(true)
      add_message(User, text)
      input_value.set("")
      let response = "You said: " + text + ". This is a simulated response."
      start_streaming(response)
    }
    is_editing.set(false)
    @tui.print_raw(@tui.ansi_full_reset())
    @tui.print_raw(@tui.enable_mouse())
    app.val.clear_prev_buffer()
    do_render()
    @tui.start_keypress_listener(handle_key)
  }
  and start_editing: () -> Unit = fn() {
    is_editing.set(true)
    do_render()

    // Calculate input area position from layout
    let row = calc_input_row(height.val)
    let col = 2
    let content_width = width.val - 2
    let content_height = max_input_rows
    let signal = input_value
    let config = @c.form_edit_config(
      "Message",
      signal,
      on_edit_start=Some(fn() {
        @tui.stop_keypress_listener()
        @tui.print_raw(@tui.disable_mouse())
      }),
    )

    // Clear content area
    for r = 0; r < content_height; r = r + 1 {
      @tui.print_raw(ansi_move_to(row + r, col) + " ".repeat(content_width))
    }
    let on_lines_change : (Int) -> Int = fn(line_count) {
      clamp_input_lines(line_count)
    }
    @c.start_edit_inplace(
      config,
      signal.get(),
      row,
      col,
      content_width,
      content_height,
      true,
      restore_tui_and_send,
      on_lines_change=Some(on_lines_change),
    )
  }
  and handle_key: (String) -> Unit = fn(key) {
    if key.length() == 0 {
      return
    }
    let event = @tui.parse_input(key)
    let mut need_render = true
    let mut should_edit = false
    let total = get_item_count()
    let visible = get_visible_count()
    match event {
      @tui.InputEvent::Key(key_event) =>
        match key_event {
          @tui.KeyEvent::Char('c', @tui.KeyModifier::Ctrl) => {
            do_quit()
            return
          }
          @tui.KeyEvent::Special(@tui.SpecialKey::Escape, _) => {
            do_quit()
            return
          }
          @tui.KeyEvent::Special(@tui.SpecialKey::Enter, _) =>
            should_edit = true
          @tui.KeyEvent::Char(_, @tui.KeyModifier::None) => should_edit = true
          @tui.KeyEvent::Special(@tui.SpecialKey::Up, _)
          | @tui.KeyEvent::Special(@tui.SpecialKey::PageUp, _) =>
            ignore(scroller.up(1))
          @tui.KeyEvent::Special(@tui.SpecialKey::Down, _)
          | @tui.KeyEvent::Special(@tui.SpecialKey::PageDown, _) =>
            ignore(scroller.down(1, total, visible))
          _ => need_render = false
        }
      @tui.InputEvent::Mouse(mouse_event) =>
        match (mouse_event.event_type, mouse_event.button) {
          (@tui.MouseEventType::Press, @tui.MouseButton::Left) =>
            match app.val.hit_test(mouse_event.x, mouse_event.y) {
              Some(hit) => if hit.id == "chat-input" { should_edit = true }
              None => ()
            }
          (@tui.MouseEventType::Press, @tui.MouseButton::ScrollUp) =>
            ignore(scroller.up(3))
          (@tui.MouseEventType::Press, @tui.MouseButton::ScrollDown) =>
            ignore(scroller.down(3, total, visible))
          _ => need_render = false
        }
      _ => need_render = false
    }
    if should_edit {
      // Extract initial character if it was a character input
      match event {
        @tui.InputEvent::Key(@tui.KeyEvent::Char(ch, @tui.KeyModifier::None)) =>
          input_value.set(ch.to_string())
        _ => ()
      }
      // Start editing (streaming continues in background)
      start_editing()
      return
    }
    if need_render && running.get() {
      do_render()
    }
  }

  // Set forward reference for start_editing
  start_editing_ref.val = start_editing

  // Initialize terminal
  @tui.print_raw(@tui.App::init_terminal())
  @tui.print_raw(@tui.enable_mouse())

  // Start resize listener
  @tui.start_resize_listener(handle_resize)

  // Initial render
  do_render()

  // Start event-driven keypress listener
  @tui.start_keypress_listener(handle_key)
}
