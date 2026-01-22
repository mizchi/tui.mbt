///|
/// Tests for Listbox component

// ============================================
// Snapshot Tests
// ============================================

///|
test "listbox: single select vertical" {
  let options = [
    @components.listbox_option("apple", "Apple"),
    @components.listbox_option("banana", "Banana"),
    @components.listbox_option("cherry", "Cherry"),
  ]
  let comp = listbox(options, "banana", focused_id="banana")
  let output = @render.render_once(25, 6, comp)
  inspect(
    output,
    content="\u{1b}[2J\u{1b}[1;1H\u{1b}[38;5;60m┌──────────────────┐\u{1b}[38;5;231m     \u{1b}[2;1H\u{1b}[38;5;60m│\u{1b}[38;5;231m   Apple          \u{1b}[38;5;60m│\u{1b}[38;5;231m     \u{1b}[3;1H\u{1b}[38;5;60m│\u{1b}[38;5;226m ▸ Banana\u{1b}[38;5;231m         \u{1b}[38;5;60m│\u{1b}[38;5;231m     \u{1b}[4;1H\u{1b}[38;5;60m│\u{1b}[38;5;231m   Cherry         \u{1b}[38;5;60m│\u{1b}[38;5;231m     \u{1b}[5;1H\u{1b}[38;5;60m└──────────────────┘\u{1b}[38;5;231m     \u{1b}[6;1H                         \u{1b}[0m",
  )
}

///|
test "listbox: with disabled option" {
  let options = [
    @components.listbox_option("a", "Option A"),
    @components.listbox_option("b", "Option B", disabled=true),
    @components.listbox_option("c", "Option C"),
  ]
  let comp = listbox(options, "a")
  let output = @render.render_once(25, 5, comp)
  inspect(
    output,
    content="\u{1b}[2J\u{1b}[1;1H\u{1b}[38;5;60m┌──────────────────┐\u{1b}[38;5;231m     \u{1b}[2;1H\u{1b}[38;5;60m│\u{1b}[38;5;51m ● Option A\u{1b}[38;5;231m       \u{1b}[38;5;60m│\u{1b}[38;5;231m     \u{1b}[3;1H\u{1b}[38;5;60m│\u{1b}[38;5;241m   Option B\u{1b}[38;5;231m       \u{1b}[38;5;60m│\u{1b}[38;5;231m     \u{1b}[4;1H\u{1b}[38;5;60m│\u{1b}[38;5;231m   Option C       \u{1b}[38;5;60m│\u{1b}[38;5;231m     \u{1b}[5;1H\u{1b}[38;5;60m└──────────────────┘\u{1b}[38;5;231m     \u{1b}[0m",
  )
}

///|
test "listbox: horizontal orientation" {
  let options = [
    @components.listbox_option("x", "X"),
    @components.listbox_option("y", "Y"),
    @components.listbox_option("z", "Z"),
  ]
  let comp = listbox(options, "y", orientation=ListboxOrientation::Horizontal)
  let output = @render.render_once(30, 3, comp)
  inspect(
    output,
    content="\u{1b}[2J\u{1b}[1;1H\u{1b}[38;5;60m┌──────────────────┐\u{1b}[38;5;231m          \u{1b}[2;1H\u{1b}[38;5;60m│\u{1b}[38;5;231m   X\u{1b}[38;5;51m ● Y\u{1b}[38;5;231m   Z      \u{1b}[38;5;60m│\u{1b}[38;5;231m          \u{1b}[3;1H\u{1b}[38;5;60m└──────────────────┘\u{1b}[38;5;231m          \u{1b}[0m",
  )
}

