///|
/// Input component behavior tests
/// Tests the rendering and state transitions of Input
///
/// NOTE: Input uses texts.set() for text wrapping support,
/// which means text content is not directly visible in plain output.
/// We test structure, element finding, and key parsing instead.

///|
test "Input element is findable by id" {
  let h = TestHarness::new(width=30, height=5)
  let input = @components.input(
    "value",
    id="my-input",
    state=@components.InputState::Idle,
    min_width=20.0,
  )
  let _ = h.render(input)
  match h.find_by_id("my-input") {
    Some(result) => {
      assert_eq(result.id, "my-input")
      // Element should have position
      assert_true(result.x >= 0)
      assert_true(result.y >= 0)
      assert_true(result.width > 0)
      assert_true(result.height > 0)
    }
    None => fail("Input element not found by id")
  }
}

///|
test "Input renders border (structural test)" {
  let h = TestHarness::new(width=30, height=5)
  let _ = h.render(
    @components.input(
      "test",
      state=@components.InputState::Idle,
      min_width=15.0,
      min_height=3.0,
    ),
  )
  // Input has rounded border
  let plain = h.last_frame_plain()
  assert_true(plain.contains("╭") || plain.contains("┌"))
  assert_true(plain.contains("╯") || plain.contains("┘"))
}

///|
test "Input states produce different renders" {
  let h = TestHarness::new(width=30, height=5)

  // Idle state
  let _ = h.render(
    @components.input("v", state=@components.InputState::Idle, min_width=15.0),
  )
  let idle_frame = h.last_frame()
  h.clear_frames()

  // Focused state (different border color)
  let _ = h.render(
    @components.input(
      "v",
      state=@components.InputState::Focused,
      min_width=15.0,
    ),
  )
  let focused_frame = h.last_frame()
  h.clear_frames()

  // Editing state (different border color)
  let _ = h.render(
    @components.input(
      "v",
      state=@components.InputState::Editing,
      min_width=15.0,
    ),
  )
  let editing_frame = h.last_frame()

  // All should be different due to border color changes
  // (ANSI codes differ even if plain text is same)
  assert_true(idle_frame != focused_frame || idle_frame != editing_frame)
}

///|
test "key_enter parses to Enter event" {
  let event = @events.parse_input(key_enter())
  assert_true(event.is_enter())
}

///|
test "key_tab parses to Tab event" {
  let event = @events.parse_input(key_tab())
  assert_true(event.is_tab())
}

///|
test "key_backtab parses to BackTab event" {
  let event = @events.parse_input(key_backtab())
  assert_true(event.is_backtab())
}

///|
test "ctrl+c parses correctly" {
  let event = @events.parse_input(ctrl('c'))
  assert_true(event.is_ctrl_c())
}

///|
test "arrow keys parse correctly" {
  let up = @events.parse_input(key_up())
  let down = @events.parse_input(key_down())
  let left = @events.parse_input(key_left())
  let right = @events.parse_input(key_right())

  // All should be arrow events
  assert_true(up.is_arrow() is Some(_))
  assert_true(down.is_arrow() is Some(_))
  assert_true(left.is_arrow() is Some(_))
  assert_true(right.is_arrow() is Some(_))

  // Check specific directions
  match up.is_arrow() {
    Some(@events.SpecialKey::Up) => ()
    _ => fail("Expected Up arrow")
  }
  match down.is_arrow() {
    Some(@events.SpecialKey::Down) => ()
    _ => fail("Expected Down arrow")
  }
}

///|
test "character input parses correctly" {
  let a = @events.parse_input("a")
  let z = @events.parse_input("z")
  let num = @events.parse_input("5")
  assert_true(a.is_char('a'))
  assert_true(z.is_char('z'))
  assert_true(num.is_char('5'))
}

///|
test "mouse click at coordinates" {
  let click = @events.parse_input(mouse_click(15, 8))
  match click {
    @events.InputEvent::Mouse(m) => {
      assert_eq(m.x, 15)
      assert_eq(m.y, 8)
      assert_true(m.button is @events.MouseButton::Left)
      assert_true(m.event_type is @events.MouseEventType::Press)
    }
    _ => fail("Expected mouse event")
  }
}

///|
test "hit_test finds element at coordinates" {
  let h = TestHarness::new(width=30, height=10)
  let btn = @components.button("Click", id="test-btn", min_width=10.0)
  let _ = h.render(btn)

  // Find the button's position
  match h.find_by_id("test-btn") {
    Some(bounds) => {
      // Hit test at button center
      let center_x = bounds.x + bounds.width / 2
      let center_y = bounds.y + bounds.height / 2
      match h.hit_test(center_x, center_y) {
        Some(hit) => assert_eq(hit.id, "test-btn")
        None => fail("hit_test failed at button center")
      }
    }
    None => fail("Button not found")
  }
}

///|
test "Button text is visible in output" {
  let h = TestHarness::new(width=30, height=8)
  let btn = @components.button(
    "Submit",
    id="submit-btn",
    state=@components.ButtonState::Normal,
    min_width=15.0,
  )
  let _ = h.render(btn)
  // Button uses text as child, so it's visible
  assert_true(h.contains("Submit"))
}

///|
test "FocusNav state changes render differently" {
  let h = TestHarness::new(width=40, height=8)
  let focus = @components.FocusNav::new(["input1", "input2", "btn"])

  // Initially unfocused
  let input1_idle = @components.input(
    "first",
    id="input1",
    state=focus.input_state("input1"),
    min_width=15.0,
  )
  let _ = h.render(input1_idle)
  let unfocused_frame = h.last_frame()

  // Focus on input1
  focus.set("input1")
  h.clear_frames()
  let input1_focused = @components.input(
    "first",
    id="input1",
    state=focus.input_state("input1"),
    min_width=15.0,
  )
  let _ = h.render(input1_focused)
  let focused_frame = h.last_frame()

  // Frames should be different (focus changes border color)
  assert_true(unfocused_frame != focused_frame)
}

///|
test "FocusNav::next cycles through elements" {
  let focus = @components.FocusNav::new(["a", "b", "c"])
  assert_eq(focus.get(), "") // Initially unfocused
  focus.next()
  assert_eq(focus.get(), "a")
  focus.next()
  assert_eq(focus.get(), "b")
  focus.next()
  assert_eq(focus.get(), "c")
  focus.next()
  assert_eq(focus.get(), "a") // Wraps around
}

///|
test "FocusNav::prev cycles backwards" {
  let focus = @components.FocusNav::new(["a", "b", "c"])
  focus.set("c")
  assert_eq(focus.get(), "c")
  focus.prev()
  assert_eq(focus.get(), "b")
  focus.prev()
  assert_eq(focus.get(), "a")
  focus.prev()
  assert_eq(focus.get(), "c") // Wraps around
}

///|
test "FocusNav::handle_tab moves focus" {
  let focus = @components.FocusNav::new(["x", "y", "z"])
  focus.set("x")
  let tab_event = @events.parse_input(key_tab())
  let handled = focus.handle_tab(tab_event)
  assert_true(handled)
  assert_eq(focus.get(), "y")
}

///|
test "FocusNav::handle_tab with backtab moves backwards" {
  let focus = @components.FocusNav::new(["x", "y", "z"])
  focus.set("y")
  let backtab_event = @events.parse_input(key_backtab())
  let handled = focus.handle_tab(backtab_event)
  assert_true(handled)
  assert_eq(focus.get(), "x")
}
