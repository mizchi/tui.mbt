///|
/// Story-based component snapshot testing
///
/// Defines stories for visual regression testing of UI components.
/// Each story renders a component in a specific state for snapshot comparison.

///|
/// A single story representing a component in a specific state
pub(all) struct Story {
  /// Category/component name (e.g., "button", "checkbox")
  category : String
  /// Story name (e.g., "normal", "hover", "disabled")
  name : String
  /// Viewport width for rendering
  width : Int
  /// Viewport height for rendering
  height : Int
  /// Component factory function
  render : () -> @core.Component
}

///|
/// Create a new story
pub fn Story::new(
  category : String,
  name : String,
  render : () -> @core.Component,
  width? : Int = 30,
  height? : Int = 5,
) -> Story {
  { category, name, width, height, render }
}

///|
/// Render story to plain text (no ANSI codes)
/// Lines are trimmed and joined with newlines for readability
pub fn Story::to_plain(self : Story) -> String {
  let app = @render.App::new(self.width, self.height)
  let component = (self.render)()
  let frame = app.render_frame(component)
  let plain = @testing.strip_ansi(frame)

  // ANSI uses cursor positioning, not newlines, so we need to split by width
  // Account for CJK characters which take 2 terminal columns but 1 character
  let chars = plain.to_array()
  let lines : Array[String] = []
  let mut pos = 0
  for row = 0; row < self.height; row = row + 1 {
    let line_chars : Array[Char] = []
    let mut col = 0
    while col < self.width && pos < chars.length() {
      let c = chars[pos]
      line_chars.push(c)
      pos = pos + 1
      // Wide characters advance column by 2
      col = col + @core.char_display_width(c)
    }
    lines.push(trim_end(String::from_array(line_chars)))
  }

  // Remove trailing empty lines
  while lines.length() > 0 && lines[lines.length() - 1] == "" {
    let _ = lines.pop()

  }
  lines
  .iter()
  .fold(init="", fn(acc, line) {
    if acc == "" {
      line
    } else {
      acc + "\n" + line
    }
  })
}

///|
/// Trim trailing whitespace from a string
fn trim_end(s : String) -> String {
  let chars = s.to_array()
  let mut end = chars.length()
  while end > 0 && (chars[end - 1] == ' ' || chars[end - 1] == '\t') {
    end = end - 1
  }
  if end == chars.length() {
    s
  } else {
    let result : Array[Char] = []
    for i = 0; i < end; i = i + 1 {
      result.push(chars[i])
    }
    String::from_array(result)
  }
}

///|
/// Render story with ANSI codes
pub fn Story::to_ansi(self : Story) -> String {
  let app = @render.App::new(self.width, self.height)
  let component = (self.render)()
  app.render_frame(component)
}

///|
/// Format story as snapshot content with header
pub fn Story::to_snapshot(self : Story) -> String {
  let plain = self.to_plain()
  let header = "# " +
    self.category +
    "/" +
    self.name +
    " (" +
    self.width.to_string() +
    "x" +
    self.height.to_string() +
    ")\n"
  header + plain
}

///|
/// Get the filename for this story's snapshot
pub fn Story::snapshot_filename(self : Story) -> String {
  self.category + "_" + self.name + ".txt"
}
