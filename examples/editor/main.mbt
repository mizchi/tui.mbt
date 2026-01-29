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
fn modifier_has_shift(mod : @tui.KeyModifier) -> Bool {
  match mod {
    Shift => true
    CtrlShift => true
    ShiftAlt => true
    CtrlShiftAlt => true
    _ => false
  }
}

///|
fn modifier_has_ctrl_or_alt(mod : @tui.KeyModifier) -> Bool {
  match mod {
    Ctrl => true
    Alt => true
    CtrlShift => true
    CtrlAlt => true
    ShiftAlt => true
    CtrlShiftAlt => true
    _ => false
  }
}

///|
fn handle_key_event(state : EditorState, key : @tui.KeyEvent) -> Unit {
  match key {
    @tui.KeyEvent::Char(c, mod) => {
      if modifier_has_ctrl_or_alt(mod) {
        ()
      } else if @vnode.is_printable_char(c) {
        state.replace_selection(c.to_string())
      }
    }
    @tui.KeyEvent::Special(special, mod) => {
      let extend = modifier_has_shift(mod)
      match special {
        Left => state.move_left(extend)
        Right => state.move_right(extend)
        Up => state.move_up(extend)
        Down => state.move_down(extend)
        Home => state.move_home(extend)
        End => state.move_end(extend)
        PageUp => state.move_page_up(extend)
        PageDown => state.move_page_down(extend)
        Backspace => state.delete_backward()
        Delete => state.delete_forward()
        Enter => state.replace_selection("\n")
        Tab => state.replace_selection("  ")
        _ => ()
      }
    }
  }
}

///|
fn main {
  let (initial_width, initial_height) = @tui.get_terminal_size()
  let mut width = initial_width
  let mut height = initial_height
  let app = @vnode.VNodeApp::new(width, height)
  let editor_height = if height > 2 { height - 2 } else { 1 }
  let state = EditorState::new(sample_text(), editor_height)

  fn render_ui() -> @vnode.TuiNode {
    render_editor(state, width, height)
  }

  fn do_render() -> Unit {
    @io.print_raw(app.render_frame(render_ui()))
  }

  fn cleanup() -> Unit {
    @io.stop_keypress_listener()
    @io.cleanup_stdin()
    @io.print_raw(@vnode.VNodeApp::restore_terminal())
  }

  fn handle_input(input : String) -> Unit {
    let event = @tui.parse_input(input)
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
      @tui.InputEvent::Resize(new_width, new_height) => {
        width = new_width
        height = new_height
        app.resize(new_width, new_height)
        let h = if new_height > 2 { new_height - 2 } else { 1 }
        state.set_height(h)
        do_render()
      }
      @tui.InputEvent::Key(key_event) => {
        handle_key_event(state, key_event)
        do_render()
      }
      _ => ()
    }
  }

  @io.print_raw(@vnode.VNodeApp::init_terminal())
  do_render()
  @io.start_keypress_listener(handle_input)
}
