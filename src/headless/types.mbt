///|
/// Headless component types and state management
/// Pure logic without styling - follows APG (ARIA Authoring Practices) patterns

// =============================================================================
// Button State
// =============================================================================

///|
/// Button state enum
pub(all) enum ButtonState {
  Default
  Focused
  Pressed
  Disabled
}

///|
/// Check if button is interactive
pub fn ButtonState::is_interactive(self : ButtonState) -> Bool {
  match self {
    Disabled => false
    _ => true
  }
}

// =============================================================================
// Input State
// =============================================================================

///|
/// Input field state
pub(all) enum InputState {
  Idle
  Focused
  Editing
  Disabled
}

///|
/// Check if input is editable
pub fn InputState::is_editable(self : InputState) -> Bool {
  match self {
    Editing => true
    _ => false
  }
}

///|
/// Check if input can receive focus
pub fn InputState::is_focusable(self : InputState) -> Bool {
  match self {
    Disabled => false
    _ => true
  }
}

// =============================================================================
// Toggle State (Checkbox, Switch, Radio)
// =============================================================================

///|
/// Toggle state for checkbox/switch
pub(all) struct ToggleState {
  checked : Bool
  focused : Bool
  disabled : Bool
}

///|
/// Create default toggle state
pub fn ToggleState::new(checked? : Bool = false) -> ToggleState {
  { checked, focused: false, disabled: false }
}

///|
/// Toggle the checked state
pub fn ToggleState::toggle(self : ToggleState) -> ToggleState {
  if self.disabled {
    self
  } else {
    { ..self, checked: not(self.checked) }
  }
}

///|
/// Set focus state
pub fn ToggleState::set_focused(
  self : ToggleState,
  focused : Bool,
) -> ToggleState {
  { ..self, focused, }
}

// =============================================================================
// Selection State (Listbox, Combobox, Tabs)
// =============================================================================

///|
/// Selection state for single-select components
pub(all) struct SelectionState {
  selected_id : String
  focused_id : String
  open : Bool
}

///|
/// Create default selection state
pub fn SelectionState::new(selected_id? : String = "") -> SelectionState {
  { selected_id, focused_id: selected_id, open: false }
}

///|
/// Select an item
pub fn SelectionState::select(
  self : SelectionState,
  id : String,
) -> SelectionState {
  { ..self, selected_id: id, focused_id: id }
}

///|
/// Focus an item (for keyboard navigation)
pub fn SelectionState::focus(
  self : SelectionState,
  id : String,
) -> SelectionState {
  { ..self, focused_id: id }
}

///|
/// Toggle open state (for dropdown-style components)
pub fn SelectionState::toggle_open(self : SelectionState) -> SelectionState {
  { ..self, open: not(self.open) }
}

// =============================================================================
// Modal State
// =============================================================================

///|
/// Modal dialog state
pub(all) struct ModalState {
  open : Bool
  focused_element : String
}

///|
/// Create closed modal state
pub fn ModalState::new() -> ModalState {
  { open: false, focused_element: "" }
}

///|
/// Open the modal
pub fn ModalState::show(self : ModalState) -> ModalState {
  { ..self, open: true }
}

///|
/// Close the modal
pub fn ModalState::hide(self : ModalState) -> ModalState {
  { ..self, open: false }
}

///|
/// Check if modal is open
pub fn ModalState::is_open(self : ModalState) -> Bool {
  self.open
}

// =============================================================================
// Accordion State
// =============================================================================

///|
/// Accordion panel state
pub(all) struct AccordionState {
  expanded_ids : Array[String]
  allow_multiple : Bool
}

///|
/// Create accordion state
pub fn AccordionState::new(allow_multiple? : Bool = false) -> AccordionState {
  { expanded_ids: [], allow_multiple }
}

///|
/// Check if a panel is expanded
pub fn AccordionState::is_expanded(self : AccordionState, id : String) -> Bool {
  self.expanded_ids.contains(id)
}

///|
/// Toggle a panel's expanded state
pub fn AccordionState::toggle(
  self : AccordionState,
  id : String,
) -> AccordionState {
  if self.is_expanded(id) {
    // Collapse
    let new_ids = self.expanded_ids.filter(fn(x) { x != id })
    { ..self, expanded_ids: new_ids }
    // Expand
  } else if self.allow_multiple {
    let new_ids = self.expanded_ids.copy()
    new_ids.push(id)
    { ..self, expanded_ids: new_ids }
  } else {
    { ..self, expanded_ids: [id] }
  }
}

// =============================================================================
// Toast State
// =============================================================================

///|
/// Toast notification severity level
pub(all) enum ToastLevel {
  Info
  Success
  Warning
  Error
}

