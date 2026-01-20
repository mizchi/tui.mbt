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
