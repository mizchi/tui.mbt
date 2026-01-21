///|
/// Headless Runner - Playwright-style API for TUI testing

///|
/// Headless app instance
pub(all) struct HeadlessApp {
  width : Int
  height : Int
  output : String
}

///|
/// Create headless app
pub fn HeadlessApp::new(width? : Int = 80, height? : Int = 24) -> HeadlessApp {
  HeadlessApp::{ width, height, output: "" }
}

///|
/// Render component and get output
pub fn HeadlessApp::render(
  self : HeadlessApp,
  component : @core.Component,
) -> HeadlessApp {
  let output = @render.render_once(self.width, self.height, component)
  HeadlessApp::{ width: self.width, height: self.height, output }
}

///|
/// Get text content (similar to playwright's page.content())
pub fn HeadlessApp::content(self : HeadlessApp) -> String {
  self.output
}

///|
/// Get ANSI output (for debugging)
pub fn HeadlessApp::ansi_output(self : HeadlessApp) -> String {
  self.output
}

///|
/// Locator for finding components by ID
pub(all) struct Locator {
  id : String
}

///|
/// Find component by ID
pub fn HeadlessApp::locator(_self : HeadlessApp, id : String) -> Locator {
  Locator::{ id, }
}

///|
/// Page-level operations (Playwright style)
pub(all) struct Page {
  app : HeadlessApp
}

///|
/// Create page from app
pub fn Page::new(app : HeadlessApp) -> Page {
  Page::{ app, }
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
/// Type text (placeholder for future input handling)
pub fn Keyboard::type_text(self : Keyboard, _text : String) -> Keyboard {
  self
}

///|
/// Press key by name (placeholder for future input handling)
pub fn Keyboard::press(self : Keyboard, _key_name : String) -> Keyboard {
  self
}

///|
/// Snapshot testing helper (simplified)
pub fn snapshot(_app : HeadlessApp, _name : String) -> Unit {
  // Snapshot content is available via app.content()
  ()
}
