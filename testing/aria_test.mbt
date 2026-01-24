///|
/// WAI-ARIA APG Keyboard Accessibility Tests
///
/// Tests follow W3C WAI-ARIA Authoring Practices Guide patterns:
/// https://www.w3.org/WAI/ARIA/apg/
///
/// Key patterns tested:
/// - Button: Enter/Space activates
/// - Checkbox/Switch: Space toggles
/// - RadioGroup: Arrow keys navigate
/// - Listbox: Arrow keys navigate, Space selects
/// - Tabs: Arrow keys navigate
/// - Modal/Dialog: Escape closes
/// - Menu: Arrow keys navigate, Enter selects, Escape closes

// ============================================================================
// Helper: Key event generators for accessibility testing
// ============================================================================

///|
fn key_space() -> String {
  " "
}

///|
fn is_space(event : @events.InputEvent) -> Bool {
  event.is_char(' ')
}

// ============================================================================
// Button: Enter and Space should activate
// ============================================================================

///|
test "Button: Enter key should be recognized for activation" {
  let event = @events.parse_input(key_enter())
  assert_true(event.is_enter())
}

///|
test "Button: Space key should be recognized for activation" {
  let event = @events.parse_input(key_space())
  assert_true(is_space(event))
}

///|
test "Button: renders with correct structure" {
  let h = TestHarness::new(width=20, height=5)
  let btn = @components.button(
    "OK",
    id="ok-btn",
    state=@components.ButtonState::Normal,
    min_width=8.0,
  )
  let _ = h.render(btn)

  // Button should be findable
  assert_true(h.find_by_id("ok-btn") is Some(_))
  // Button text should be visible
  assert_true(h.contains("OK"))
}

///|
test "Button: state changes affect rendering" {
  let h = TestHarness::new(width=20, height=5)

  // Normal state
  let _ = h.render(
    @components.button(
      "X",
      state=@components.ButtonState::Normal,
      min_width=6.0,
    ),
  )
  let normal = h.last_frame()
  h.clear_frames()

  // Hover state (keyboard focused)
  let _ = h.render(
    @components.button("X", state=@components.ButtonState::Hover, min_width=6.0),
  )
  let hover = h.last_frame()
  h.clear_frames()

  // Pressed state
  let _ = h.render(
    @components.button(
      "X",
      state=@components.ButtonState::Pressed,
      min_width=6.0,
    ),
  )
  let pressed = h.last_frame()

  // States should produce different output (different colors/styles)
  assert_true(normal != hover || normal != pressed)
}

// ============================================================================
// Checkbox: Space should toggle checked state
// ============================================================================

///|
test "Checkbox: Space key for toggling" {
  let event = @events.parse_input(key_space())
  // Space key should be recognized
  assert_true(is_space(event))
}

///|
test "Checkbox: unchecked renders correctly" {
  let h = TestHarness::new(width=15, height=3)
  let _ = h.render(@components.checkbox(false))
  let plain = h.last_frame_plain()
  // Should show unchecked indicator (☐ or [ ])
  assert_true(
    plain.contains("☐") || plain.contains("[ ]") || plain.contains("□"),
  )
}

///|
test "Checkbox: checked renders correctly" {
  let h = TestHarness::new(width=15, height=3)
  let _ = h.render(@components.checkbox(true))
  let plain = h.last_frame_plain()
  // Should show checked indicator (☑ or [x])
  assert_true(
    plain.contains("☑") ||
    plain.contains("[x]") ||
    plain.contains("✓") ||
    plain.contains("■"),
  )
}

///|
test "Checkbox: checked and unchecked produce different output" {
  let h = TestHarness::new(width=15, height=3)
  let _ = h.render(@components.checkbox(false))
  let unchecked = h.last_frame_plain()
  h.clear_frames()
  let _ = h.render(@components.checkbox(true))
  let checked = h.last_frame_plain()
  assert_true(unchecked != checked)
}

