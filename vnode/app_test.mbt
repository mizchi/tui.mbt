///|
test "VNodeApp: simple render" {
  let app = VNodeApp::new(20, 5)
  let output = app.render(text("Hello"))
  // Output should contain "Hello"
  assert_true(output.contains("Hello"))
}

///|
test "VNodeApp: row layout" {
  let app = VNodeApp::new(20, 5)
  let node = row(children=[text("A"), text("B"), text("C")])
  let output = app.render(node)
  assert_true(output.contains("A"))
  assert_true(output.contains("B"))
  assert_true(output.contains("C"))
}

///|
test "VNodeApp: column layout" {
  let app = VNodeApp::new(20, 5)
  let node = column(children=[text("Line 1"), text("Line 2")])
  let output = app.render(node)
  assert_true(output.contains("Line 1"))
  assert_true(output.contains("Line 2"))
}

///|
test "VNodeApp: nested layout" {
  let app = VNodeApp::new(30, 10)
  let node = column(children=[
    row(children=[text("Header")]),
    row(children=[text("Content")]),
    row(children=[text("Footer")]),
  ])
  let output = app.render(node)
  assert_true(output.contains("Header"))
  assert_true(output.contains("Content"))
  assert_true(output.contains("Footer"))
}

///|
test "VNodeApp: styled text" {
  let app = VNodeApp::new(20, 5)
  let node = text("Red Text", fg="red")
  let output = app.render(node)
  // Output should contain the text
  assert_true(output.contains("Red Text"))
  // ANSI codes should be present for color (ESC[)
  assert_true(output.contains("\u001b["))
}

///|
test "VNodeApp: border" {
  let app = VNodeApp::new(20, 8)
  let node = column(border="single", padding=1.0, children=[text("Inside")])
  let output = app.render(node)
  // Should contain border characters
  assert_true(output.contains("Inside"))
  // Border chars: ┌ ┐ └ ┘ │ ─
  assert_true(output.contains("─") || output.contains("│"))
}

///|
test "VNodeApp: diff rendering" {
  let app = VNodeApp::new(20, 5)

  // First render - clears screen and renders full
  let output1 = app.render(text("Hello"))
  assert_true(output1.contains("Hello"))

  // Second render with different content - uses diff
  // Diff output may not contain "World" as a continuous string
  // but should produce valid ANSI output
  let output2 = app.render(text("World"))
  // Just verify it produces some output (diff or characters)
  assert_true(output2.length() > 0)
}

///|
test "VNodeApp: hit test" {
  let app = VNodeApp::new(20, 5)
  let node = column(id="clickable", children=[text("Click me")])
  let _ = app.render(node)

  // Hit test should find the component
  let result = app.find_by_id("clickable")
  assert_true(result is Some(_))
}

///|
test "render_vnode_once: simple" {
  let output = render_vnode_once(20, 5, text("Test"))
  assert_true(output.contains("Test"))
}

///|
test "VNodeApp: show conditional" {
  let app = VNodeApp::new(20, 5)

  // Visible
  let node1 = show(fn() { true }, fn() { text("Visible") })
  let output1 = app.render(node1)
  assert_true(output1.contains("Visible"))

  // Clear buffer for clean test
  app.clear_prev_buffer()

  // Hidden
  let node2 = show(fn() { false }, fn() { text("Hidden") })
  let output2 = app.render(node2)
  assert_false(output2.contains("Hidden"))
}

///|
test "VNodeApp: for_each" {
  let app = VNodeApp::new(30, 10)
  let items = ["Item 1", "Item 2", "Item 3"]
  let node = for_each(fn() { items.map(fn(s) { text(s) }) })
  let output = app.render(node)
  assert_true(output.contains("Item 1"))
  assert_true(output.contains("Item 2"))
  assert_true(output.contains("Item 3"))
}

///|
test "VNodeApp: text_dyn" {
  let app = VNodeApp::new(20, 5)
  let counter : Ref[Int] = Ref::new(0)
  let node = text_dyn(fn() { "Count: " + counter.val.to_string() })

  // First render
  let output1 = app.render(node)
  assert_true(output1.contains("Count: 0"))

  // Update state and re-render
  counter.val = 42
  app.clear_prev_buffer() // Force full re-render
  let output2 = app.render(node)
  assert_true(output2.contains("Count: 42"))
}

