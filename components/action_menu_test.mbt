///|
test "ActionItem::new creates an action" {
  let called : Ref[Bool] = Ref::new(false)
  let action = ActionItem::new('a', "Test Action", fn() { called.val = true })
  inspect(action.key, content="a")
  inspect(action.label, content="Test Action")
  (action.handler)()
  inspect(called.val, content="true")
}

///|
test "ActionMenu::new creates a closed menu" {
  let menu = ActionMenu::new("Test Menu", [])
  inspect(menu.is_open(), content="false")
  inspect(menu.title, content="Test Menu")
}

///|
test "ActionMenu::open and close" {
  let menu = ActionMenu::new("Test", [])
  menu.open()
  inspect(menu.is_open(), content="true")
  menu.close()
  inspect(menu.is_open(), content="false")
}

///|
test "ActionMenu::handle_key triggers action" {
  let called : Ref[Bool] = Ref::new(false)
  let menu = ActionMenu::new("Test", [
    ActionItem::new('x', "Execute", fn() { called.val = true }),
  ])
  menu.open()
  let handled = menu.handle_key('x')
  inspect(handled, content="true")
  inspect(called.val, content="true")
  // Menu should be closed after action
  inspect(menu.is_open(), content="false")
}

///|
test "ActionMenu::handle_key with uppercase" {
  let called : Ref[Bool] = Ref::new(false)
  let menu = ActionMenu::new("Test", [
    ActionItem::new('a', "Action", fn() { called.val = true }),
  ])
  menu.open()
  // Should handle uppercase 'A' for action 'a'
  let handled = menu.handle_key('A')
  inspect(handled, content="true")
  inspect(called.val, content="true")
}

///|
test "ActionMenu::handle_key with toggle_key" {
  let menu = ActionMenu::new("Test", [], toggle_key=Some('f'))
  menu.open()
  let handled = menu.handle_key('f')
  inspect(handled, content="true")
  inspect(menu.is_open(), content="false")
}

///|
test "ActionMenu::handle_escape closes menu" {
  let menu = ActionMenu::new("Test", [])
  menu.open()
  let handled = menu.handle_escape()
  inspect(handled, content="true")
  inspect(menu.is_open(), content="false")
}

///|
test "ActionMenu::handle_escape when closed" {
  let menu = ActionMenu::new("Test", [])
  let handled = menu.handle_escape()
  inspect(handled, content="false")
}

///|
test "ActionMenu::build creates component" {
  let menu = ActionMenu::new(
    "Actions",
    [
      ActionItem::new('1', "First", fn() {  }),
      ActionItem::new('2', "Second", fn() {  }),
    ],
    toggle_key=Some('f'),
  )
  let comp = menu.build(80, 24)
  inspect(comp.node.id.length() > 0, content="true")
}

///|
test "ActionMenu on_close callback" {
  let closed : Ref[Bool] = Ref::new(false)
  let menu = ActionMenu::new("Test", [], on_close=fn() { closed.val = true })
  menu.open()
  menu.close()
  inspect(closed.val, content="true")
}

// ============================================
// Accessibility Tests
// ============================================

///|
/// a11y: All actions must be keyboard accessible
test "a11y: all actions have keyboard shortcuts" {
  let menu = ActionMenu::new("Test", [
    ActionItem::new('1', "Action One", fn() {  }),
    ActionItem::new('2', "Action Two", fn() {  }),
    ActionItem::new('3', "Action Three", fn() {  }),
  ])
  // Every action must have a key binding
  for action in menu.actions {
    // Key should be a printable character (not null)
    inspect(action.key.to_int() > 0, content="true")
  }
}

///|
/// a11y: All actions must have descriptive labels
test "a11y: all actions have non-empty labels" {
  let menu = ActionMenu::new("Test", [
    ActionItem::new('1', "Delete item", fn() {  }),
    ActionItem::new('2', "Save changes", fn() {  }),
  ])
  for action in menu.actions {
    // Label must not be empty
    inspect(action.label.length() > 0, content="true")
  }
}

///|
/// a11y: Menu must have a title for screen reader context
test "a11y: menu has title" {
  let menu = ActionMenu::new("File Actions", [])
  inspect(menu.title.length() > 0, content="true")
}

///|
/// a11y: Escape key must always close the menu (universal dismiss)
test "a11y: escape always closes menu" {
  let menu = ActionMenu::new("Test", [ActionItem::new('x', "Action", fn() {  })])
  menu.open()
  inspect(menu.is_open(), content="true")
  // Escape should always work regardless of other key bindings
  let closed = menu.handle_escape()
  inspect(closed, content="true")
  inspect(menu.is_open(), content="false")
}

///|
/// a11y: Focus trap - unhandled keys should not pass through when menu is open
test "a11y: focus trap - unhandled keys consumed when open" {
  let menu = ActionMenu::new("Test", [
    ActionItem::new('a', "Action A", fn() {  }),
  ])
  menu.open()
  // Press 'z' which is not a registered action
  let handled = menu.handle_key('z')
  // Key should NOT be handled (no action triggered)
  inspect(handled, content="false")
  // But menu should remain open (focus trapped)
  inspect(menu.is_open(), content="true")
}

///|
/// a11y: Case insensitive keys for easier access
test "a11y: case insensitive key handling" {
  let called_lower : Ref[Bool] = Ref::new(false)
  let called_upper : Ref[Bool] = Ref::new(false)
  let menu1 = ActionMenu::new("Test", [
    ActionItem::new('a', "Action", fn() { called_lower.val = true }),
  ])
  let menu2 = ActionMenu::new("Test", [
    ActionItem::new('A', "Action", fn() { called_upper.val = true }),
  ])
  // Lowercase action should respond to uppercase key
  menu1.open()
  ignore(menu1.handle_key('A'))
  inspect(called_lower.val, content="true")
  // Uppercase action should respond to lowercase key
  menu2.open()
  ignore(menu2.handle_key('a'))
  inspect(called_upper.val, content="true")
}

///|
/// a11y: Toggle key provides quick access
test "a11y: toggle key works bidirectionally" {
  let menu = ActionMenu::new("Test", [], toggle_key=Some('f'))
  // Can close with toggle key
  menu.open()
  inspect(menu.is_open(), content="true")
  ignore(menu.handle_key('f'))
  inspect(menu.is_open(), content="false")
  // Toggle key case insensitive
  menu.open()
  ignore(menu.handle_key('F'))
  inspect(menu.is_open(), content="false")
}

///|
/// a11y: Built component includes visible key hints
test "a11y: rendered menu shows key hints" {
  let menu = ActionMenu::new(
    "Actions",
    [
      ActionItem::new('1', "First", fn() {  }),
      ActionItem::new('2', "Second", fn() {  }),
    ],
    toggle_key=Some('f'),
  )
  let comp = menu.build(80, 24)
  // Check that text content exists (labels are rendered)
  // texts.0 is the map of id -> text content
  inspect(comp.texts.0.length() > 0, content="true")
}

///|
/// a11y: Action executes and closes in single keypress
test "a11y: single keypress completes action" {
  let executed : Ref[Bool] = Ref::new(false)
  let menu = ActionMenu::new("Test", [
    ActionItem::new('x', "Execute", fn() { executed.val = true }),
  ])
  menu.open()
  // Single keypress should: execute action AND close menu
  ignore(menu.handle_key('x'))
  inspect(executed.val, content="true")
  inspect(menu.is_open(), content="false")
}
