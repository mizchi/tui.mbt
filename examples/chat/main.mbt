///|
/// VNode Chat - Simple chat UI with Claude API

///|
using @vnode {type TuiNode, column, row, text}

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

///|
/// Truncate text to fit within max_width (display width)
fn truncate_text(text : String, max_width : Int) -> String {
  let buf = StringBuilder::new()
  let mut current_width = 0
  for c in text {
    let char_width = @core.char_display_width(c)
    if current_width + char_width > max_width {
      break
    }
    buf.write_char(c)
    current_width = current_width + char_width
  }
  buf.to_string()
}

// =============================================================================
// Main
// =============================================================================

///|
fn main {
  let (initial_width, initial_height) = @tui.get_terminal_size()

  // Mutable terminal size (updated on resize)
  let width = Ref::new(initial_width)
  let height = Ref::new(initial_height)

  // State
  let messages : Array[Message] = []
  let editor_state = @editor.EditorState::new_with_filename("", 3, "input.txt")
  let editing = @signals.signal(false)
  let scroll_offset = @signals.signal(0)
  let streaming = StreamingState::new()
  let input_queue = InputQueue::new()
  let (app, cleanup) = @vnode.init_vnode_terminal(
    initial_width,
    initial_height,
    @tui.print_raw,
    mouse=true,
  )

  // Sidebar state
  let sidebar_visible = @signals.signal(true)
  let sidebar_focused = @signals.signal(false)
  let file_tree = FilerState::new(@ai.js_get_cwd())
  file_tree.refresh()

  // File preview state
  let preview_visible = @signals.signal(false)

  // Layout constants
  let input_rows = 3
  let divider_rows = 1
  let footer_rows = 1
  let sidebar_width = @signals.signal(28)
  let sidebar_min_width = 20
  let sidebar_max_width = 60

  fn get_chat_width() -> Int {
    if sidebar_visible.get() {
      width.val - sidebar_width.get() - 1 // 1 for border
    } else {
      width.val
    }
  }

  fn message_area_height() -> Int {
    height.val - input_rows - divider_rows - footer_rows - 1
  }

  // AI client (Claude or OpenRouter)
  let ai_client : @ai.BoxedAIClient? = @ai.create_client_from_env(
    system_prompt="You are a helpful assistant. Keep responses concise.",
  )

  // Build message lines for display
  fn build_message_lines() -> Array[String] {
    let lines : Array[String] = []
    let chat_width = get_chat_width()
    for msg in messages {
      let prefix = match msg.role {
        User => "> "
        Assistant => "  "
      }
      // Wrap long lines
      let content_lines = wrap_text(msg.content, chat_width - 4)
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
      let streaming_lines = wrap_text(streaming.text, chat_width - 4)
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
    let max = lines.length() - message_area_height()
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
    let chat_width = get_chat_width()
    // Ensure line doesn't exceed chat width
    let display_line = truncate_text(line, chat_width - 1)
    row(
      id="msg-" + idx.to_string(),
      min_width=chat_width.to_double(),
      height=1.0,
      [text(display_line, fg~)],
    )
  }

  fn render_messages() -> TuiNode {
    let all_lines = build_message_lines()
    let total_lines = all_lines.length()
    let offset = scroll_offset.get()
    let visible_lines : Array[TuiNode] = []
    let area_height = message_area_height()
    let chat_width = get_chat_width()

    // Bottom-align: add empty lines at top if content is shorter than area
    let empty_lines_at_top = if total_lines < area_height {
      area_height - total_lines
    } else {
      0
    }
    for i = 0; i < area_height; i = i + 1 {
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
      min_width=chat_width.to_double(),
      height=area_height.to_double(),
      visible_lines,
    )
  }

  fn render_divider() -> TuiNode {
    let color = if editing.get() { "rgb(100,150,255)" } else { "rgb(60,60,60)" }
    let chat_width = get_chat_width()
    text("\u{2500}".repeat(chat_width), fg=color)
  }

  fn render_input() -> TuiNode {
    let current = editor_state.get_text()
    let chat_width = get_chat_width()
    if editing.get() {
      // Use editor component when editing
      @editor.render_editor(editor_state, chat_width, input_rows)
    } else {
      // Show placeholder when not editing
      let display_text = if current.length() == 0 {
        "Type a message... (press Enter to start)"
      } else {
        current
      }
      let fg = if current.length() == 0 {
        "rgb(100,100,100)"
      } else {
        "white"
      }
      let truncated_display = truncate_text(" " + display_text, chat_width - 1)
      column(height=input_rows.to_double(), min_width=chat_width.to_double(), [
        row(id="input-line", min_width=chat_width.to_double(), [
          text(truncated_display, fg~),
        ]),
      ])
    }
  }

  fn render_footer() -> TuiNode {
    let queue_info = if input_queue.is_busy() {
      let count = input_queue.length()
      if count > 0 {
        " [Q:" + count.to_string() + "]"
      } else {
        " [...]"
      }
    } else {
      ""
    }
    let chat_width = get_chat_width()
    let msg_count = " [" + messages.length().to_string() + "]"
    let sidebar_hint = if sidebar_visible.get() {
      if sidebar_focused.get() {
        let git_hint = if file_tree.is_git_repo { " g:git" } else { "" }
        "Tab:chat \u{2190}\u{2192}:nav" + git_hint
      } else {
        "Tab:tree ^L/H:resize"
      }
    } else {
      "b:tree"
    }
    let status = sidebar_hint +
      " | \u{2191}\u{2193}:scroll | ^C:quit" +
      msg_count +
      queue_info
    row(min_width=chat_width.to_double(), [
      text(" " + truncate_text(status, chat_width - 2), fg="rgb(80,80,80)"),
    ])
  }

  fn render_main_content() -> TuiNode {
    let chat_width = get_chat_width()
    let area_height = message_area_height()
    if preview_visible.get() && file_tree.preview_file.length() > 0 {
      // Show file preview in message area
      render_file_preview(file_tree, chat_width, area_height)
    } else {
      // Show messages
      render_messages()
    }
  }

  fn render_chat_area() -> TuiNode {
    let chat_width = get_chat_width()
    column(width=chat_width.to_double(), height=(height.val - 1).to_double(), [
      render_main_content(),
      render_divider(),
      render_input(),
      render_footer(),
    ])
  }

  fn render_ui() -> TuiNode {
    if sidebar_visible.get() {
      let filer_height = height.val - 2
      let sw = sidebar_width.get()
      // Always show sidebar + chat area (preview is shown in message area)
      row(width=width.val.to_double(), height=(height.val - 1).to_double(), [
        render_filer(file_tree, sw, filer_height, sidebar_focused.get()),
        render_chat_area(),
      ])
    } else {
      render_chat_area()
    }
  }

  fn do_render() -> Unit {
    let output = app.render_frame(render_ui())
    @tui.print_raw(output)
    // Position cursor at input line
    if editing.get() {
      let chat_width = get_chat_width()
      let editor_x = if sidebar_visible.get() { sidebar_width.get() + 1 } else { 0 }
      let editor_y = message_area_height() + divider_rows
      let (cursor_row, cursor_col) = @editor.editor_cursor_position(
        editor_state,
        chat_width,
        input_rows,
      )
      @tui.print_raw(
        @render.ansi_move_to(editor_y + cursor_row, editor_x + cursor_col) +
        @render.ansi_show_cursor(),
      )
    } else {
      @tui.print_raw(@render.ansi_hide_cursor())
    }
  }

  // Handle terminal resize
  fn handle_resize(new_width : Int, new_height : Int) -> Unit {
    width.val = new_width
    height.val = new_height
    app.resize(new_width, new_height)
    do_render()
  }

  fn do_quit() -> Unit {
    streaming.clear()
    cleanup()
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

  // Send to AI
  fn send_to_ai() -> Unit {
    match ai_client {
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
          "[No API key set]\nYou said: " +
          last_msg +
          "\n\nSet ANTHROPIC_API_KEY or OPENROUTER_API_KEY to use AI.",
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
      send_to_ai()
      return true
    }
    false
  }

  process_queue_ref.val = process_queue

  // Compact conversation by summarizing past messages
  fn do_compact() -> Unit {
    if messages.length() < 4 {
      add_message(Assistant, "[Compact: Not enough messages to summarize]")
      do_render()
      return
    }
    match ai_client {
      Some(client) => {
        input_queue.start_processing()
        ignore(streaming.start_realtime())
        streaming.append("[Compacting conversation...]")
        do_render()

        // Build summary prompt
        let conversation_text = StringBuilder::new()
        for msg in messages {
          let prefix = match msg.role {
            User => "User: "
            Assistant => "Assistant: "
          }
          conversation_text.write_string(prefix)
          conversation_text.write_string(msg.content)
          conversation_text.write_string("\n\n")
        }

        let summary_prompt : Array[@ai.Message] = [
          {
            role: @ai.Role::User,
            content: "Summarize this conversation concisely, preserving key context, decisions, and any code/technical details that would be needed to continue the conversation. Format as a brief narrative:\n\n" +
            conversation_text.to_string(),
          },
        ]

        let summary_result = Ref::new("")
        client.stream(
          summary_prompt,
          fn(chunk) {
            summary_result.val = summary_result.val + chunk
            streaming.clear()
            ignore(streaming.start_realtime())
            streaming.append("[Compacting...]\n" + summary_result.val)
            do_render()
          },
          fn() {
            // Replace messages with summary
            messages.clear()
            messages.push(
              {
                role: Assistant,
                content: "[Conversation Summary]\n" + summary_result.val,
              },
            )
            streaming.clear()
            input_queue.finish_processing()
            scroll_offset.set(0)
            app.clear_prev_buffer()
            do_render()
          },
          fn(error) {
            streaming.clear()
            add_message(Assistant, "[Compact failed: " + error + "]")
            input_queue.finish_processing()
            do_render()
          },
        )
      }
      None => {
        add_message(Assistant, "[Compact requires API key]")
        do_render()
      }
    }
  }

  // Mutually recursive input handling
  letrec restore_tui_and_send: () -> Unit = fn() {
    let raw = editor_state.get_text()
    let text = raw.trim(chars=" \t\n\r").to_string()
    if text.length() > 0 {
      editor_state.set_text("")
      // Handle slash commands
      if text == "/compact" {
        @tui.print_raw(@render.ansi_full_reset())
        app.clear_prev_buffer()
        editing.set(false)
        do_compact()
        @io.start_keypress_listener(handle_key)
        return
      }
      if text == "/clear" {
        messages.clear()
        scroll_offset.set(0)
        app.clear_prev_buffer()
        @tui.print_raw(@render.ansi_full_reset())
        editing.set(false)
        do_render()
        @io.start_keypress_listener(handle_key)
        return
      }
      if text == "/help" {
        add_message(
          Assistant,
          "Available commands:\n  /compact - Summarize conversation to save context\n  /clear   - Clear all messages\n  /help    - Show this help",
        )
        @tui.print_raw(@render.ansi_full_reset())
        app.clear_prev_buffer()
        editing.set(false)
        do_render()
        @io.start_keypress_listener(handle_key)
        return
      }
      // Normal message
      if input_queue.is_busy() {
        input_queue.enqueue(text)
      } else {
        add_message(User, text)
        send_to_ai()
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
      editor_state.replace_selection(key)
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
          // Escape: go back to sidebar (keep input)
          @tui.KeyEvent::Special(@tui.SpecialKey::Escape, _) => {
            @io.stop_keypress_listener()
            editing.set(false)
            sidebar_focused.set(true)
            @tui.print_raw(@render.ansi_full_reset())
            app.clear_prev_buffer()
            do_render()
            @io.start_keypress_listener(handle_key)
          }
          // Enter without modifier: send message
          @tui.KeyEvent::Special(@tui.SpecialKey::Enter, @tui.KeyModifier::None) =>
            restore_tui_and_send()
          // Other keys: delegate to editor
          _ => {
            @editor.handle_key_event(editor_state, key_event)
            do_render()
          }
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
          // Tab: toggle focus between sidebar and chat
          @tui.KeyEvent::Special(@tui.SpecialKey::Tab, _) => {
            if sidebar_visible.get() {
              let new_focused = not(sidebar_focused.get())
              sidebar_focused.set(new_focused)
              // Load preview when focusing on sidebar
              if new_focused {
                file_tree.load_selected_preview()
                if file_tree.preview_file.length() > 0 {
                  preview_visible.set(true)
                }
                app.clear_prev_buffer()
              }
              do_render()
            }
          }
          // Escape: close preview, unfocus sidebar, or hide sidebar
          @tui.KeyEvent::Special(@tui.SpecialKey::Escape, _) => {
            if preview_visible.get() {
              // Close preview first
              file_tree.clear_preview()
              preview_visible.set(false)
              app.clear_prev_buffer()
              do_render()
            } else if sidebar_focused.get() {
              sidebar_focused.set(false)
              do_render()
            } else if sidebar_visible.get() {
              sidebar_visible.set(false)
              app.clear_prev_buffer()
              do_render()
            }
          }
          // Backslash or 'b': toggle sidebar visibility
          @tui.KeyEvent::Char('b', @tui.KeyModifier::None)
          | @tui.KeyEvent::Char('\\', @tui.KeyModifier::None) => {
            sidebar_visible.set(not(sidebar_visible.get()))
            app.clear_prev_buffer()
            do_render()
          }
          // 'g': toggle git-only mode in sidebar
          @tui.KeyEvent::Char('g', @tui.KeyModifier::None) => {
            if sidebar_focused.get() && file_tree.is_git_repo {
              file_tree.toggle_git_mode()
              app.clear_prev_buffer()
              do_render()
            }
          }
          // 'j': scroll preview down (when preview is visible)
          @tui.KeyEvent::Char('j', @tui.KeyModifier::None) => {
            if preview_visible.get() && file_tree.preview_file.length() > 0 {
              let preview_height = height.val - 2 - 1 // filer_height - header
              file_tree.scroll_preview(1, preview_height)
              do_render()
            }
          }
          // 'k': scroll preview up (when preview is visible)
          @tui.KeyEvent::Char('k', @tui.KeyModifier::None) => {
            if preview_visible.get() && file_tree.preview_file.length() > 0 {
              let preview_height = height.val - 2 - 1 // filer_height - header
              file_tree.scroll_preview(-1, preview_height)
              do_render()
            }
          }
          // Ctrl+Enter: focus input form directly (from sidebar)
          @tui.KeyEvent::Special(@tui.SpecialKey::Enter, @tui.KeyModifier::Ctrl) => {
            if sidebar_focused.get() {
              sidebar_focused.set(false)
              start_editing()
            } else {
              start_editing()
            }
          }
          // Enter: enter directory or select file (in sidebar), or start editing
          @tui.KeyEvent::Special(@tui.SpecialKey::Enter, @tui.KeyModifier::None) => {
            if sidebar_focused.get() {
              // Enter directory or select file
              match file_tree.enter_selected() {
                Some(file_path) => {
                  // Insert file path into input
                  editor_state.replace_selection(file_path)
                  sidebar_focused.set(false)
                  start_editing()
                }
                None => {
                  // Directory entered, clear buffer and refresh
                  app.clear_prev_buffer()
                  do_render()
                }
              }
            } else {
              start_editing()
            }
          }
          @tui.KeyEvent::Char(_, @tui.KeyModifier::None) => {
            if sidebar_focused.get() {
              // In sidebar, ignore character input
              ()
            } else {
              start_editing()
            }
          }
          @tui.KeyEvent::Special(@tui.SpecialKey::Up, _) => {
            if sidebar_focused.get() {
              file_tree.move_selection(-1)
              // Scroll if needed
              if file_tree.selected_idx < file_tree.scroll_offset {
                file_tree.scroll_offset = file_tree.selected_idx
              }
              // Auto-load preview for selected file
              file_tree.load_selected_preview()
              if file_tree.preview_file.length() > 0 {
                preview_visible.set(true)
              }
              app.clear_prev_buffer()
              do_render()
            } else {
              let offset = scroll_offset.get()
              if offset > 0 {
                scroll_offset.set(offset - 1)
              }
              do_render()
            }
          }
          @tui.KeyEvent::Special(@tui.SpecialKey::Down, _) => {
            if sidebar_focused.get() {
              file_tree.move_selection(1)
              // Scroll if needed
              let visible_height = height.val - 4
              if file_tree.selected_idx >= file_tree.scroll_offset + visible_height {
                file_tree.scroll_offset = file_tree.selected_idx - visible_height + 1
              }
              // Auto-load preview for selected file
              file_tree.load_selected_preview()
              if file_tree.preview_file.length() > 0 {
                preview_visible.set(true)
              }
              app.clear_prev_buffer()
              do_render()
            } else {
              let offset = scroll_offset.get()
              let max = max_scroll_offset()
              if offset < max {
                scroll_offset.set(offset + 1)
              }
              do_render()
            }
          }
          @tui.KeyEvent::Special(@tui.SpecialKey::Backspace, _) => {
            // Backspace in sidebar: go to parent directory
            if sidebar_focused.get() {
              file_tree.go_up()
              app.clear_prev_buffer()
              do_render()
            }
          }
          // Left arrow: collapse directory or go to parent (when sidebar focused)
          @tui.KeyEvent::Special(@tui.SpecialKey::Left, _) => {
            if sidebar_focused.get() {
              file_tree.collapse_selected()
              file_tree.load_selected_preview()
              if file_tree.preview_file.length() > 0 {
                preview_visible.set(true)
              } else {
                preview_visible.set(false)
              }
              app.clear_prev_buffer()
              do_render()
            }
          }
          // Right arrow: expand directory, select file, or move to editor (when sidebar focused)
          @tui.KeyEvent::Special(@tui.SpecialKey::Right, _) => {
            if sidebar_focused.get() {
              // If preview is already visible (file selected), move to editor
              if preview_visible.get() && file_tree.preview_file.length() > 0 {
                sidebar_focused.set(false)
                start_editing()
              } else {
                match file_tree.toggle_selected() {
                  Some(file_path) => {
                    // File selected - load preview
                    file_tree.load_preview(file_path)
                    preview_visible.set(true)
                    app.clear_prev_buffer()
                    do_render()
                  }
                  None => {
                    // Directory toggled
                    file_tree.load_selected_preview()
                    if file_tree.preview_file.length() > 0 {
                      preview_visible.set(true)
                    } else {
                      preview_visible.set(false)
                    }
                    app.clear_prev_buffer()
                    do_render()
                  }
                }
              }
            }
          }
          // Ctrl-L: increase sidebar width (when not focused)
          @tui.KeyEvent::Char('l', @tui.KeyModifier::Ctrl) => {
            if sidebar_visible.get() && not(sidebar_focused.get()) {
              let new_width = sidebar_width.get() + 4
              if new_width <= sidebar_max_width {
                sidebar_width.set(new_width)
                app.clear_prev_buffer()
                do_render()
              }
            }
          }
          // Ctrl-H: decrease sidebar width (when not focused)
          @tui.KeyEvent::Char('h', @tui.KeyModifier::Ctrl) => {
            if sidebar_visible.get() && not(sidebar_focused.get()) {
              let new_width = sidebar_width.get() - 4
              if new_width >= sidebar_min_width {
                sidebar_width.set(new_width)
                app.clear_prev_buffer()
                do_render()
              }
            }
          }
          _ => ()
        }
      @tui.InputEvent::Mouse(mouse_event) => {
        // Only handle Press events (not Release to avoid double-trigger)
        match mouse_event.event_type {
          @tui.MouseEventType::Press => {
            // Handle mouse click/scroll in sidebar
            if sidebar_visible.get() {
              match mouse_event.button {
                @tui.MouseButton::Left =>
                  if mouse_event.x < sidebar_width.get() {
                    // Click in sidebar area
                    sidebar_focused.set(true)
                    // Terminal coordinates are 1-indexed, convert to 0-indexed
                    let row = mouse_event.y - 1
                    match file_tree.handle_click(row) {
                      Some(file_path) => {
                        // File was clicked - load preview
                        file_tree.load_preview(file_path)
                        preview_visible.set(true)
                        app.clear_prev_buffer()
                        do_render()
                      }
                      None => {
                        // Directory navigation or toggle happened
                        file_tree.load_selected_preview()
                        if file_tree.preview_file.length() > 0 {
                          preview_visible.set(true)
                        } else {
                          preview_visible.set(false)
                        }
                        app.clear_prev_buffer()
                        do_render()
                      }
                    }
                  } else {
                    // Click in chat/preview area
                    sidebar_focused.set(false)
                    do_render()
                  }
                @tui.MouseButton::ScrollUp => {
                  // Scroll up in preview if visible and in preview area
                  let sw = sidebar_width.get()
                  if preview_visible.get() &&
                    file_tree.preview_file.length() > 0 &&
                    mouse_event.x >= sw {
                    let preview_height = height.val - 2 - 1
                    file_tree.scroll_preview(-3, preview_height)
                    do_render()
                  } else if mouse_event.x < sw {
                    // Scroll in file tree
                    if file_tree.scroll_offset > 0 {
                      file_tree.scroll_offset = file_tree.scroll_offset - 3
                      if file_tree.scroll_offset < 0 {
                        file_tree.scroll_offset = 0
                      }
                      do_render()
                    }
                  }
                }
                @tui.MouseButton::ScrollDown => {
                  // Scroll down in preview if visible and in preview area
                  let sw = sidebar_width.get()
                  if preview_visible.get() &&
                    file_tree.preview_file.length() > 0 &&
                    mouse_event.x >= sw {
                    let preview_height = height.val - 2 - 1
                    file_tree.scroll_preview(3, preview_height)
                    do_render()
                  } else if mouse_event.x < sw {
                    // Scroll in file tree
                    let visible_height = height.val - 4
                    let max_offset = if file_tree.visible_items.length() > visible_height {
                      file_tree.visible_items.length() - visible_height
                    } else {
                      0
                    }
                    file_tree.scroll_offset = file_tree.scroll_offset + 3
                    if file_tree.scroll_offset > max_offset {
                      file_tree.scroll_offset = max_offset
                    }
                    do_render()
                  }
                }
                _ => ()
              }
            }
          }
          _ => ()
        }
      }
      _ => ()
    }
  }

  // Initialize
  @io.start_resize_listener(handle_resize)
  do_render()
  @io.start_keypress_listener(handle_key)
}
