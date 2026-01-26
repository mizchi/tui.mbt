///|
/// VNode Chat - Simple chat UI with Claude API

///|
using @vnode {type TuiNode, type VNodeApp, column, row, text}

// =============================================================================
// Message Types
// =============================================================================

///|
enum MessageRole {
  User
  Assistant
}

///|
struct Message {
  role : MessageRole
  content : String
}

// =============================================================================
// Streaming State
// =============================================================================

///|
struct StreamingState {
  mut text : String
  mut is_streaming : Bool
}

///|
fn StreamingState::new() -> StreamingState {
  { text: "", is_streaming: false }
}

///|
fn StreamingState::clear(self : StreamingState) -> Unit {
  self.text = ""
  self.is_streaming = false
}

///|
fn StreamingState::append(self : StreamingState, chunk : String) -> Unit {
  self.text = self.text + chunk
}

///|
fn StreamingState::start_realtime(self : StreamingState) -> Bool {
  if self.is_streaming {
    return false
  }
  self.text = ""
  self.is_streaming = true
  true
}

///|
fn StreamingState::complete(self : StreamingState) -> Unit {
  self.is_streaming = false
}

///|
fn StreamingState::take(self : StreamingState) -> String {
  let result = self.text
  self.clear()
  result
}

// =============================================================================
// Input Queue
// =============================================================================

///|
struct InputQueue {
  queue : Array[String]
  mut processing : Bool
}

///|
fn InputQueue::new() -> InputQueue {
  { queue: [], processing: false }
}

///|
fn InputQueue::enqueue(self : InputQueue, text : String) -> Unit {
  self.queue.push(text)
}

///|
fn InputQueue::dequeue_all(self : InputQueue) -> Array[String] {
  let result = self.queue.copy()
  self.queue.clear()
  result
}

///|
fn InputQueue::is_busy(self : InputQueue) -> Bool {
  self.processing
}

///|
fn InputQueue::is_empty(self : InputQueue) -> Bool {
  self.queue.is_empty()
}

///|
fn InputQueue::start_processing(self : InputQueue) -> Unit {
  self.processing = true
}

///|
fn InputQueue::finish_processing(self : InputQueue) -> Unit {
  self.processing = false
}

///|
fn InputQueue::length(self : InputQueue) -> Int {
  self.queue.length()
}

// =============================================================================
// Text Wrapping
// =============================================================================

///|
fn wrap_text(text : String, max_width : Int) -> Array[String] {
  let lines : Array[String] = []
  let current_line = StringBuilder::new()
  let mut current_width = 0
  for c in text {
    if c == '\n' {
      lines.push(current_line.to_string())
      current_line.reset()
      current_width = 0
    } else {
      let char_width = @core.char_display_width(c)
      if current_width + char_width > max_width {
        lines.push(current_line.to_string())
        current_line.reset()
        current_width = 0
      }
      current_line.write_char(c)
      current_width = current_width + char_width
    }
  }
  if current_width > 0 {
    lines.push(current_line.to_string())
  }
  if lines.is_empty() {
    lines.push("")
  }
  lines
}

// =============================================================================
// Main
// =============================================================================