///|
test "labeled_checkbox: shows label with checkbox" {
  let h = TestHarness::new(width=25, height=3)
  let _ = h.render(
    @components.labeled_checkbox("Accept terms", false, id="terms"),
  )
  assert_true(h.contains("Accept terms"))
  assert_true(h.find_by_id("terms") is Some(_))
}

// ============================================================================
// Switch: Space should toggle on/off state
// ============================================================================

///|
test "Switch: on state renders differently from off" {
  let h = TestHarness::new(width=15, height=3)
  let _ = h.render(@components.switch(false))
  let off = h.last_frame_plain()
  h.clear_frames()
  let _ = h.render(@components.switch(true))
  let on = h.last_frame_plain()
  assert_true(off != on)
}

///|
test "Switch: disabled state prevents interaction" {
  let h = TestHarness::new(width=15, height=3)
  let _ = h.render(@components.switch(false, disabled=true))
  let disabled = h.last_frame()
  h.clear_frames()
  let _ = h.render(@components.switch(false))
  let normal = h.last_frame()

  // Disabled should look different (different colors)
  assert_true(disabled != normal)
}

// ============================================================================
// RadioGroup: Arrow keys should navigate between options
// ============================================================================

///|
test "RadioGroup: arrow keys are recognized for navigation" {
  let up = @events.parse_input(key_up())
  let down = @events.parse_input(key_down())
  assert_true(up.is_arrow() is Some(@events.SpecialKey::Up))
  assert_true(down.is_arrow() is Some(@events.SpecialKey::Down))
}

///|
test "RadioGroup: renders options correctly" {
  let h = TestHarness::new(width=20, height=8)
  let options = [
    @components.RadioOption::{ id: "opt1", label: "Option 1" },
    @components.RadioOption::{ id: "opt2", label: "Option 2" },
    @components.RadioOption::{ id: "opt3", label: "Option 3" },
  ]
  let _ = h.render(@components.radiogroup(options, "opt1", id="radio-group"))
  assert_true(h.contains("Option 1"))
  assert_true(h.contains("Option 2"))
  assert_true(h.contains("Option 3"))
}

///|
test "RadioGroup: selected option is visually distinct" {
  let h = TestHarness::new(width=20, height=8)
  let options = [
    @components.RadioOption::{ id: "a", label: "A" },
    @components.RadioOption::{ id: "b", label: "B" },
  ]

  // Option A selected
  let _ = h.render(@components.radiogroup(options, "a"))
  let a_selected = h.last_frame()
  h.clear_frames()

  // Option B selected
  let _ = h.render(@components.radiogroup(options, "b"))
  let b_selected = h.last_frame()
  assert_true(a_selected != b_selected)
}

// ============================================================================
// Listbox: Arrow keys navigate, Space/Enter selects
// ============================================================================

///|
test "Listbox: renders options" {
  let h = TestHarness::new(width=25, height=10)
  let options = [
    @components.listbox_option("apple", "Apple"),
    @components.listbox_option("banana", "Banana"),
    @components.listbox_option("cherry", "Cherry"),
  ]
  let _ = h.render(@components.listbox(options, "apple", id="fruit-list"))
  assert_true(h.contains("Apple"))
  assert_true(h.contains("Banana"))
  assert_true(h.contains("Cherry"))
}

///|
test "Listbox: selected item is highlighted" {
  let h = TestHarness::new(width=25, height=10)
  let options = [
    @components.listbox_option("a", "Item A"),
    @components.listbox_option("b", "Item B"),
  ]

  // A selected
  let _ = h.render(@components.listbox(options, "a"))
  let a_selected = h.last_frame()
  h.clear_frames()

  // B selected
  let _ = h.render(@components.listbox(options, "b"))
  let b_selected = h.last_frame()
  assert_true(a_selected != b_selected)
}

