///|
/// Benchmark: Current TUI vs Luna-based approach

///|
/// TUI Event type for luna integration
pub(all) enum TuiEvent {
  Click(x~ : Int, y~ : Int)
  Key(key~ : String)
}

// =============================================================================
// Current TUI approach
// =============================================================================

///|
fn build_current_tree(n : Int) -> @tui.Component {
  let children : Array[@tui.Component] = []
  for i = 0; i < n; i = i + 1 {
    children.push(
      @tui.row([@tui.text("Item " + i.to_string())], id="item-" + i.to_string()),
    )
  }
  @tui.column(children, width=80.0, height=24.0)
}

///|
test "current: build 100 items" {
  let tree = build_current_tree(100)
  // Just verify it builds without error
  assert_true(tree.id().length() > 0)
}

///|
test "current: build 1000 items" {
  let tree = build_current_tree(1000)
  assert_true(tree.id().length() > 0)
}

// =============================================================================
// Luna-based approach
// =============================================================================

///|
fn build_luna_tree(n : Int) -> @luna.Node[TuiEvent, String] {
  let children : Array[@luna.Node[TuiEvent, String]] = []
  for i = 0; i < n; i = i + 1 {
    children.push(
      @luna.h("row", [("id", @luna.attr_static("item-" + i.to_string()))], [
        @luna.text("Item " + i.to_string()),
      ]),
    )
  }
  @luna.h(
    "column",
    [("width", @luna.attr_static("80")), ("height", @luna.attr_static("24"))],
    children,
  )
}

///|
test "luna: build 100 items" {
  let tree = build_luna_tree(100)
  guard tree is @luna.Node::Element(el) else { fail("expected Element") }
  assert_eq(el.tag, "column")
}

///|
test "luna: build 1000 items" {
  let tree = build_luna_tree(1000)
  guard tree is @luna.Node::Element(el) else { fail("expected Element") }
  assert_eq(el.tag, "column")
}

// =============================================================================
// Control flow comparison
// =============================================================================

///|
fn build_luna_with_show(visible : Bool) -> @luna.Node[TuiEvent, String] {
  @luna.h("column", [], [
    @luna.text("Header"),
    @luna.show(fn() { visible }, fn() { @luna.text("Visible content") }),
    @luna.text("Footer"),
  ])
}

///|
test "luna: show control flow" {
  let tree_visible = build_luna_with_show(true)
  let _tree_hidden = build_luna_with_show(false)
  guard tree_visible is @luna.Node::Element(el) else {
    fail("expected Element")
  }
  assert_eq(el.children.length(), 3)
}

///|
fn build_luna_with_for(items : Array[String]) -> @luna.Node[TuiEvent, String] {
  @luna.h("column", [], [
    @luna.text("List:"),
    @luna.for_each(fn() { items.map(fn(s) { @luna.text(s) }) }),
  ])
}

///|
test "luna: for_each control flow" {
  let tree = build_luna_with_for(["a", "b", "c"])
  guard tree is @luna.Node::Element(el) else { fail("expected Element") }
  // Children: Text("List:") + For(...)
  assert_eq(el.children.length(), 2)
}
