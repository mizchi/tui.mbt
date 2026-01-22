///|
/// Inplace text editor prototype (generalized input demo)

///|
fn main {
  let (cols, rows) = @io.get_terminal_size()
  let width : Ref[Int] = { val: cols }
  let height : Ref[Int] = { val: rows }

  let editing = @signals.signal(false)
  let text_value = @signals.signal("")

  let app : Ref[@render.App] = { val: @render.App::new(cols, rows) }

  fn editor_box_size() -> (Int, Int) {
    let header_lines = 1
    let footer_lines = 1
    let raw_height = height.val - header_lines - footer_lines
    let box_height = if raw_height > 1 { raw_height } else { 1 }
    (width.val, box_height)
  }

  fn render_ui() -> @core.Component {
    let (box_width, box_height) = editor_box_size()
    let fg = @core.Color::white()
    let value = text_value.get()
    let state = if editing.get() {
      @c.TextareaState::Editing
    } else {
      @c.TextareaState::Idle
    }
    let header = @c.row(
      [@c.text("Editor Prototype", fg=@core.Color::yellow(), bold=true)],
      justify=@types.Alignment::Center,
    )
    let editor_box = @c.multiline_input(
      value,
      id="editor-box",
      rows=box_height,
      placeholder="Press Enter to edit",
      state~,
      width=@types.Dimension::Length(box_width.to_double()),
      padding_x=1.0,
      padding_y=0.0,
      fg~,
    )
    let footer_text = if editing.get() {
      "Editing: Shift+Enter newline | Enter confirm | Esc cancel"
    } else {
      "Enter: edit | q: quit | Ctrl+C: quit"
    }
    let footer = @c.row(
      [@c.text(footer_text, fg=@core.Color::rgb(120, 120, 120))],
      justify=@types.Alignment::Center,
    )
    @c.column(
      [header, editor_box, footer],
      width=@types.Dimension::Length(width.val.to_double()),
      height=@types.Dimension::Length(height.val.to_double()),
      justify=@types.Alignment::Start,
      align=@types.Alignment::Start,
    )
  }

  fn do_render() -> Unit {
    @io.print_raw(app.val.render_frame(render_ui()))
  }

  fn do_quit() -> Unit {
    @io.stop_keypress_listener()
    @io.stop_resize_listener()
    @io.cleanup_stdin()
    @io.print_raw(@render.App::restore_terminal())
    println("Goodbye!")
  }

  fn handle_resize(new_width : Int, new_height : Int) -> Unit {
    width.val = new_width
    height.val = new_height
    app.val = @render.App::new(new_width, new_height)
    @io.print_raw(@render.ansi_clear_screen())
    do_render()
  }

  letrec restore_tui: () -> Unit = fn() {
    @io.print_raw(@render.ansi_full_reset())
    app.val.clear_prev_buffer()
    editing.set(false)
    do_render()
    @io.start_resize_listener(handle_resize)
    @io.start_keypress_listener(handle_key)
  }
  and start_editing: () -> Unit = fn() {
    editing.set(true)
    do_render()
    match app.val.find_by_id("editor-box") {
      Some(bounds) => {
        let config = @c.EditConfig::{
          field_name: "Editor",
          on_change: fn(value) { text_value.set(value) },
          on_edit_start: Some(fn() {
            @io.stop_keypress_listener()
            @io.stop_resize_listener()
          }),
          on_edit_end: Some(fn() { editing.set(false) }),
          on_force_quit: Some(fn() { do_quit() }),
        }
        @c.start_edit_inplace_in_bounds(
          config,
          text_value.get(),
          bounds,
          true,
          restore_tui,
        )
      }
      None => {
        editing.set(false)
        do_render()
      }
    }
  }
  and handle_key: (String) -> Unit = fn(key) {
    if key.length() == 0 {
      return
    }
    let event = @events.parse_input(key)
    match event {
      @events.InputEvent::Key(key_event) =>
        match key_event {
          @events.KeyEvent::Char('c', @events.KeyModifier::Ctrl) => do_quit()
          @events.KeyEvent::Char('q', @events.KeyModifier::None) => do_quit()
          @events.KeyEvent::Special(@events.SpecialKey::Enter, _) => {
            start_editing()
          }
          @events.KeyEvent::Char('e', @events.KeyModifier::None) =>
            start_editing()
          _ => ()
        }
      _ => ()
    }
  }

  @io.print_raw(@render.App::init_terminal())
  do_render()
  @io.start_resize_listener(handle_resize)
  @io.start_keypress_listener(handle_key)
}
