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
