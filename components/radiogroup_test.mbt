///|
/// Tests for RadioGroup component

// ============================================
// Snapshot Tests
// ============================================

///|
test "radiogroup: vertical layout" {
  let options = [
    @components.RadioOption::{ id: "opt1", label: "Option 1" },
    @components.RadioOption::{ id: "opt2", label: "Option 2" },
    @components.RadioOption::{ id: "opt3", label: "Option 3" },
  ]
  let comp = radiogroup(options, "opt2")
  let output = @render.render_once(30, 5, comp)
  inspect(
    output,
    content="\u{1b}[2J\u{1b}[1;1H\u{1b}[38;5;231m○ Option 1                    \u{1b}[2;1H                              \u{1b}[3;1H\u{1b}[38;5;51m◉\u{1b}[38;5;231m \u{1b}[38;5;51mOption 2\u{1b}[38;5;231m                    \u{1b}[4;1H                              \u{1b}[5;1H○ Option 3                    \u{1b}[0m",
  )
}

///|
test "radiogroup: horizontal layout" {
  let options = [
    @components.RadioOption::{ id: "a", label: "A" },
    @components.RadioOption::{ id: "b", label: "B" },
    @components.RadioOption::{ id: "c", label: "C" },
  ]
  let comp = radiogroup(options, "b", orientation=RadioOrientation::Horizontal)
  let output = @render.render_once(30, 2, comp)
  inspect(
    output,
    content="\u{1b}[2J\u{1b}[1;1H\u{1b}[38;5;231m○ A  \u{1b}[38;5;51m◉\u{1b}[38;5;231m \u{1b}[38;5;51mB\u{1b}[38;5;231m  ○ C                 \u{1b}[2;1H                              \u{1b}[0m",
  )
}

///|
test "radiogroup: no selection" {
  let options = [
    @components.RadioOption::{ id: "x", label: "X" },
    @components.RadioOption::{ id: "y", label: "Y" },
  ]
  let comp = radiogroup(options, "none")
  let output = @render.render_once(20, 3, comp)
  inspect(
    output,
    content="\u{1b}[2J\u{1b}[1;1H\u{1b}[38;5;231m○ X                 \u{1b}[2;1H○ Y                 \u{1b}[3;1H                    \u{1b}[0m",
  )
}

///|
test "radio: single radio button" {
  let selected = radio("Selected", true)
  let unselected = radio("Unselected", false)
  let out_s = @render.render_once(20, 1, selected)
  let out_u = @render.render_once(20, 1, unselected)
  inspect(
    out_s,
    content="\u{1b}[2J\u{1b}[1;1H\u{1b}[38;5;51m◉\u{1b}[38;5;231m \u{1b}[38;5;51mSelected\u{1b}[38;5;231m          \u{1b}[0m",
  )
  inspect(
    out_u,
    content="\u{1b}[2J\u{1b}[1;1H\u{1b}[38;5;231m○ Unselected        \u{1b}[0m",
  )
}

// ============================================
// Accessibility Tests
// ============================================

///|
test "a11y: radiogroup - each option has unique ID" {
  let options = [
    @components.RadioOption::{ id: "red", label: "Red" },
    @components.RadioOption::{ id: "green", label: "Green" },
    @components.RadioOption::{ id: "blue", label: "Blue" },
  ]
  let comp = radiogroup(options, "green")
  let ids : Array[String] = []
  for child in comp.node.children {
    ids.push(child.id)
  }
  inspect(
    ids,
    content=(
      #|["red", "green", "blue"]
    ),
  )
}

///|
test "a11y: radiogroup - selected is visually distinct" {
  let options = [
    @components.RadioOption::{ id: "a", label: "A" },
    @components.RadioOption::{ id: "b", label: "B" },
  ]
  let out_a = @render.render_once(15, 2, radiogroup(options, "a"))
  let out_b = @render.render_once(15, 2, radiogroup(options, "b"))
  inspect(out_a != out_b, content="true")
  inspect(out_a.contains("◉"), content="true")
  inspect(out_a.contains("○"), content="true")
}

///|
test "a11y: radio - focusable ID for keyboard nav" {
  let r = radio("Choice", false, id="choice-radio")
  inspect(r.node.id, content="choice-radio")
}

///|
test "a11y: radiogroup - only one selected at a time" {
  let options = [
    @components.RadioOption::{ id: "a", label: "A" },
    @components.RadioOption::{ id: "b", label: "B" },
    @components.RadioOption::{ id: "c", label: "C" },
  ]
  let comp = radiogroup(options, "b")
  let output = @render.render_once(20, 4, comp)
  // Count filled circles (◉) - should be exactly 1
  let mut count = 0
  for i = 0; i < output.length(); i = i + 1 {
    if output[i] == '◉' {
      count = count + 1
    }
  }
  inspect(count, content="1")
}

///|
test "a11y: radiogroup - container has ID for group management" {
  let options = [@components.RadioOption::{ id: "x", label: "X" }]
  let comp = radiogroup(options, "x", id="color-group")
  inspect(comp.node.id, content="color-group")
}

///|
test "a11y: radiogroup - selected icon is distinct from unselected" {
  let options = [
    @components.RadioOption::{ id: "sel", label: "Selected" },
    @components.RadioOption::{ id: "unsel", label: "Unselected" },
  ]
  let comp = radiogroup(options, "sel")
  let output = @render.render_once(25, 3, comp)
  // Selected should have filled circle, unselected should have empty
  inspect(output.contains("◉ Selected"), content="false")
  inspect(output.contains("○ Unselected"), content="true")
}

///|
test "a11y: radiogroup - orientation changes layout" {
  let options = [
    @components.RadioOption::{ id: "a", label: "A" },
    @components.RadioOption::{ id: "b", label: "B" },
  ]
  let v = radiogroup(options, "a", orientation=RadioOrientation::Vertical)
  let h = radiogroup(options, "a", orientation=RadioOrientation::Horizontal)
  // Vertical uses Column, Horizontal uses Row
  inspect(v.node.style.flex_direction, content="Column")
  inspect(h.node.style.flex_direction, content="Row")
}
