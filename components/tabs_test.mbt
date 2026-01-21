///|
/// Tests for Tabs component

// ============================================
// Snapshot Tests
// ============================================

///|
test "tabs: horizontal layout" {
  let items = [
    @components.TabItem::{ id: "tab1", label: "Home" },
    @components.TabItem::{ id: "tab2", label: "Settings" },
    @components.TabItem::{ id: "tab3", label: "About" },
  ]
  let comp = tabs(items, "tab1")
  let output = @render.render_once(60, 10, comp)
  inspect(
    output,
    content="\u{1b}[2J\u{1b}[1;1H\u{1b}[38;5;16m\u{1b}[48;5;51mHome\u{1b}[38;5;231m  \u{1b}[48;5;17mSettings  About  \u{1b}[49m                                     \u{1b}[2;1H\u{1b}[48;5;51m      \u{1b}[48;5;17m                 \u{1b}[49m                                     \u{1b}[3;1H\u{1b}[48;5;51m      \u{1b}[48;5;17m                 \u{1b}[49m                                     \u{1b}[4;1H                                                            \u{1b}[5;1H                                                            \u{1b}[6;1H                                                            \u{1b}[7;1H                                                            \u{1b}[8;1H                                                            \u{1b}[9;1H                                                            \u{1b}[10;1H                                                            \u{1b}[0m",
  )
}

///|
test "tabs: vertical layout" {
  let items = [
    @components.TabItem::{ id: "t1", label: "Tab A" },
    @components.TabItem::{ id: "t2", label: "Tab B" },
  ]
  let comp = tabs(items, "t2", orientation=TabOrientation::Vertical)
  let output = @render.render_once(30, 6, comp)
  inspect(
    output,
    content="\u{1b}[2J\u{1b}[1;1H\u{1b}[38;5;231m\u{1b}[48;5;17mTab A  \u{1b}[49m                       \u{1b}[2;1H\u{1b}[48;5;17m       \u{1b}[49m                       \u{1b}[3;1H\u{1b}[48;5;17m       \u{1b}[49m                       \u{1b}[4;1H\u{1b}[48;5;17m       \u{1b}[49m                       \u{1b}[5;1H\u{1b}[38;5;16m\u{1b}[48;5;51mTab B\u{1b}[38;5;231m  \u{1b}[49m                       \u{1b}[6;1H\u{1b}[48;5;51m       \u{1b}[49m                       \u{1b}[0m",
  )
}

///|
test "tabs: tab container with panel" {
  let items = [
    @components.TabItem::{ id: "main", label: "Main" },
    @components.TabItem::{ id: "aux", label: "Aux" },
  ]
  let content = @core.text("Panel content")
  let comp = tab_container(items, "main", content)
  let output = @render.render_once(40, 8, comp)
  inspect(
    output,
    content="\u{1b}[2J\u{1b}[1;1H\u{1b}[38;5;16m\u{1b}[48;5;51mMain\u{1b}[38;5;231m  \u{1b}[48;5;17mAux  \u{1b}[49m                             \u{1b}[2;1H\u{1b}[48;5;51m      \u{1b}[48;5;17m     \u{1b}[49m                             \u{1b}[3;1H\u{1b}[48;5;51m      \u{1b}[48;5;17m     \u{1b}[49m                             \u{1b}[4;1H\u{1b}[38;5;60m┌───────────────┐\u{1b}[38;5;231m                       \u{1b}[5;1H\u{1b}[38;5;60m│\u{1b}[38;5;231m               \u{1b}[38;5;60m│\u{1b}[38;5;231m                       \u{1b}[6;1H\u{1b}[38;5;60m│\u{1b}[38;5;231m Panel content \u{1b}[38;5;60m│\u{1b}[38;5;231m                       \u{1b}[7;1H\u{1b}[38;5;60m│\u{1b}[38;5;231m               \u{1b}[38;5;60m│\u{1b}[38;5;231m                       \u{1b}[8;1H\u{1b}[38;5;60m│\u{1b}[38;5;231m               \u{1b}[38;5;60m│\u{1b}[38;5;231m                       \u{1b}[0m",
  )
}

// ============================================
// Accessibility Tests
// ============================================

///|
test "a11y: tabs - each tab has unique ID for focus" {
  let items = [
    @components.TabItem::{ id: "home", label: "Home" },
    @components.TabItem::{ id: "settings", label: "Settings" },
  ]
  let comp = tabs(items, "home")
  let ids : Array[String] = []
  for child in comp.node.children {
    ids.push(child.id)
  }
  inspect(
    ids,
    content=(
      #|["home", "settings"]
    ),
  )
}

///|
test "a11y: tabs - selected tab is visually distinct" {
  let items = [
    @components.TabItem::{ id: "a", label: "A" },
    @components.TabItem::{ id: "b", label: "B" },
  ]
  let comp_a = tabs(items, "a")
  let comp_b = tabs(items, "b")
  let output_a = @render.render_once(20, 3, comp_a)
  let output_b = @render.render_once(20, 3, comp_b)
  inspect(output_a != output_b, content="true")
}

///|
test "a11y: tab_panel - has border for visual boundary" {
  let content = @core.text("Content")
  let panel = tab_panel(content)
  // Panel should have border defined
  inspect(panel.node.style.border.top != @types.Dimension::Auto, content="true")
}

///|
test "a11y: tabs - keyboard navigable (all tabs focusable)" {
  let items = [
    @components.TabItem::{ id: "t1", label: "Tab 1" },
    @components.TabItem::{ id: "t2", label: "Tab 2" },
    @components.TabItem::{ id: "t3", label: "Tab 3" },
  ]
  let comp = tabs(items, "t1")
  // All tabs should have IDs for keyboard navigation
  inspect(comp.node.children.length(), content="3")
  for child in comp.node.children {
    assert_true(child.id.length() > 0)
  }
}

///|
test "a11y: tabs - orientation affects layout direction" {
  let items = [
    @components.TabItem::{ id: "a", label: "A" },
    @components.TabItem::{ id: "b", label: "B" },
  ]
  let h = tabs(items, "a", orientation=TabOrientation::Horizontal)
  let v = tabs(items, "a", orientation=TabOrientation::Vertical)
  // Horizontal uses Row (flex-direction row)
  // Vertical uses Column (flex-direction column)
  inspect(h.node.style.flex_direction, content="Row")
  inspect(v.node.style.flex_direction, content="Column")
}

///|
test "a11y: tab_container - panel associated with tabs" {
  let items = [@components.TabItem::{ id: "main", label: "Main" }]
  let content = @core.text("Content")
  let comp = tab_container(items, "main", content, id="tab-nav")
  // Container should have ID for aria-controls relationship
  inspect(comp.node.id, content="tab-nav")
}