///|
test "VNodeApp: component boundary" {
  let app = VNodeApp::new(20, 5)

  // Define a reusable component
  fn my_button(label : String) -> TuiNode {
    component(fn() {
      row(border="single", padding_x=1.0, children=[text(label)])
    })
  }

  let node = row(children=[my_button("OK"), hspace(1.0), my_button("Cancel")])
  let output = app.render(node)
  assert_true(output.contains("OK"))
  assert_true(output.contains("Cancel"))
}

///|
test "VNodeApp: nested show" {
  let app = VNodeApp::new(20, 5)
  let show_outer = true
  let show_inner = true
  let node = show(fn() { show_outer }, fn() {
    show(fn() { show_inner }, fn() { text("Nested") })
  })
  let output = app.render(node)
  assert_true(output.contains("Nested"))
}

///|
test "VNodeApp: border styles" {
  // Test different border styles
  for style in ["single", "double", "rounded", "ascii"] {
    let app = VNodeApp::new(15, 5)
    let node = row(border=style, padding=1.0, children=[text("Box")])
    let output = app.render(node)
    assert_true(output.contains("Box"))
  }
}

///|
test "VNodeApp: event handler registration" {
  let app = VNodeApp::new(20, 5)
  let clicked : Ref[Bool] = Ref::new(false)

  // Create a node with on_click handler
  let node = row(id="btn", on_click=Some(fn(_event) { clicked.val = true }), children=[
    text("Click me"),
  ])

  // Render to register handlers
  let _ = app.render(node)

  // Verify handler is registered
  assert_true(app.render_ctx.handlers.get("btn") is Some(_))
}

///|
test "VNodeApp: handle_click dispatches event" {
  let app = VNodeApp::new(20, 5)
  let click_count : Ref[Int] = Ref::new(0)

  // Create a clickable button at a known position
  let node = column(width=20.0, height=5.0, children=[
    row(
      id="my-btn",
      on_click=Some(fn(_event) { click_count.val = click_count.val + 1 }),
      border="single",
      padding=1.0,
      children=[text("Button")],
    ),
  ])

  // Render to compute layout and register handlers
  let _ = app.render(node)

  // Find button position via hit test
  match app.find_by_id("my-btn") {
    Some(hit) => {
      // Simulate click at button center
      let center_x = hit.x + hit.width / 2
      let center_y = hit.y + hit.height / 2
      let event : @events.MouseEvent = {
        event_type: @events.MouseEventType::Press,
        button: @events.MouseButton::Left,
        x: center_x,
        y: center_y,
        modifier: @events.KeyModifier::None,
      }
      // Dispatch click
      let result = app.handle_click(event)
      assert_true(result is Some(_))
      assert_eq(click_count.val, 1)
    }
    None => assert_true(false) // Button should be found
  }
}

///|
test "completion popup: items in single lines" {
  // Simulate completion items like IDE
  let items = ["apple", "apricot", "avocado"]
  let selected = 1
  let query = "ap"
  fn render_item(item : String, idx : Int) -> TuiNode {
    let is_selected = idx == selected
    let bg = if is_selected { "rgb(30,80,120)" } else { "rgb(60,60,60)" }
    let suffix = item.unsafe_substring(start=query.length(), end=item.length())
    row(bg~, children=[
      text(query, fg="cyan", bold=is_selected),
      text(suffix, fg=if is_selected { "white" } else { "rgb(150,150,150)" }),
    ])
  }

  let popup = column(
    children=items.mapi(fn(idx, item) { render_item(item, idx) }),
  )

  // Use render_to_lines to verify each item is on its own line
  let lines = render_to_lines(popup)
  inspect(lines.length(), content="3")

  // Each line should contain the query prefix "ap"
  for line in lines {
    assert_true(line.contains("ap"))
  }

  // Verify suffixes are present (text is split by ANSI codes)
  assert_true(lines[0].contains("ple"))
  assert_true(lines[1].contains("ricot"))
  assert_true(lines[2].contains("ocado"))
}

