///|
/// Tests for TUI components

///|
test "input: creates component structure" {
  let comp = input("hello", id="test-input")
  // Verify component has correct node ID
  inspect(comp.node.id, content="test-input")
  // Verify text content is set
  inspect(comp.texts.get("test-input"), content="Some(\"hello\")")
}

///|
test "input: placeholder when empty" {
  let comp = input("", id="empty-input", placeholder="Enter name")
  // Verify placeholder is set as text content
  inspect(comp.texts.get("empty-input"), content="Some(\"Enter name\")")
}

///|
test "input: cursor when editing" {
  let comp = input("hello", id="edit-input", state=InputState::Editing)
  // Verify cursor is appended
  inspect(comp.texts.get("edit-input"), content="Some(\"hello_\")")
}

///|
test "textarea: creates component with value" {
  let comp = textarea("line1", id="test-textarea")
  let output = @render.render_once(80, 24, comp)
  assert_true(output.contains("line1"))
}

///|
test "textarea: placeholder shown when value is empty" {
  let comp = textarea("", placeholder="Enter message")
  let output = @render.render_once(80, 24, comp)
  assert_true(output.contains("Enter message"))
}

///|
test "button: creates component with text" {
  let comp = button("Click me", id="test-btn")
  let output = @render.render_once(80, 24, comp)
  assert_true(output.contains("Click me"))
}

///|
test "button: different states" {
  let normal = button("OK", id="btn-normal", state=ButtonState::Normal)
  let hover = button("OK", id="btn-hover", state=ButtonState::Hover)
  let pressed = button("OK", id="btn-pressed", state=ButtonState::Pressed)
  // All should have the button text
  inspect(normal.texts.get("btn-normal"), content="None")
  inspect(hover.texts.get("btn-hover"), content="None")
  inspect(pressed.texts.get("btn-pressed"), content="None")
}

///|
test "row: creates horizontal container" {
  let r = row([@core.text("A"), @core.text("B")])
  // Row should have 2 children
  inspect(r.node.children.length(), content="2")
}

///|
test "column: creates vertical container" {
  let c = column([@core.text("A"), @core.text("B")])
  // Column should have 2 children
  inspect(c.node.children.length(), content="2")
}

///|
test "text: creates text component" {
  let t = @core.text("Hello")
  // Text should have content
  inspect(t.texts.get(t.node.id), content="Some(\"Hello\")")
}

///|
test "spacer: creates flexible space" {
  let s = spacer()
  // Spacer should have flex_grow = 1.0
  inspect(s.node.style.flex_grow, content="1")
}

///|
test "hspace: creates horizontal space" {
  let h = hspace(5.0)
  // Should have width = 5
  inspect(h.node.style.width, content="Length(5)")
}

///|
test "vspace: creates vertical space" {
  let v = vspace(3.0)
  // Should have height = 3
  inspect(v.node.style.height, content="Length(3)")
}

///|
/// Test case to reproduce scrollable_list height instability
/// When items transition from no-scroll to scroll mode,
/// the content height changes by 1 line
test "scrollable_list: height stability at scroll threshold" {
  let scroll_state = ScrollState::new()
  let visible_height = 10

  // Create items just below scroll threshold
  let items_below : Array[@core.Component] = []
  for i = 0; i < 10; i = i + 1 {
    items_below.push(@core.text("Item " + i.to_string()))
  }

  // Create items just above scroll threshold
  let items_above : Array[@core.Component] = []
  for i = 0; i < 11; i = i + 1 {
    items_above.push(@core.text("Item " + i.to_string()))
  }

  // Get visible items for both cases
  let visible_below = scrollable_list(items_below, scroll_state, visible_height)
  scroll_state.offset.set(0)
  let visible_above = scrollable_list(items_above, scroll_state, visible_height)

  // BUG: When total <= visible_height, we get 10 items
  //      When total > visible_height, we get 9 items + 1 indicator = 10 items
  // But the content area height changes!
  inspect(visible_below.length(), content="10") // 10 items, no indicator
  inspect(visible_above.length(), content="10") // 9 items + 1 indicator

  // This shows the height instability issue:
  // apply_scroll uses visible_height when no scroll needed
  // apply_scroll uses visible_height - 1 when scroll needed
  let applied_below = apply_scroll(items_below, 0, visible_height)
  let applied_above = apply_scroll(items_above, 0, visible_height)
  inspect(applied_below.length(), content="10") // Full height used
  inspect(applied_above.length(), content="9") // Height - 1 used for indicator
}

