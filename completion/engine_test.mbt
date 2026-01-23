///|
/// Tests for CompletionEngine

///|
test "CompletionEngine::new creates empty state" {
  let engine = CompletionEngine::new()
  inspect(engine.get_input(), content="")
  inspect(engine.get_version(), content="0")
  inspect(engine.get_items().length(), content="0")
  inspect(engine.is_loading(), content="false")
  inspect(engine.is_visible(), content="false")
  inspect(engine.get_selected_idx(), content="0")
}

///|
test "CompletionEngine::set_input updates input and increments version" {
  let engine = CompletionEngine::new()
  let v1 = engine.set_input("hello")
  inspect(engine.get_input(), content="hello")
  inspect(v1, content="1")
  inspect(engine.get_version(), content="1")
  let v2 = engine.set_input("world")
  inspect(engine.get_input(), content="world")
  inspect(v2, content="2")
  inspect(engine.get_version(), content="2")
}

///|
test "CompletionEngine::set_loading and is_loading" {
  let engine = CompletionEngine::new()
  inspect(engine.is_loading(), content="false")
  engine.set_loading(true)
  inspect(engine.is_loading(), content="true")
  engine.set_loading(false)
  inspect(engine.is_loading(), content="false")
}

///|
test "CompletionEngine::apply_result with matching version" {
  let engine = CompletionEngine::new()
  let version = engine.set_input("test")
  engine.set_loading(true)
  let result : CompletionResult = {
    items: ["item1", "item2"],
    request_version: version,
  }
  let applied = engine.apply_result(result)
  inspect(applied, content="true")
  inspect(engine.get_items().length(), content="2")
  inspect(engine.is_loading(), content="false")
  inspect(engine.is_visible(), content="true")
}

///|
test "CompletionEngine::apply_result with stale version is ignored" {
  let engine = CompletionEngine::new()
  let old_version = engine.set_input("old")
  let _ = engine.set_input("new") // version is now 2
  let result : CompletionResult = {
    items: ["stale"],
    request_version: old_version,
  }
  let applied = engine.apply_result(result)
  inspect(applied, content="false")
  inspect(engine.get_items().length(), content="0")
}

///|
test "CompletionEngine::apply_result with empty items hides popup" {
  let engine = CompletionEngine::new()
  let version = engine.set_input("test")
  let result : CompletionResult = { items: [], request_version: version }
  let applied = engine.apply_result(result)
  inspect(applied, content="true")
  inspect(engine.is_visible(), content="false")
}

///|
test "CompletionEngine selection navigation" {
  let engine = CompletionEngine::new()
  let version = engine.set_input("test")
  let result : CompletionResult = {
    items: ["a", "b", "c"],
    request_version: version,
  }
  let _ = engine.apply_result(result)
  // Initial selection is 0
  inspect(engine.get_selected_idx(), content="0")
  inspect(engine.get_selected_item(), content="Some(\"a\")")
  // Select next
  engine.select_next()
  inspect(engine.get_selected_idx(), content="1")
  inspect(engine.get_selected_item(), content="Some(\"b\")")
  // Select next again
  engine.select_next()
  inspect(engine.get_selected_idx(), content="2")
  // Select next wraps to 0
  engine.select_next()
  inspect(engine.get_selected_idx(), content="0")
  // Select prev wraps to last
  engine.select_prev()
  inspect(engine.get_selected_idx(), content="2")
  inspect(engine.get_selected_item(), content="Some(\"c\")")
}

///|
test "CompletionEngine::select_next and select_prev with empty items" {
  let engine = CompletionEngine::new()
  // With empty items, selection should not change
  engine.select_next()
  inspect(engine.get_selected_idx(), content="0")
  engine.select_prev()
  inspect(engine.get_selected_idx(), content="0")
}

///|
test "CompletionEngine::set_selected_idx validates bounds" {
  let engine = CompletionEngine::new()
  let version = engine.set_input("test")
  let result : CompletionResult = {
    items: ["a", "b"],
    request_version: version,
  }
  let _ = engine.apply_result(result)
  // Valid index
  engine.set_selected_idx(1)
  inspect(engine.get_selected_idx(), content="1")
  // Invalid index (too high) - should not change
  engine.set_selected_idx(10)
  inspect(engine.get_selected_idx(), content="1")
  // Invalid index (negative) - should not change
  engine.set_selected_idx(-1)
  inspect(engine.get_selected_idx(), content="1")
}

///|
test "CompletionEngine::get_selected_item with invalid index returns None" {
  let engine = CompletionEngine::new()
  // Empty items
  inspect(engine.get_selected_item(), content="None")
}

