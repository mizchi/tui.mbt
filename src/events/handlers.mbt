///|
/// Event handlers and hit testing for TUI components

///|
/// Click handler type
pub struct ClickHandler(() -> Unit)

///|
/// Create a new click handler
pub fn ClickHandler::new(handler : () -> Unit) -> ClickHandler {
  ClickHandler(handler)
}

///|
/// Event handlers map (component ID -> handler)
pub struct EventHandlers {
  click_handlers : Map[String, ClickHandler]
}

///|
pub fn EventHandlers::new() -> EventHandlers {
  { click_handlers: Map::new() }
}

///|
/// Register a click handler for a component
pub fn EventHandlers::on_click(
  self : EventHandlers,
  id : String,
  handler : ClickHandler,
) -> Unit {
  self.click_handlers.set(id, handler)
}

///|
/// Get click handler for a component
pub fn EventHandlers::get_click(
  self : EventHandlers,
  id : String,
) -> ClickHandler? {
  self.click_handlers.get(id)
}

///|
/// Perform hit test on layout tree
/// Returns the deepest (most specific) node containing the point
pub fn hit_test(
  layout : @types.Layout,
  mouse_x : Int,
  mouse_y : Int,
  offset_x : Int,
  offset_y : Int,
) -> HitTestResult? {
  hit_test_f(
    layout,
    mouse_x,
    mouse_y,
    offset_x.to_double(),
    offset_y.to_double(),
  )
}

///|
fn hit_test_f(
  layout : @types.Layout,
  mouse_x : Int,
  mouse_y : Int,
  offset_x : Double,
  offset_y : Double,
) -> HitTestResult? {
  let abs_x = offset_x + layout.x
  let abs_y = offset_y + layout.y
  let rect = @core.normalize_grid_rect(
    abs_x,
    abs_y,
    layout.width,
    layout.height,
  )
  let x = rect.x
  let y = rect.y
  let w = rect.width
  let h = rect.height

  if mouse_x >= x && mouse_x < x + w && mouse_y >= y && mouse_y < y + h {
    for child in layout.children {
      match hit_test_f(child, mouse_x, mouse_y, abs_x, abs_y) {
        Some(result) => return Some(result)
        None => continue
      }
    }
    Some({ id: layout.id, x, y, width: w, height: h, role: None })
  } else {
    None
  }
}

///|
/// Hit test from root (convenience function)
pub fn hit_test_root(
  layout : @types.Layout,
  mouse_x : Int,
  mouse_y : Int,
) -> HitTestResult? {
  hit_test(layout, mouse_x, mouse_y, 0, 0)
}

///|
/// Handle mouse click event
/// Returns true if a handler was invoked
pub fn handle_click(
  layout : @types.Layout,
  handlers : EventHandlers,
  mouse_x : Int,
  mouse_y : Int,
) -> Bool {
  match hit_test_root(layout, mouse_x, mouse_y) {
    Some(result) =>
      match handlers.get_click(result.id) {
        Some(ClickHandler(handler)) => {
          handler()
          true
        }
        None => false
      }
    None => false
  }
}

///|
/// Find layout by ID
/// Returns the position and size of the component with the given ID
pub fn find_layout_by_id(
  layout : @types.Layout,
  target_id : String,
  offset_x : Int,
  offset_y : Int,
) -> HitTestResult? {
  find_layout_by_id_f(
    layout,
    target_id,
    offset_x.to_double(),
    offset_y.to_double(),
  )
}

///|
fn find_layout_by_id_f(
  layout : @types.Layout,
  target_id : String,
  offset_x : Double,
  offset_y : Double,
) -> HitTestResult? {
  let abs_x = offset_x + layout.x
  let abs_y = offset_y + layout.y
  let rect = @core.normalize_grid_rect(
    abs_x,
    abs_y,
    layout.width,
    layout.height,
  )
  let x = rect.x
  let y = rect.y
  let w = rect.width
  let h = rect.height

  if layout.id == target_id {
    return Some({ id: layout.id, x, y, width: w, height: h, role: None })
  }

  for child in layout.children {
    match find_layout_by_id_f(child, target_id, abs_x, abs_y) {
      Some(result) => return Some(result)
      None => continue
    }
  }
  None
}

///|
/// Find layout by ID from root
pub fn find_layout_by_id_root(
  layout : @types.Layout,
  target_id : String,
) -> HitTestResult? {
  find_layout_by_id(layout, target_id, 0, 0)
}

///|
/// Collect all layout rectangles (absolute coordinates) into a flat list.
fn collect_layout_rects(
  layout : @types.Layout,
  offset_x : Double,
  offset_y : Double,
  out : Array[HitTestResult],
) -> Unit {
  let abs_x = offset_x + layout.x
  let abs_y = offset_y + layout.y
  let rect = @core.normalize_grid_rect(
    abs_x,
    abs_y,
    layout.width,
    layout.height,
  )
  let x = rect.x
  let y = rect.y
  let w = rect.width
  let h = rect.height
  out.push({ id: layout.id, x, y, width: w, height: h, role: None })
  for child in layout.children {
    collect_layout_rects(child, abs_x, abs_y, out)
  }
}

///|
/// Flatten layout tree into rects (root is included).
pub fn layout_rects_root(layout : @types.Layout) -> Array[HitTestResult] {
  let out : Array[HitTestResult] = []
  collect_layout_rects(layout, 0.0, 0.0, out)
  out
}

///|
/// Debug: dump layout tree structure
pub fn dump_layout(
  layout : @types.Layout,
  offset_x : Int,
  offset_y : Int,
  depth : Int,
) -> String {
  dump_layout_f(layout, offset_x.to_double(), offset_y.to_double(), depth)
}

///|
fn dump_layout_f(
  layout : @types.Layout,
  offset_x : Double,
  offset_y : Double,
  depth : Int,
) -> String {
  let abs_x = offset_x + layout.x
  let abs_y = offset_y + layout.y
  let rect = @core.normalize_grid_rect(
    abs_x,
    abs_y,
    layout.width,
    layout.height,
  )
  let raw_x = @core.snap_to_grid(layout.x)
  let raw_y = @core.snap_to_grid(layout.y)
  let x = rect.x
  let y = rect.y
  let w = rect.width
  let h = rect.height
  let indent = "  ".repeat(depth)
  let mut result = indent +
    layout.id +
    " raw=(" +
    raw_x.to_string() +
    "," +
    raw_y.to_string() +
    ") abs=(" +
    x.to_string() +
    "," +
    y.to_string() +
    ") " +
    w.to_string() +
    "x" +
    h.to_string() +
    " " +
    layout.children.length().to_string() +
    "\n"
  for child in layout.children {
    result = result + dump_layout_f(child, abs_x, abs_y, depth + 1)
  }
  result
}
