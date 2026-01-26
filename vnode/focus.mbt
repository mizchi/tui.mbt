///|
/// Focus management utilities for accessibility-based Tab navigation

///|
/// Focusable element with its tab index and element id
pub struct FocusableElement {
  id : String
  tab_index : Int
}

///|
/// Focus context for managing Tab navigation
pub struct FocusContext {
  elements : Array[FocusableElement]
  mut current_index : Int
}

///|
/// Create a new focus context
pub fn FocusContext::new() -> FocusContext {
  { elements: [], current_index: -1 }
}

///|
/// Register a focusable element
/// Elements are sorted by tab_index when calculating focus order
pub fn FocusContext::register(
  self : FocusContext,
  id : String,
  tab_index : Int,
) -> Unit {
  // Only register if tab_index >= 0 (-1 means not focusable)
  if tab_index >= 0 {
    self.elements.push({ id, tab_index })
  }
}

///|
/// Clear all registered elements (call before re-rendering)
pub fn FocusContext::clear(self : FocusContext) -> Unit {
  // Reset to empty state
  let _ = self.elements.drain(0, self.elements.length())
  self.current_index = -1
}

///|
/// Get the sorted list of focusable elements by tab_index
/// Tab order: 0 comes first (in document order), then 1, 2, 3, ...
fn FocusContext::sorted_elements(
  self : FocusContext,
) -> Array[FocusableElement] {
  if self.elements.length() == 0 {
    return []
  }
  // Stable sort by tab_index
  let sorted = self.elements.copy()
  sorted.sort_by(fn(a, b) { a.tab_index - b.tab_index })
  sorted
}

///|
/// Move focus to the next element (Tab key)
/// Returns the id of the newly focused element, or None if no focusable elements
pub fn FocusContext::focus_next(self : FocusContext) -> String? {
  let sorted = self.sorted_elements()
  if sorted.length() == 0 {
    return None
  }
  self.current_index = (self.current_index + 1) % sorted.length()
  Some(sorted[self.current_index].id)
}

///|
/// Move focus to the previous element (Shift+Tab key)
/// Returns the id of the newly focused element, or None if no focusable elements
pub fn FocusContext::focus_prev(self : FocusContext) -> String? {
  let sorted = self.sorted_elements()
  if sorted.length() == 0 {
    return None
  }
  self.current_index = if self.current_index <= 0 {
    sorted.length() - 1
  } else {
    self.current_index - 1
  }
  Some(sorted[self.current_index].id)
}

///|
/// Set focus to a specific element by id
/// Returns true if the element was found and focused
pub fn FocusContext::focus_by_id(self : FocusContext, id : String) -> Bool {
  let sorted = self.sorted_elements()
  for i, elem in sorted {
    if elem.id == id {
      self.current_index = i
      return true
    }
  }
  false
}

///|
/// Get the currently focused element id
pub fn FocusContext::current_focus(self : FocusContext) -> String? {
  let sorted = self.sorted_elements()
  if self.current_index >= 0 && self.current_index < sorted.length() {
    Some(sorted[self.current_index].id)
  } else {
    None
  }
}

///|
/// Get all focusable element ids in tab order
pub fn FocusContext::focusable_ids(self : FocusContext) -> Array[String] {
  self.sorted_elements().map(fn(e) { e.id })
}

///|
/// Check if an element is focusable
pub fn FocusContext::is_focusable(self : FocusContext, id : String) -> Bool {
  for elem in self.elements {
    if elem.id == id {
      return true
    }
  }
  false
}

///|
/// Get the number of focusable elements
pub fn FocusContext::count(self : FocusContext) -> Int {
  self.elements.length()
}

///|
/// Extract tab_index from TuiAttrValue if present
pub fn extract_tab_index(attrs : Array[(String, TuiAttr)]) -> Int? {
  for attr in attrs {
    let (key, value) = attr
    if key == "tab_index" {
      match value {
        @luna.Attr::VStatic(TuiAttrValue::TabIndex(v)) => return Some(v)
        @luna.Attr::VDynamic(getter) =>
          match getter() {
            TuiAttrValue::TabIndex(v) => return Some(v)
            _ => continue
          }
        _ => continue
      }
    }
  }
  None
}
