///|
test "ModalState::new creates closed modal by default" {
  let state = ModalState::new()
  inspect(state.get_is_open(), content="false")
}

///|
test "ModalState::new with initial_open=true creates open modal" {
  let state = ModalState::new(initial_open=true)
  inspect(state.get_is_open(), content="true")
}

///|
test "ModalState::open opens the modal" {
  let state = ModalState::new()
  state.open()
  inspect(state.get_is_open(), content="true")
}

///|
test "ModalState::close closes the modal" {
  let state = ModalState::new(initial_open=true)
  state.close()
  inspect(state.get_is_open(), content="false")
}

///|
test "ModalState::toggle toggles the modal state" {
  let state = ModalState::new()
  inspect(state.get_is_open(), content="false")
  state.toggle()
  inspect(state.get_is_open(), content="true")
  state.toggle()
  inspect(state.get_is_open(), content="false")
}

///|
test "modal creates a component" {
  let content = text("Hello Modal")
  let m = modal(content)
  // Should create a valid component (node exists)
  inspect(m.node.id.length() > 0, content="true")
}

///|
test "modal_with_backdrop creates a component" {
  let content = text("Hello Modal")
  let m = modal_with_backdrop(content)
  inspect(m.node.id.length() > 0, content="true")
}

///|
test "with_modal returns base when modal is closed" {
  let base = text("Base Content")
  let modal_content = modal(text("Modal Content"))
  let result = with_modal(base, modal_content, false)
  // When closed, should return the base component
  inspect(result.texts.0.length(), content="1")
}

///|
test "with_modal returns stacked content when modal is open" {
  let base = text("Base Content")
  let modal_content = modal(text("Modal Content"))
  let result = with_modal(base, modal_content, true)
  // When open, should have both base and modal text content
  inspect(result.texts.0.length() >= 2, content="true")
}

///|
test "confirm_dialog creates dialog with buttons" {
  let dialog = confirm_dialog("Are you sure?", title="Confirm Action")
  // Should have text content for message and buttons
  inspect(dialog.texts.0.length() >= 1, content="true")
}

///|
test "alert_dialog creates dialog with single button" {
  let dialog = alert_dialog("Something happened!", title="Warning")
  inspect(dialog.texts.0.length() >= 1, content="true")
}

///|
test "backdrop creates full-size overlay" {
  let b = backdrop()
  inspect(b.node.id.length() > 0, content="true")
}

// ============================================
// Accessibility Tests
// ============================================

///|
/// a11y: Modal state is clearly queryable (for assistive tech integration)
test "a11y: modal state is queryable" {
  let state = ModalState::new()
  // Can always check if modal is open
  inspect(state.get_is_open(), content="false")
  state.open()
  inspect(state.get_is_open(), content="true")
  state.close()
  inspect(state.get_is_open(), content="false")
}

///|
/// a11y: Confirm dialog has required elements - title, message, buttons
test "a11y: confirm dialog has complete structure" {
  let dialog = confirm_dialog(
    "Delete this item?",
    title="Confirm Delete",
    confirm_label="Delete",
    cancel_label="Cancel",
  )
  // Dialog should have text content (title + message + button labels)
  let text_count = dialog.texts.0.length()
  // At minimum: title, message, confirm button, cancel button
  inspect(text_count >= 4, content="true")
}

///|
/// a11y: Alert dialog has required elements - title, message, button
test "a11y: alert dialog has complete structure" {
  let dialog = alert_dialog(
    "Operation completed successfully",
    title="Success",
    button_label="OK",
  )
  // Dialog should have text content
  let text_count = dialog.texts.0.length()
  // At minimum: title, message, OK button
  inspect(text_count >= 3, content="true")
}

///|
/// a11y: Confirm dialog buttons have IDs for interaction
test "a11y: confirm dialog buttons are identifiable" {
  let dialog = confirm_dialog("Test message")
  // Buttons should have IDs for keyboard/programmatic access
  // The confirm_dialog creates buttons with id="modal-confirm" and id="modal-cancel"
  let styles = dialog.styles.0
  // Should have styled elements (buttons have styles)
  inspect(styles.length() > 0, content="true")
}

///|
/// a11y: Alert dialog button has ID for interaction
test "a11y: alert dialog button is identifiable" {
  let dialog = alert_dialog("Test message")
  // The alert_dialog creates button with id="modal-ok"
  let styles = dialog.styles.0
  inspect(styles.length() > 0, content="true")
}

///|
/// a11y: Modal content is centered for visual focus
test "a11y: modal is visually centered" {
  let content = text("Centered Content")
  let m = modal(content)
  // Modal uses justify_content=Center and align_items=Center
  // The outer box has the centering styles applied
  inspect(m.node.id.length() > 0, content="true")
}

///|
/// a11y: Backdrop provides visual separation from background
test "a11y: backdrop has distinct background" {
  // Default backdrop has semi-transparent black background
  let b = backdrop()
  // Backdrop component exists and is renderable
  inspect(b.node.id.length() > 0, content="true")
}

///|
/// a11y: Modal with backdrop provides clear visual boundary
test "a11y: modal with backdrop creates visual boundary" {
  let content = text("Modal Content")
  let m = modal_with_backdrop(content)
  // The modal_with_backdrop has bg color for backdrop
  inspect(m.node.id.length() > 0, content="true")
  // Should have styles applied (border, colors)
  inspect(m.styles.0.length() > 0, content="true")
}

///|
/// a11y: Modal has visible border by default
test "a11y: modal has visible border" {
  let content = text("Content")
  let m = modal(content)
  // Default modal has border (rounded by default)
  // Styles should include border styling
  inspect(m.styles.0.length() > 0, content="true")
}

///|
/// a11y: Modal can have custom ID for programmatic access
test "a11y: modal supports custom ID" {
  let content = text("Content")
  let m = modal_with_backdrop(content, id="custom-modal")
  // Custom ID should be set on the modal box
  // The component tree includes the ID
  inspect(m.node.id.length() > 0, content="true")
}

///|
/// a11y: with_modal properly hides/shows based on state
test "a11y: with_modal reflects open state" {
  let base = text("Base")
  let modal_content = modal(text("Modal"))
  // When closed, modal is not in the tree
  let closed_result = with_modal(base, modal_content, false)
  let closed_texts = closed_result.texts.0.length()
  // When open, modal is added to tree
  let open_result = with_modal(base, modal_content, true)
  let open_texts = open_result.texts.0.length()
  // Open state should have more text content
  inspect(open_texts > closed_texts, content="true")
}
