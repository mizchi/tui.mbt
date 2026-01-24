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
  let messages : Array[@composed.Message] = []
  let streaming = @c.StreamingState::new()
  let input_queue = @composed.InputQueue::new()

  // Simulate many messages to test scrolling
  for i = 0; i < 10; i = i + 1 {
    messages.push({ role: User, content: "Message " + i.to_string() })
    messages.push({
      role: Assistant,
      content: "Response to message " + i.to_string(),
    })
  }

  // Calculate visible height
  let vh = @composed.calc_visible_height(height)

  // Test ScrollableView
  let scroller = @c.ScrollableView::new(width - 1, vh) // -1 for scrollbar

  // Build and set lines
  let lines = @composed.build_chat_lines(
    messages,
    streaming,
    input_queue,
    width - 1,
  )
  scroller.set_lines(lines)

  // Output state as plain text (no ANSI escapes)
  println("=== HEADLESS MODE - SCROLLABLE VIEW TEST ===")
  println("Terminal: " + width.to_string() + "x" + height.to_string())
  println(
    "TotalLines: " +
    scroller.total_lines().to_string() +
    ", VisibleHeight: " +
    vh.to_string() +
    ", MaxOffset: " +
    scroller.max_offset().to_string(),
  )
  println(
    "Initial: offset=" +
    scroller.offset.get().to_string() +
    ", auto_scroll=" +
    scroller.auto_scroll.get().to_string(),
  )

  // Simulate pressing Up arrow
  let up_result = scroller.up(1)
  println(
    "After UP: offset=" +
    scroller.offset.get().to_string() +
    ", returned=" +
    up_result.to_string(),
  )

  // Simulate pressing Up 5 more times
  for j = 0; j < 5; j = j + 1 {
    ignore(scroller.up(1))
  }
  println(
    "After 5 more UPs: offset=" +
    scroller.offset.get().to_string() +
    ", can_up=" +
    scroller.can_scroll_up().to_string() +
    ", can_down=" +
    scroller.can_scroll_down().to_string(),
  )

  // Test scrollbar visibility condition
  let show_scrollbar = scroller.total_lines() > vh
  println(
    "Scrollbar: show=" +
    show_scrollbar.to_string() +
    " (total=" +
    scroller.total_lines().to_string() +
    " > visible=" +
    vh.to_string() +
    ")",
  )

  // Test scrollbar rendering
  let scrollbar_lines = @c.build_scrollbar(
    scroller.offset.get(),
    scroller.total_lines(),
    vh,
    vh,
  )
  println("Scrollbar height: " + scrollbar_lines.length().to_string())
  println(
    "Scrollbar preview: " +
    scrollbar_lines.iter().fold(init="", fn(acc, s) { acc + s }),
  )

  // Test scroll positions - get first line at different offsets
  scroller.to_bottom()
  let bottom_offset = scroller.offset.get()
  let bottom_lines = scroller.lines.val
  let bottom_first = if bottom_offset < bottom_lines.length() {
    bottom_lines[bottom_offset].content
  } else {
    ""
  }
  scroller.offset.set(0)
  let top_first = if bottom_lines.length() > 0 {
    bottom_lines[0].content
  } else {
    ""
  }
  println(
    "Scroll test: top first='" +
    top_first +
    "', bottom first (offset=" +
    bottom_offset.to_string() +
    ")='" +
    bottom_first +
    "'",
  )
  println("=== END ===")
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
  let messages : @signals.Signal[Array[@composed.Message]] = @signals.signal([])
  let input_value = @signals.signal("")
  let ime_session = @c.ImeSession::new()
  let running = @signals.signal(true)

  // Action menu will be created after other state is defined
  // (handlers need to capture messages, streaming, message_view)

  // Forward reference for start_editing (set later in letrec)
  let start_editing_ref : Ref[() -> Unit] = { val: fn() { () } }

  // ScrollableView for message list (width-1 for scrollbar)
  let message_view = @c.ScrollableView::new(
    cols - 1,
    @composed.calc_visible_height(rows),
  )

  // Streaming state using StreamingState component
  let streaming = @c.StreamingState::new()

  // Input queue for batching inputs during task processing
  let input_queue = @composed.InputQueue::new()

  // Claude API client (from ANTHROPIC_API_KEY env var)
  let claude_client : @ai.ClaudeClient? = @ai.ClaudeClient::from_env(
    system_prompt="You are a helpful coding assistant with access to file system tools. You can read files, write files, list directories, and run shell commands. Use these tools when the user asks about files or wants you to modify code. Keep responses concise.",
  )

  // Create the app (mutable for resize support)
  let app : Ref[@render.App] = { val: @render.App::new(width.val, height.val) }

  // Action menu with clear messages action
  let action_menu = @c.ActionMenu::new(
    "Actions",
    [
      @c.ActionItem::new('1', "Clear messages", fn() {
        messages.set([])
        streaming.clear()
        message_view.offset.set(0)
        message_view.auto_scroll.set(true)
        message_view.set_lines([])
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

  // Update message view lines from current state
  fn update_message_lines() -> Unit {
    let w = width.val - 1 // Reserve space for scrollbar
    let lines = @composed.build_chat_lines(
      messages.get(),
      streaming,
      input_queue,
      w,
    )
    message_view.set_lines(lines)
  }

  // Check if scrollbar should be shown
  fn should_show_scrollbar() -> Bool {
    message_view.total_lines() > message_view.get_visible_height()
  }

  // Build the message area using visible lines from ScrollableView
  fn build_message_area() -> @core.Component {
    let w = width.val
    let visible_height = @composed.calc_visible_height(height.val)
    let content_width = if should_show_scrollbar() { w - 1 } else { w }

    // Get visible lines from ScrollableView
    let offset = message_view.offset.get()
    let all_lines = message_view.lines.val
    let total = all_lines.length()

    // Build text components for each visible line (each exactly 1 row)
    let line_components : Array[@core.Component] = []
    for i = 0; i < visible_height; i = i + 1 {
      let line_idx = offset + i
      if line_idx < total {
        let styled_line = all_lines[line_idx]
        // Use text_box with height=1 to ensure each line takes exactly 1 row
        line_components.push(
          @core.text_box(
            styled_line.content,
            fg=styled_line.fg,
            bold=styled_line.bold,
            width=@types.Dimension::Length(content_width.to_double()),
            height=@types.Dimension::Length(1.0),
          ),
        )
      } else {
        // Empty line for padding (height=1)
        line_components.push(
          @core.text_box(
            "",
            width=@types.Dimension::Length(content_width.to_double()),
            height=@types.Dimension::Length(1.0),
          ),
        )
      }
    }
    let messages_column = @c.column(
      line_components,
      width=@types.Dimension::Length(content_width.to_double()),
      height=@types.Dimension::Length(visible_height.to_double()),
    )

    // Add scrollbar if needed
    if should_show_scrollbar() {
      let scrollbar_component = @c.scrollbar(
        message_view.offset.get(),
        message_view.total_lines(),
        visible_height,
        visible_height,
        track_color=@core.Color::rgb(60, 60, 60),
        thumb_color=@core.Color::rgb(140, 140, 140),
      )
      @c.row(
        [messages_column, scrollbar_component],
        width=@types.Dimension::Length(w.to_double()),
        height=@types.Dimension::Length(visible_height.to_double()),
      )
    } else {
      messages_column
    }
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
      height=@types.Dimension::Length(@composed.max_input_rows.to_double()),
    )
    let input_area = @c.column(
      [
        input_content,
        @c.text(" " + status_text, fg=@core.Color::rgb(80, 80, 80)),
      ],
      height=@types.Dimension::Length(@composed.input_area_height.to_double()),
    )

    // Buffer line to prevent layout interference
    let buffer = @c.column(
      [],
      height=@types.Dimension::Length(@composed.buffer_lines.to_double()),
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

  // Render helper
  fn do_render() -> Unit {
    let editing = ime_session.is_editing()
    // Save cursor position before rendering if editing
    if editing {
      @io.print_raw(@c.ansi_save_cursor())
    }
    // Update message lines before rendering
    update_message_lines()
    // Render entire UI via crater
    let ui = build_ui()
    let output = app.val.render_frame(ui)
    @io.print_raw(output)
    if editing {
      // Restore cursor position - cooked input manages cursor visibility
      @io.print_raw(@c.ansi_restore_cursor())
    } else {
      // Keep cursor in input area when not editing
      @io.print_raw(@c.ansi_move_to(@composed.calc_input_row(height.val), 0))
    }
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
  fn add_message(role : @composed.MessageRole, content : String) -> Unit {
    let current = messages.get()
    current.push({ role, content })
    messages.set(current)
    // Update lines and auto-scroll to bottom
    update_message_lines()
    message_view.follow_bottom()
  }

  // Complete streaming and add to messages
  fn finish_streaming() -> Unit {
    let text = streaming.take()
    if text.length() > 0 {
      add_message(Assistant, text)
    }
    update_message_lines()
    message_view.follow_bottom()
    // Clear main app's prev_buffer to force full render after streaming
    app.val.clear_prev_buffer()
  }

  // Forward reference for process_queue
  let process_queue_ref : Ref[() -> Bool] = { val: fn() { false } }

  // Start streaming response
  fn start_streaming(response : String) -> Unit {
    input_queue.start_processing()
    // Force scroll to bottom when starting output
    update_message_lines()
    message_view.to_bottom()
    fn on_tick() {
      update_message_lines()
      message_view.follow_bottom()
      do_render()
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

  // Convert UI messages to AI format (limit to last N messages to avoid token limits)
  fn convert_messages_for_ai() -> Array[@ai.Message] {
    let all_msgs = messages.get()
    let max_history = 20 // Keep last 20 messages (10 exchanges)
    let start_idx = if all_msgs.length() > max_history {
      all_msgs.length() - max_history
    } else {
      0
    }
    let ai_messages : Array[@ai.Message] = []
    for i = start_idx; i < all_msgs.length(); i = i + 1 {
      let msg = all_msgs[i]
      let role : @ai.Role = match msg.role {
        @composed.MessageRole::User => @ai.Role::User
        @composed.MessageRole::Assistant => @ai.Role::Assistant
      }
      ai_messages.push({ role, content: msg.content })
    }
    ai_messages
  }

  // Send messages to Claude API with streaming
  fn send_to_claude() -> Unit {
    match claude_client {
      Some(client) => {
        input_queue.start_processing()
        update_message_lines()
        message_view.to_bottom()
        // Start realtime streaming mode with loading indicator
        ignore(streaming.start_realtime())
        streaming.append("Thinking...")
        if not(ime_session.is_editing()) {
          do_render()
        }
        let ai_messages = convert_messages_for_ai()
        let first_chunk = Ref::new(true)
        client.stream_with_tools(
          ai_messages,
          fn(chunk) {
            // Clear "Thinking..." on first real chunk
            if first_chunk.val {
              first_chunk.val = false
              streaming.clear()
              ignore(streaming.start_realtime())
            }
            // Append chunk and render
            streaming.append(chunk)
            update_message_lines()
            message_view.follow_bottom()
            do_render()
          },
          fn(_tool_id, tool_name, input_json) {
            // Execute tool and return result
            @ai.execute_tool(tool_name, input_json)
          },
          fn() {
            // Complete
            finish_streaming()
            input_queue.finish_processing()
            let started_new = (process_queue_ref.val)()
            if not(ime_session.is_editing()) && not(started_new) {
              do_render()
            }
          },
          fn(error) {
            // Error - show as message
            streaming.append("\n\n[Error: " + error + "]")
            streaming.complete()
            finish_streaming()
            input_queue.finish_processing()
            if not(ime_session.is_editing()) {
              do_render()
            }
          },
        )
      }
      None => {
        // Fallback to simulated response when no API key
        let last_msg = messages.get()
        let user_text = if last_msg.length() > 0 {
          last_msg[last_msg.length() - 1].content
        } else {
          ""
        }
        let response = "[No ANTHROPIC_API_KEY set]\nYou said: " +
          user_text +
          "\n\nSet ANTHROPIC_API_KEY environment variable to use Claude."
        start_streaming(response)
      }
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
      message_view.auto_scroll.set(true)
      // Add each queued message as separate user message
      for msg in queued {
        add_message(User, msg)
      }
      // Send to Claude (or fallback)
      send_to_claude()
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
    message_view.resize(
      new_width - 1,
      @composed.calc_visible_height(new_height),
    )
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
        message_view.auto_scroll.set(true)
        add_message(User, text)
        send_to_claude()
      }
    }
    @io.print_raw(@render.ansi_full_reset())
    @io.print_raw(@render.enable_mouse())
    app.val.clear_prev_buffer()
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
    let row = @composed.calc_input_row(height.val)
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
            ignore(message_view.up(1))
          @events.KeyEvent::Special(@events.SpecialKey::Down, _)
          | @events.KeyEvent::Special(@events.SpecialKey::PageDown, _) =>
            ignore(message_view.down(1))
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
            ignore(message_view.up(3))
          (@events.MouseEventType::Press, @events.MouseButton::ScrollDown) =>
            ignore(message_view.down(3))
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
