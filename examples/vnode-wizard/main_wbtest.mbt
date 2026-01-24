///|
test "render_select_prompt with active state" {
  let lines = render_select_prompt(
    "Which template?",
    ["React", "Vue", "Svelte"],
    1,
    "",
  )
  // Active state: question + help text + 3 options = 5 lines
  inspect(lines.length(), content="5")
  // First line should contain the question
  inspect(lines[0].contains("Which template?"), content="true")
  // Current option (index 1 = Vue) should have ">"
  inspect(lines[3].contains(">"), content="true")
  inspect(lines[3].contains("Vue"), content="true")
}

///|
test "render_select_prompt with completed state" {
  let lines = render_select_prompt(
    "Which template?",
    ["React", "Vue", "Svelte"],
    0,
    "React",
  )
  // Completed state: just 1 line
  inspect(lines.length(), content="1")
  inspect(lines[0].contains("Which template?"), content="true")
  inspect(lines[0].contains("React"), content="true")
}

///|
test "render_confirm_prompt with active state" {
  let lines = render_confirm_prompt("Initialize git?", 0, None)
  // Active state: question + Yes/No = 2 lines
  inspect(lines.length(), content="2")
  inspect(lines[0].contains("Initialize git?"), content="true")
  inspect(lines[1].contains("Yes"), content="true")
  inspect(lines[1].contains("No"), content="true")
}

///|
test "render_confirm_prompt with completed state" {
  let lines = render_confirm_prompt("Initialize git?", 0, Some(true))
  // Completed state: just 1 line
  inspect(lines.length(), content="1")
  inspect(lines[0].contains("Initialize git?"), content="true")
  inspect(lines[0].contains("Yes"), content="true")
}