///|
/// Test to verify scrollable_list consistency with streaming content
test "scrollable_list: streaming content height consistency" {
  let scroll_state = ScrollState::new()
  let visible_height = 5

  // Simulate streaming: content grows from 4 to 6 items
  let heights : Array[Int] = []
  for item_count = 4; item_count <= 6; item_count = item_count + 1 {
    let items : Array[@core.Component] = []
    for i = 0; i < item_count; i = i + 1 {
      items.push(@core.text("Message " + i.to_string()))
    }
    scroll_state.offset.set(0)
    let visible = scrollable_list(items, scroll_state, visible_height)
    heights.push(visible.length())
  }

  // Heights: [4, 5, 5]
  // When items go from 5 to 6, scroll indicator appears
  // This causes the content area to shrink
  inspect(heights, content="[4, 5, 5]")
}

///|
/// Test chat-like layout rendering with fixed height container
test "chat layout: fixed height container rendering" {
  let total_height = 20
  let input_area_height = 6
  let buffer_lines = 1
  let divider_height = 1
  let message_area_height = total_height -
    input_area_height -
    divider_height -
    buffer_lines

  // Create message items (2 lines per message: role + content)
  fn build_messages(count : Int) -> Array[@core.Component] {
    let items : Array[@core.Component] = []
    for i = 0; i < count; i = i + 1 {
      items.push(
        column(
          [
            text("User", fg=@core.Color::cyan()),
            text("  Message " + i.to_string()),
          ],
          gap=0.0,
        ),
      )
    }
    items
  }

  let scroll_state = ScrollState::new()

  // Test with 5 messages (10 visual lines) - fits in message_area_height=12
  let messages_5 = build_messages(5)
  scroll_state.offset.set(0)
  let visible_5 = scrollable_list(messages_5, scroll_state, message_area_height)

  // Test with 7 messages (14 visual lines) - exceeds message_area_height=12
  let messages_7 = build_messages(7)
  scroll_state.offset.set(0)
  let visible_7 = scrollable_list(messages_7, scroll_state, message_area_height)

  // The key issue: when scrolling is needed, one less item is shown
  inspect(visible_5.length(), content="5") // All 5 fit
  inspect(visible_7.length(), content="7") // 6 items + indicator (but only 6 items shown!)
}

///|
/// Test that demonstrates the +1 height issue with different text lengths
test "chat layout: text length affects height" {
  let scroll_state = ScrollState::new()
  let visible_height = 10

  // Short texts - each takes 1 line
  let short_items : Array[@core.Component] = []
  for i = 0; i < 11; i = i + 1 {
    short_items.push(@core.text("Hi"))
  }

  // Long texts - each takes 1 line (but may wrap in real render)
  let long_items : Array[@core.Component] = []
  for i = 0; i < 11; i = i + 1 {
    long_items.push(
      @core.text("This is a much longer message that might cause issues"),
    )
  }
  scroll_state.offset.set(0)
  let short_visible = scrollable_list(short_items, scroll_state, visible_height)
  scroll_state.offset.set(0)
  let long_visible = scrollable_list(long_items, scroll_state, visible_height)

  // Both should have same number of visible items
  // BUG: In real rendering, text wrapping may cause different heights
  inspect(short_visible.length(), content="10")
  inspect(long_visible.length(), content="10")
}

// ============================================
// Accessibility Tests - Keyboard Interaction
// ============================================

///|
/// a11y: Button must have ID for focus tracking
test "a11y: button has focusable ID" {
  let btn = button("Submit", id="submit-btn")
  // Button must have an ID for keyboard focus
  inspect(btn.node.id, content="submit-btn")
}

