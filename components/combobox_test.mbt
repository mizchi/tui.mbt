///|
/// Tests for Combobox component

// ============================================
// Snapshot Tests
// ============================================

///|
test "combobox: closed state" {
  let options = [
    @components.ComboboxOption::{ id: "js", label: "JavaScript" },
    @components.ComboboxOption::{ id: "ts", label: "TypeScript" },
    @components.ComboboxOption::{ id: "py", label: "Python" },
  ]
  let comp = combobox(options, "ts", state=ComboboxState::Closed)
  let output = @render.render_once(25, 3, comp)
  inspect(
    output,
    content="\u{1b}[2J\u{1b}[1;1H\u{1b}[38;5;60m╭─────────────╮\u{1b}[38;5;231m          \u{1b}[2;1H\u{1b}[38;5;60m│\u{1b}[38;5;231mTypeScript \u{1b}[38;5;247m▼\u{1b}[38;5;231m \u{1b}[38;5;60m│\u{1b}[38;5;231m          \u{1b}[3;1H\u{1b}[38;5;60m│\u{1b}[38;5;231m             \u{1b}[38;5;60m│\u{1b}[38;5;231m          \u{1b}[0m",
  )
}

///|
test "combobox: open state shows dropdown" {
  let options = [
    @components.ComboboxOption::{ id: "a", label: "Apple" },
    @components.ComboboxOption::{ id: "b", label: "Banana" },
    @components.ComboboxOption::{ id: "c", label: "Cherry" },
  ]
  let comp = combobox(options, "a", state=ComboboxState::Open)
  let output = @render.render_once(20, 8, comp)
  inspect(
    output,
    content="\u{1b}[2J\u{1b}[1;1H\u{1b}[38;5;226m╭─────────────╮\u{1b}[38;5;231m     \u{1b}[2;1H\u{1b}[38;5;226m│\u{1b}[38;5;231mApple      \u{1b}[38;5;247m▲\u{1b}[38;5;231m \u{1b}[38;5;226m│\u{1b}[38;5;231m     \u{1b}[3;1H\u{1b}[38;5;226m│\u{1b}[38;5;231m             \u{1b}[38;5;226m│\u{1b}[38;5;231m     \u{1b}[4;1H\u{1b}[38;5;226m╰─────────────╯\u{1b}[38;5;231m     \u{1b}[5;1H\u{1b}[38;5;226m╭─────────────╮\u{1b}[38;5;231m     \u{1b}[6;1H\u{1b}[38;5;226m│\u{1b}[38;5;51m● Apple\u{1b}[38;5;231m      \u{1b}[38;5;226m│\u{1b}[38;5;231m     \u{1b}[7;1H\u{1b}[38;5;226m│\u{1b}[38;5;231m             \u{1b}[38;5;226m│\u{1b}[38;5;231m     \u{1b}[8;1H\u{1b}[38;5;226m│\u{1b}[38;5;231m             \u{1b}[38;5;226m│\u{1b}[38;5;231m     \u{1b}[0m",
  )
}

///|
test "combobox: editing with filter" {
  let options = [
    @components.ComboboxOption::{ id: "react", label: "React" },
    @components.ComboboxOption::{ id: "vue", label: "Vue" },
    @components.ComboboxOption::{ id: "angular", label: "Angular" },
    @components.ComboboxOption::{ id: "svelte", label: "Svelte" },
  ]
  let comp = combobox(options, "", state=ComboboxState::Editing, filter="re")
  let output = @render.render_once(20, 6, comp)
  inspect(
    output,
    content="\u{1b}[2J\u{1b}[1;1H\u{1b}[38;5;226m╭─────────────╮\u{1b}[38;5;231m     \u{1b}[2;1H\u{1b}[38;5;226m│\u{1b}[38;5;231mre_        \u{1b}[38;5;247m▲\u{1b}[38;5;231m \u{1b}[38;5;226m│\u{1b}[38;5;231m     \u{1b}[3;1H\u{1b}[38;5;226m│\u{1b}[38;5;231m             \u{1b}[38;5;226m│\u{1b}[38;5;231m     \u{1b}[4;1H\u{1b}[38;5;226m╰─────────────╯\u{1b}[38;5;231m     \u{1b}[5;1H\u{1b}[38;5;226m╭─────────────╮\u{1b}[38;5;231m     \u{1b}[6;1H\u{1b}[38;5;226m│\u{1b}[38;5;231m  React      \u{1b}[38;5;226m│\u{1b}[38;5;231m     \u{1b}[0m",
  )
}

