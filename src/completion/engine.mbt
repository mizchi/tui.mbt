///|
/// Async completion engine with stale response prevention
///
/// Key features:
/// - Request versioning to ignore stale responses
/// - Signal-based result management
/// - Supports async completion sources

///|
/// Completion result from source
pub(all) struct CompletionResult {
  items : Array[String]
  /// Version of the request that produced this result
  request_version : Int
}

///|
/// Completion engine state
pub(all) struct CompletionEngine {
  /// Current input being completed
  input : @signals.Signal[String]
  /// Current request version (incremented on each input change)
  request_version : @signals.Signal[Int]
  /// Filtered completion items
  items : @signals.Signal[Array[String]]
  /// Whether a request is in flight
  loading : @signals.Signal[Bool]
  /// Selected index
  selected_idx : @signals.Signal[Int]
  /// Popup visibility
  visible : @signals.Signal[Bool]
}

///|
/// Create a new completion engine
pub fn CompletionEngine::new() -> CompletionEngine {
  {
    input: @signals.signal(""),
    request_version: @signals.signal(0),
    items: @signals.signal([]),
    loading: @signals.signal(false),
    selected_idx: @signals.signal(0),
    visible: @signals.signal(false),
  }
}

///|
/// Update input and increment request version
pub fn CompletionEngine::set_input(
  self : CompletionEngine,
  input : String,
) -> Int {
  self.input.set(input)
  let new_version = self.request_version.get() + 1
  self.request_version.set(new_version)
  self.selected_idx.set(0)
  new_version
}

///|
/// Get current request version
pub fn CompletionEngine::get_version(self : CompletionEngine) -> Int {
  self.request_version.get()
}

///|
/// Get current input
pub fn CompletionEngine::get_input(self : CompletionEngine) -> String {
  self.input.get()
}

///|
/// Set loading state
pub fn CompletionEngine::set_loading(
  self : CompletionEngine,
  loading : Bool,
) -> Unit {
  self.loading.set(loading)
}

///|
/// Check if loading
pub fn CompletionEngine::is_loading(self : CompletionEngine) -> Bool {
  self.loading.get()
}

///|
/// Apply completion result if version matches current
/// Returns true if result was applied, false if stale
pub fn CompletionEngine::apply_result(
  self : CompletionEngine,
  result : CompletionResult,
) -> Bool {
  let current_version = self.request_version.get()
  if result.request_version != current_version {
    // Stale response, ignore
    return false
  }
  self.items.set(result.items)
  self.loading.set(false)
  self.visible.set(result.items.length() > 0)
  self.selected_idx.set(0)
  true
}

///|
/// Get completion items
pub fn CompletionEngine::get_items(self : CompletionEngine) -> Array[String] {
  self.items.get()
}

///|
/// Get selected index
pub fn CompletionEngine::get_selected_idx(self : CompletionEngine) -> Int {
  self.selected_idx.get()
}

///|
/// Set selected index
pub fn CompletionEngine::set_selected_idx(
  self : CompletionEngine,
  idx : Int,
) -> Unit {
  let items = self.items.get()
  if idx >= 0 && idx < items.length() {
    self.selected_idx.set(idx)
  }
}

///|
/// Move selection up (with wrap-around)
pub fn CompletionEngine::select_prev(self : CompletionEngine) -> Unit {
  let items = self.items.get()
  if items.length() == 0 {
    return
  }
  let current = self.selected_idx.get()
  let new_idx = if current > 0 { current - 1 } else { items.length() - 1 }
  self.selected_idx.set(new_idx)
}

///|
/// Move selection down (with wrap-around)
pub fn CompletionEngine::select_next(self : CompletionEngine) -> Unit {
  let items = self.items.get()
  if items.length() == 0 {
    return
  }
  let current = self.selected_idx.get()
  let new_idx = if current < items.length() - 1 { current + 1 } else { 0 }
  self.selected_idx.set(new_idx)
}

///|
/// Get currently selected item
pub fn CompletionEngine::get_selected_item(self : CompletionEngine) -> String? {
  let items = self.items.get()
  let idx = self.selected_idx.get()
  if idx >= 0 && idx < items.length() {
    Some(items[idx])
  } else {
    None
  }
}

///|
/// Check if popup is visible
pub fn CompletionEngine::is_visible(self : CompletionEngine) -> Bool {
  self.visible.get()
}

///|
/// Hide popup
pub fn CompletionEngine::hide(self : CompletionEngine) -> Unit {
  self.visible.set(false)
}

///|
/// Clear completion state
pub fn CompletionEngine::clear(self : CompletionEngine) -> Unit {
  self.items.set([])
  self.selected_idx.set(0)
  self.visible.set(false)
  self.loading.set(false)
}

// =============================================================================
// Async Request Management
// =============================================================================

///|
/// Pending async completion request
pub(all) struct PendingRequest {
  version : Int
  target_time : Int
  query : String
}

///|
/// Async completion manager - handles delayed completion requests
pub(all) struct AsyncCompletionManager {
  engine : CompletionEngine
  pending : @signals.Signal[PendingRequest?]
  delay_ms : Int
  /// Filter function: (query) -> items
  filter_fn : (String) -> Array[String]
  /// Time function: () -> current_time_ms
  time_fn : () -> Int
}