///|
/// Toast notification state
pub(all) struct ToastState {
  message : String
  level : ToastLevel
  visible : Bool
}

///|
/// Create a new toast state
pub fn ToastState::new(
  message : String,
  level? : ToastLevel = Info,
) -> ToastState {
  { message, level, visible: true }
}

///|
/// Dismiss the toast
pub fn ToastState::dismiss(self : ToastState) -> ToastState {
  { ..self, visible: false }
}

// =============================================================================
// Grid Select State
// =============================================================================

///|
/// 2D grid selection state
pub(all) struct GridSelectState {
  columns : Int
  selected : Int
  total : Int
}

///|
/// Create a new grid select state
pub fn GridSelectState::new(
  columns : Int,
  total : Int,
  selected? : Int = 0,
) -> GridSelectState {
  { columns, total, selected }
}

///|
/// Move selection right
pub fn GridSelectState::move_right(self : GridSelectState) -> GridSelectState {
  let next = self.selected + 1
  if next < self.total {
    { ..self, selected: next }
  } else {
    self
  }
}

///|
/// Move selection left
pub fn GridSelectState::move_left(self : GridSelectState) -> GridSelectState {
  if self.selected > 0 {
    { ..self, selected: self.selected - 1 }
  } else {
    self
  }
}

///|
/// Move selection down
pub fn GridSelectState::move_down(self : GridSelectState) -> GridSelectState {
  let next = self.selected + self.columns
  if next < self.total {
    { ..self, selected: next }
  } else {
    self
  }
}

///|
/// Move selection up
pub fn GridSelectState::move_up(self : GridSelectState) -> GridSelectState {
  let next = self.selected - self.columns
  if next >= 0 {
    { ..self, selected: next }
  } else {
    self
  }
}

///|
/// Get row and column of current selection
pub fn GridSelectState::position(self : GridSelectState) -> (Int, Int) {
  (self.selected / self.columns, self.selected % self.columns)
}

// =============================================================================
// Tree State
// =============================================================================

///|
/// Tree view state
pub(all) struct TreeState {
  expanded_ids : Array[String]
  selected_id : String
  focused_id : String
}

///|
/// Create a new tree state
pub fn TreeState::new() -> TreeState {
  { expanded_ids: [], selected_id: "", focused_id: "" }
}

///|
/// Toggle expand/collapse for a node
pub fn TreeState::toggle_expand(self : TreeState, id : String) -> TreeState {
  if self.expanded_ids.contains(id) {
    let new_ids = self.expanded_ids.filter(fn(x) { x != id })
    { ..self, expanded_ids: new_ids }
  } else {
    let new_ids = self.expanded_ids.copy()
    new_ids.push(id)
    { ..self, expanded_ids: new_ids }
  }
}

///|
/// Check if a node is expanded
pub fn TreeState::is_expanded(self : TreeState, id : String) -> Bool {
  self.expanded_ids.contains(id)
}

///|
/// Select a node
pub fn TreeState::select(self : TreeState, id : String) -> TreeState {
  { ..self, selected_id: id, focused_id: id }
}

///|
/// Focus a node
pub fn TreeState::focus(self : TreeState, id : String) -> TreeState {
  { ..self, focused_id: id }
}

// =============================================================================
// Focus Navigation
// =============================================================================

///|
/// Focus navigation helper for keyboard navigation
pub(all) struct FocusNav {
  ids : Array[String]
  current_index : Int
}

///|
/// Create focus navigation
pub fn FocusNav::new(ids : Array[String]) -> FocusNav {
  { ids, current_index: 0 }
}

///|
/// Get current focused ID
pub fn FocusNav::current(self : FocusNav) -> String {
  if self.ids.length() == 0 {
    ""
  } else {
    self.ids[self.current_index]
  }
}

///|
/// Move focus to next item
pub fn FocusNav::next(self : FocusNav) -> FocusNav {
  if self.ids.length() == 0 {
    self
  } else {
    let next_index = (self.current_index + 1) % self.ids.length()
    { ..self, current_index: next_index }
  }
}

///|
/// Move focus to previous item
pub fn FocusNav::prev(self : FocusNav) -> FocusNav {
  if self.ids.length() == 0 {
    self
  } else {
    let prev_index = if self.current_index == 0 {
      self.ids.length() - 1
    } else {
      self.current_index - 1
    }
    { ..self, current_index: prev_index }
  }
}

///|
/// Focus specific ID
pub fn FocusNav::focus_id(self : FocusNav, id : String) -> FocusNav {
  for i, item in self.ids {
    if item == id {
      return { ..self, current_index: i }
    }
  }
  self
}

///|
/// Check if ID is focused
pub fn FocusNav::is_focused(self : FocusNav, id : String) -> Bool {
  self.current() == id
}