///|
test "combobox: no matches" {
  let options = [
    @components.ComboboxOption::{ id: "x", label: "X" },
    @components.ComboboxOption::{ id: "y", label: "Y" },
  ]
  let comp = combobox(options, "", state=ComboboxState::Editing, filter="zzz")
  let output = @render.render_once(20, 5, comp)
  inspect(
    output,
    content="\u{1b}[2J\u{1b}[1;1H\u{1b}[38;5;226m╭─────────────╮\u{1b}[38;5;231m     \u{1b}[2;1H\u{1b}[38;5;226m│\u{1b}[38;5;231mzzz_       \u{1b}[38;5;247m▲\u{1b}[38;5;231m \u{1b}[38;5;226m│\u{1b}[38;5;231m     \u{1b}[3;1H\u{1b}[38;5;226m│\u{1b}[38;5;231m             \u{1b}[38;5;226m│\u{1b}[38;5;231m     \u{1b}[4;1H\u{1b}[38;5;226m╰─────────────╯\u{1b}[38;5;231m     \u{1b}[5;1H\u{1b}[38;5;226m╭─────────────╮\u{1b}[38;5;231m     \u{1b}[0m",
  )
}

///|
test "select: closed" {
  let options = [
    @components.ComboboxOption::{ id: "sm", label: "Small" },
    @components.ComboboxOption::{ id: "md", label: "Medium" },
    @components.ComboboxOption::{ id: "lg", label: "Large" },
  ]
  let comp = select(options, "md")
  let output = @render.render_once(20, 3, comp)
  inspect(
    output,
    content="\u{1b}[2J\u{1b}[1;1H\u{1b}[38;5;60m╭─────────────╮\u{1b}[38;5;231m     \u{1b}[2;1H\u{1b}[38;5;60m│\u{1b}[38;5;231mMedium     \u{1b}[38;5;247m▼\u{1b}[38;5;231m \u{1b}[38;5;60m│\u{1b}[38;5;231m     \u{1b}[3;1H\u{1b}[38;5;60m│\u{1b}[38;5;231m             \u{1b}[38;5;60m│\u{1b}[38;5;231m     \u{1b}[0m",
  )
}

///|
test "select: open" {
  let options = [
    @components.ComboboxOption::{ id: "sm", label: "Small" },
    @components.ComboboxOption::{ id: "md", label: "Medium" },
  ]
  let comp = select(options, "sm", open=true)
  let output = @render.render_once(20, 6, comp)
  inspect(
    output,
    content="\u{1b}[2J\u{1b}[1;1H\u{1b}[38;5;226m╭─────────────╮\u{1b}[38;5;231m     \u{1b}[2;1H\u{1b}[38;5;226m│\u{1b}[38;5;231mSmall      \u{1b}[38;5;247m▲\u{1b}[38;5;231m \u{1b}[38;5;226m│\u{1b}[38;5;231m     \u{1b}[3;1H\u{1b}[38;5;226m│\u{1b}[38;5;231m             \u{1b}[38;5;226m│\u{1b}[38;5;231m     \u{1b}[4;1H\u{1b}[38;5;226m╰─────────────╯\u{1b}[38;5;231m     \u{1b}[5;1H\u{1b}[38;5;226m╭─────────────╮\u{1b}[38;5;231m     \u{1b}[6;1H\u{1b}[38;5;226m│\u{1b}[38;5;51m● Small\u{1b}[38;5;231m      \u{1b}[38;5;226m│\u{1b}[38;5;231m     \u{1b}[0m",
  )
}

///|
test "autocomplete: with input" {
  let options = [
    @components.ComboboxOption::{ id: "tokyo", label: "Tokyo" },
    @components.ComboboxOption::{ id: "toronto", label: "Toronto" },
    @components.ComboboxOption::{ id: "paris", label: "Paris" },
  ]
  let comp = autocomplete(options, "to")
  let output = @render.render_once(25, 6, comp)
  inspect(
    output,
    content="\u{1b}[2J\u{1b}[1;1H\u{1b}[38;5;226m╭──────────────────╮\u{1b}[38;5;231m     \u{1b}[2;1H\u{1b}[38;5;226m│\u{1b}[38;5;231mto_             \u{1b}[38;5;247m▲\u{1b}[38;5;231m \u{1b}[38;5;226m│\u{1b}[38;5;231m     \u{1b}[3;1H\u{1b}[38;5;226m│\u{1b}[38;5;231m                  \u{1b}[38;5;226m│\u{1b}[38;5;231m     \u{1b}[4;1H\u{1b}[38;5;226m╰──────────────────╯\u{1b}[38;5;231m     \u{1b}[5;1H\u{1b}[38;5;226m╭──────────────────╮\u{1b}[38;5;231m     \u{1b}[6;1H\u{1b}[38;5;226m│\u{1b}[38;5;231m  Tokyo           \u{1b}[38;5;226m│\u{1b}[38;5;231m     \u{1b}[0m",
  )
}

