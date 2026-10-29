///|
test "render_to_lines with simple text" {
  let node = text("Hello")
  let lines = render_to_lines(node)
  inspect(lines.length(), content="1")
  inspect(lines[0].contains("Hello"), content="true")
}

///|
test "render_to_lines with colored text" {
  let node = text("Green", fg="green")
  let lines = render_to_lines(node)
  inspect(lines.length(), content="1")
  inspect(lines[0].contains("Green"), content="true")
  // Should contain ANSI color codes
  inspect(lines[0].length() > 5, content="true")
}

///|
test "render_to_lines with row" {
  let node = row([text("A"), text("B"), text("C")])
  let lines = render_to_lines(node)
  // Row should produce a single line
  inspect(lines.length(), content="1")
  inspect(lines[0].contains("A"), content="true")
  inspect(lines[0].contains("B"), content="true")
  inspect(lines[0].contains("C"), content="true")
}

///|
test "render_to_lines with column" {
  let node = column([text("Line1"), text("Line2"), text("Line3")])
  let lines = render_to_lines(node)
  // Column should produce multiple lines
  inspect(lines.length(), content="3")
  inspect(lines[0].contains("Line1"), content="true")
  inspect(lines[1].contains("Line2"), content="true")
  inspect(lines[2].contains("Line3"), content="true")
}

///|
test "render_to_lines with nested structure" {
  let node = column([
    row([text("? ", fg="yellow"), text("Question", bold=true)]),
    text("  Option 1", fg="cyan"),
    text("  Option 2"),
  ])
  let lines = render_to_lines(node)
  inspect(lines.length(), content="3")
  inspect(lines[0].contains("Question"), content="true")
  inspect(lines[1].contains("Option 1"), content="true")
  inspect(lines[2].contains("Option 2"), content="true")
}

///|
test "render_to_lines: true color mode emits 24-bit SGR" {
  let node = text("Red", fg="rgb(255,0,0)")
  let lines = render_to_lines(node, color_mode=@render.ColorMode::TrueColor)
  inspect(lines.length(), content="1")
  inspect(lines[0].contains("\u{1b}[38;2;255;0;0m"), content="true")
}

///|
test "render_to_lines: default color mode stays on the 256-color palette" {
  let node = text("Red", fg="rgb(255,0,0)")
  let lines = render_to_lines(node)
  inspect(lines[0].contains("\u{1b}[38;5;196m"), content="true")
  inspect(lines[0].contains("38;2;"), content="false")
}

///|
test "render_overlay_at: forwards the color mode" {
  let node = text("Hi", fg="rgb(1,2,3)")
  let overlay = render_overlay_at(
    0,
    0,
    node,
    color_mode=@render.ColorMode::TrueColor,
  )
  inspect(overlay.contains("\u{1b}[38;2;1;2;3m"), content="true")
}
