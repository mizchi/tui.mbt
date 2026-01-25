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
  let node = row(children=[text("A"), text("B"), text("C")])
  let lines = render_to_lines(node)
  // Row should produce a single line
  inspect(lines.length(), content="1")
  inspect(lines[0].contains("A"), content="true")
  inspect(lines[0].contains("B"), content="true")
  inspect(lines[0].contains("C"), content="true")
}

///|
test "render_to_lines with column" {
  let node = column(children=[text("Line1"), text("Line2"), text("Line3")])
  let lines = render_to_lines(node)
  // Column should produce multiple lines
  inspect(lines.length(), content="3")
  inspect(lines[0].contains("Line1"), content="true")
  inspect(lines[1].contains("Line2"), content="true")
  inspect(lines[2].contains("Line3"), content="true")
}

///|
test "render_to_lines with nested structure" {
  let node = column(children=[
    row(children=[text("? ", fg="yellow"), text("Question", bold=true)]),
    text("  Option 1", fg="cyan"),
    text("  Option 2"),
  ])
  let lines = render_to_lines(node)
  inspect(lines.length(), content="3")
  inspect(lines[0].contains("Question"), content="true")
  inspect(lines[1].contains("Option 1"), content="true")
  inspect(lines[2].contains("Option 2"), content="true")
}