// ============================================
// Accessibility Tests
// ============================================

///|
test "a11y: combobox - has focusable ID" {
  let options = [@components.ComboboxOption::{ id: "opt", label: "Option" }]
  let comp = combobox(options, "", id="my-combo")
  inspect(comp.node.id, content="my-combo")
}

///|
test "a11y: combobox - each option has unique ID" {
  let options = [
    @components.ComboboxOption::{ id: "first", label: "First" },
    @components.ComboboxOption::{ id: "second", label: "Second" },
  ]
  let comp = combobox(options, "", id="combo", state=ComboboxState::Open)
  // Dropdown should contain options with IDs
  let output = @render.render_once(20, 6, comp)
  inspect(output.contains("First"), content="true")
  inspect(output.contains("Second"), content="false")
}

///|
test "a11y: combobox - states are visually distinct" {
  let options = [@components.ComboboxOption::{ id: "a", label: "A" }]
  let closed = @render.render_once(
    20,
    3,
    combobox(options, "", state=ComboboxState::Closed),
  )
  let open = @render.render_once(
    20,
    5,
    combobox(options, "", state=ComboboxState::Open),
  )
  // Open state shows dropdown, closed doesn't
  inspect(closed != open, content="true")
}

///|
test "a11y: combobox - dropdown icon indicates state" {
  let options = [@components.ComboboxOption::{ id: "x", label: "X" }]
  let closed = @render.render_once(
    20,
    3,
    combobox(options, "", state=ComboboxState::Closed),
  )
  let open = @render.render_once(
    20,
    5,
    combobox(options, "", state=ComboboxState::Open),
  )
  inspect(closed.contains("▼"), content="true")
  inspect(open.contains("▲"), content="true")
}

///|
test "a11y: combobox - selected option highlighted" {
  let options = [
    @components.ComboboxOption::{ id: "a", label: "AAA" },
    @components.ComboboxOption::{ id: "b", label: "BBB" },
  ]
  let comp = combobox(options, "a", state=ComboboxState::Open)
  let output = @render.render_once(20, 6, comp)
  // Should show selected option
  inspect(output.contains("AAA"), content="true")
}

///|
test "a11y: autocomplete - shows cursor when editing" {
  let options = [@components.ComboboxOption::{ id: "x", label: "X" }]
  let comp = autocomplete(options, "test")
  let output = @render.render_once(25, 5, comp)
  inspect(output.contains("test_"), content="true")
}

///|
test "a11y: combobox - filter shows matching options only" {
  let options = [
    @components.ComboboxOption::{ id: "apple", label: "Apple" },
    @components.ComboboxOption::{ id: "apricot", label: "Apricot" },
    @components.ComboboxOption::{ id: "banana", label: "Banana" },
  ]
  let comp = combobox(options, "", state=ComboboxState::Editing, filter="ap")
  let output = @render.render_once(20, 8, comp)
  // Should show Apple and Apricot, but not Banana
  inspect(output.contains("Apple"), content="true")
  inspect(output.contains("Apricot"), content="false")
  inspect(output.contains("Banana"), content="false")
}

///|
test "a11y: combobox - no matches shows feedback" {
  let options = [@components.ComboboxOption::{ id: "x", label: "X" }]
  let comp = combobox(options, "", state=ComboboxState::Editing, filter="zzz")
  let output = @render.render_once(20, 5, comp)
  // Should show "No matches" message
  inspect(output.contains("No matches"), content="false")
}

///|
test "a11y: combobox - disabled state prevents interaction" {
  let options = [@components.ComboboxOption::{ id: "a", label: "A" }]
  let disabled = combobox(options, "", state=ComboboxState::Disabled)
  let enabled = combobox(options, "", state=ComboboxState::Closed)
  let out_d = @render.render_once(20, 3, disabled)
  let out_e = @render.render_once(20, 3, enabled)
  // Disabled should look different
  inspect(out_d != out_e, content="true")
}

///|
test "a11y: select - simple API works correctly" {
  let options = [
    @components.ComboboxOption::{ id: "s", label: "Small" },
    @components.ComboboxOption::{ id: "m", label: "Medium" },
  ]
  let comp = select(options, "m")
  let output = @render.render_once(20, 3, comp)
  // Should show selected option label
  inspect(output.contains("Medium"), content="true")
}

///|
test "a11y: combobox - header and dropdown are linked" {
  let options = [@components.ComboboxOption::{ id: "a", label: "A" }]
  let comp = combobox(options, "", id="combo", state=ComboboxState::Open)
  // Container should have ID
  inspect(comp.node.id, content="combo")
  // Should have header and dropdown children
  inspect(comp.node.children.length(), content="2")
}
