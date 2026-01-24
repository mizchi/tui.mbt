///|
/// TUI Application renderer with reactive signals integration
/// Provides ink-like API for building terminal UIs

///|
/// App manages the render loop and diff-based updates
pub struct App {
  width : Int
  height : Int
  mut prev_buffer : CharBuffer?
  mut last_layout : @types.Layout?
  handlers : @events.EventHandlers
}

///|
pub fn App::new(width : Int, height : Int) -> App {
  {
    width,
    height,
    prev_buffer: None,
    last_layout: None,
    handlers: @events.EventHandlers::new(),
  }
}

///|
/// Render a component tree to ANSI string
pub fn App::render(self : App, component : @core.Component) -> String {
  // Compute layout
  let layout = compute_layout(component.node, self.width, self.height)

  // Save layout for hit testing
  self.last_layout = Some(layout)

  // Create new buffer
  let buf = CharBuffer::new(self.width, self.height)
  render_layout(buf, layout, component.styles, component.texts, 0, 0)

  // Generate output with diff if possible
  let output = match self.prev_buffer {
    Some(prev) => buf.diff_to_ansi(prev)
    None =>
      // First render: clear screen and render full
      // to_ansi already handles cursor positioning, so no need for explicit move
      ansi_clear_screen() + buf.to_ansi()
  }

  // Save current buffer for next diff
  self.prev_buffer = Some(buf)
  output
}

///|
/// Render a component tree with a cursor offset (no screen clear)
pub fn App::render_with_offset(
  self : App,
  component : @core.Component,
  row_offset? : Int = 0,
  col_offset? : Int = 0,
) -> String {
  let layout = compute_layout(component.node, self.width, self.height)
  self.last_layout = Some(layout)
  let buf = CharBuffer::new(self.width, self.height)
  render_layout(buf, layout, component.styles, component.texts, 0, 0)
  let output = match self.prev_buffer {
    Some(prev) => buf.diff_to_ansi_offset(prev, row_offset, col_offset)
    None => buf.to_ansi_offset(row_offset, col_offset)
  }
  self.prev_buffer = Some(buf)
  output
}

///|
/// Render with cursor hidden and positioned at origin
pub fn App::render_frame(self : App, component : @core.Component) -> String {
  ansi_hide_cursor() + self.render(component)
}

///|
/// Create a reactive effect that re-renders when signals change
/// Returns a dispose function
pub fn App::create_render_effect(
  self : App,
  render_fn : () -> @core.Component,
  output_fn : (String) -> Unit,
) -> () -> Unit {
  @signals.render_effect(fn() {
    let component = render_fn()
    let output = self.render_frame(component)
    output_fn(output)
  })
}

///|
/// Initialize terminal (enter alt screen, hide cursor)
pub fn App::init_terminal() -> String {
  ansi_enter_alt_screen() + ansi_hide_cursor() + ansi_clear_screen()
}

///|
/// Restore terminal (show cursor, leave alt screen)
pub fn App::restore_terminal() -> String {
  ansi_show_cursor() + ansi_leave_alt_screen()
}

///|
/// Full-screen app helper: sets up alt screen and handles cleanup
pub fn run_app(
  width : Int,
  height : Int,
  render_fn : () -> @core.Component,
  output_fn : (String) -> Unit,
) -> () -> Unit {
  let app = App::new(width, height)

  // Initialize terminal
  output_fn(App::init_terminal())

  // Create render effect
  let dispose = app.create_render_effect(render_fn, output_fn)

  // Return cleanup function
  fn() {
    dispose()
    output_fn(App::restore_terminal())
  }
}

///|
/// Simple render function for one-shot rendering (no reactivity)
pub fn render_once(
  width : Int,
  height : Int,
  component : @core.Component,
) -> String {
  let app = App::new(width, height)
  app.render(component)
}

///|
/// Register a click handler for a component ID
pub fn App::on_click(self : App, id : String, handler : () -> Unit) -> Unit {
  self.handlers.on_click(id, @events.ClickHandler::new(handler))
}

///|
/// Handle a mouse event
/// Returns true if an event handler was invoked
pub fn App::handle_mouse(self : App, event : @events.MouseEvent) -> Bool {
  match event.event_type {
    @events.MouseEventType::Press =>
      match event.button {
        @events.MouseButton::Left =>
          match self.last_layout {
            Some(layout) =>
              @events.handle_click(layout, self.handlers, event.x, event.y)
            None => false
          }
        _ => false
      }
    _ => false
  }
}

///|
/// Perform hit test at coordinates
pub fn App::hit_test(self : App, x : Int, y : Int) -> @events.HitTestResult? {
  match self.last_layout {
    Some(layout) => @events.hit_test_root(layout, x, y)
    None => None
  }
}

///|
/// Find component by ID
pub fn App::find_by_id(self : App, id : String) -> @events.HitTestResult? {
  match self.last_layout {
    Some(layout) => @events.find_layout_by_id_root(layout, id)
    None => None
  }
}

///|
/// Clear the previous buffer to force a full re-render on next render call
pub fn App::clear_prev_buffer(self : App) -> Unit {
  self.prev_buffer = None
}

///|
/// Dispatch a click event to handlers based on hit test result
/// Returns the clicked component ID if found, None otherwise
pub fn App::dispatch_click(
  self : App,
  event : @events.MouseEvent,
  handlers : Map[String, () -> Unit],
) -> String? {
  // Only handle left click press
  match (event.event_type, event.button) {
    (@events.MouseEventType::Press, @events.MouseButton::Left) =>
      match self.hit_test(event.x, event.y) {
        Some(hit) => {
          match handlers.get(hit.id) {
            Some(handler) => handler()
            None => ()
          }
          Some(hit.id)
        }
        None => None
      }
    _ => None
  }
}

///|
/// Dispatch a click event, returns hit result for custom handling
pub fn App::dispatch_click_with_result(
  self : App,
  event : @events.MouseEvent,
) -> @events.HitTestResult? {
  match (event.event_type, event.button) {
    (@events.MouseEventType::Press, @events.MouseButton::Left) =>
      self.hit_test(event.x, event.y)
    _ => None
  }
}

///|
/// Dispatch a click event using Component's click_handlers
/// Returns the clicked component ID if found and handler was invoked, None otherwise
pub fn App::dispatch_click_from_component(
  self : App,
  event : @events.MouseEvent,
  component : @core.Component,
) -> String? {
  // Only handle left click press
  match (event.event_type, event.button) {
    (@events.MouseEventType::Press, @events.MouseButton::Left) =>
      match self.hit_test(event.x, event.y) {
        Some(hit) => {
          match component.click_handlers.get(hit.id) {
            Some(handler) => handler.invoke()
            None => ()
          }
          Some(hit.id)
        }
        None => None
      }
    _ => None
  }
}
