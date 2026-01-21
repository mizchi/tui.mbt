///|
/// Simple Text Editor Example

///|
fn main {
  let (cols, rows) = @io.get_terminal_size()
  let width = cols
  let height = rows

  // State
  let running = @signals.signal(true)
  let editor_state = @signals.signal(@components.EditorState::new())
  let message = @signals.signal("Press q to quit | Ctrl+S to save")
  let app = @render.App::new(width, height)

  fn render_ui() -> @core.Component {
    let state = editor_state.get()
    let fg = @core.Color::white()
    let bg = @core.Color::rgb(20, 20, 25)
    let gutter_bg = @core.Color::rgb(30, 30, 35)
    let selection_fg = @core.Color::white()
    let selection_bg = @core.Color::rgb(40, 80, 120)
    let line_fg = @core.Color::rgb(200, 200, 200)
    let line_bg = @core.Color::transparent()
    let cursor_fg = @core.Color::rgb(20, 20, 25)
    let cursor_bg = @core.Color::white()
    
    @c.column(
      [
        @components.editor(
          state,
          "editor",
          fg,
          bg,
          gutter_bg,
          selection_fg,
          selection_bg,
          line_fg,
          line_bg,
          cursor_fg,
          cursor_bg,
          60.0,
          20.0,
          true,
          message.get(),
        ),
      ],
      width=@types.Dimension::Length(width.to_double()),
      height=@types.Dimension::Length(height.to_double()),
    )
  }

  fn do_render() -> Unit {
    @io.print_raw(app.render_frame(render_ui()))
  }

  fn do_quit() -> Unit {
    running.set(false)
    @io.stop_keypress_listener()
    @io.print_raw(@render.disable_mouse())
    @io.cleanup_stdin()
    @io.print_raw(@render.App::restore_terminal())
    println("Goodbye!")
  }

  fn handle_key(key : String) -> Unit {
    if key.length() == 0 {
      return
    }
    let event = @events.parse_input(key)
    match event {
      @events.InputEvent::Key(key_event) =>
        match key_event {
          @events.KeyEvent::Char('q', @events.KeyModifier::None) => {
            do_quit()
            return
          }
          @events.KeyEvent::Char('c', @events.KeyModifier::Ctrl) => {
            do_quit()
            return
          }
          @events.KeyEvent::Special(@events.SpecialKey::Escape, _) => {
            do_quit()
            return
          }
          // Character input
          @events.KeyEvent::Char(ch, @events.KeyModifier::None) => {
            let state = editor_state.get()
            let new_buffer = state.buffer.insert_char(ch)
            editor_state.set(@components.EditorState::{ buffer: new_buffer, modified: true, ..state })
            message.set("Inserted: " + ch.to_string())
          }
          // Backspace
          @events.KeyEvent::Special(@events.SpecialKey::Backspace, _) => {
            let state = editor_state.get()
            let new_buffer = state.buffer.delete_backwards()
            editor_state.set(@components.EditorState::{ buffer: new_buffer, modified: true, ..state })
            message.set("Deleted character")
          }
          // Enter - insert newline
          @events.KeyEvent::Special(@events.SpecialKey::Enter, _) => {
            let state = editor_state.get()
            let new_buffer = state.buffer.insert_newline()
            editor_state.set(@components.EditorState::{ buffer: new_buffer, modified: true, ..state })
            message.set("Inserted newline")
          }
          // Arrow keys
          @events.KeyEvent::Special(@events.SpecialKey::Left, _) => {
            let state = editor_state.get()
            let new_buffer = state.buffer.move_to(state.buffer.cursor.row, (state.buffer.cursor.col - 1).max(1))
            editor_state.set(@components.EditorState::{ buffer: new_buffer, ..state })
          }
          @events.KeyEvent::Special(@events.SpecialKey::Right, _) => {
            let state = editor_state.get()
            let new_buffer = state.buffer.move_to(state.buffer.cursor.row, state.buffer.cursor.col + 1)
            editor_state.set(@components.EditorState::{ buffer: new_buffer, ..state })
          }
          @events.KeyEvent::Special(@events.SpecialKey::Up, _) => {
            let state = editor_state.get()
            let new_buffer = state.buffer.move_to((state.buffer.cursor.row - 1).max(1), state.buffer.cursor.col)
            editor_state.set(@components.EditorState::{ buffer: new_buffer, ..state })
          }
          @events.KeyEvent::Special(@events.SpecialKey::Down, _) => {
            let state = editor_state.get()
            let new_buffer = state.buffer.move_to(state.buffer.cursor.row + 1, state.buffer.cursor.col)
            editor_state.set(@components.EditorState::{ buffer: new_buffer, ..state })
          }
          @events.KeyEvent::Char('s', @events.KeyModifier::Ctrl) => {
            let state = editor_state.get()
            let text = state.buffer.to_string()
            message.set("Saved: " + state.filename + " (" + text.length().to_string() + " chars)")
          }
          _ => ()
        }
      @events.InputEvent::Mouse(mouse_event) => {
        message.set("Mouse: " + mouse_event.x.to_string() + "," + mouse_event.y.to_string())
      }
    }
    do_render()
  }

  // Initialize
  @io.print_raw(@render.App::init_terminal())
  do_render()
  @io.start_keypress_listener(handle_key)
}
