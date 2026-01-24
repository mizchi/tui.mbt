///|
/// Input component verification tests using VirtualTerminal
/// These tests render components to ANSI and process through VirtualTerminal
/// to verify actual screen output
///
/// NOTE: Bordered input with default min_height renders only border (no content area).
/// Use input_plain for text content verification, or button for bordered text.

///|
/// Helper to render component to VirtualTerminal
fn render_to_vt(
  component : @core.Component,
  width : Int,
  height : Int,
) -> VirtualTerminal {
  let app = @render.App::new(width, height)
  let ansi = app.render_frame(component)
  let vt = VirtualTerminal::new(width, height)
  vt.write(ansi)
  vt
}

// =============================================================================
// input_plain tests (text is directly visible)
// =============================================================================

///|
test "VT input_plain: displays value text" {
  let input = @components.input_plain("Hello World")
  let vt = render_to_vt(input, 20, 3)
  assert_true(vt.contains("Hello World"))
}

///|
test "VT input_plain: displays placeholder when empty" {
  let input = @components.input_plain(
    "",
    placeholder="Enter text...",
    state=@components.InputState::Idle,
  )
  let vt = render_to_vt(input, 20, 3)
  assert_true(vt.contains("Enter text..."))
}

///|
test "VT input_plain: editing state shows cursor" {
  let input = @components.input_plain(
    "Test",
    state=@components.InputState::Editing,
  )
  let vt = render_to_vt(input, 15, 3)
  assert_true(vt.contains("Test_"))
}

///|
test "VT input_plain: editing state empty shows cursor only" {
  let input = @components.input_plain(
    "",
    placeholder="Type here",
    state=@components.InputState::Editing,
  )
  let vt = render_to_vt(input, 20, 3)
  // Should show cursor, not placeholder
  assert_true(vt.contains("_"))
  assert_false(vt.contains("Type here"))
}

///|
test "VT input_plain: idle state no cursor" {
  let input = @components.input_plain(
    "Value",
    state=@components.InputState::Idle,
  )
  let vt = render_to_vt(input, 15, 3)
  assert_true(vt.contains("Value"))
  assert_false(vt.contains("Value_"))
}

///|
test "VT input_plain: CJK text rendering" {
  let input = @components.input_plain("日本語入力")
  let vt = render_to_vt(input, 20, 3)
  assert_true(vt.contains("日本語入力"))
}

///|
test "VT input_plain: mixed ASCII and CJK" {
  let input = @components.input_plain("Hello世界")
  let vt = render_to_vt(input, 20, 3)
  assert_true(vt.contains("Hello"))
  assert_true(vt.contains("世界"))
}

///|
test "VT input_plain: CJK placeholder" {
  let input = @components.input_plain(
    "",
    placeholder="テキストを入力",
    state=@components.InputState::Idle,
  )
  let vt = render_to_vt(input, 25, 3)
  assert_true(vt.contains("テキストを入力"))
}

// =============================================================================
// Bordered input structural tests
// =============================================================================

///|
test "VT input: renders rounded border" {
  let input = @components.input("X", min_width=10.0, min_height=3.0)
  let vt = render_to_vt(input, 15, 5)
  // Rounded border characters
  assert_true(vt.contains("╭"))
  assert_true(vt.contains("╯"))
}

///|
test "VT input: border findable by id" {
  let input = @components.input(
    "value",
    id="my-input",
    min_width=15.0,
    min_height=3.0,
  )
  let app = @render.App::new(20, 5)
  let _ = app.render_frame(input)
  match app.find_by_id("my-input") {
    Some(result) => {
      assert_eq(result.id, "my-input")
      assert_true(result.width > 0)
      assert_true(result.height > 0)
    }
    None => fail("Input element not found by id")
  }
}

// =============================================================================
// State transition tests with input_plain
// =============================================================================

///|
test "VT input_plain: state transitions render differently" {
  let width = 15
  let height = 3

  // Idle state
  let idle = @components.input_plain("Text", state=@components.InputState::Idle)
  let vt_idle = render_to_vt(idle, width, height)

  // Editing state
  let editing = @components.input_plain(
    "Text",
    state=@components.InputState::Editing,
  )
  let vt_editing = render_to_vt(editing, width, height)

  // Both should contain the text
  assert_true(vt_idle.contains("Text"))
  assert_true(vt_editing.contains("Text"))

  // Only editing should have cursor
  assert_false(vt_idle.contains("Text_"))
  assert_true(vt_editing.contains("Text_"))
}

// =============================================================================
// Button text tests (bordered component with visible text)
// =============================================================================

///|
test "VT button: displays text inside border" {
  let btn = @components.button("Click Me", min_width=15.0)
  let vt = render_to_vt(btn, 20, 5)
  assert_true(vt.contains("Click Me"))
  assert_true(vt.contains("╭"))
  assert_true(vt.contains("╯"))
}

///|
test "VT button: CJK text" {
  let btn = @components.button("送信", min_width=10.0)
  let vt = render_to_vt(btn, 15, 5)
  assert_true(vt.contains("送信"))
}

// =============================================================================
// Form layout tests
// =============================================================================

