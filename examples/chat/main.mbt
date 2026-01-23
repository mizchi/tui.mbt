///|
/// Chat example - Claude Code-like chat UI using crater layout
/// Top area shows scrollable message log, bottom has input field
/// Supports input queue for batching user inputs while task is running
///
/// Run with --headless or TUI_HEADLESS=1 for non-interactive testing

///|
fn run_headless() -> Unit {
  // Fixed size for headless mode
  let width = 80
  let height = 24

  // Create state
  let messages : Array[@c.Message] = []
  let streaming = @c.StreamingState::new()
  let input_queue = @c.InputQueue::new()

  // Simulate some messages
  messages.push({ role: User, content: "Hello, how are you?" })
  messages.push({
    role: Assistant,
    content: "I'm doing great! How can I help you today?",
  })
  messages.push({ role: User, content: "Tell me about MoonBit" })

  // Build message list
  let all_items = @c.chat_message_list(
    messages, streaming, input_queue, width, @c.streaming_message_height,
  )

  // Output state as plain text (no ANSI escapes)
  println("=== HEADLESS MODE ===")
  println("Terminal size: " + width.to_string() + "x" + height.to_string())
  println("Messages: " + messages.length().to_string())
  println("")
  println("--- Message Log ---")
  for i, msg in messages {
    let role_str = match msg.role {
      User => "[User]"
      Assistant => "[Assistant]"
    }
    println(i.to_string() + ". " + role_str + " " + msg.content)
  }
  println("")
  println("--- UI Components ---")
  println("Item count: " + all_items.length().to_string())
  println("")
  println("=== END HEADLESS ===")
}