///|
/// Create a new async completion manager
pub fn AsyncCompletionManager::new(
  delay_ms : Int,
  filter_fn : (String) -> Array[String],
  time_fn : () -> Int,
) -> AsyncCompletionManager {
  {
    engine: CompletionEngine::new(),
    pending: @signals.signal(None),
    delay_ms,
    filter_fn,
    time_fn,
  }
}

///|
/// Request completion for given input
pub fn AsyncCompletionManager::request(
  self : AsyncCompletionManager,
  input : String,
) -> Unit {
  let version = self.engine.set_input(input)
  if input.length() == 0 {
    self.engine.clear()
    self.pending.set(None)
    return
  }
  let now = (self.time_fn)()
  self.pending.set(
    Some(PendingRequest::{
      version,
      target_time: now + self.delay_ms,
      query: input,
    }),
  )
  self.engine.set_loading(true)
}

///|
/// Check and apply pending completion if delay has passed
/// Returns true if result was applied
pub fn AsyncCompletionManager::check_pending(
  self : AsyncCompletionManager,
) -> Bool {
  match self.pending.get() {
    Some(req) => {
      let now = (self.time_fn)()
      if now >= req.target_time {
        let items = (self.filter_fn)(req.query)
        let result = CompletionResult::{ items, request_version: req.version }
        let applied = self.engine.apply_result(result)
        self.pending.set(None)
        applied
      } else {
        false
      }
    }
    None => false
  }
}

///|
/// Get the underlying engine
pub fn AsyncCompletionManager::get_engine(
  self : AsyncCompletionManager,
) -> CompletionEngine {
  self.engine
}

///|
/// Check if has pending request
pub fn AsyncCompletionManager::has_pending(
  self : AsyncCompletionManager,
) -> Bool {
  self.pending.get() is Some(_)
}

///|
/// Get pending request info for debugging
pub fn AsyncCompletionManager::get_pending(
  self : AsyncCompletionManager,
) -> PendingRequest? {
  self.pending.get()
}

///|
/// Clear pending request
pub fn AsyncCompletionManager::clear_pending(
  self : AsyncCompletionManager,
) -> Unit {
  self.pending.set(None)
}

// =============================================================================
// Word-based Input State
// =============================================================================

///|
/// Word-based input state for completion
/// Manages confirmed text (completed words) and current word being typed
pub(all) struct WordInputState {
  /// Confirmed text (completed words with separators)
  confirmed : @signals.Signal[String]
  /// Current word being typed
  current : @signals.Signal[String]
}

///|
/// Create new word input state
pub fn WordInputState::new() -> WordInputState {
  { confirmed: @signals.signal(""), current: @signals.signal("") }
}

///|
/// Get confirmed text
pub fn WordInputState::get_confirmed(self : WordInputState) -> String {
  self.confirmed.get()
}

///|
/// Get current word
pub fn WordInputState::get_current(self : WordInputState) -> String {
  self.current.get()
}

///|
/// Get full text (confirmed + current)
pub fn WordInputState::get_full_text(self : WordInputState) -> String {
  self.confirmed.get() + self.current.get()
}

///|
/// Set current word
pub fn WordInputState::set_current(
  self : WordInputState,
  word : String,
) -> Unit {
  self.current.set(word)
}

///|
/// Append character to current word
pub fn WordInputState::append_char(self : WordInputState, c : Char) -> Unit {
  self.current.set(self.current.get() + c.to_string())
}

///|
/// Delete last character from current word
/// Returns true if deleted, false if current was empty
pub fn WordInputState::delete_char(self : WordInputState) -> Bool {
  let current = self.current.get()
  if current.length() > 0 {
    let chars : Array[Char] = current.iter().collect()
    let new_chars : Array[Char] = []
    for i = 0; i < chars.length() - 1; i = i + 1 {
      new_chars.push(chars[i])
    }
    self.current.set(String::from_array(new_chars))
    true
  } else {
    false
  }
}

///|
/// Confirm current word with separator and start new word
pub fn WordInputState::confirm_word(
  self : WordInputState,
  word : String,
  separator : String,
) -> Unit {
  let confirmed = self.confirmed.get()
  self.confirmed.set(confirmed + word + separator)
  self.current.set("")
}

///|
/// Restore previous word when backspacing at empty current
/// Returns true if restored, false if confirmed was empty
pub fn WordInputState::restore_previous_word(self : WordInputState) -> Bool {
  let confirmed = self.confirmed.get()
  if confirmed.length() == 0 {
    return false
  }
  let chars : Array[Char] = confirmed.iter().collect()
  let mut last_space = -1
  for i = 0; i < chars.length() - 1; i = i + 1 {
    if chars[i] == ' ' {
      last_space = i
    }
  }
  if last_space >= 0 {
    let new_confirmed : Array[Char] = []
    for i = 0; i <= last_space; i = i + 1 {
      new_confirmed.push(chars[i])
    }
    let restored : Array[Char] = []
    for i = last_space + 1; i < chars.length(); i = i + 1 {
      restored.push(chars[i])
    }
    self.confirmed.set(String::from_array(new_confirmed))
    self.current.set(String::from_array(restored))
  } else {
    self.confirmed.set("")
    self.current.set(confirmed)
  }
  true
}

///|
/// Clear all input
pub fn WordInputState::clear(self : WordInputState) -> Unit {
  self.confirmed.set("")
  self.current.set("")
}