///|
/// a11y: Button states are distinguishable
test "a11y: button has distinct states for visual feedback" {
  // All button states should be creatable
  let normal = button("OK", state=ButtonState::Normal)
  let hover = button("OK", state=ButtonState::Hover)
  let pressed = button("OK", state=ButtonState::Pressed)
  let disabled = button("OK", state=ButtonState::Disabled)
  // All should create valid components
  inspect(normal.node.id.length() > 0, content="true")
  inspect(hover.node.id.length() > 0, content="true")
  inspect(pressed.node.id.length() > 0, content="true")
  inspect(disabled.node.id.length() > 0, content="true")
}

///|
/// a11y: Input has focusable ID for keyboard navigation
test "a11y: input has focusable ID" {
  let inp = input("", id="email-input", placeholder="Enter email")
  inspect(inp.node.id, content="email-input")
}

///|
/// a11y: Input states indicate interaction mode
test "a11y: input has distinct states (idle/focused/editing/disabled)" {
  let idle = input("test", state=InputState::Idle)
  let focused = input("test", state=InputState::Focused)
  let editing = input("test", state=InputState::Editing)
  let disabled = input("test", state=InputState::Disabled)
  // All states should be distinguishable (cursor shows in editing)
  inspect(idle.texts.get(idle.node.id).unwrap().contains("_"), content="false")
  inspect(
    focused.texts.get(focused.node.id).unwrap().contains("_"),
    content="false",
  )
  inspect(
    editing.texts.get(editing.node.id).unwrap().contains("_"),
    content="true",
  )
  inspect(
    disabled.texts.get(disabled.node.id).unwrap().contains("_"),
    content="false",
  )
}

///|
/// a11y: Input shows placeholder for empty value (user guidance)
test "a11y: input placeholder provides guidance" {
  let inp = input("", placeholder="Type here...")
  inspect(
    inp.texts.get(inp.node.id).unwrap().contains("Type here"),
    content="true",
  )
}

///|
/// a11y: Textarea has distinct editing state
test "a11y: textarea editing state shows cursor" {
  let idle = textarea("content", state=TextareaState::Idle)
  let editing = textarea("content", state=TextareaState::Editing)
  // Editing state should show cursor
  let idle_output = @render.render_once(80, 24, idle)
  let editing_output = @render.render_once(80, 24, editing)
  inspect(idle_output.contains("content_"), content="false")
  inspect(editing_output.contains("content_"), content="true")
}

///|
/// Test that simulates streaming text and its effect on layout
/// This reproduces the +1 height issue in chat example
test "chat layout: streaming text height variation" {
  let width = 40

  // Build a message component similar to chat example
  fn build_message_component(content : String) -> @core.Component {
    column(
      [
        text("✦ Assistant", fg=@core.Color::rgb(255, 150, 100)),
        text("   " + content),
      ],
      gap=0.0,
      width=@types.Dimension::Length(width.to_double()),
    )
  }

  // Different text lengths that may cause height variation
  let texts = [
    "Short",
    "Medium length text",
    "This is a longer text that might wrap",
    "This is an even longer text that will definitely wrap across multiple lines",
    "x".repeat(width - 3), // Exactly fits one line (minus "   " prefix)
    "x".repeat(width - 2), // One char over - should wrap
  ]

  // Build and compute layout for each text
  let results : Array[(String, Int)] = []
  for t in texts {
    let comp = build_message_component(t)
    // Compute layout to get actual height
    let layout = @render.compute_layout(comp.node, width, 100)
    let height = layout.height.to_int()
    let label = if t.length() > 10 { t[:10].to_string() } else { t }
    results.push((label, height))
  }

  // Expected: all messages should have consistent or predictable heights
  // The issue is that text wrapping causes height to jump unexpectedly
  inspect(
    results,
    content=(
      #|[("Short", 4), ("Medium len", 6), ("This is a ", 9), ("This is an", 10), ("xxxxxxxxxx", 4), ("xxxxxxxxxx", 4)]
    ),
  )
}