///|
fn main {
  let (width, height) = @tui.get_terminal_size()

  // State
  let messages : Array[Message] = []
  let input = @signals.signal("")
  let editing = @signals.signal(false)
  let scroll_offset = @signals.signal(0)
  let streaming = StreamingState::new()
  let input_queue = InputQueue::new()
  let app = VNodeApp::new(width, height)

  // Layout constants
  let input_rows = 3
  let divider_rows = 1
  let footer_rows = 1
  let message_area_height = height - input_rows - divider_rows - footer_rows - 1

  // Claude API client
  let claude_client : @ai.ClaudeClient? = @ai.ClaudeClient::from_env(
    system_prompt="You are a helpful assistant. Keep responses concise.",
  )

  // Build message lines for display
  fn build_message_lines() -> Array[String] {
    let lines : Array[String] = []
    for msg in messages {
      let prefix = match msg.role {
        User => "> "
        Assistant => "  "
      }
      // Wrap long lines
      let content_lines = wrap_text(msg.content, width - 4)
      for i, line in content_lines {
        if i == 0 {
          lines.push(prefix + line)
        } else {
          lines.push("  " + line)
        }
      }
    }
    // Add streaming content if any
    if streaming.is_streaming && streaming.text.length() > 0 {
      let streaming_lines = wrap_text(streaming.text, width - 4)
      for i, line in streaming_lines {
        if i == 0 {
          lines.push("  " + line)
        } else {
          lines.push("  " + line)
        }
      }
    }
    lines
  }

  // Calculate max scroll offset
  fn max_scroll_offset() -> Int {
    let lines = build_message_lines()
    let max = lines.length() - message_area_height
    if max < 0 {
      0
    } else {
      max
    }
  }

  // Auto-scroll to bottom
  fn scroll_to_bottom() -> Unit {
    scroll_offset.set(max_scroll_offset())
  }

  fn render_message_line(line : String, idx : Int) -> TuiNode {
    let is_user = line.has_prefix("> ")
    let fg = if is_user { "cyan" } else { "white" }
    row(id="msg-" + idx.to_string(), min_width=width.to_double(), height=1.0, [
      text(line, fg~),
    ])
  }

  fn render_messages() -> TuiNode {
    let all_lines = build_message_lines()
    let total_lines = all_lines.length()
    let offset = scroll_offset.get()
    let visible_lines : Array[TuiNode] = []

    // Bottom-align: add empty lines at top if content is shorter than area
    let empty_lines_at_top = if total_lines < message_area_height {
      message_area_height - total_lines
    } else {
      0
    }
    for i = 0; i < message_area_height; i = i + 1 {
      if i < empty_lines_at_top {
        // Empty line for bottom-alignment
        visible_lines.push(row(height=1.0, []))
      } else {
        let line_idx = offset + (i - empty_lines_at_top)
        if line_idx < total_lines {
          visible_lines.push(render_message_line(all_lines[line_idx], line_idx))
        } else {
          visible_lines.push(row(height=1.0, []))
        }
      }
    }
    column(
      min_width=width.to_double(),
      height=message_area_height.to_double(),
      visible_lines,
    )
  }

  fn render_divider() -> TuiNode {
    let color = if editing.get() { "rgb(100,150,255)" } else { "rgb(60,60,60)" }
    text("\u{2500}".repeat(width), fg=color)
  }

  fn render_input() -> TuiNode {
    let current = input.get()
    let display_text = if current.length() == 0 && not(editing.get()) {
      "Type a message... (press Enter to start)"
    } else {
      current
    }
    let fg = if current.length() == 0 && not(editing.get()) {
      "rgb(100,100,100)"
    } else {
      "white"
    }
    column(height=input_rows.to_double(), min_width=width.to_double(), [
      row(id="input-line", min_width=width.to_double(), [
        text(" " + display_text, fg~),
      ]),
    ])
  }

  fn render_footer() -> TuiNode {
    let queue_info = if input_queue.is_busy() {
      let count = input_queue.length()
      if count > 0 {
        " [Queue: " + count.to_string() + "]"
      } else {
        " [Processing...]"
      }
    } else {
      ""
    }
    let status = "Enter: send | \u{2191}\u{2193}: scroll | Ctrl+C: quit" +
      queue_info
    row(min_width=width.to_double(), [text(" " + status, fg="rgb(80,80,80)")])
  }

  fn render_ui() -> TuiNode {
    column(width=width.to_double(), height=(height - 1).to_double(), [
      render_messages(),
      render_divider(),
      render_input(),
      render_footer(),
    ])
  }

  fn do_render() -> Unit {
    let output = app.render_frame(render_ui())
    @tui.print_raw(output)
    // Position cursor at input line
    if editing.get() {
      match app.find_by_id("input-line") {
        Some(bounds) => {
          let cursor_x = bounds.x + 1 + @core.string_display_width(input.get())
          @tui.print_raw(
            @render.ansi_move_to(bounds.y, cursor_x) +
            @render.ansi_show_cursor(),
          )
        }
        None => ()
      }
    } else {
      @tui.print_raw(@render.ansi_hide_cursor())
    }
  }

  fn do_quit() -> Unit {
    streaming.clear()
    @io.stop_keypress_listener()
    @tui.print_raw(VNodeApp::restore_terminal())
    println("Goodbye!")
  }

  // Forward reference for process_queue
  let process_queue_ref : Ref[() -> Bool] = Ref::new(fn() { false })

  // Add a message
  fn add_message(role : MessageRole, content : String) -> Unit {
    messages.push({ role, content })
    scroll_to_bottom()
  }

  // Complete streaming and add to messages
  fn finish_streaming() -> Unit {
    let text = streaming.take()
    if text.length() > 0 {
      add_message(Assistant, text)
    }
    scroll_to_bottom()
    app.clear_prev_buffer()
  }

  // Convert messages for AI
  fn convert_messages_for_ai() -> Array[@ai.Message] {
    let max_history = 20
    let start_idx = if messages.length() > max_history {
      messages.length() - max_history
    } else {
      0
    }
    let ai_messages : Array[@ai.Message] = []
    for i = start_idx; i < messages.length(); i = i + 1 {
      let msg = messages[i]
      let role : @ai.Role = match msg.role {
        User => @ai.Role::User
        Assistant => @ai.Role::Assistant
      }
      ai_messages.push({ role, content: msg.content })
    }
    ai_messages
  }

  // Send to Claude
  fn send_to_claude() -> Unit {
    match claude_client {
      Some(client) => {
        input_queue.start_processing()
        scroll_to_bottom()
        ignore(streaming.start_realtime())
        streaming.append("Thinking...")
        do_render()
        let ai_messages = convert_messages_for_ai()
        let first_chunk = Ref::new(true)
        client.stream_with_tools(
          ai_messages,
          fn(chunk) {
            if first_chunk.val {
              first_chunk.val = false
              streaming.clear()
              ignore(streaming.start_realtime())
            }
            streaming.append(chunk)
            scroll_to_bottom()
            do_render()
          },
          fn(_tool_id, tool_name, input_json) {
            @ai.execute_tool(tool_name, input_json)
          },
          fn() {
            finish_streaming()
            input_queue.finish_processing()
            let started_new = (process_queue_ref.val)()
            if not(started_new) {
              do_render()
            }
          },
          fn(error) {
            streaming.append("\n\n[Error: " + error + "]")
            streaming.complete()
            finish_streaming()
            input_queue.finish_processing()
            do_render()
          },
        )
      }
      None => {
        // Fallback when no API key
        input_queue.start_processing()
        scroll_to_bottom()
        ignore(streaming.start_realtime())
        let last_msg = if messages.length() > 0 {
          messages[messages.length() - 1].content
        } else {
          ""
        }
        streaming.append(
          "[No ANTHROPIC_API_KEY set]\nYou said: " +
          last_msg +
          "\n\nSet ANTHROPIC_API_KEY environment variable to use Claude.",
        )
        streaming.complete()
        finish_streaming()
        input_queue.finish_processing()
        do_render()
      }
    }
  }

  // Process queued inputs
  fn process_queue() -> Bool {
    if input_queue.is_busy() || input_queue.is_empty() {
      return false
    }
    let queued = input_queue.dequeue_all()
    if queued.length() > 0 {
      for msg in queued {
        add_message(User, msg)
      }
      send_to_claude()
      return true
    }
    false
  }

  process_queue_ref.val = process_queue

  // Mutually recursive input handling
  letrec restore_tui_and_send: () -> Unit = fn() {
    let raw = input.get()
    let text = raw.trim(chars=" \t\n\r").to_string()
    if text.length() > 0 {
      input.set("")
      if input_queue.is_busy() {
        input_queue.enqueue(text)
      } else {
        add_message(User, text)
        send_to_claude()
      }
    }
    @tui.print_raw(@render.ansi_full_reset())
    app.clear_prev_buffer()
    editing.set(false)
    do_render()
    @io.start_keypress_listener(handle_key)
  }
  and start_editing: () -> Unit = fn() {
    @io.stop_keypress_listener()
    editing.set(true)
    @tui.enable_raw_mode()
    do_render()
    @io.start_keypress_listener(handle_edit_key)
  }
  and handle_edit_key: (String) -> Unit = fn(key) {
    if key.length() == 0 {
      return
    }
    // Handle multi-character printable input (IME)
    if key.length() > 1 &&
      key[0].to_int() != 0x1b &&
      @tui.is_printable_string(key) {
      input.set(input.get() + key)
      do_render()
      return
    }
    let event = @tui.parse_input(key)
    if event.is_ctrl_c() {
      do_quit()
      return
    }
    match event {
      @tui.InputEvent::Key(key_event) =>
        match key_event {
          @tui.KeyEvent::Special(@tui.SpecialKey::Escape, _) => {
            input.set("")
            restore_tui_and_send()
          }
          @tui.KeyEvent::Special(@tui.SpecialKey::Enter, _) =>
            restore_tui_and_send()
          @tui.KeyEvent::Special(@tui.SpecialKey::Backspace, _) => {
            let current = input.get()
            if current.length() > 0 {
              let chars : Array[Char] = current.iter().collect()
              let buf = StringBuilder::new()
              for i = 0; i < chars.length() - 1; i = i + 1 {
                buf.write_char(chars[i])
              }
              input.set(buf.to_string())
            }
            do_render()
          }
          @tui.KeyEvent::Char(c, @tui.KeyModifier::None)
          | @tui.KeyEvent::Char(c, @tui.KeyModifier::Shift) => {
            input.set(input.get() + c.to_string())
            do_render()
          }
          _ => ()
        }
      _ => ()
    }
  }
  and handle_key: (String) -> Unit = fn(key) {
    if key.length() == 0 {
      return
    }
    let event = @tui.parse_input(key)
    if event.is_ctrl_c() {
      do_quit()
      return
    }
    match event {
      @tui.InputEvent::Key(key_event) =>
        match key_event {
          @tui.KeyEvent::Special(@tui.SpecialKey::Enter, _) => start_editing()
          @tui.KeyEvent::Char(_, @tui.KeyModifier::None) => start_editing()
          @tui.KeyEvent::Special(@tui.SpecialKey::Up, _) => {
            let offset = scroll_offset.get()
            if offset > 0 {
              scroll_offset.set(offset - 1)
            }
            do_render()
          }
          @tui.KeyEvent::Special(@tui.SpecialKey::Down, _) => {
            let offset = scroll_offset.get()
            let max = max_scroll_offset()
            if offset < max {
              scroll_offset.set(offset + 1)
            }
            do_render()
          }
          _ => ()
        }
      _ => ()
    }
  }

  // Initialize
  @tui.print_raw(VNodeApp::init_terminal())
  @tui.enable_raw_mode()
  do_render()
  @io.start_keypress_listener(handle_key)
}