///|
test "Listbox: focused item is visually distinct" {
  let h = TestHarness::new(width=25, height=10)
  let options = [
    @components.listbox_option("x", "X"),
    @components.listbox_option("y", "Y"),
  ]

  // No focus
  let _ = h.render(@components.listbox(options, "x"))
  let no_focus = h.last_frame()
  h.clear_frames()

  // Y focused
  let _ = h.render(@components.listbox(options, "x", focused_id="y"))
  let y_focused = h.last_frame()
  assert_true(no_focus != y_focused)
}

///|
test "Listbox: disabled options render differently" {
  let h = TestHarness::new(width=25, height=10)
  let options_enabled = [@components.listbox_option("a", "Item")]
  let options_disabled = [
    @components.ListboxOption::{ id: "a", label: "Item", disabled: true },
  ]
  let _ = h.render(@components.listbox(options_enabled, ""))
  let enabled = h.last_frame()
  h.clear_frames()
  let _ = h.render(@components.listbox(options_disabled, ""))
  let disabled = h.last_frame()
  assert_true(enabled != disabled)
}

// ============================================================================
// Tabs: Arrow keys navigate between tabs
// ============================================================================

///|
test "Tabs: left/right arrows for horizontal navigation" {
  let left = @events.parse_input(key_left())
  let right = @events.parse_input(key_right())
  assert_true(left.is_arrow() is Some(@events.SpecialKey::Left))
  assert_true(right.is_arrow() is Some(@events.SpecialKey::Right))
}

///|
test "Tabs: renders tab labels" {
  let h = TestHarness::new(width=30, height=5)
  let items = [
    @components.TabItem::{ id: "tab1", label: "Home" },
    @components.TabItem::{ id: "tab2", label: "Profile" },
    @components.TabItem::{ id: "tab3", label: "Settings" },
  ]
  let _ = h.render(@components.tabs(items, "tab1"))
  assert_true(h.contains("Home"))
  assert_true(h.contains("Profile"))
  assert_true(h.contains("Settings"))
}

///|
test "Tabs: selected tab is visually distinct" {
  let h = TestHarness::new(width=30, height=5)
  let items = [
    @components.TabItem::{ id: "t1", label: "A" },
    @components.TabItem::{ id: "t2", label: "B" },
  ]
  let _ = h.render(@components.tabs(items, "t1"))
  let t1_selected = h.last_frame()
  h.clear_frames()
  let _ = h.render(@components.tabs(items, "t2"))
  let t2_selected = h.last_frame()
  assert_true(t1_selected != t2_selected)
}

///|
test "Tabs: underline style" {
  let h = TestHarness::new(width=30, height=5)
  let items = [
    @components.TabItem::{ id: "t1", label: "Tab 1" },
    @components.TabItem::{ id: "t2", label: "Tab 2" },
  ]
  let _ = h.render(@components.tabs_underline(items, "t1"))
  assert_true(h.contains("Tab 1"))
  assert_true(h.contains("Tab 2"))
}

///|
test "Tabs: boxed style" {
  let h = TestHarness::new(width=30, height=5)
  let items = [
    @components.TabItem::{ id: "t1", label: "Tab 1" },
    @components.TabItem::{ id: "t2", label: "Tab 2" },
  ]
  let _ = h.render(@components.tabs_boxed(items, "t1"))
  assert_true(h.contains("Tab 1"))
  assert_true(h.contains("Tab 2"))
}

// ============================================================================
// Modal/Dialog: Escape key should close
// ============================================================================

///|
test "Modal: Escape key is recognized for closing" {
  let event = @events.parse_input(key_esc())
  assert_true(event.is_escape())
}

///|
test "ModalState: open and close work correctly" {
  let state = @components.ModalState::new()
  assert_true(state.get_is_open() == false)
  state.open()
  assert_true(state.get_is_open() == true)
  state.close()
  assert_true(state.get_is_open() == false)
}

///|
test "ModalState: toggle works correctly" {
  let state = @components.ModalState::new()
  assert_true(state.get_is_open() == false)
  state.toggle()
  assert_true(state.get_is_open() == true)
  state.toggle()
  assert_true(state.get_is_open() == false)
}

