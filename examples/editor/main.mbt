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
  let completion_popup = @editor.CompletionPopup::new(completion_session)
  let suppress_popup : Ref[Bool] = Ref::new(false)
  let last_popup_rect : Ref[@editor.PopupRect?] = Ref::new(None)
  let completion_request_id : Ref[Int] = Ref::new(0)

  fn render_ui() -> @vnode.TuiNode {
    @editor.render_editor(state, width, height)
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

  fn clear_rect(rect : @editor.PopupRect) -> Unit {
    for i = 0; i < rect.height; i = i + 1 {
      @term.print_raw(
        @render.ansi_move_to(rect.row + i, rect.col) +
        " ".repeat(rect.width),
      )
    }
  }

  fn do_render() -> Unit {
    let (cursor_row, cursor_col) = @editor.editor_cursor_position(
      state,
      width,
      height,
    )

    let next_rect : @editor.PopupRect? = if suppress_popup.val {
      None
    } else {
      match completion_popup.render_overlay(state, width, height) {
        Some((_, rect)) => Some(rect)
        None => None
      }
    }

    let mut need_clear = false
    match (last_popup_rect.val, next_rect) {
      (Some(prev), Some(next)) =>
        if not(prev.eq(next)) {
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

    if not(suppress_popup.val) {
      match completion_popup.render_overlay(state, width, height) {
        Some((overlay, rect)) => {
          @term.print_raw(overlay)
          last_popup_rect.val = Some(rect)
        }
        None => last_popup_rect.val = None
      }
    } else {
      last_popup_rect.val = None
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
