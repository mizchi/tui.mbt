///|
test "completion_request returns prefix based on cursor position" {
  let state = EditorState::new("", 3)
  // 空の状態では prefix は空
  let req1 = state.completion_request(1)
  assert_eq(req1.prefix, "")

  // "hello" を入力
  state.replace_selection("hello")
  let req2 = state.completion_request(2)
  assert_eq(req2.prefix, "hello")
  assert_eq(req2.anchor.col, 0)

  // スペースを追加して新しい単語を開始
  state.replace_selection(" wor")
  let req3 = state.completion_request(3)
  assert_eq(req3.prefix, "wor")
  assert_eq(req3.anchor.col, 6) // "hello " の後

  // カーソルを左に移動（スペースの位置へ）
  handle_key_event(state, @events.KeyEvent::Special(@events.SpecialKey::Home, @events.KeyModifier::None))
  // 行頭では prefix は空（単語の先頭）
  let req4 = state.completion_request(4)
  assert_eq(req4.prefix, "")
}

///|
test "completion_request unchanged by cursor movement alone" {
  let state = EditorState::new("const value = 123", 3)
  // カーソルは行頭
  let req1 = state.completion_request(1)
  assert_eq(req1.prefix, "")

  // 右に5回移動して "const" の末尾へ
  for _ in 0..<5 {
    handle_key_event(state, @events.KeyEvent::Special(@events.SpecialKey::Right, @events.KeyModifier::None))
  }
  // カーソルは "const" の末尾、prefix は "const"
  let req2 = state.completion_request(2)
  assert_eq(req2.prefix, "const")

  // さらに右に移動してスペースへ
  handle_key_event(state, @events.KeyEvent::Special(@events.SpecialKey::Right, @events.KeyModifier::None))
  // スペース位置では prefix は空
  let req3 = state.completion_request(3)
  assert_eq(req3.prefix, "")

  // "value" の途中へ移動
  for _ in 0..<3 {
    handle_key_event(state, @events.KeyEvent::Special(@events.SpecialKey::Right, @events.KeyModifier::None))
  }
  let req4 = state.completion_request(4)
  assert_eq(req4.prefix, "val")
}

///|
test "completion and tooltip api types construct" {
  let state = EditorState::new("", 3)
  let anchor = CompletionAnchor::{ line: 0, col: 0 }
  let replace = CompletionRange::{ start_col: 0, end_col: 0 }
  let req = CompletionRequest::{
    id: 1,
    line: 0,
    col: 0,
    prefix: "",
    line_text: "",
    anchor,
    replace,
  }
  let session = CompletionSession::new()
  session.set_request(req)
  let item = CompletionItem::{
    label: "abc",
    insert_text: "abc",
    detail: None,
    documentation: None,
  }
  let res = CompletionResponse::{ id: 1, items: [item], is_incomplete: false }
  let _ = session.apply_response(res)

  let tooltip = Tooltip::{ title: None, content: TooltipContent::Plain("doc") }
  let _ = tooltip
  let tip_anchor = TooltipAnchor::{ line: 0, col: 0, prefer_below: true }
  let _ = tooltip_position(state, 10, 5, tip_anchor, 8, 2)
}
