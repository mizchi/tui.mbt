///|
/// Completion API surface for editor integrations (e.g. LSP)

///|
pub(all) struct CompletionAnchor {
  line : Int
  col : Int
}

///|
pub(all) struct CompletionRange {
  start_col : Int
  end_col : Int
}

///|
pub(all) struct CompletionRequest {
  id : Int
  line : Int
  col : Int
  prefix : String
  line_text : String
  anchor : CompletionAnchor
  replace : CompletionRange
}

///|
pub(all) struct CompletionItem {
  label : String
  insert_text : String
  detail : String?
  documentation : String?
}

///|
pub(all) struct CompletionResponse {
  id : Int
  items : Array[CompletionItem]
  is_incomplete : Bool
}

///|
pub type CompletionProvider = (CompletionRequest) -> CompletionResponse

///|
pub type CompletionProviderAsync = (
  CompletionRequest,
  (CompletionResponse) -> Unit,
) -> Unit

///|
pub struct CompletionSession {
  engine : @completion.CompletionEngine
  mut items : Array[CompletionItem]
  mut anchor : CompletionAnchor
  mut replace : CompletionRange
  mut request_id : Int
}

///|
pub fn CompletionSession::new() -> CompletionSession {
  {
    engine: @completion.CompletionEngine::new(),
    items: [],
    anchor: { line: 0, col: 0 },
    replace: { start_col: 0, end_col: 0 },
    request_id: 0,
  }
}

///|
pub fn CompletionSession::set_request(
  self : CompletionSession,
  req : CompletionRequest,
) -> Unit {
  self.request_id = req.id
  self.anchor = req.anchor
  self.replace = req.replace
  let _ = self.engine.set_input(req.prefix)
}

///|
pub fn CompletionSession::apply_response(
  self : CompletionSession,
  res : CompletionResponse,
) -> Bool {
  if res.id != self.request_id {
    return false
  }
  self.items = res.items
  let labels = self.items.map(fn(item) { item.label })
  self.engine.set_items(labels)
  true
}

///|
pub fn CompletionSession::get_items(
  self : CompletionSession,
) -> Array[CompletionItem] {
  self.items
}

///|
pub fn CompletionSession::get_selected_item(
  self : CompletionSession,
) -> CompletionItem? {
  let idx = self.engine.get_selected_idx()
  if idx >= 0 && idx < self.items.length() {
    Some(self.items[idx])
  } else {
    None
  }
}

///|
pub fn CompletionSession::get_selected_index(self : CompletionSession) -> Int {
  self.engine.get_selected_idx()
}

///|
pub fn CompletionSession::select_prev(self : CompletionSession) -> Unit {
  self.engine.select_prev()
}

///|
pub fn CompletionSession::select_next(self : CompletionSession) -> Unit {
  self.engine.select_next()
}

///|
pub fn CompletionSession::is_visible(self : CompletionSession) -> Bool {
  self.engine.is_visible()
}

///|
pub fn CompletionSession::hide(self : CompletionSession) -> Unit {
  self.engine.hide()
}

///|
pub fn CompletionSession::clear(self : CompletionSession) -> Unit {
  self.items = []
  self.engine.clear()
}

///|
pub fn CompletionSession::get_anchor(
  self : CompletionSession,
) -> CompletionAnchor {
  self.anchor
}

///|
pub fn CompletionSession::get_replace(
  self : CompletionSession,
) -> CompletionRange {
  self.replace
}
