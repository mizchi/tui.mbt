///|
/// VNode-based TUI Application renderer
/// Provides efficient rendering pipeline: TuiNode -> crater -> CharBuffer -> ANSI

///|
/// VNodeApp manages the vnode render loop with diff-based updates
pub struct VNodeApp {
  mut width : Int
  mut height : Int
  mut prev_buffer : @render.CharBuffer?
  mut last_layout : @types.Layout?
  mut overlay_layouts : Array[@types.Layout]
  mut render_ctx : RenderContext
}

///|
pub fn VNodeApp::new(width : Int, height : Int) -> VNodeApp {
  {
    width,
    height,
    prev_buffer: None,
    last_layout: None,
    overlay_layouts: [],
    render_ctx: RenderContext::new(),
  }
}

///|
/// Reset the render context for a new frame
fn VNodeApp::reset_context(self : VNodeApp) -> Unit {
  self.render_ctx = RenderContext::new()
}

///|
/// Render a vnode tree to ANSI string
pub fn VNodeApp::render(self : VNodeApp, root : TuiNode) -> String {
  // Reset context for new render
  self.reset_context()

  // Convert vnode to crater node
  let crater_node = to_crater_node(self.render_ctx, root)

  // Compute layout
  let layout = @render.compute_layout(crater_node, self.width, self.height)

  // Save layout for hit testing
  self.last_layout = Some(layout)

  // Create style map from render context
  let styles = @core.RenderStyleMap::new()
  for entry in self.render_ctx.styles {
    styles.set(entry.0, entry.1)
  }

  // Create text map from render context
  let texts = @core.TextContentMap::new()
  for entry in self.render_ctx.texts {
    texts.set(entry.0, entry.1)
  }

  // Create new buffer
  let buf = @render.CharBuffer::new(self.width, self.height)
  @render.render_layout(buf, layout, styles, texts, 0, 0)

  // Generate output with diff if possible
  let output = match self.prev_buffer {
    Some(prev) => buf.diff_to_ansi(prev)
    None =>
      // First render: clear screen and render full
      @render.ansi_clear_screen() + buf.to_ansi()
  }

  // Save current buffer for next diff
  self.prev_buffer = Some(buf)
  output
}

///|
/// Render main content with overlay layers on top
pub fn VNodeApp::render_with_overlays(
  self : VNodeApp,
  main : TuiNode,
  overlays : Array[OverlayEntry],
) -> String {
  // Reset context for new render
  self.reset_context()
  self.overlay_layouts = []

  // Convert main vnode to crater node
  let crater_node = to_crater_node(self.render_ctx, main)

  // Compute layout
  let layout = @render.compute_layout(crater_node, self.width, self.height)

  // Save layout for hit testing
  self.last_layout = Some(layout)

  // Create style map from render context
  let styles = @core.RenderStyleMap::new()
  for entry in self.render_ctx.styles {
    styles.set(entry.0, entry.1)
  }

  // Create text map from render context
  let texts = @core.TextContentMap::new()
  for entry in self.render_ctx.texts {
    texts.set(entry.0, entry.1)
  }

  // Create buffer and render main content (1st pass)
  let buf = @render.CharBuffer::new(self.width, self.height)
  @render.render_layout(buf, layout, styles, texts, 0, 0)

  // Render each overlay (2nd+ pass)
  for overlay in overlays {
    // Draw backdrop if requested
    if overlay.backdrop {
      buf.fill_bg(0, 0, self.width, self.height, @core.Color::rgb(0, 0, 0))
    }

    // Create a new render context for the overlay
    let overlay_ctx = RenderContext::new()
    let overlay_crater = to_crater_node(overlay_ctx, overlay.node)
    let overlay_layout = @render.compute_layout(
      overlay_crater,
      self.width,
      self.height,
    )

    // Calculate offset based on position
    let overlay_w = overlay_layout.width.to_int()
    let overlay_h = overlay_layout.height.to_int()
    let (offset_x, offset_y) = match overlay.position {
      PopupPosition::Center =>
        ((self.width - overlay_w) / 2, (self.height - overlay_h) / 2)
      PopupPosition::Top => ((self.width - overlay_w) / 2, 0)
      PopupPosition::Bottom =>
        ((self.width - overlay_w) / 2, self.height - overlay_h)
      PopupPosition::At(x, y) => (x, y)
    }

    // Build style/text maps for overlay
    let overlay_styles = @core.RenderStyleMap::new()
    for entry in overlay_ctx.styles {
      overlay_styles.set(entry.0, entry.1)
    }
    let overlay_texts = @core.TextContentMap::new()
    for entry in overlay_ctx.texts {
      overlay_texts.set(entry.0, entry.1)
    }

    // Render overlay onto the same buffer
    @render.render_layout(
      buf, overlay_layout, overlay_styles, overlay_texts, offset_x, offset_y,
    )

    // Merge handlers into main render context
    for entry in overlay_ctx.handlers {
      self.render_ctx.handlers[entry.0] = entry.1
    }
    for entry in overlay_ctx.roles {
      self.render_ctx.roles[entry.0] = entry.1
    }

    // Save overlay layout with offset applied
    self.overlay_layouts.push({
      ..overlay_layout,
      x: overlay_layout.x + offset_x.to_double(),
      y: overlay_layout.y + offset_y.to_double(),
    })
  }

  // Generate output with diff if possible
  let output = match self.prev_buffer {
    Some(prev) => buf.diff_to_ansi(prev)
    None => @render.ansi_clear_screen() + buf.to_ansi()
  }

  // Save current buffer for next diff
  self.prev_buffer = Some(buf)
  output
}

