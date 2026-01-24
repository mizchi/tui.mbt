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
  let node = row([text("A"), text("B"), text("C")])
  let output = app.render(node)
  assert_true(output.contains("A"))
  assert_true(output.contains("B"))
  assert_true(output.contains("C"))
}

///|
test "VNodeApp: column layout" {
  let app = VNodeApp::new(20, 5)
  let node = column([text("Line 1"), text("Line 2")])
  let output = app.render(node)
  assert_true(output.contains("Line 1"))
  assert_true(output.contains("Line 2"))
}

///|
test "VNodeApp: nested layout" {
  let app = VNodeApp::new(30, 10)
  let node = column([
    row([text("Header")]),
    row([text("Content")]),
    row([text("Footer")]),
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
  let node = column([text("Inside")], border="single", padding=1.0)
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
  let node = column([text("Click me")], id="clickable")
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
    component(fn() { row([text(label)], border="single", padding_x=1.0) })
  }

  let node = row([my_button("OK"), hspace(1.0), my_button("Cancel")])
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
    let node = row([text("Box")], border=style, padding=1.0)
    let output = app.render(node)
    assert_true(output.contains("Box"))
  }
}

///|
test "VNodeApp: event handler registration" {
  let app = VNodeApp::new(20, 5)
  let clicked : Ref[Bool] = Ref::new(false)

  // Create a node with on_click handler
  let node = row(
    [text("Click me")],
    id="btn",
    on_click=Some(fn(_event) { clicked.val = true }),
  )

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
  let node = column(
    [
      row(
        [text("Button")],
        id="my-btn",
        on_click=Some(fn(_event) { click_count.val = click_count.val + 1 }),
        border="single",
        padding=1.0,
      ),
    ],
    width=20.0,
    height=5.0,
  )

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
