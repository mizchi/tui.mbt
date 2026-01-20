///|
/// Event handling for interactive TUI components
/// Re-exports functions from events subpackage for backwards compatibility

///|
/// Perform hit test on layout tree
/// Returns the deepest (most specific) node containing the point
pub fn hit_test(
  layout : @types.Layout,
  mouse_x : Int,
  mouse_y : Int,
  offset_x : Int,
  offset_y : Int,
) -> @events.HitTestResult? {
  @events.hit_test(layout, mouse_x, mouse_y, offset_x, offset_y)
}

///|
/// Hit test from root (convenience function)
pub fn hit_test_root(
  layout : @types.Layout,
  mouse_x : Int,
  mouse_y : Int,
) -> @events.HitTestResult? {
  @events.hit_test_root(layout, mouse_x, mouse_y)
}

///|
/// Handle mouse click event
/// Returns true if a handler was invoked
pub fn handle_click(
  layout : @types.Layout,
  handlers : @events.EventHandlers,
  mouse_x : Int,
  mouse_y : Int,
) -> Bool {
  @events.handle_click(layout, handlers, mouse_x, mouse_y)
}

///|
/// Find layout by ID
/// Returns the position and size of the component with the given ID
pub fn find_layout_by_id(
  layout : @types.Layout,
  target_id : String,
  offset_x : Int,
  offset_y : Int,
) -> @events.HitTestResult? {
  @events.find_layout_by_id(layout, target_id, offset_x, offset_y)
}

///|
/// Find layout by ID from root
pub fn find_layout_by_id_root(
  layout : @types.Layout,
  target_id : String,
) -> @events.HitTestResult? {
  @events.find_layout_by_id_root(layout, target_id)
}

///|
/// Debug: dump layout tree structure
pub fn dump_layout(
  layout : @types.Layout,
  offset_x : Int,
  offset_y : Int,
  depth : Int,
) -> String {
  @events.dump_layout(layout, offset_x, offset_y, depth)
}
