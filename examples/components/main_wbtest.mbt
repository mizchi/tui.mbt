///|
/// Tests for vnode-components

///|
test "components demo indices are valid" {
  inspect(demo_tabs, content="0")
  inspect(demo_accordion, content="1")
  inspect(demo_radio, content="2")
  inspect(demo_switch, content="3")
  inspect(demo_listbox, content="4")
  inspect(demo_combobox, content="5")
  inspect(demo_splitter, content="6")
  inspect(demo_menubar, content="7")
}

///|
test "components uses signals" {
  let current_demo = @signals.signal(0)
  current_demo.set(demo_accordion)
  inspect(current_demo.get(), content="1")
}

// ==========================================================================
// Menubar height consistency tests
// ==========================================================================

///|
/// Helper to create menu item for testing
fn test_menu_item(label : String, selected : Bool) -> @vnode.TuiNode {
  let bg = if selected { "rgb(40,80,120)" } else { "rgb(50,50,60)" }
  let fg = if selected { "cyan" } else { "white" }
  @vnode.row(bg~, padding_x=1.0, padding_y=0.5, min_height=2.0, children=[
    @vnode.text(" " + label + " ", fg~),
  ])
}

///|
/// Create dropdown column with fixed height
fn test_dropdown(items : Array[String], selected : Int) -> @vnode.TuiNode {
  let item_nodes : Array[@vnode.TuiNode] = []
  for i, item in items {
    item_nodes.push(test_menu_item(item, selected == i))
  }
  @vnode.column(
    border="single",
    border_color="cyan",
    bg="rgb(50,50,60)",
    height=10.0,
    children=item_nodes,
  )
}

///|
/// Count newlines in a string
fn count_lines(s : String) -> Int {
  let mut count = 0
  for c in s.iter() {
    if c == '\n' {
      count += 1
    }
  }
  count
}

///|
test "dropdown heights should be consistent" {
  let file_items = ["New", "Open", "Save", "Exit"]
  let edit_items = ["Cut", "Copy", "Paste"]
  let view_items = ["Toolbar", "Status Bar", "Zoom In", "Zoom Out"]

  // Render each dropdown
  let file_dropdown = test_dropdown(file_items, 0)
  let edit_dropdown = test_dropdown(edit_items, 0)
  let view_dropdown = test_dropdown(view_items, 0)

  // Render to string and check output
  let file_output = @vnode.render_vnode_once(60, 12, file_dropdown)
  let edit_output = @vnode.render_vnode_once(60, 12, edit_dropdown)
  let view_output = @vnode.render_vnode_once(60, 12, view_dropdown)
  let file_lines = count_lines(file_output)
  let edit_lines = count_lines(edit_output)
  let view_lines = count_lines(view_output)
  println("File dropdown lines: " + file_lines.to_string())
  println("Edit dropdown lines: " + edit_lines.to_string())
  println("View dropdown lines: " + view_lines.to_string())

  // All should have the same number of lines
  inspect(file_lines == edit_lines, content="true")
  inspect(edit_lines == view_lines, content="true")
}

///|
test "menu items have consistent height" {
  let item1 = test_menu_item("Short", false)
  let item2 = test_menu_item("Medium Text", false)
  let item3 = test_menu_item("Status Bar", true)
  let out1 = @vnode.render_vnode_once(30, 3, item1)
  let out2 = @vnode.render_vnode_once(30, 3, item2)
  let out3 = @vnode.render_vnode_once(30, 3, item3)
  let lines1 = count_lines(out1)
  let lines2 = count_lines(out2)
  let lines3 = count_lines(out3)
  println("Item 'Short' lines: " + lines1.to_string())
  println("Item 'Medium Text' lines: " + lines2.to_string())
  println("Item 'Status Bar' (selected) lines: " + lines3.to_string())
  inspect(lines1 == lines2, content="true")
  inspect(lines2 == lines3, content="true")
}

///|
test "render dropdown and print output" {
  let edit_items = ["Cut", "Copy", "Paste"]
  let view_items = ["Toolbar", "Status Bar", "Zoom In", "Zoom Out"]
  let edit_dropdown = test_dropdown(edit_items, 1)
  let view_dropdown = test_dropdown(view_items, 1)
  let edit_output = @vnode.render_vnode_once(40, 12, edit_dropdown)
  let view_output = @vnode.render_vnode_once(40, 12, view_dropdown)
  println("=== Edit dropdown (3 items) ===")
  println(edit_output)
  println("=== end ===")
  println("=== View dropdown (4 items) ===")
  println(view_output)
  println("=== end ===")

  // Just verify they render
  inspect(edit_output.length() > 0, content="true")
  inspect(view_output.length() > 0, content="true")
}

