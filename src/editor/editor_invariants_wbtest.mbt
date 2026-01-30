///|
test "editor invariants after mixed edits" {
  let text =
    #|line 1
    #|line 2
    #|line 3
    #|line 4
    #|line 5
    #|line 6
    #|
  let state = EditorState::new(text, 3)
  assert_state_invariants(state)
  state.replace_selection("abc")
  assert_state_invariants(state)
  state.replace_selection("\n")
  assert_state_invariants(state)
  state.move_down(false)
  state.move_end(false)
  state.replace_selection("Z")
  assert_state_invariants(state)
  state.delete_backward()
  assert_state_invariants(state)
  state.delete_forward()
  assert_state_invariants(state)
  state.scroll_view(100)
  assert_state_invariants(state)
  state.scroll_view(-100)
  assert_state_invariants(state)
}