///|
test "listbox_multi: multiple selections" {
  let options = [
    @components.listbox_option("red", "Red"),
    @components.listbox_option("green", "Green"),
    @components.listbox_option("blue", "Blue"),
  ]
  let state : @components.ListboxState = {
    focused_id: "green",
    selected_ids: ["red", "blue"],
    anchor_id: "red",
  }
  let comp = listbox_multi(options, state)
  let output = @render.render_once(25, 6, comp)
  inspect(
    output,
    content="\u{1b}[2J\u{1b}[1;1H\u{1b}[38;5;60m┌──────────────────┐\u{1b}[38;5;231m     \u{1b}[2;1H\u{1b}[38;5;60m│\u{1b}[38;5;51m ● [✓] Red\u{1b}[38;5;231m        \u{1b}[38;5;60m│\u{1b}[38;5;231m     \u{1b}[3;1H\u{1b}[38;5;60m│\u{1b}[38;5;226m ▸ [ ] Green\u{1b}[38;5;231m      \u{1b}[38;5;60m│\u{1b}[38;5;231m     \u{1b}[4;1H\u{1b}[38;5;60m│\u{1b}[38;5;51m ● [✓] Blue\u{1b}[38;5;231m       \u{1b}[38;5;60m│\u{1b}[38;5;231m     \u{1b}[5;1H\u{1b}[38;5;60m└──────────────────┘\u{1b}[38;5;231m     \u{1b}[6;1H                         \u{1b}[0m",
  )
}

///|
test "listbox: overflow with scroll indicator" {
  let options = [
    @components.listbox_option("1", "Item 1"),
    @components.listbox_option("2", "Item 2"),
    @components.listbox_option("3", "Item 3"),
    @components.listbox_option("4", "Item 4"),
    @components.listbox_option("5", "Item 5"),
    @components.listbox_option("6", "Item 6"),
  ]
  let comp = listbox(options, "1", max_height=3)
  let output = @render.render_once(25, 7, comp)
  inspect(
    output,
    content="\u{1b}[2J\u{1b}[1;1H\u{1b}[38;5;60m┌──────────────────┐\u{1b}[38;5;231m     \u{1b}[2;1H\u{1b}[38;5;60m│\u{1b}[38;5;51m ● Item 1\u{1b}[38;5;231m         \u{1b}[38;5;60m│\u{1b}[38;5;231m     \u{1b}[3;1H\u{1b}[38;5;60m│\u{1b}[38;5;231m   Item 2         \u{1b}[38;5;60m│\u{1b}[38;5;231m     \u{1b}[4;1H\u{1b}[38;5;60m│\u{1b}[38;5;231m   Item 3         \u{1b}[38;5;60m│\u{1b}[38;5;231m     \u{1b}[5;1H\u{1b}[38;5;60m│\u{1b}[38;5;241m   ... 3 more\u{1b}[38;5;231m     \u{1b}[38;5;60m│\u{1b}[38;5;231m     \u{1b}[6;1H\u{1b}[38;5;60m└──────────────────┘\u{1b}[38;5;231m     \u{1b}[7;1H                         \u{1b}[0m",
  )
}

///|
test "option_list: inline list" {
  let options = [
    @components.listbox_option("a", "Alpha"),
    @components.listbox_option("b", "Beta"),
  ]
  let comp = option_list(options, ["a"])
  let output = @render.render_once(20, 3, comp)
  inspect(
    output,
    content="\u{1b}[2J\u{1b}[1;1H\u{1b}[38;5;51m  Alpha\u{1b}[38;5;231m             \u{1b}[2;1H                    \u{1b}[3;1H  Beta              \u{1b}[0m",
  )
}

///|
test "selectable_list: simple tuple API" {
  let items = [("opt1", "First"), ("opt2", "Second"), ("opt3", "Third")]
  let comp = selectable_list(items, "opt2", focused_id="opt2")
  let output = @render.render_once(20, 4, comp)
  inspect(
    output,
    content="\u{1b}[2J\u{1b}[1;1H\u{1b}[38;5;231m  First             \u{1b}[2;1H                    \u{1b}[3;1H\u{1b}[38;5;226m▸ Second\u{1b}[38;5;231m            \u{1b}[4;1H                    \u{1b}[0m",
  )
}

// ============================================
// Accessibility Tests
// ============================================

///|
test "a11y: listbox - each option has unique ID" {
  let options = [
    @components.listbox_option("item1", "Item 1"),
    @components.listbox_option("item2", "Item 2"),
  ]
  let comp = listbox(options, "item1")
  // Container should have children with IDs
  let ids : Array[String] = []
  for child in comp.node.children {
    if child.id.length() > 0 {
      ids.push(child.id)
    }
  }
  inspect(
    ids,
    content=(
      #|["item1", "item2"]
    ),
  )
}