///|
test "CompletionEngine::hide and clear" {
  let engine = CompletionEngine::new()
  let version = engine.set_input("test")
  let result : CompletionResult = { items: ["a"], request_version: version }
  let _ = engine.apply_result(result)
  inspect(engine.is_visible(), content="true")
  // Hide
  engine.hide()
  inspect(engine.is_visible(), content="false")
  inspect(engine.get_items().length(), content="1") // items still present
  // Clear
  engine.clear()
  inspect(engine.get_items().length(), content="0")
  inspect(engine.is_loading(), content="false")
}

///|
test "AsyncCompletionManager basic workflow" {
  let current_time = Ref::new(0)
  let filter_fn = fn(query : String) -> Array[String] {
    if query == "test" {
      ["test1", "test2"]
    } else {
      []
    }
  }
  let time_fn = fn() -> Int { current_time.val }
  let manager = AsyncCompletionManager::new(100, filter_fn, time_fn)
  // Request completion
  manager.request("test")
  inspect(manager.has_pending(), content="true")
  inspect(manager.get_engine().is_loading(), content="true")
  // Time hasn't passed yet
  let applied1 = manager.check_pending()
  inspect(applied1, content="false")
  // Advance time
  current_time.val = 100
  let applied2 = manager.check_pending()
  inspect(applied2, content="true")
  inspect(manager.get_engine().get_items().length(), content="2")
  inspect(manager.has_pending(), content="false")
}

///|
test "AsyncCompletionManager empty input clears state" {
  let filter_fn = fn(_query : String) -> Array[String] { ["item"] }
  let time_fn = fn() -> Int { 0 }
  let manager = AsyncCompletionManager::new(100, filter_fn, time_fn)
  // Request with empty input
  manager.request("")
  inspect(manager.has_pending(), content="false")
  inspect(manager.get_engine().is_visible(), content="false")
}

///|
test "AsyncCompletionManager::clear_pending" {
  let filter_fn = fn(_query : String) -> Array[String] { [] }
  let time_fn = fn() -> Int { 0 }
  let manager = AsyncCompletionManager::new(100, filter_fn, time_fn)
  manager.request("test")
  inspect(manager.has_pending(), content="true")
  manager.clear_pending()
  inspect(manager.has_pending(), content="false")
}

///|
test "AsyncCompletionManager::get_pending returns request info" {
  let filter_fn = fn(_query : String) -> Array[String] { [] }
  let time_fn = fn() -> Int { 50 }
  let manager = AsyncCompletionManager::new(100, filter_fn, time_fn)
  inspect(manager.has_pending(), content="false")
  manager.request("hello")
  match manager.get_pending() {
    Some(req) => {
      inspect(req.query, content="hello")
      inspect(req.target_time, content="150") // 50 + 100
    }
    None => fail("Expected pending request")
  }
}

///|
test "WordInputState basic operations" {
  let state = WordInputState::new()
  inspect(state.get_confirmed(), content="")
  inspect(state.get_current(), content="")
  inspect(state.get_full_text(), content="")
  // Set current
  state.set_current("hello")
  inspect(state.get_current(), content="hello")
  inspect(state.get_full_text(), content="hello")
  // Append char
  state.append_char('!')
  inspect(state.get_current(), content="hello!")
}

///|
test "WordInputState::delete_char" {
  let state = WordInputState::new()
  // Delete from empty returns false
  inspect(state.delete_char(), content="false")
  // Delete from non-empty
  state.set_current("abc")
  inspect(state.delete_char(), content="true")
  inspect(state.get_current(), content="ab")
  inspect(state.delete_char(), content="true")
  inspect(state.get_current(), content="a")
  inspect(state.delete_char(), content="true")
  inspect(state.get_current(), content="")
  inspect(state.delete_char(), content="false")
}

///|
test "WordInputState::confirm_word" {
  let state = WordInputState::new()
  state.set_current("hello")
  state.confirm_word("hello", " ")
  inspect(state.get_confirmed(), content="hello ")
  inspect(state.get_current(), content="")
  state.set_current("world")
  state.confirm_word("world", " ")
  inspect(state.get_confirmed(), content="hello world ")
}

///|
test "WordInputState::restore_previous_word" {
  let state = WordInputState::new()
  // Empty confirmed returns false
  inspect(state.restore_previous_word(), content="false")
  // With confirmed text
  state.confirm_word("hello", " ")
  state.confirm_word("world", " ")
  inspect(state.get_confirmed(), content="hello world ")
  // Restore previous
  inspect(state.restore_previous_word(), content="true")
  inspect(state.get_confirmed(), content="hello ")
  inspect(state.get_current(), content="world ")
  // Clear and try again
  state.clear()
  state.confirm_word("single", " ")
  inspect(state.restore_previous_word(), content="true")
  inspect(state.get_confirmed(), content="")
  inspect(state.get_current(), content="single ")
}

///|
test "WordInputState::clear" {
  let state = WordInputState::new()
  state.confirm_word("hello", " ")
  state.set_current("world")
  state.clear()
  inspect(state.get_confirmed(), content="")
  inspect(state.get_current(), content="")
}
