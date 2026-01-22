///|
/// Test harness for E2E testing of TUI components
/// Provides a small viewport and captures rendered output

///|
/// Default small viewport size for tests
pub fn test_width() -> Int {
  40
}

///|
pub fn test_height() -> Int {
  10
}

///|
/// Test harness for capturing TUI renders
pub(all) struct TestHarness {
  app : @render.App
  width : Int
  height : Int
  // Captured output history
  frames : Array[String]
}

///|
/// Create a new test harness with default small viewport
pub fn TestHarness::new(width? : Int = 40, height? : Int = 10) -> TestHarness {
  { app: @render.App::new(width, height), width, height, frames: [] }
}

///|
/// Render a component and capture output
pub fn TestHarness::render(
  self : TestHarness,
  component : @core.Component,
) -> String {
  let output = self.app.render_frame(component)
  self.frames.push(output)
  output
}

///|
/// Get the last rendered frame
pub fn TestHarness::last_frame(self : TestHarness) -> String {
  if self.frames.length() > 0 {
    self.frames[self.frames.length() - 1]
  } else {
    ""
  }
}

///|
/// Get the last rendered frame with ANSI codes stripped
pub fn TestHarness::last_frame_plain(self : TestHarness) -> String {
  strip_ansi(self.last_frame())
}

///|
/// Get frame count
pub fn TestHarness::frame_count(self : TestHarness) -> Int {
  self.frames.length()
}

///|
/// Clear frame history
pub fn TestHarness::clear_frames(self : TestHarness) -> Unit {
  self.frames.clear()
}

///|
/// Hit test at coordinates
pub fn TestHarness::hit_test(
  self : TestHarness,
  x : Int,
  y : Int,
) -> @events.HitTestResult? {
  self.app.hit_test(x, y)
}

///|
/// Find element by ID
pub fn TestHarness::find_by_id(
  self : TestHarness,
  id : String,
) -> @events.HitTestResult? {
  self.app.find_by_id(id)
}

///|
/// Simulate a key input and return parsed event
pub fn TestHarness::parse_key(
  self : TestHarness,
  key : String,
) -> @events.InputEvent {
  ignore(self) // harness context not needed for parsing
  @events.parse_input(key)
}

///|
/// Check if frame contains text (searches in plain text)
pub fn TestHarness::contains(self : TestHarness, text : String) -> Bool {
  self.last_frame_plain().contains(text)
}

///|
/// Check if frame contains text at specific line (0-indexed)
pub fn TestHarness::line_contains(
  self : TestHarness,
  line : Int,
  text : String,
) -> Bool {
  let plain = self.last_frame_plain()
  let lines : Array[String] = plain
    .split("\n")
    .map(fn(sv) { sv.to_string() })
    .collect()
  if line >= 0 && line < lines.length() {
    lines[line].contains(text)
  } else {
    false
  }
}

///|
/// Get specific line from plain output (0-indexed)
pub fn TestHarness::get_line(self : TestHarness, line : Int) -> String {
  let plain = self.last_frame_plain()
  let lines : Array[String] = plain
    .split("\n")
    .map(fn(sv) { sv.to_string() })
    .collect()
  if line >= 0 && line < lines.length() {
    lines[line]
  } else {
    ""
  }
}

///|
/// Get all lines from plain output
pub fn TestHarness::get_lines(self : TestHarness) -> Array[String] {
  let plain = self.last_frame_plain()
  plain.split("\n").map(fn(sv) { sv.to_string() }).collect()
}
