///|
/// Tests for vnode-layout components

///|
test "header renders with correct structure" {
  let node = header()
  // Header should create a row with title and navigation
  let output = @vnode.render_vnode_once(80, 3, node)
  inspect(output.contains("TUI Dashboard"), content="true")
  inspect(output.contains("Home"), content="true")
}

///|
test "sidebar renders menu items" {
  let node = sidebar()
  let output = @vnode.render_vnode_once(20, 20, node)
  inspect(output.contains("Navigation"), content="true")
  inspect(output.contains("Dashboard"), content="true")
  inspect(output.contains("Analytics"), content="true")
}

///|
test "menu_item active state" {
  let active = menu_item("Test", true)
  let inactive = menu_item("Test", false)
  let active_output = @vnode.render_vnode_once(20, 1, active)
  let inactive_output = @vnode.render_vnode_once(20, 1, inactive)
  // Active item should have marker
  inspect(active_output.contains("▸"), content="true")
  inspect(inactive_output.contains("▸"), content="false")
}

///|
test "stat_card renders value and title" {
  let card = stat_card("Users", "1,234", "green")
  let output = @vnode.render_vnode_once(15, 5, card)
  inspect(output.contains("1,234"), content="true")
  inspect(output.contains("Users"), content="true")
}

///|
test "grid_cell renders with label" {
  let cell = grid_cell("A1", "red")
  let output = @vnode.render_vnode_once(10, 3, cell)
  inspect(output.contains("A1"), content="true")
}

///|
test "footer renders content" {
  let node = footer()
  // Footer has height=1.0, width varies
  let output = @vnode.render_vnode_once(80, 3, node)
  // Output should not be empty
  inspect(output.length() > 0, content="true")
}

///|
test "build_dashboard creates full layout" {
  let dashboard = build_dashboard(80, 24)
  let output = @vnode.render_vnode_once(80, 24, dashboard)
  // Should contain header elements
  inspect(output.contains("TUI Dashboard"), content="true")
  // Should contain sidebar elements
  inspect(output.contains("Navigation"), content="true")
  // Should contain stat cards
  inspect(output.contains("Users"), content="true")
}

///|
test "activity_item renders with time" {
  let item = activity_item("Test action", "5m ago", "green")
  let output = @vnode.render_vnode_once(40, 1, item)
  inspect(output.contains("Test action"), content="true")
  inspect(output.contains("5m ago"), content="true")
}