///|
fn main {
  // Check for headless mode
  if @io.is_headless() {
    run_headless()
    return
  }
  // Get terminal size (mutable for resize support)
  let (cols, rows) = @io.get_terminal_size()
  let width : Ref[Int] = { val: cols }
  let height : Ref[Int] = { val: rows }

  // Create reactive state
  let messages : @signals.Signal[Array[@c.Message]] = @signals.signal([])
  let input_value = @signals.signal("")
  let ime_session = @c.ImeSession::new()
  let running = @signals.signal(true)

  // Action menu will be created after other state is defined
  // (handlers need to capture messages, streaming, scroller)

  // Forward reference for start_editing (set later in letrec)
  let start_editing_ref : Ref[() -> Unit] = { val: fn() { () } }

  // Item-based scroller for message list
  let scroller = @c.ItemScroller::new()

  // Streaming state using StreamingState component
  let streaming = @c.StreamingState::new()

  // Cursor-safe stream buffer for message area updates
  let stream_buffer = @c.StreamBuffer::new(cols, @c.calc_visible_height(rows))

  // Input queue for batching inputs during task processing
  let input_queue = @c.InputQueue::new()

  // Create the app (mutable for resize support)
  let app : Ref[@render.App] = { val: @render.App::new(width.val, height.val) }

  // Action menu with clear messages action
  let action_menu = @c.ActionMenu::new(
    "Actions",
    [
      @c.ActionItem::new('1', "Clear messages", fn() {
        messages.set([])
        streaming.clear()
        scroller.offset.set(0)
        scroller.auto_scroll.set(true)
      }),
      @c.ActionItem::new('2', "Export chat", fn() {
        // Placeholder - just close modal
      }),
      @c.ActionItem::new('3', "Settings", fn() {
        // Placeholder - just close modal
      }),
    ],
    toggle_key=Some('f'),
  )

  // Get total item count (messages + streaming + queued)
  fn get_item_count() -> Int {
    let mut count = messages.get().length()
    if streaming.has_content() {
      count = count + 1
    }
    count + input_queue.length()
  }

  // Calculate visible item count based on terminal height
  // Each message takes roughly 2-3 lines, so we estimate
  fn get_visible_count() -> Int {
    let vh = @c.calc_visible_height(height.val)
    // Estimate: each item takes about 3 lines on average
    let count = vh / 3
    if count < 3 {
      3
    } else {
      count
    }
  }

  // Build the message area with scrolling and indicator
  fn build_message_area() -> @core.Component {
    let w = width.val
    let h = height.val
    let all_items = @c.chat_message_list(
      messages.get(),
      streaming,
      input_queue,
      w,
      @c.streaming_message_height,
    )
    let visible_count = get_visible_count()
    let visible_items = scroller.slice(all_items, visible_count)

    // Add scroll indicator if needed
    let indicator = scroller.indicator(get_item_count(), visible_count)
    let display_items : Array[@core.Component] = []
    for item in visible_items {
      display_items.push(item)
    }
    match indicator {
      @c.ScrollIndicator::None => ()
      _ => display_items.push(@c.scroll_indicator(indicator))
    }
    let visible_height = @c.calc_visible_height(h)
    @c.column(
      display_items,
      height=@types.Dimension::Length(visible_height.to_double()),
      justify=@types.Alignment::FlexEnd, // Align messages to bottom
    )
  }

  // Build the entire UI using crater layout
  fn build_ui() -> @core.Component {
    let editing = ime_session.is_editing()
    let input_text = input_value.get()
    let w = width.val
    let h = height.val
    let message_area = build_message_area()

    // Divider - simple text line instead of hdivider (which uses border)
    let divider_color = if editing {
      @core.Color::rgb(100, 150, 255)
    } else {
      @core.Color::rgb(60, 60, 60)
    }
    let divider = @c.text("─".repeat(w), fg=divider_color)

    // Input area - fixed height
    let display_text = if input_text.length() == 0 && not(editing) {
      "Type a message... (press Enter to start)"
    } else {
      input_text
    }
    let input_color = if input_text.length() == 0 && not(editing) {
      @core.Color::rgb(100, 100, 100)
    } else {
      @core.Color::white()
    }
    let cursor = "" // No cursor - cooked input manages cursor position
    // Build status text with queue info
    let queue_info = if input_queue.is_busy() {
      let count = input_queue.length()
      if count > 0 {
        " · [Queue: " + count.to_string() + "]"
      } else {
        " · [Processing...]"
      }
    } else {
      ""
    }
    let status_text = "Enter: send · ↑↓: scroll · F: actions · Ctrl+C: quit" +
      queue_info
    // Input content box (5 lines)
    let input_content = @core.text_box(
      " " + display_text + cursor,
      fg=input_color,
      height=@types.Dimension::Length(@c.max_input_rows.to_double()),
    )
    let input_area = @c.column(
      [
        input_content,
        @c.text(" " + status_text, fg=@core.Color::rgb(80, 80, 80)),
      ],
      height=@types.Dimension::Length(@c.input_area_height.to_double()),
    )

    // Buffer line to prevent layout interference
    let buffer = @c.column(
      [],
      height=@types.Dimension::Length(@c.buffer_lines.to_double()),
    )

    // Main layout - vertical split
    let base_ui = @c.column(
      [message_area, divider, buffer, input_area],
      width=@types.Dimension::Length(w.to_double()),
      height=@types.Dimension::Length(h.to_double()),
    )

    // When modal is open, render modal full-screen instead of base UI
    if action_menu.is_open() {
      action_menu.build(w, h)
    } else {
      base_ui
    }
  }

  // Render message area with cursor-safe stream buffer
  fn render_message_area_stream() -> Unit {
    let message_area = build_message_area()
    stream_buffer.render(message_area)
  }

  // Render helper
  fn do_render() -> Unit {
    let editing = ime_session.is_editing()
    // Save cursor position before rendering if editing
    if editing {
      @io.print_raw(@c.ansi_save_cursor())
    }
    let ui = build_ui()
    let output = app.val.render_frame(ui)
    @io.print_raw(output)
    if editing {
      // Restore cursor position - cooked input manages cursor visibility
      @io.print_raw(@c.ansi_restore_cursor())
    } else {
      // Keep cursor in input area when not editing
      @io.print_raw(@c.ansi_move_to(@c.calc_input_row(height.val), 0))
    }
    stream_buffer.sync(build_message_area())
  }

  // Quit helper
  fn do_quit() -> Unit {
    running.set(false)
    streaming.clear() // Stop any ongoing streaming
    @io.stop_keypress_listener()
    @io.stop_resize_listener()
    @io.print_raw(@render.disable_mouse())
    @io.cleanup_stdin()
    @io.print_raw(@render.App::restore_terminal())
    println("Goodbye!")
  }

  // Add a message
  fn add_message(role : @c.MessageRole, content : String) -> Unit {
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
    // Clear main app's prev_buffer to force full render after streaming
    // (stream_buffer was updating screen independently, main app's buffer is stale)
    app.val.clear_prev_buffer()
  }

  // Forward reference for process_queue
  let process_queue_ref : Ref[() -> Bool] = { val: fn() { false } }

  // Start streaming response
  fn start_streaming(response : String) -> Unit {
    input_queue.start_processing()
    // Clear stream buffer to avoid stale content from previous streaming
    stream_buffer.clear()
    // Force scroll to bottom when starting output
    scroller.to_bottom(get_item_count(), get_visible_count())
    fn on_tick() {
      scroller.follow_bottom(get_item_count(), get_visible_count())
      render_message_area_stream()
    }

    fn on_complete() {
      finish_streaming()
      input_queue.finish_processing()
      // Process any queued inputs after task completion
      // If a new streaming started, skip do_render (start_streaming already called it)
      let started_new = (process_queue_ref.val)()
      // Only render if not editing and no new streaming started
      if not(ime_session.is_editing()) && not(started_new) {
        do_render()
      }
    }

    let started = streaming.start(response, 200, on_tick, on_complete)
    // If start failed (already streaming), add message directly
    // Note: ticker_id == 0 case is handled inside start() which calls on_complete
    if not(started) {
      add_message(Assistant, response)
      input_queue.finish_processing()
      ignore((process_queue_ref.val)())
    }
    if not(ime_session.is_editing()) {
      do_render()
    }
  }

  // Process all queued inputs and send as batch
  // Returns true if processing started (a new streaming was initiated)
  fn process_queue() -> Bool {
    if input_queue.is_busy() || input_queue.is_empty() {
      return false
    }
    let queued = input_queue.dequeue_all()
    if queued.length() > 0 {
      scroller.auto_scroll.set(true)
      // Add each queued message as separate user message
      for msg in queued {
        add_message(User, msg)
      }
      // Single response for all
      let response = "Processed " +
        queued.length().to_string() +
        " queued message(s)."
      start_streaming(response)
      return true
    }
    false
  }

  process_queue_ref.val = process_queue

  // Handle resize event
  fn handle_resize(new_width : Int, new_height : Int) -> Unit {
    width.val = new_width
    height.val = new_height
    // Recreate apps with new dimensions
    app.val = @render.App::new(new_width, new_height)
    stream_buffer.resize(new_width, @c.calc_visible_height(new_height))
    // Clear screen and re-render
    @io.print_raw(@render.ansi_clear_screen())
    do_render()
  }

  // Input handling - mutually recursive
  letrec restore_tui_and_send: () -> Unit = fn() {
    let raw = input_value.get()
    let text = raw.trim(chars=" \t\n\r").to_string()
    if text.length() > 0 {
      input_value.set("")
      // If task is running (streaming), queue the input instead of sending immediately
      if input_queue.is_busy() {
        input_queue.enqueue(text)
      } else {
        // No task running, send immediately
        scroller.auto_scroll.set(true)
        add_message(User, text)
        let response = "You said: " + text + ". This is a simulated response."
        start_streaming(response)
      }
    }
    @io.print_raw(@render.ansi_full_reset())
    @io.print_raw(@render.enable_mouse())
    app.val.clear_prev_buffer()
    stream_buffer.clear()
    do_render()
    @io.start_resize_listener(handle_resize)
    @io.start_keypress_listener(handle_key)
  }
  and start_editing: () -> Unit = fn() {
    let config = @c.form_edit_config(
      "Message",
      input_value,
      on_edit_start=Some(fn() {
        @io.stop_keypress_listener()
        @io.stop_resize_listener()
        @io.print_raw(@render.disable_mouse())
      }),
      on_force_quit=Some(fn() { do_quit() }),
    )
    let row = @c.calc_input_row(height.val)
    @io.print_raw(@c.ansi_move_to(row, 0) + " ".repeat(width.val))
    @io.print_raw(@c.ansi_move_to(row, 1))
    ime_session.start(config, input_value.get(), restore_tui_and_send)
  }
  and handle_key: (String) -> Unit = fn(key) {
    if key.length() == 0 {
      return
    }
    let event = @events.parse_input(key)
    let mut need_render = true
    let mut should_edit = false
    let total = get_item_count()
    let visible = get_visible_count()

    // Handle modal keys when modal is open
    match action_menu.handle_event(app.val, event) {
      @c.MenuKeyResult::Handled | @c.MenuKeyResult::Closed => {
        if running.get() {
          do_render()
        }
        return
      }
      @c.MenuKeyResult::NotHandled => ()
    }

    // Normal mode key handling
    match event {
      @events.InputEvent::Key(key_event) =>
        match key_event {
          @events.KeyEvent::Char('c', @events.KeyModifier::Ctrl) => {
            do_quit()
            return
          }
          @events.KeyEvent::Special(@events.SpecialKey::Escape, _) => {
            do_quit()
            return
          }
          @events.KeyEvent::Char('f', @events.KeyModifier::None)
          | @events.KeyEvent::Char('F', @events.KeyModifier::None) =>
            // Open action menu - clear buffer for full redraw
            action_menu.open_with_app(app.val)
          @events.KeyEvent::Special(@events.SpecialKey::Enter, _) =>
            should_edit = true
          @events.KeyEvent::Char(_, @events.KeyModifier::None) =>
            should_edit = true
          @events.KeyEvent::Special(@events.SpecialKey::Up, _)
          | @events.KeyEvent::Special(@events.SpecialKey::PageUp, _) =>
            ignore(scroller.up(1))
          @events.KeyEvent::Special(@events.SpecialKey::Down, _)
          | @events.KeyEvent::Special(@events.SpecialKey::PageDown, _) =>
            ignore(scroller.down(1, total, visible))
          _ => need_render = false
        }
      @events.InputEvent::Mouse(mouse_event) =>
        match (mouse_event.event_type, mouse_event.button) {
          (@events.MouseEventType::Press, @events.MouseButton::Left) =>
            match app.val.hit_test(mouse_event.x, mouse_event.y) {
              Some(hit) => if hit.id == "chat-input" { should_edit = true }
              None => ()
            }
          (@events.MouseEventType::Press, @events.MouseButton::ScrollUp) =>
            ignore(scroller.up(3))
          (@events.MouseEventType::Press, @events.MouseButton::ScrollDown) =>
            ignore(scroller.down(3, total, visible))
          _ => need_render = false
        }
      _ => need_render = false
    }
    if should_edit {
      // Extract initial character if it was a character input
      match event {
        @events.InputEvent::Key(
          @events.KeyEvent::Char(ch, @events.KeyModifier::None)
        ) =>
          // Don't start editing with 'f'/'F' as it opens modal
          if ch != 'f' && ch != 'F' {
            input_value.set(ch.to_string())
          }
        _ => ()
      }
      // Start editing (streaming continues in background) - but not if we just opened modal
      if not(action_menu.is_open()) {
        start_editing()
      }
      return
    }
    if need_render && running.get() {
      do_render()
    }
  }

  // Set forward reference for start_editing
  start_editing_ref.val = start_editing

  // Initialize terminal
  @io.print_raw(@render.App::init_terminal())
  @io.print_raw(@render.enable_mouse())

  // Start resize listener
  @io.start_resize_listener(handle_resize)

  // Initial render
  do_render()

  // Start event-driven keypress listener
  @io.start_keypress_listener(handle_key)
}
