///|
/// Collect all stories from all component categories

///|
pub fn all_stories() -> Array[Story] {
  let stories : Array[Story] = []

  // Button
  for s in button_stories() {
    stories.push(s)
  }

  // Checkbox & Switch
  for s in checkbox_stories() {
    stories.push(s)
  }
  for s in switch_stories() {
    stories.push(s)
  }

  // Selection (Radio, Listbox, Select)
  for s in radio_stories() {
    stories.push(s)
  }
  for s in listbox_stories() {
    stories.push(s)
  }
  for s in select_stories() {
    stories.push(s)
  }

  // Navigation (Tabs, Accordion, Menu)
  for s in tabs_stories() {
    stories.push(s)
  }
  for s in accordion_stories() {
    stories.push(s)
  }
  for s in menu_stories() {
    stories.push(s)
  }
  for s in context_menu_stories() {
    stories.push(s)
  }

  // Input
  for s in input_stories() {
    stories.push(s)
  }
  for s in textarea_stories() {
    stories.push(s)
  }

  // Feedback (Progress, Spinner)
  for s in progress_stories() {
    stories.push(s)
  }
  for s in spinner_stories() {
    stories.push(s)
  }
  for s in loading_dots_stories() {
    stories.push(s)
  }

  // Layout
  for s in card_stories() {
    stories.push(s)
  }
  for s in panel_stories() {
    stories.push(s)
  }
  for s in divider_stories() {
    stories.push(s)
  }
  for s in bordered_stories() {
    stories.push(s)
  }
  for s in text_stories() {
    stories.push(s)
  }
  stories
}

///|
/// Get stories for a specific category
pub fn stories_by_category(category : String) -> Array[Story] {
  let result : Array[Story] = []
  for s in all_stories() {
    if s.category == category {
      result.push(s)
    }
  }
  result
}

///|
/// Get all category names
pub fn all_categories() -> Array[String] {
  let categories : Array[String] = []
  let seen : Map[String, Bool] = {}
  for s in all_stories() {
    if not(seen.contains(s.category)) {
      categories.push(s.category)
      seen[s.category] = true
    }
  }
  categories
}
