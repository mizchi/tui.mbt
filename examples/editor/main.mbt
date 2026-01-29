///|
fn sample_text() -> String {
  let text =
    #|type User = {
    #|  id: number
    #|  name: string
    #|}
    #|
    #|const user: User = { id: 1, name: "mizchi" }
    #|
    #|function greet(name: string): string {
    #|  return `Hello, ${name}`
    #|}
    #|
    #|console.log(greet(user.name))
    #|
  text
}

///|
let completion_candidates : Array[String] = [
  "const",
  "let",
  "function",
  "return",
  "type",
  "interface",
  "string",
  "number",
  "boolean",
  "console",
  "log",
  "user",
  "name",
  "greet",
  "こんにちは",
  "日本語",
]

///|
struct PopupRect {
  row : Int
  col : Int
  width : Int
  height : Int
}

///|
fn filter_candidates(prefix : String) -> Array[String] {
  if prefix.length() == 0 {
    return []
  }
  let lower = prefix.to_lower()
  completion_candidates
  .iter()
  .filter(fn(item) { item.to_lower().has_prefix(lower) })
  .collect()
}

///|
///|
fn main {
  let (initial_width, initial_height) = @term.get_terminal_size()
  let mut width = initial_width
  let mut height = initial_height
  let app = @vnode.VNodeApp::new(width, height)
  let editor_height = if height > 2 { height - 2 } else { 1 }
  let state = @editor.EditorState::new(sample_text(), editor_height)
  let completion_engine = @completion.CompletionEngine::new()
  let max_items = 6
  let suppress_popup : Ref[Bool] = Ref::new(false)
  let last_popup_rect : Ref[PopupRect?] = Ref::new(None)

  fn render_ui() -> @vnode.TuiNode {
    @editor.render_editor(state, width, height)
  }

  fn split_by_chars(text : String, count : Int) -> (String, String) {
    let chars = text.to_array()
    let limit = if count < 0 { 0 } else if count > chars.length() { chars.length() } else { count }
    let head = StringBuilder::new()
    let tail = StringBuilder::new()
    for i = 0; i < chars.length(); i = i + 1 {
      if i < limit {
        head.write_char(chars[i])
      } else {
        tail.write_char(chars[i])
      }
    }
    (head.to_string(), tail.to_string())
  }

  fn popup_width(items : Array[String]) -> Int {
    let mut max_width = 0
    for item in items {
      let w = @core.string_display_width(item)
      if w > max_width {
        max_width = w
      }
    }
    if max_width < 4 { 4 } else { max_width }
  }

  fn pad_to_width(text : String, width : Int) -> String {
    if width <= 0 {
      ""
    } else {
      let w = @core.string_display_width(text)
      if w >= width {
        text
      } else {
        text + " ".repeat(width - w)
      }
    }
  }

  fn render_popup_item(
    item : String,
    idx : Int,
    prefix : String,
    width : Int,
  ) -> @vnode.TuiNode {
    let is_selected = idx == completion_engine.get_selected_idx()
    let bg = if is_selected { "rgb(30,80,120)" } else { "rgb(60,60,60)" }
    let prefix_len = prefix.to_array().length()
    let (head, tail) = split_by_chars(item, prefix_len)
    let suffix_width = width - @core.string_display_width(head)
    let suffix = pad_to_width(tail, suffix_width)
    let fg_suffix = if is_selected { "white" } else { "rgb(150,150,150)" }
    @vnode.row(bg~, [
      @vnode.text(head, fg="cyan", bold=is_selected),
      @vnode.text(suffix, fg=fg_suffix),
    ])
  }

  fn render_completion_popup(items : Array[String], width : Int) -> @vnode.TuiNode {
    if items.length() == 0 {
      return @vnode.text("")
    }
    let count = if items.length() > max_items { max_items } else { items.length() }
    let prefix = completion_engine.get_input()
    let nodes : Array[@vnode.TuiNode] = []
    for i = 0; i < count; i = i + 1 {
      nodes.push(render_popup_item(items[i], i, prefix, width))
    }
    @vnode.column(nodes)
  }

  fn popup_height(items : Array[String]) -> Int {
    if items.length() > max_items { max_items } else { items.length() }
  }

  fn update_completion() -> Unit {
    let prefix = state.current_word_prefix()
    let _ = completion_engine.set_input(prefix)
    if prefix.length() == 0 {
      completion_engine.clear()
      return
    }
    let items = filter_candidates(prefix)
    completion_engine.set_items(items)
  }

  fn apply_completion() -> Bool {
    match completion_engine.get_selected_item() {
      Some(word) => {
        state.replace_current_word(word)
        update_completion()
        true
      }
      None => false
    }
  }

  fn rect_equal(a : PopupRect, b : PopupRect) -> Bool {
    a.row == b.row &&
    a.col == b.col &&
    a.width == b.width &&
    a.height == b.height
  }

  fn clear_rect(rect : PopupRect) -> Unit {
    for i = 0; i < rect.height; i = i + 1 {
      @term.print_raw(
        @render.ansi_move_to(rect.row + i, rect.col) +
        " ".repeat(rect.width),
      )
    }
  }

  fn do_render() -> Unit {
    let items = completion_engine.get_items()
    let show_popup =
      not(suppress_popup.val) &&
      completion_engine.is_visible() &&
      items.length() > 0
    let caret_line = state.caret_line()
    let (cursor_row, cursor_col) = @editor.editor_cursor_position(
      state,
      width,
      height,
    )
    let (word_start, _) = state.current_word_bounds()
    let (anchor_row, anchor_col) = @editor.editor_position_for(
      state,
      width,
      height,
      caret_line,
      word_start,
    )

    let next_rect = if show_popup {
      let popup_h = popup_height(items)
      let raw_width = popup_width(items)
      let popup_w = if raw_width > width { width } else { raw_width }
      let below = anchor_row + 1
      let popup_row = if below + popup_h <= height { below } else { anchor_row - popup_h }
      let popup_col = if anchor_col + popup_w <= width { anchor_col } else { width - popup_w }
      let safe_row = if popup_row < 0 { 0 } else { popup_row }
      let safe_col = if popup_col < 0 { 0 } else { popup_col }
      Some(PopupRect::{
        row: safe_row,
        col: safe_col,
        width: popup_w,
        height: popup_h,
      })
    } else {
      None
    }
    let mut need_clear = false
    match (last_popup_rect.val, next_rect) {
      (Some(prev), Some(next)) =>
        if not(rect_equal(prev, next)) {
          clear_rect(prev)
          need_clear = true
        }
      (Some(prev), None) => {
        clear_rect(prev)
        need_clear = true
      }
      _ => ()
    }
    if need_clear {
      app.clear_prev_buffer()
    }
    let frame = app.render_frame(render_ui())
    @term.print_raw(frame)

    match next_rect {
      Some(rect) => {
        let popup = render_completion_popup(items, rect.width)
        @term.print_raw(@vnode.render_overlay_at(rect.col, rect.row, popup))
        last_popup_rect.val = Some(rect)
      }
      None => last_popup_rect.val = None
    }

    @term.print_raw(
      @render.ansi_move_to(cursor_row, cursor_col) +
      @render.ansi_show_cursor(),
    )
  }

  fn cleanup() -> Unit {
    @term.stop_keypress_listener()
    @term.cleanup_stdin()
    @term.print_raw(@vnode.VNodeApp::restore_terminal())
  }

  fn handle_input(input : String) -> Unit {
    if input.length() > 1 &&
      input[0].to_int() != 0x1b &&
      @vnode.is_printable_string(input) {
      state.replace_selection(input)
      suppress_popup.val = false
      update_completion()
      do_render()
      return
    }
    let event = @term.parse_input(input)
    if event.is_ctrl_c() || event.is_escape() {
      cleanup()
      return
    }
    if event.is_scroll_up() {
      state.scroll_view(-3)
      do_render()
      return
    }
    if event.is_scroll_down() {
      state.scroll_view(3)
      do_render()
      return
    }
    match event {
      @term.InputEvent::Resize(new_width, new_height) => {
        width = new_width
        height = new_height
        app.resize(new_width, new_height)
        let h = if new_height > 2 { new_height - 2 } else { 1 }
        state.set_height(h)
        do_render()
      }
      @term.InputEvent::Key(key_event) => {
        match key_event {
          @term.KeyEvent::Special(@term.SpecialKey::Up, _) =>
            if completion_engine.is_visible() && not(suppress_popup.val) {
              completion_engine.select_prev()
              do_render()
              return
            }
          @term.KeyEvent::Special(@term.SpecialKey::Down, _) =>
            if completion_engine.is_visible() && not(suppress_popup.val) {
              completion_engine.select_next()
              do_render()
              return
            }
          @term.KeyEvent::Special(@term.SpecialKey::Tab, _) =>
            if completion_engine.is_visible() && not(suppress_popup.val) {
              if apply_completion() {
                do_render()
                return
              }
            }
          @term.KeyEvent::Special(@term.SpecialKey::Enter, _) =>
            if completion_engine.is_visible() && not(suppress_popup.val) {
              if apply_completion() {
                do_render()
                return
              }
            }
          @term.KeyEvent::Special(@term.SpecialKey::Backspace, _) =>
            suppress_popup.val = true
          @term.KeyEvent::Char(_, @term.KeyModifier::None)
          | @term.KeyEvent::Char(_, @term.KeyModifier::Shift) =>
            suppress_popup.val = false
          _ => ()
        }
        @editor.handle_key_event(state, key_event)
        update_completion()
        do_render()
      }
      _ => ()
    }
  }

  @term.print_raw(@vnode.VNodeApp::init_terminal())
  update_completion()
  do_render()
  @term.start_keypress_listener(handle_input)
}
