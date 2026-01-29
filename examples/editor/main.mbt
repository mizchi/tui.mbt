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
///|
fn main {
  let (initial_width, initial_height) = @term.get_terminal_size()
  let mut width = initial_width
  let mut height = initial_height
  let app = @vnode.VNodeApp::new(width, height)
  let editor_height = if height > 2 { height - 2 } else { 1 }
  let state = @editor.EditorState::new(sample_text(), editor_height)

  fn render_ui() -> @vnode.TuiNode {
    @editor.render_editor(state, width, height)
  }

  fn do_render() -> Unit {
    @term.print_raw(app.render_frame(render_ui()))
  }

  fn cleanup() -> Unit {
    @term.stop_keypress_listener()
    @term.cleanup_stdin()
    @term.print_raw(@vnode.VNodeApp::restore_terminal())
  }

  fn handle_input(input : String) -> Unit {
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
        @editor.handle_key_event(state, key_event)
        do_render()
      }
      _ => ()
    }
  }

  @term.print_raw(@vnode.VNodeApp::init_terminal())
  do_render()
  @term.start_keypress_listener(handle_input)
}