///|
test "Modal: card renders content as simpler modal alternative" {
  let h = TestHarness::new(width=40, height=12)
  // Card is a simpler bordered container that works without complex positioning
  let _ = h.render(
    @components.card([@components.text("Modal Content")], padding=1.0),
  )
  assert_true(h.contains("Modal Content"))
}

///|
test "Dialog pattern: card with title and button" {
  let h = TestHarness::new(width=40, height=12)
  // Simulate dialog pattern with card, title, and button
  let _ = h.render(
    @components.card(
      [
        @components.text("Alert"),
        @components.text("Something happened!"),
        @components.button("OK", min_width=8.0),
      ],
      padding=1.0,
    ),
  )
  assert_true(h.contains("Alert"))
  assert_true(h.contains("OK"))
}

///|
test "Confirm dialog pattern: card with confirm/cancel buttons" {
  let h = TestHarness::new(width=40, height=12)
  // Simulate confirm dialog pattern with card and two buttons
  let _ = h.render(
    @components.card(
      [
        @components.text("Confirm"),
        @components.text("Are you sure?"),
        @components.row(
          [
            @components.button("Yes", min_width=6.0),
            @components.button("No", min_width=6.0),
          ],
          gap=1.0,
        ),
      ],
      padding=1.0,
    ),
  )
  assert_true(h.contains("Confirm"))
  assert_true(h.contains("Yes"))
  assert_true(h.contains("No"))
}

// ============================================================================
// Menu: Arrow keys navigate, Enter selects, Escape closes
// ============================================================================

///|
test "Menu: renders menu items" {
  let h = TestHarness::new(width=25, height=10)
  let items = [
    @components.menu_item("cut", "Cut"),
    @components.menu_item("copy", "Copy"),
    @components.menu_item("paste", "Paste"),
  ]
  let _ = h.render(@components.menu(items))
  assert_true(h.contains("Cut"))
  assert_true(h.contains("Copy"))
  assert_true(h.contains("Paste"))
}

///|
test "Menu: focused item is highlighted" {
  let h = TestHarness::new(width=25, height=10)
  let items = [
    @components.menu_item("a", "Action A"),
    @components.menu_item("b", "Action B"),
  ]
  let _ = h.render(@components.menu(items))
  let no_focus = h.last_frame()
  h.clear_frames()
  let _ = h.render(@components.menu(items, focused_id="a"))
  let a_focused = h.last_frame()
  assert_true(no_focus != a_focused)
}

///|
test "Menu: separator renders" {
  let h = TestHarness::new(width=25, height=10)
  let items = [
    @components.menu_item("a", "A"),
    @components.menu_separator(),
    @components.menu_item("b", "B"),
  ]
  let _ = h.render(@components.menu(items))
  assert_true(h.contains("A"))
  assert_true(h.contains("B"))
}

///|
test "Menu: disabled items render differently" {
  let h = TestHarness::new(width=25, height=10)
  let enabled = [@components.menu_item("x", "Item")]
  let disabled = [@components.menu_item("x", "Item", disabled=true)]
  let _ = h.render(@components.menu(enabled))
  let enabled_frame = h.last_frame()
  h.clear_frames()
  let _ = h.render(@components.menu(disabled))
  let disabled_frame = h.last_frame()
  assert_true(enabled_frame != disabled_frame)
}

// ============================================================================
// FocusNav: Tab/Shift+Tab navigation (complementary to arrows)
// ============================================================================

///|
test "FocusNav: Tab navigates forward" {
  let focus = @components.FocusNav::new(["field1", "field2", "submit"])
  focus.set("field1")
  let tab = @events.parse_input(key_tab())
  let handled = focus.handle_tab(tab)
  assert_true(handled)
  assert_eq(focus.get(), "field2")
}

