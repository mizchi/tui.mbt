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
extern "js" fn js_read_file(path : String) -> String? =
  #|(path) => {
  #|  try {
  #|    const fs = require('fs');
  #|    return fs.readFileSync(path, 'utf8');
  #|  } catch (e) {
  #|    return null;
  #|  }
  #|}

///|
extern "js" fn js_get_args() -> Array[String] =
  #|() => {
  #|  return process.argv.slice(2);
  #|}

///|
fn load_file_or_sample() -> (String, String) {
  let args = js_get_args()
  if args.length() > 0 {
    let filename = args[0]
    match js_read_file(filename) {
      Some(content) => (content, filename)
      None => {
        println("Failed to read file: \{filename}")
        (sample_text(), "sample.ts")
      }
    }
  } else {
    (sample_text(), "sample.ts")
  }
}

///|
fn main {
  let (initial_width, initial_height) = @term.get_terminal_size()
  let mut width = initial_width
  let mut height = initial_height
  let app = @vnode.VNodeApp::new(width, height)
  let editor_height = if height > 2 { height - 2 } else { 1 }
  let (text, filename) = load_file_or_sample()
  let state = @editor.EditorState::new_with_filename(text, editor_height, filename)
  let completion_session = @editor.CompletionSession::new()
  let max_items = 6
  let suppress_popup : Ref[Bool] = Ref::new(false)
  let last_popup_rect : Ref[PopupRect?] = Ref::new(None)
  let completion_request_id : Ref[Int] = Ref::new(0)

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

  fn popup_width(items : Array[@editor.CompletionItem]) -> Int {
    let mut max_width = 0
    for item in items {
      let w = @core.string_display_width(item.label)
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
    item : @editor.CompletionItem,
    idx : Int,
    prefix : String,
    width : Int,
  ) -> @vnode.TuiNode {
    let is_selected = idx == completion_session.get_selected_index()
    let bg = if is_selected { "rgb(30,80,120)" } else { "rgb(60,60,60)" }
    let prefix_len = prefix.to_array().length()
    let label = item.label
    let (head, tail) = split_by_chars(label, prefix_len)
    let suffix_width = width - @core.string_display_width(head)
    let suffix = pad_to_width(tail, suffix_width)
    let fg_suffix = if is_selected { "white" } else { "rgb(150,150,150)" }
    @vnode.row(bg~, [
      @vnode.text(head, fg="cyan", bold=is_selected),
      @vnode.text(suffix, fg=fg_suffix),
    ])
  }

  fn render_completion_popup(
    items : Array[@editor.CompletionItem],
    width : Int,
    prefix : String,
  ) -> @vnode.TuiNode {
    if items.length() == 0 {
      return @vnode.text("")
    }
    let count = if items.length() > max_items { max_items } else { items.length() }
    let nodes : Array[@vnode.TuiNode] = []
    for i = 0; i < count; i = i + 1 {
      nodes.push(render_popup_item(items[i], i, prefix, width))
    }
    @vnode.column(nodes)
  }

  fn popup_height(items : Array[@editor.CompletionItem]) -> Int {
    if items.length() > max_items { max_items } else { items.length() }
  }

  fn update_completion() -> Unit {
    let next_id = completion_request_id.val + 1
    completion_request_id.val = next_id
    let req = state.completion_request(next_id)
    if req.prefix.length() == 0 {
      completion_session.clear()
      return
    }
    completion_session.set_request(req)
    let items = filter_candidates(req.prefix)
    let response : @editor.CompletionResponse = {
      id: req.id,
      items: items.map(fn(item) {
        @editor.CompletionItem::{
          label: item,
          insert_text: item,
          detail: None,
          documentation: None,
        }
      }),
      is_incomplete: false,
    }
    let _ = completion_session.apply_response(response)
    if items.length() == 1 && items[0] == req.prefix {
      completion_session.hide()
    }
  }

  fn apply_completion() -> Bool {
    match completion_session.get_selected_item() {
      Some(item) => {
        state.replace_current_word(item.insert_text)
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
    let items = completion_session.get_items()
    let show_popup =
      not(suppress_popup.val) &&
      completion_session.is_visible() &&
      items.length() > 0
    let (cursor_row, cursor_col) = @editor.editor_cursor_position(
      state,
      width,
      height,
    )
    let prefix = if show_popup { state.current_word_prefix() } else { "" }
    let (anchor_row, anchor_col) = if show_popup {
      let anchor = completion_session.get_anchor()
      @editor.editor_position_for(
        state,
        width,
        height,
        anchor.line,
        anchor.col,
      )
    } else {
      (0, 0)
    }

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
        let popup = render_completion_popup(items, rect.width, prefix)
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
        let mut should_update_completion = false
        match key_event {
          @term.KeyEvent::Special(@term.SpecialKey::Up, _) =>
            if completion_session.is_visible() && not(suppress_popup.val) {
              completion_session.select_prev()
              do_render()
              return
            }
          @term.KeyEvent::Special(@term.SpecialKey::Down, _) =>
            if completion_session.is_visible() && not(suppress_popup.val) {
              completion_session.select_next()
              do_render()
              return
            }
          @term.KeyEvent::Special(@term.SpecialKey::Tab, _) =>
            if completion_session.is_visible() && not(suppress_popup.val) {
              if apply_completion() {
                do_render()
                return
              }
            }
          @term.KeyEvent::Special(@term.SpecialKey::Enter, _) =>
            if completion_session.is_visible() && not(suppress_popup.val) {
              if apply_completion() {
                do_render()
                return
              }
            }
          @term.KeyEvent::Special(@term.SpecialKey::Backspace, _) => {
            suppress_popup.val = true
            should_update_completion = true
          }
          @term.KeyEvent::Char(_, @term.KeyModifier::None)
          | @term.KeyEvent::Char(_, @term.KeyModifier::Shift) => {
            suppress_popup.val = false
            should_update_completion = true
          }
          _ => ()
        }
        @editor.handle_key_event(state, key_event)
        if should_update_completion {
          update_completion()
        }
        do_render()
      }
      _ => ()
    }
  }

  @term.print_raw(@vnode.VNodeApp::init_terminal())
  do_render()
  @term.start_keypress_listener(handle_input)
}