///|
/// Create full menubar demo layout for testing
fn test_menubar_layout(open_menu : Int, selected_item : Int) -> @vnode.TuiNode {
  let menus = ["File", "Edit", "View"]
  let file_items = ["New", "Open", "Save", "Exit"]
  let edit_items = ["Cut", "Copy", "Paste"]
  let view_items = ["Toolbar", "Status Bar", "Zoom In", "Zoom Out"]
  fn get_items(idx : Int) -> Array[String] {
    match idx {
      0 => file_items
      1 => edit_items
      2 => view_items
      _ => []
    }
  }

  // Menu bar items
  let menu_bar_items : Array[@vnode.TuiNode] = []
  for i, m in menus {
    let bg = if open_menu == i { "rgb(60,80,120)" } else { "" }
    menu_bar_items.push(
      @vnode.row(bg~, padding_x=0.5, children=[
        @vnode.text(" " + m + " ", bold=open_menu == i),
      ]),
    )
  }

  // Dropdown - use same structure for both states
  let dropdown_height = 10.0
  let dropdown : @vnode.TuiNode = if open_menu >= 0 {
    let items = get_items(open_menu)
    let item_nodes : Array[@vnode.TuiNode] = []
    for i, item in items {
      item_nodes.push(test_menu_item(item, selected_item == i))
    }
    @vnode.column(
      border="single",
      border_color="cyan",
      bg="rgb(50,50,60)",
      height=dropdown_height,
      children=item_nodes,
    )
  } else {
    // Use same column structure as placeholder
    @vnode.column(height=dropdown_height, children=[])
  }
  @vnode.column(children=[
    @vnode.text("Menubar", fg="yellow", bold=true),
    @vnode.vspace(1.0),
    @vnode.row(
      bg="rgb(40,40,50)",
      border="single",
      border_color="rgb(60,60,80)",
      children=menu_bar_items,
    ),
    dropdown,
    @vnode.spacer(),
    @vnode.text("Status line", fg="green"),
  ])
}

///|
/// Extract row numbers from ANSI output (e.g., "[21;1H" -> 21)
fn extract_row_positions(s : String) -> Array[Int] {
  let rows : Array[Int] = []
  let mut i = 0
  let chars : Array[Char] = []
  for c in s.iter() {
    chars.push(c)
  }
  while i < chars.length() - 4 {
    // Look for pattern [N;1H where N is row number
    if chars[i] == '[' {
      let mut j = i + 1
      let mut num_str = ""
      while j < chars.length() && chars[j] >= '0' && chars[j] <= '9' {
        num_str = num_str + chars[j].to_string()
        j += 1
      }
      if j < chars.length() - 2 &&
        chars[j] == ';' &&
        chars[j + 1] == '1' &&
        chars[j + 2] == 'H' &&
        num_str.length() > 0 {
        // Parse row number
        let mut row = 0
        for c in num_str.iter() {
          row = row * 10 + (c.to_int() - '0'.to_int())
        }
        if not(rows.contains(row)) {
          rows.push(row)
        }
      }
    }
    i += 1
  }
  rows.sort()
  rows
}

///|
test "menubar full layout height consistency" {
  // Test Edit menu open (3 items)
  let edit_layout = test_menubar_layout(1, 0)
  let edit_output = @vnode.render_vnode_once(60, 25, edit_layout)

  // Test View menu open (4 items)
  let view_layout = test_menubar_layout(2, 0)
  let view_output = @vnode.render_vnode_once(60, 25, view_layout)
  println("=== Edit menu full layout ===")
  println(edit_output)
  println("=== end ===")
  println("=== View menu full layout ===")
  println(view_output)
  println("=== end ===")

  // Extract row positions from both outputs
  let edit_rows = extract_row_positions(edit_output)
  let view_rows = extract_row_positions(view_output)
  println("Edit rows: " + edit_rows.to_string())
  println("View rows: " + view_rows.to_string())

  // Both should have the same row positions (same visual layout)
  inspect(edit_rows.length(), content="25")
  inspect(view_rows.length(), content="25")

  // Check specific important rows match
  // Status line should be at row 21 for both
  inspect(edit_rows.contains(21), content="true")
  inspect(view_rows.contains(21), content="true")
}

///|
test "menubar closed vs open height consistency" {
  // Test that closed menu has same row positions as open menu
  let closed_layout = test_menubar_layout(-1, 0)
  let open_layout = test_menubar_layout(1, 0)
  let closed_output = @vnode.render_vnode_once(60, 25, closed_layout)
  let open_output = @vnode.render_vnode_once(60, 25, open_layout)
  let closed_rows = extract_row_positions(closed_output)
  let open_rows = extract_row_positions(open_output)
  println("Closed rows: " + closed_rows.to_string())
  println("Open rows: " + open_rows.to_string())

  // Both should have same row positions
  inspect(closed_rows.length(), content="25")
  inspect(open_rows.length(), content="25")

  // Status line should be at same position
  inspect(closed_rows.contains(21), content="true")
  inspect(open_rows.contains(21), content="true")
}

///|
test "menubar diff rendering consistency" {
  // Simulate switching from Edit to View menu
  let app = @vnode.VNodeApp::new(60, 25)

  // First render: Edit menu
  let edit_layout = test_menubar_layout(1, 0)
  let _ = app.render_frame(edit_layout)

  // Second render: View menu (should use diff)
  let view_layout = test_menubar_layout(2, 0)
  let view_output = app.render_frame(view_layout)
  println("=== Edit to View diff output ===")
  println(view_output)
  println("=== end ===")

  // Diff output should be shorter than full render
  let full_view = @vnode.render_vnode_once(60, 25, view_layout)
  println("Full view length: " + full_view.length().to_string())
  println("Diff view length: " + view_output.length().to_string())

  // Verify diff is actually smaller
  inspect(view_output.length() < full_view.length(), content="true")
}
