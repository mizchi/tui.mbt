///|
/// IME input view behavior

///|
test "ime_session_initial_state" {
  let session = ImeSession::new()
  inspect(session.is_editing(), content="false")
}

///|
test "ime_input_editing_state_sets_cursor" {
  let comp = ime_input("hello", true, id="ime-input")
  inspect(comp.texts.get("ime-input"), content="Some(\"hello_\")")
}

///|
test "ime_input_placeholder_when_idle" {
  let comp = ime_input("", false, id="ime-empty", placeholder="Type here")
  inspect(comp.texts.get("ime-empty"), content="Some(\"Type here\")")
}

///|
test "ime_textarea_editing_state_sets_cursor" {
  let comp = ime_textarea("line1", true, rows=2)
  let output = @render.render_once(20, 4, comp)
  assert_true(output.contains("line1_"))
}

///|
test "ime_textarea_placeholder_when_idle" {
  let comp = ime_textarea("", false, rows=2, placeholder="Enter message")
  let output = @render.render_once(20, 4, comp)
  assert_true(output.contains("Enter message"))
}
