///|
/// Tests for FocusManager - Keyboard Navigation and Accessibility

///|
test "FocusManager::new creates unfocused state" {
  let fm = @events.FocusManager::new()
  inspect(fm.get_focused(), content="None")
  inspect(fm.is_editing(), content="false")
}

///|
test "FocusManager::register adds focusable ID" {
  let fm = @events.FocusManager::new()
  fm.register("btn-1")
  fm.register("btn-2")
  inspect(fm.focusable_count(), content="2")
}

///|
test "FocusManager::focus sets focus" {
  let fm = @events.FocusManager::new()
  fm.register("input-1")
  fm.focus("input-1")
  inspect(fm.get_focused(), content="Some(\"input-1\")")
  inspect(fm.is_focused("input-1"), content="true")
}

///|
test "FocusManager::blur removes focus" {
  let fm = @events.FocusManager::new()
  fm.register("btn-1")
  fm.focus("btn-1")
  fm.blur()
  inspect(fm.get_focused(), content="None")
}

// ============================================
// Accessibility Tests - Keyboard Navigation
// ============================================

///|
/// a11y: Tab key cycles forward through focusable elements
test "a11y: focus_next cycles forward (Tab)" {
  let fm = @events.FocusManager::new()
  fm.register("btn-1")
  fm.register("btn-2")
  fm.register("btn-3")
  // Start with no focus, Tab focuses first element
  fm.focus_next()
  inspect(fm.get_focused(), content="Some(\"btn-1\")")
  // Tab to next
  fm.focus_next()
  inspect(fm.get_focused(), content="Some(\"btn-2\")")
  // Tab to next
  fm.focus_next()
  inspect(fm.get_focused(), content="Some(\"btn-3\")")
  // Tab wraps to first
  fm.focus_next()
  inspect(fm.get_focused(), content="Some(\"btn-1\")")
}

///|
/// a11y: Shift+Tab cycles backward through focusable elements
test "a11y: focus_prev cycles backward (Shift+Tab)" {
  let fm = @events.FocusManager::new()
  fm.register("btn-1")
  fm.register("btn-2")
  fm.register("btn-3")
  // Start with no focus, Shift+Tab focuses last element
  fm.focus_prev()
  inspect(fm.get_focused(), content="Some(\"btn-3\")")
  // Shift+Tab to previous
  fm.focus_prev()
  inspect(fm.get_focused(), content="Some(\"btn-2\")")
  // Shift+Tab to previous
  fm.focus_prev()
  inspect(fm.get_focused(), content="Some(\"btn-1\")")
  // Shift+Tab wraps to last
  fm.focus_prev()
  inspect(fm.get_focused(), content="Some(\"btn-3\")")
}

///|
/// a11y: Focus state is always queryable
test "a11y: focus state queryable" {
  let fm = @events.FocusManager::new()
  fm.register("input-1")
  // Can check if specific element is focused
  inspect(fm.is_focused("input-1"), content="false")
  fm.focus("input-1")
  inspect(fm.is_focused("input-1"), content="true")
  inspect(fm.is_focused("other"), content="false")
}

///|
/// a11y: Input mode distinguishes normal vs editing
test "a11y: input mode for editing state" {
  let fm = @events.FocusManager::new()
  // Normal mode for keyboard navigation
  inspect(fm.is_editing(), content="false")
  // Editing mode for text input (Enter on focused input)
  fm.start_editing()
  inspect(fm.is_editing(), content="true")
  // Return to normal mode (Enter to confirm)
  fm.stop_editing()
  inspect(fm.is_editing(), content="false")
}

///|
/// a11y: Empty focus list handles navigation gracefully
test "a11y: empty focusable list handled gracefully" {
  let fm = @events.FocusManager::new()
  // Navigation with no focusable elements should not crash
  fm.focus_next()
  inspect(fm.get_focused(), content="None")
  fm.focus_prev()
  inspect(fm.get_focused(), content="None")
}

///|
/// a11y: Unregister removes element from focus cycle
test "a11y: unregister removes from focus cycle" {
  let fm = @events.FocusManager::new()
  fm.register("btn-1")
  fm.register("btn-2")
  fm.register("btn-3")
  // Remove middle element
  fm.unregister("btn-2")
  inspect(fm.focusable_count(), content="2")
  // Tab should skip removed element
  fm.focus_next() // btn-1
  fm.focus_next() // btn-3 (not btn-2)
  inspect(fm.get_focused(), content="Some(\"btn-3\")")
}

///|
/// a11y: Duplicate registration prevented
test "a11y: duplicate registration ignored" {
  let fm = @events.FocusManager::new()
  fm.register("btn-1")
  fm.register("btn-1") // duplicate
  fm.register("btn-1") // duplicate
  inspect(fm.focusable_count(), content="1")
}

///|
/// a11y: Focus can be set directly to any registered element
test "a11y: direct focus to specific element" {
  let fm = @events.FocusManager::new()
  fm.register("btn-1")
  fm.register("input-1")
  fm.register("btn-2")
  // Can focus directly without cycling
  fm.focus("input-1")
  inspect(fm.get_focused(), content="Some(\"input-1\")")
}

///|
/// a11y: Focus navigation works after direct focus
test "a11y: navigation continues from direct focus" {
  let fm = @events.FocusManager::new()
  fm.register("btn-1")
  fm.register("input-1")
  fm.register("btn-2")
  // Focus directly
  fm.focus("input-1")
  // Tab should go to next
  fm.focus_next()
  inspect(fm.get_focused(), content="Some(\"btn-2\")")
}