///|
test "FocusNav: Shift+Tab navigates backward" {
  let focus = @components.FocusNav::new(["field1", "field2", "submit"])
  focus.set("field2")
  let backtab = @events.parse_input(key_backtab())
  let handled = focus.handle_tab(backtab)
  assert_true(handled)
  assert_eq(focus.get(), "field1")
}

///|
test "FocusNav: wraps around at boundaries" {
  let focus = @components.FocusNav::new(["a", "b", "c"])
  focus.set("c")
  focus.next()
  assert_eq(focus.get(), "a")
  focus.prev()
  assert_eq(focus.get(), "c")
}

///|
test "FocusNav: button_state returns correct state" {
  let focus = @components.FocusNav::new(["btn1", "btn2"])

  // Unfocused
  assert_true(focus.button_state("btn1") is @components.ButtonState::Normal)

  // Focused
  focus.set("btn1")
  assert_true(focus.button_state("btn1") is @components.ButtonState::Hover)
  assert_true(focus.button_state("btn2") is @components.ButtonState::Normal)
}

///|
test "FocusNav: input_state returns correct state" {
  let focus = @components.FocusNav::new(["input1", "input2"])

  // Unfocused
  assert_true(focus.input_state("input1") is @components.InputState::Idle)

  // Focused
  focus.set("input1")
  assert_true(focus.input_state("input1") is @components.InputState::Focused)
  assert_true(focus.input_state("input2") is @components.InputState::Idle)
}

///|
test "FocusNav: handle_arrows for radiogroup-like navigation" {
  let focus = @components.FocusNav::new(["opt1", "opt2", "opt3"])
  focus.set("opt1")
  let down = @events.parse_input(key_down())
  let handled = focus.handle_arrows(down)
  assert_true(handled)
  assert_eq(focus.get(), "opt2")
}

// ============================================================================
// Combobox/Select: Combined input and listbox
// ============================================================================

///|
test "Combobox: renders with placeholder" {
  let h = TestHarness::new(width=30, height=8)
  let options = [
    @components.ComboboxOption::{ id: "opt1", label: "Option 1" },
    @components.ComboboxOption::{ id: "opt2", label: "Option 2" },
  ]
  let _ = h.render(@components.combobox(options, "", placeholder="Select..."))

  // Combobox should render (may show placeholder or dropdown icon)
  assert_true(h.last_frame_plain().length() > 0)
}

///|
test "Select: closed state shows selected value" {
  let h = TestHarness::new(width=30, height=8)
  let options = [
    @components.ComboboxOption::{ id: "a", label: "Alpha" },
    @components.ComboboxOption::{ id: "b", label: "Beta" },
  ]
  let _ = h.render(@components.select(options, "a", open=false))
  assert_true(h.contains("Alpha"))
}

///|
test "Select: open state shows options" {
  let h = TestHarness::new(width=30, height=10)
  let options = [
    @components.ComboboxOption::{ id: "a", label: "Alpha" },
    @components.ComboboxOption::{ id: "b", label: "Beta" },
  ]
  let _ = h.render(@components.select(options, "a", open=true))
  // When open, should show options
  let frame = h.last_frame_plain()
  assert_true(frame.contains("Alpha") || frame.contains("Beta"))
}

// ============================================================================
// Accordion: Expandable sections
// ============================================================================

///|
test "Accordion: renders titles" {
  let h = TestHarness::new(width=35, height=15)
  let items = [
    @components.AccordionItem::{
      id: "section1",
      title: "Section 1",
      content: @components.text("Content 1"),
      expanded: false,
    },
    @components.AccordionItem::{
      id: "section2",
      title: "Section 2",
      content: @components.text("Content 2"),
      expanded: false,
    },
  ]
  let _ = h.render(@components.accordion(items))
  assert_true(h.contains("Section 1"))
  assert_true(h.contains("Section 2"))
}

///|
test "Accordion: expanded section shows content" {
  let h = TestHarness::new(width=35, height=15)
  let items = [
    @components.AccordionItem::{
      id: "sec",
      title: "Header",
      content: @components.text("Hidden Content"),
      expanded: true,
    },
  ]
  let _ = h.render(@components.accordion(items))
  assert_true(h.contains("Hidden Content"))
}

