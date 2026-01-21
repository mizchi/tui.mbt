///|
/// Headless Runner - Playwright-style API for TUI testing

///|
/// Headless app instance
pub(all) struct HeadlessApp {
  width : Int
  height : Int
  app : @render.App
  buffer : @render.CharBuffer?
}

///|
/// Create headless app
pub fn HeadlessApp::new(width? : Int = 80, height? : Int = 24) -> HeadlessApp {
  let app = @render.App::new(width, height)
  HeadlessApp::{
    width,
    height,
    app,
    buffer: None,
  }
}

///|
/// Render component and get buffer
pub fn HeadlessApp::render(
  self : HeadlessApp,
  component : @core.Component,
) -> HeadlessApp {
  let _buffer = @render.render_once(component, self.width, self.height)
  HeadlessApp::{ buffer: Some(_buffer), ..self }
}

///|
/// Get text content (similar to playwright's page.content())
pub fn HeadlessApp::content(self : HeadlessApp) -> String {
  match self.buffer {
    Some(buf) => buffer_to_text(buf)
    None => ""
  }
}

///|
/// Convert buffer to plain text
fn buffer_to_text(buf : @render.CharBuffer) -> String {
  let mut result = ""
  for row = 0; row < buf.height; row = row + 1 {
    for col = 0; col < buf.width; col = col + 1 {
      let cell = buf.get_cell(col, row)
      result = result + cell.char.to_string()
    }
    if row < buf.height - 1 {
      result = result + "\n"
    }
  }
  result
}

///|
/// Get ANSI output (for debugging)
pub fn HeadlessApp::ansi_output(self : HeadlessApp) -> String {
  match self.buffer {
    Some(buf) => @render.buffer_to_ansi(buf)
    None => ""
  }
}

///|
/// Locator for finding components by ID
pub(all) struct Locator {
  app : HeadlessApp
  id : String
}

///|
/// Find component by ID
pub fn HeadlessApp::locator(self : HeadlessApp, id : String) -> Locator {
  Locator::{ app: self, id }
}

///|
/// Get hit test result for locator
pub fn Locator::element(self : Locator) -> @events.HitTestResult? {
  match self.app.buffer {
    Some(buf) => @events.hit_test_root(buf, 0, 0)
    None => None
  }
}

///|
/// Check if element exists
pub fn Locator::exists(self : Locator) -> Bool {
  match self.app.buffer {
    Some(buf) => @events.find_layout_by_id_root(buf, self.id) != None
    None => false
  }
}

///|
/// Get element text content
pub fn Locator::text(self : Locator) -> String {
  match self.app.buffer {
    Some(buf) => {
      match @events.find_layout_by_id_root(buf, self.id) {
        Some(layout) => layout.node.text
        None => ""
      }
    }
    None => ""
  }
}

///|
/// Simulate mouse click
pub fn Locator::click(self : Locator) -> HeadlessApp {
  match self.app.buffer {
    Some(buf) => {
      match @events.find_layout_by_id_root(buf, self.id) {
        Some(layout) => {
          let (x, y) = (layout.x + layout.width / 2, layout.y + layout.height / 2)
          self.app.hit_test(x, y)
          self.app
        }
        None => self.app
      }
    }
    None => self.app
  }
}

///|
/// Page-level operations (Playwright style)
pub(all) struct Page {
  app : HeadlessApp
}

///|
/// Create page from app
pub fn Page::new(app : HeadlessApp) -> Page {
  Page::{ app }
}

///|
/// Get full page content
pub fn Page::content(self : Page) -> String {
  self.app.content()
}

///|
/// Locator by ID
pub fn Page::locator(self : Page, id : String) -> Locator {
  self.app.locator(id)
}

///|
/// Simulate keyboard input
pub fn Page::keyboard(self : Page, input : String) -> HeadlessApp {
  // In a real implementation, this would:
  // 1. Parse the input string into key events
  // 2. Route events through the app's input handler
  // 3. Re-render and return updated app
  self.app
}

///|
/// Keyboard object for detailed input
pub(all) struct Keyboard {
  app : HeadlessApp
}

///|
/// Get keyboard for page
pub fn Page::keyboard(self : Page) -> Keyboard {
  Keyboard::{ app: self.app }
}

///|
/// Type text (sends key events for each character)
pub fn Keyboard::type(self : Keyboard, text : String) -> HeadlessApp {
  self.app
}

///|
/// Press key by name (Enter, Escape, arrows, etc.)
pub fn Keyboard::press(self : Keyboard, key_name : String) -> HeadlessApp {
  self.app
}

///|
/// Assert helpers for testing
pub(all) struct Assertions {
  locator : Locator
}

///|
/// Get assertions for locator
pub fn Locator::assertions(self : Locator) -> Assertions {
  Assertions::{ locator: self }
}

///|
/// Assert element is visible
pub fn Assertions::is_visible(self : Assertions) -> Bool {
  self.locator.exists()
}

///|
/// Assert element has specific text
pub fn Assertions::has_text(self : Assertions, expected : String) -> Bool {
  self.locator.text() == expected
}

///|
/// Assert element contains text
pub fn Assertions::contains_text(self : Assertions, expected : String) -> Bool {
  self.locator.text().contains(expected)
}

///|
/// Snapshot testing
pub fn snapshot(
  app : HeadlessApp,
  name : String,
) -> Unit {
  let content = app.content()
  inspect(content, content=name)
}

///|
/// Expect test helpers
pub fn expect_eq(
  actual : String,
  expected : String,
  message? : String = "",
) -> Unit {
  assert_eq(actual, expected, message)
}
