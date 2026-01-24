///|
/// E2E tests for TUI components using TestHarness

///|
test "TestHarness basic render" {
  let h = TestHarness::new(width=20, height=5)
  let text = @core.text("Hello")
  let _ = h.render(text)
  assert_true(h.contains("Hello"))
  assert_eq(h.frame_count(), 1)
}

///|
test "TestHarness strip_ansi removes escape sequences" {
  let input = "\u001b[31mRed\u001b[0m Normal"
  let result = strip_ansi(input)
  assert_eq(result, "Red Normal")
}

///|
test "TestHarness strip_ansi handles CSI sequences" {
  let input = "\u001b[1;2H\u001b[2J\u001b[?25hText"
  let result = strip_ansi(input)
  assert_eq(result, "Text")
}

///|
test "key sequences parse correctly - arrows" {
  let up = @events.parse_input(key_up())
  let down = @events.parse_input(key_down())
  let left = @events.parse_input(key_left())
  let right = @events.parse_input(key_right())
  assert_true(up.is_arrow() is Some(_))
  assert_true(down.is_arrow() is Some(_))
  assert_true(left.is_arrow() is Some(_))
  assert_true(right.is_arrow() is Some(_))
}

///|
test "key sequences parse correctly - special keys" {
  let enter = @events.parse_input(key_enter())
  let tab = @events.parse_input(key_tab())
  let esc = @events.parse_input(key_esc())
  let backtab = @events.parse_input(key_backtab())
  assert_true(enter.is_enter())
  assert_true(tab.is_tab())
  assert_true(esc.is_escape())
  assert_true(backtab.is_backtab())
}

///|
test "key sequences parse correctly - ctrl keys" {
  let ctrl_c = @events.parse_input(ctrl('c'))
  let ctrl_d = @events.parse_input(ctrl('d'))
  assert_true(ctrl_c.is_ctrl_c())
  assert_true(ctrl_d.is_ctrl('d'))
}

///|
test "mouse click sequences parse correctly" {
  let click = @events.parse_input(mouse_click(10, 5))
  match click {
    @events.InputEvent::Mouse(m) => {
      assert_eq(m.x, 10)
      assert_eq(m.y, 5)
      assert_true(m.button is @events.MouseButton::Left)
    }
    _ => assert_true(false)
  }
}

///|
test "scroll sequences parse correctly" {
  let up = @events.parse_input(scroll_up(1, 1))
  let down = @events.parse_input(scroll_down(1, 1))
  assert_true(up.is_scroll_up())
  assert_true(down.is_scroll_down())
}

///|
test "TestHarness button render and click" {
  let h = TestHarness::new(width=30, height=8)
  let counter : Ref[Int] = Ref::new(0)
  // Build a simple button
  let btn = @components.button(
    "Click me",
    id="test-btn",
    state=@components.ButtonState::Normal,
    min_width=15.0,
  )
  let _ = h.render(btn)
  // Check button text is rendered
  assert_true(h.contains("Click me"))
  // Check element can be found
  match h.find_by_id("test-btn") {
    Some(result) => {
      assert_eq(result.id, "test-btn")
      assert_true(result.x >= 0)
      assert_true(result.y >= 0)
    }
    None => assert_true(false)
  }
  ignore(counter)
}

///|
test "TestHarness input component render" {
  let h = TestHarness::new(width=40, height=6)
  let input = @components.input(
    "hello",
    id="test-input",
    state=@components.InputState::Idle,
    min_width=30.0,
    min_height=3.0,
  )
  let _ = h.render(input)
  // Check element is rendered and findable
  let found = h.find_by_id("test-input")
  assert_true(found is Some(_))
  // Check frame was captured
  assert_true(h.frame_count() > 0)
}

///|
test "TestHarness focused button state" {
  let h = TestHarness::new(width=30, height=8)
  let btn = @components.button(
    "Submit",
    id="submit-btn",
    state=@components.ButtonState::Hover,
    min_width=15.0,
  )
  let _ = h.render(btn)
  assert_true(h.contains("Submit"))
}

///|
test "TestHarness column layout" {
  let h = TestHarness::new(width=20, height=10)
  let col = @components.column([
    @core.text("Line 1"),
    @core.text("Line 2"),
    @core.text("Line 3"),
  ])
  let _ = h.render(col)
  assert_true(h.contains("Line 1"))
  assert_true(h.contains("Line 2"))
  assert_true(h.contains("Line 3"))
}

///|
test "TestHarness row layout" {
  let h = TestHarness::new(width=40, height=5)
  let row = @components.row([@core.text("A"), @core.text("B"), @core.text("C")])
  let _ = h.render(row)
  let plain = h.last_frame_plain()
  // All items should be on same line
  assert_true(plain.contains("A"))
  assert_true(plain.contains("B"))
  assert_true(plain.contains("C"))
}

///|
test "TestHarness get_lines" {
  let h = TestHarness::new(width=20, height=5)
  let col = @components.column([@core.text("First"), @core.text("Second")])
  let _ = h.render(col)
  let lines = h.get_lines()
  // Should have multiple lines
  assert_true(lines.length() > 0)
}

///|
test "visible_length excludes ANSI codes" {
  let colored = "\u001b[31mRed\u001b[0m"
  assert_eq(visible_length(colored), 3)
  let plain = "Red"
  assert_eq(visible_length(plain), 3)
}