///|
test "completion popup: render_to_lines" {
  let items = ["apple", "apricot", "avocado"]
  let selected = 1
  let query = "ap"
  fn render_item(item : String, idx : Int) -> TuiNode {
    let is_selected = idx == selected
    let bg = if is_selected { "rgb(30,80,120)" } else { "rgb(60,60,60)" }
    let suffix = item.unsafe_substring(start=query.length(), end=item.length())
    row(bg~, children=[
      text(query, fg="cyan", bold=is_selected),
      text(suffix, fg=if is_selected { "white" } else { "rgb(150,150,150)" }),
    ])
  }

  let popup = column(
    children=items.mapi(fn(idx, item) { render_item(item, idx) }),
  )
  let lines = render_to_lines(popup)
  // Should have 3 lines, one for each item
  inspect(lines.length(), content="3")
  for line in lines {
    println(line)
  }
}

///|
test "render_overlay_at: positions content correctly" {
  let popup = column(children=[text("Line 1"), text("Line 2"), text("Line 3")])
  let overlay = render_overlay_at(5, 10, popup)

  // Output should contain ANSI cursor positioning sequences
  // ansi_move_to converts 0-indexed to 1-indexed: (y, x) -> ESC[y+1;x+1H
  // First line: ansi_move_to(10, 5) -> ESC[11;6H
  assert_true(overlay.contains("\u001b[11;6H"))
  // Second line: ansi_move_to(11, 5) -> ESC[12;6H
  assert_true(overlay.contains("\u001b[12;6H"))
  // Third line: ansi_move_to(12, 5) -> ESC[13;6H
  assert_true(overlay.contains("\u001b[13;6H"))

  // Content should be present
  assert_true(overlay.contains("Line 1"))
  assert_true(overlay.contains("Line 2"))
  assert_true(overlay.contains("Line 3"))
}

// =============================================================================
// Completion popup visibility logic tests
// =============================================================================

///|
/// Simulates completion popup state management
struct CompletionState {
  mut input : String
  mut suppress_popup : Bool
}

///|
fn CompletionState::new() -> CompletionState {
  { input: "", suppress_popup: false }
}

///|
fn CompletionState::should_show_popup(self : CompletionState) -> Bool {
  not(self.suppress_popup) && self.input.length() > 0
}

///|
fn CompletionState::on_type_char(self : CompletionState, c : Char) -> Unit {
  self.input = self.input + c.to_string()
  self.suppress_popup = false // Reset suppression when typing
}

///|
fn CompletionState::on_tab_confirm(
  self : CompletionState,
  completion : String,
) -> Unit {
  self.input = completion
  self.suppress_popup = true // Suppress popup after Tab confirmation
}

///|
fn CompletionState::on_backspace(self : CompletionState) -> Unit {
  if self.input.length() > 0 {
    let chars : Array[Char] = self.input.iter().collect()
    let buf = StringBuilder::new()
    for i = 0; i < chars.length() - 1; i = i + 1 {
      buf.write_char(chars[i])
    }
    self.input = buf.to_string()
  }
  self.suppress_popup = true // Suppress popup when deleting
}

///|
test "completion: Tab confirms and hides popup" {
  let state = CompletionState::new()

  // Type "ap"
  state.on_type_char('a')
  state.on_type_char('p')
  assert_eq(state.input, "ap")
  assert_true(state.should_show_popup()) // Popup should be visible

  // Tab confirms "apple"
  state.on_tab_confirm("apple")
  assert_eq(state.input, "apple")
  assert_false(state.should_show_popup()) // Popup should be hidden after Tab
}

///|
test "completion: Backspace hides popup" {
  let state = CompletionState::new()

  // Type "ap"
  state.on_type_char('a')
  state.on_type_char('p')
  assert_true(state.should_show_popup())

  // Backspace
  state.on_backspace()
  assert_eq(state.input, "a")
  assert_false(state.should_show_popup()) // Popup should be hidden after backspace
}

///|
test "completion: typing after Tab shows popup again" {
  let state = CompletionState::new()

  // Type and confirm
  state.on_type_char('a')
  state.on_tab_confirm("apple")
  assert_false(state.should_show_popup())

  // Type more
  state.on_type_char('s')
  assert_eq(state.input, "apples")
  assert_true(state.should_show_popup()) // Popup should reappear
}

///|
test "completion: typing after Backspace shows popup again" {
  let state = CompletionState::new()

  // Type and backspace
  state.on_type_char('a')
  state.on_type_char('p')
  state.on_backspace()
  assert_false(state.should_show_popup())

  // Type more
  state.on_type_char('p')
  assert_eq(state.input, "ap")
  assert_true(state.should_show_popup()) // Popup should reappear
}
