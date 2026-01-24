///|
/// FocusNav - Signal-based focus navigation utility
/// Simplifies focus management in forms and interactive components

///|
/// Focus navigation state with signal-based tracking
pub(all) struct FocusNav {
  focused_id : @signals.Signal[String]
  ids : Array[String]
}

///|
/// Create a new focus navigation helper
pub fn FocusNav::new(ids : Array[String]) -> FocusNav {
  { focused_id: @signals.signal(""), ids }
}

///|
/// Create with initial focus
pub fn FocusNav::with_initial(
  ids : Array[String],
  initial : String,
) -> FocusNav {
  { focused_id: @signals.signal(initial), ids }
}

///|
/// Get the currently focused ID (empty string if none)
pub fn FocusNav::get(self : FocusNav) -> String {
  self.focused_id.get()
}

///|
/// Set focus to a specific ID
pub fn FocusNav::set(self : FocusNav, id : String) -> Unit {
  self.focused_id.set(id)
}

///|
/// Clear focus
pub fn FocusNav::blur(self : FocusNav) -> Unit {
  self.focused_id.set("")
}

///|
/// Check if an ID is currently focused
pub fn FocusNav::is_focused(self : FocusNav, id : String) -> Bool {
  self.focused_id.get() == id
}

///|
/// Move focus to the next item (wraps around)
pub fn FocusNav::next(self : FocusNav) -> Unit {
  let current = self.focused_id.get()
  if self.ids.length() == 0 {
    return
  }
  if current == "" {
    self.focused_id.set(self.ids[0])
    return
  }
  match self.ids.search(current) {
    Some(idx) => {
      let next_idx = (idx + 1) % self.ids.length()
      self.focused_id.set(self.ids[next_idx])
    }
    None => self.focused_id.set(self.ids[0])
  }
}

///|
/// Move focus to the previous item (wraps around)
pub fn FocusNav::prev(self : FocusNav) -> Unit {
  let current = self.focused_id.get()
  if self.ids.length() == 0 {
    return
  }
  if current == "" {
    self.focused_id.set(self.ids[self.ids.length() - 1])
    return
  }
  match self.ids.search(current) {
    Some(idx) => {
      let prev_idx = if idx == 0 { self.ids.length() - 1 } else { idx - 1 }
      self.focused_id.set(self.ids[prev_idx])
    }
    None => self.focused_id.set(self.ids[self.ids.length() - 1])
  }
}

///|
/// Get InputState for an input component
pub fn FocusNav::input_state(self : FocusNav, id : String) -> InputState {
  if self.is_focused(id) {
    InputState::Focused
  } else {
    InputState::Idle
  }
}

///|
/// Get TextareaState for a textarea component
pub fn FocusNav::textarea_state(self : FocusNav, id : String) -> TextareaState {
  if self.is_focused(id) {
    TextareaState::Focused
  } else {
    TextareaState::Idle
  }
}

///|
/// Get ButtonState for a button component
pub fn FocusNav::button_state(self : FocusNav, id : String) -> ButtonState {
  if self.is_focused(id) {
    ButtonState::Hover
  } else {
    ButtonState::Normal
  }
}

///|
/// Check if the focused ID is in a specific list
pub fn FocusNav::focused_in(self : FocusNav, ids : Array[String]) -> Bool {
  ids.contains(self.focused_id.get())
}

///|
/// Handle Tab/Shift+Tab navigation events
/// Returns true if the event was handled
pub fn FocusNav::handle_tab(
  self : FocusNav,
  event : @events.InputEvent,
) -> Bool {
  if event.is_tab() {
    self.next()
    return true
  }
  if event.is_backtab() {
    self.prev()
    return true
  }
  false
}

///|
/// Handle arrow key navigation (Up/Down)
/// Returns true if the event was handled
pub fn FocusNav::handle_arrows(
  self : FocusNav,
  event : @events.InputEvent,
) -> Bool {
  match event.is_arrow() {
    Some(@events.SpecialKey::Down) => {
      self.next()
      true
    }
    Some(@events.SpecialKey::Up) => {
      self.prev()
      true
    }
    _ => false
  }
}