///|
test "VT form: multiple input_plain in column" {
  let form = @components.column([
    @components.input_plain("Username"),
    @components.input_plain("Password"),
  ])
  let vt = render_to_vt(form, 20, 5)
  assert_true(vt.contains("Username"))
  assert_true(vt.contains("Password"))
}

///|
test "VT form: labeled input_plain in row" {
  let row = @components.row([
    @core.text("Name: "),
    @components.input_plain("John"),
  ])
  let vt = render_to_vt(row, 25, 3)
  assert_true(vt.contains("Name:"))
  assert_true(vt.contains("John"))
}

///|
test "VT form: buttons and text" {
  let form = @components.column([
    @core.text("Welcome"),
    @components.row([
      @components.button("OK", min_width=8.0),
      @components.button("Cancel", min_width=10.0),
    ]),
  ])
  let vt = render_to_vt(form, 30, 8)
  assert_true(vt.contains("Welcome"))
  assert_true(vt.contains("OK"))
  assert_true(vt.contains("Cancel"))
}

// =============================================================================
// Diff rendering tests (partial update)
// =============================================================================

///|
test "VT input_plain: diff update changes value" {
  let width = 20
  let height = 3
  let vt = VirtualTerminal::new(width, height)
  let app = @render.App::new(width, height)

  // Initial render with "Hello"
  let input1 = @components.input_plain(
    "Hello",
    state=@components.InputState::Editing,
  )
  let ansi1 = app.render_frame(input1)
  vt.write(ansi1)
  assert_true(vt.contains("Hello_"))

  // Update to "Hello World"
  let input2 = @components.input_plain(
    "Hello World",
    state=@components.InputState::Editing,
  )
  let ansi2 = app.render_frame(input2)
  vt.write(ansi2)
  assert_true(vt.contains("Hello World_"))
}

///|
test "VT: typing simulation" {
  let width = 20
  let height = 3
  let vt = VirtualTerminal::new(width, height)
  let app = @render.App::new(width, height)

  // Simulate typing character by character
  let chars = ["H", "e", "l", "l", "o"]
  let mut text = ""
  for c in chars {
    text = text + c
    let input = @components.input_plain(
      text,
      state=@components.InputState::Editing,
    )
    let ansi = app.render_frame(input)
    vt.write(ansi)
  }

  // Final state should have "Hello_"
  assert_true(vt.contains("Hello_"))
}

// =============================================================================
// Cell-level verification tests
// =============================================================================

///|
test "VT: verify cell colors in text" {
  let text = @core.text("X", fg=@core.Color::rgb(255, 0, 0))
  let vt = render_to_vt(text, 10, 3)

  // Find the 'X' character and verify it has red color
  let mut found_x = false
  for y = 0; y < 3; y = y + 1 {
    for x = 0; x < 10; x = x + 1 {
      let cell = vt.get_cell(x, y)
      if cell.char == 'X' {
        found_x = true
        // Should have red foreground
        assert_true(cell.fg.r > 200)
      }
    }
  }
  assert_true(found_x)
}

///|
test "VT: verify border cell in button" {
  let btn = @components.button("A", min_width=5.0)
  let vt = render_to_vt(btn, 10, 5)

  // Find top-left corner
  let mut found_corner = false
  for y = 0; y < 5; y = y + 1 {
    for x = 0; x < 10; x = x + 1 {
      let cell = vt.get_cell(x, y)
      if cell.char == '╭' {
        found_corner = true
        break
      }
    }
    if found_corner {
      break
    }
  }
  assert_true(found_corner)
}

// =============================================================================
// Focus navigation simulation
// =============================================================================

///|
test "VT: focus navigation between elements" {
  // Create focus navigator
  let focus = @components.FocusNav::new(["input1", "input2"])

  // Focus first element
  focus.set("input1")
  assert_eq(focus.get(), "input1")

  // Tab to next
  let tab_event = @events.parse_input(key_tab())
  let handled = focus.handle_tab(tab_event)
  assert_true(handled)
  assert_eq(focus.get(), "input2")

  // BackTab to previous
  let backtab_event = @events.parse_input(key_backtab())
  let handled2 = focus.handle_tab(backtab_event)
  assert_true(handled2)
  assert_eq(focus.get(), "input1")
}

// =============================================================================
// Input state rendering tests
// =============================================================================

///|
test "VT: input state colors differ" {
  let width = 20
  let height = 3

  // Idle state (placeholder color)
  let idle = @components.input_plain(
    "",
    placeholder="text",
    state=@components.InputState::Idle,
  )
  let vt_idle = render_to_vt(idle, width, height)

  // Find 't' character
  let mut idle_fg : @core.Color = @core.Color::white()
  for x = 0; x < width; x = x + 1 {
    let cell = vt_idle.get_cell(x, 0)
    if cell.char == 't' {
      idle_fg = cell.fg
      break
    }
  }

  // Editing state (normal color)
  let editing = @components.input_plain(
    "text",
    state=@components.InputState::Editing,
  )
  let vt_editing = render_to_vt(editing, width, height)
  let mut editing_fg : @core.Color = @core.Color::white()
  for x = 0; x < width; x = x + 1 {
    let cell = vt_editing.get_cell(x, 0)
    if cell.char == 't' {
      editing_fg = cell.fg
      break
    }
  }

  // Colors should be different (placeholder is gray, editing is white)
  assert_true(idle_fg != editing_fg)
}