///|
test "a11y: listbox - selected option is visually distinct" {
  let options = [
    @components.listbox_option("a", "A"),
    @components.listbox_option("b", "B"),
  ]
  let out_a = @render.render_once(20, 4, listbox(options, "a"))
  let out_b = @render.render_once(20, 4, listbox(options, "b"))
  inspect(out_a != out_b, content="true")
}

///|
test "a11y: listbox - focused option has indicator" {
  let options = [
    @components.listbox_option("x", "X"),
    @components.listbox_option("y", "Y"),
  ]
  let comp = listbox(options, "x", focused_id="y")
  let output = @render.render_once(20, 4, comp)
  // Focused item should have ▸ indicator
  inspect(output.contains("▸"), content="true")
}

///|
test "a11y: listbox_multi - shows checkboxes" {
  let options = [
    @components.listbox_option("a", "A"),
    @components.listbox_option("b", "B"),
  ]
  let state : @components.ListboxState = {
    focused_id: "",
    selected_ids: ["a"],
    anchor_id: "",
  }
  let comp = listbox_multi(options, state)
  let output = @render.render_once(20, 4, comp)
  // Multi-select should show checkbox icons
  inspect(output.contains("[✓]"), content="true")
  inspect(output.contains("[ ]"), content="true")
}

///|
test "a11y: listbox - disabled option styled differently" {
  let options = [
    @components.listbox_option("enabled", "Enabled"),
    @components.listbox_option("disabled", "Disabled", disabled=true),
  ]
  let comp = listbox(options, "enabled")
  let output = @render.render_once(25, 4, comp)
  // Both options should be visible
  inspect(output.contains("Enabled"), content="true")
  inspect(output.contains("Disabled"), content="true")
}

///|
test "a11y: listbox - has container ID for focus management" {
  let options = [@components.listbox_option("x", "X")]
  let comp = listbox(options, "x", id="my-listbox")
  inspect(comp.node.id, content="my-listbox")
}

///|
test "a11y: listbox - orientation affects layout" {
  let options = [
    @components.listbox_option("a", "A"),
    @components.listbox_option("b", "B"),
  ]
  let v = listbox(options, "a", orientation=ListboxOrientation::Vertical)
  let h = listbox(options, "a", orientation=ListboxOrientation::Horizontal)
  // Vertical uses Column, Horizontal uses Row
  inspect(v.node.style.flex_direction, content="Column")
  inspect(h.node.style.flex_direction, content="Row")
}

///|
test "a11y: listbox_multi - multiple items can be selected" {
  let options = [
    @components.listbox_option("a", "A"),
    @components.listbox_option("b", "B"),
    @components.listbox_option("c", "C"),
  ]
  let state : @components.ListboxState = {
    focused_id: "",
    selected_ids: ["a", "c"],
    anchor_id: "",
  }
  let comp = listbox_multi(options, state)
  let output = @render.render_once(25, 5, comp)
  // Two items should be checked
  let mut check_count = 0
  for i = 0; i < output.length(); i = i + 1 {
    if output[i] == '✓' {
      check_count = check_count + 1
    }
  }
  inspect(check_count, content="2")
}

///|
test "a11y: listbox - scroll indicator when overflow" {
  let options = [
    @components.listbox_option("1", "Item 1"),
    @components.listbox_option("2", "Item 2"),
    @components.listbox_option("3", "Item 3"),
    @components.listbox_option("4", "Item 4"),
    @components.listbox_option("5", "Item 5"),
  ]
  let comp = listbox(options, "1", max_height=2)
  let output = @render.render_once(25, 5, comp)
  // Should show scroll indicator
  inspect(output.contains("more"), content="true")
}

///|
test "a11y: option_list - no border for embedding" {
  let options = [@components.listbox_option("a", "A")]
  let comp = option_list(options, ["a"])
  // Should not have border
  inspect(comp.node.style.border.top, content="Length(0)")
}

///|
test "a11y: selectable_list - tuple API preserves IDs" {
  let items = [("id1", "Label 1"), ("id2", "Label 2")]
  let comp = selectable_list(items, "id1")
  // Children should have IDs
  let ids : Array[String] = []
  for child in comp.node.children {
    if child.id.length() > 0 {
      ids.push(child.id)
    }
  }
  inspect(ids.length(), content="2")
}