///|
/// Render with overlays and cursor hidden
pub fn VNodeApp::render_frame_with_overlays(
  self : VNodeApp,
  main : TuiNode,
  overlays : Array[OverlayEntry],
) -> String {
  @render.ansi_hide_cursor() + self.render_with_overlays(main, overlays)
}

///|
/// Render with cursor hidden and positioned at origin
pub fn VNodeApp::render_frame(self : VNodeApp, root : TuiNode) -> String {
  @render.ansi_hide_cursor() + self.render(root)
}

///|
/// Create a reactive effect that re-renders when signals change
/// Returns a dispose function
pub fn VNodeApp::create_render_effect(
  self : VNodeApp,
  render_fn : () -> TuiNode,
  output_fn : (String) -> Unit,
) -> () -> Unit {
  @signals.render_effect(fn() {
    let node = render_fn()
    let output = self.render_frame(node)
    output_fn(output)
  })
}

///|
/// Initialize terminal (enter alt screen, hide cursor)
pub fn VNodeApp::init_terminal() -> String {
  @render.ansi_enter_alt_screen() +
  @render.ansi_hide_cursor() +
  @render.ansi_clear_screen()
}

///|
/// Restore terminal (show cursor, leave alt screen)
pub fn VNodeApp::restore_terminal() -> String {
  @render.ansi_show_cursor() + @render.ansi_leave_alt_screen()
}

///|
/// Perform hit test at coordinates
/// Checks overlays first (top-most layer) before main layout
pub fn VNodeApp::hit_test(
  self : VNodeApp,
  x : Int,
  y : Int,
) -> @events.HitTestResult? {
  // Check overlays in reverse order (top-most first)
  let len = self.overlay_layouts.length()
  for i = len - 1; i >= 0; i = i - 1 {
    let result = @events.hit_test_root(self.overlay_layouts[i], x, y)
    if result is Some(_) {
      return result
    }
  }
  match self.last_layout {
    Some(layout) => @events.hit_test_root(layout, x, y)
    None => None
  }
}

///|
/// Find component by ID
pub fn VNodeApp::find_by_id(
  self : VNodeApp,
  id : String,
) -> @events.HitTestResult? {
  match self.last_layout {
    Some(layout) => @events.find_layout_by_id_root(layout, id)
    None => None
  }
}

///|
/// Get all layout rects from the last render (absolute coordinates).
pub fn VNodeApp::layout_rects(self : VNodeApp) -> Array[@events.HitTestResult] {
  match self.last_layout {
    Some(layout) => @events.layout_rects_root(layout)
    None => []
  }
}

///|
/// Get accessibility tree from the last render.
pub fn VNodeApp::a11y_tree(self : VNodeApp) -> Array[A11yNode] {
  match self.last_layout {
    Some(layout) => build_a11y_tree(layout, self.render_ctx)
    None => []
  }
}

///|
/// Debug: dump accessibility tree structure.
pub fn VNodeApp::dump_a11y_tree(self : VNodeApp) -> String {
  dump_a11y_tree(self.a11y_tree())
}

///|
/// Handle a mouse event using the render context's handlers
/// Returns the clicked component ID if found and handler was invoked
pub fn VNodeApp::handle_click(
  self : VNodeApp,
  event : @events.MouseEvent,
) -> String? {
  match (event.event_type, event.button) {
    (@events.MouseEventType::Press, @events.MouseButton::Left) =>
      match self.hit_test(event.x, event.y) {
        Some(hit) => {
          match self.render_ctx.handlers.get(hit.id) {
            Some(handler) =>
              handler(
                TuiEvent::Click(x=event.x, y=event.y, button=MouseButton::Left),
              )
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
/// Clear the previous buffer to force a full re-render on next render call
pub fn VNodeApp::clear_prev_buffer(self : VNodeApp) -> Unit {
  self.prev_buffer = None
}

///|
/// Resize the render target and force a full redraw on next render.
pub fn VNodeApp::resize(self : VNodeApp, width : Int, height : Int) -> Unit {
  self.width = width
  self.height = height
  self.clear_prev_buffer()
}

///|
/// Full-screen vnode app helper: sets up alt screen and handles cleanup
pub fn run_vnode_app(
  width : Int,
  height : Int,
  render_fn : () -> TuiNode,
  output_fn : (String) -> Unit,
) -> () -> Unit {
  let app = VNodeApp::new(width, height)

  // Initialize terminal
  output_fn(VNodeApp::init_terminal())

  // Create render effect
  let dispose = app.create_render_effect(render_fn, output_fn)

  // Return cleanup function
  fn() {
    dispose()
    output_fn(VNodeApp::restore_terminal())
  }
}

///|
/// Initialize a VNodeApp with terminal setup and return a cleanup function.
pub fn init_vnode_terminal(
  width : Int,
  height : Int,
  output_fn : (String) -> Unit,
  mouse? : Bool = false,
  raw_mode? : Bool = true,
) -> (VNodeApp, () -> Unit) {
  let app = VNodeApp::new(width, height)

  // Initialize terminal
  output_fn(VNodeApp::init_terminal())
  if mouse {
    output_fn(@render.enable_mouse())
  }
  if raw_mode {
    @io.enable_raw_mode()
  }
  fn cleanup() {
    @io.stop_keypress_listener()
    @io.stop_resize_listener()
    if mouse {
      output_fn(@render.disable_mouse())
    }
    @io.cleanup_stdin()
    output_fn(VNodeApp::restore_terminal())
  }

  (app, cleanup)
}

///|
/// Simple render function for one-shot rendering (no reactivity)
pub fn render_vnode_once(width : Int, height : Int, root : TuiNode) -> String {
  let app = VNodeApp::new(width, height)
  app.render(root)
}