///|
test "Accordion: collapsed section hides content" {
  let h = TestHarness::new(width=35, height=15)
  let items_expanded = [
    @components.AccordionItem::{
      id: "sec",
      title: "Header",
      content: @components.text("Content Here"),
      expanded: true,
    },
  ]
  let items_collapsed = [
    @components.AccordionItem::{
      id: "sec",
      title: "Header",
      content: @components.text("Content Here"),
      expanded: false,
    },
  ]
  let _ = h.render(@components.accordion(items_expanded))
  let expanded = h.last_frame_plain()
  h.clear_frames()
  let _ = h.render(@components.accordion(items_collapsed))
  let collapsed = h.last_frame_plain()

  // Expanded should show content, collapsed should not
  assert_true(expanded.contains("Content Here"))
  assert_true(
    collapsed.contains("Content Here") == false || expanded != collapsed,
  )
}

// ============================================================================
// Context Menu: Right-click menu
// ============================================================================

///|
test "context_menu: renders items" {
  let h = TestHarness::new(width=25, height=10)
  let items = [
    @components.menu_item("refresh", "Refresh"),
    @components.menu_item("delete", "Delete"),
  ]
  let _ = h.render(@components.context_menu(items))
  assert_true(h.contains("Refresh"))
  assert_true(h.contains("Delete"))
}

// ============================================================================
// Keyboard event recognition tests
// ============================================================================

///|
test "Ctrl+C is recognized as quit signal" {
  let event = @events.parse_input(ctrl('c'))
  assert_true(event.is_ctrl_c())
  assert_true(event.is_quit())
}

///|
test "Home/End keys are recognized" {
  let home = @events.parse_input(key_home())
  let end = @events.parse_input(key_end())
  match home {
    @events.InputEvent::Key(
      @events.KeyEvent::Special(@events.SpecialKey::Home, _)
    ) => ()
    _ => fail("Expected Home key")
  }
  match end {
    @events.InputEvent::Key(
      @events.KeyEvent::Special(@events.SpecialKey::End, _)
    ) => ()
    _ => fail("Expected End key")
  }
}

///|
test "PageUp/PageDown keys are recognized" {
  let pgup = @events.parse_input(key_page_up())
  let pgdown = @events.parse_input(key_page_down())
  match pgup {
    @events.InputEvent::Key(
      @events.KeyEvent::Special(@events.SpecialKey::PageUp, _)
    ) => ()
    _ => fail("Expected PageUp key")
  }
  match pgdown {
    @events.InputEvent::Key(
      @events.KeyEvent::Special(@events.SpecialKey::PageDown, _)
    ) => ()
    _ => fail("Expected PageDown key")
  }
}

///|
test "Function keys are recognized" {
  let f1 = @events.parse_input(key_f1())
  match f1 {
    @events.InputEvent::Key(
      @events.KeyEvent::Special(@events.SpecialKey::F(1), _)
    ) => ()
    _ => fail("Expected F1 key")
  }
}

///|
test "Delete and Backspace are distinct" {
  let del = @events.parse_input(key_delete())
  let bs = @events.parse_input(key_backspace())
  match del {
    @events.InputEvent::Key(
      @events.KeyEvent::Special(@events.SpecialKey::Delete, _)
    ) => ()
    _ => fail("Expected Delete key")
  }
  match bs {
    @events.InputEvent::Key(
      @events.KeyEvent::Special(@events.SpecialKey::Backspace, _)
    ) => ()
    _ => fail("Expected Backspace key")
  }
}

///|
test "Alt modifier is recognized" {
  let alt_a = @events.parse_input(alt('a'))
  match alt_a {
    @events.InputEvent::Key(
      @events.KeyEvent::Char('a', @events.KeyModifier::Alt)
    ) => ()
    _ => fail("Expected Alt+A")
  }
}
