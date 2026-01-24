///|
/// Performance benchmark: Current TUI vs Luna-based approach
/// Run: moon bench -p mizchi/tui/experiments/luna-bench

///|
/// TUI Event type for luna integration
pub(all) enum TuiEvent2 {
  Click(x~ : Int, y~ : Int)
  Key(key~ : String)
}

// =============================================================================
// Current TUI approach (immediate crater node creation)
// =============================================================================

///|
fn build_current_n(n : Int) -> @tui.Component {
  let children : Array[@tui.Component] = []
  for i = 0; i < n; i = i + 1 {
    children.push(
      @tui.row([@tui.text("Item " + i.to_string())], id="item-" + i.to_string()),
    )
  }
  @tui.column(children, width=80.0, height=24.0)
}

///|
test "build: current 100 items" (b : @bench.T) {
  b.bench(fn() { b.keep(build_current_n(100)) })
}

///|
test "build: current 1000 items" (b : @bench.T) {
  b.bench(fn() { b.keep(build_current_n(1000)) })
}

///|
fn render_current_app_n(app : @tui.App, n : Int) -> String {
  let component = build_current_n(n)
  app.render(component)
}

///|
test "render: current App 100 items" (b : @bench.T) {
  let app = @tui.App::new(80, 24)
  b.bench(fn() { b.keep(render_current_app_n(app, 100)) })
}

///|
test "render: current App 1000 items" (b : @bench.T) {
  let app = @tui.App::new(80, 24)
  b.bench(fn() { b.keep(render_current_app_n(app, 1000)) })
}

// =============================================================================
// Luna raw VNode approach (VNode tree only, no crater conversion)
// =============================================================================

///|
fn build_luna_n(n : Int) -> @luna.Node[TuiEvent2, String] {
  let children : Array[@luna.Node[TuiEvent2, String]] = []
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
test "build: luna raw 100 items" (b : @bench.T) {
  b.bench(fn() { b.keep(build_luna_n(100)) })
}

///|
test "build: luna raw 1000 items" (b : @bench.T) {
  b.bench(fn() { b.keep(build_luna_n(1000)) })
}

// =============================================================================
// vnode DSL approach (VNode tree using DSL helpers)
// =============================================================================

///|
fn build_vnode_dsl_n(n : Int) -> @vnode.TuiNode {
  let children : Array[@vnode.TuiNode] = []
  for i = 0; i < n; i = i + 1 {
    children.push(
      @vnode.row(
        [@vnode.text("Item " + i.to_string())],
        id="item-" + i.to_string(),
      ),
    )
  }
  @vnode.column(children, width=80.0, height=24.0)
}

///|
test "build: vnode dsl 100 items" (b : @bench.T) {
  b.bench(fn() { b.keep(build_vnode_dsl_n(100)) })
}

///|
test "build: vnode dsl 1000 items" (b : @bench.T) {
  b.bench(fn() { b.keep(build_vnode_dsl_n(1000)) })
}

// =============================================================================
// Full render pipeline: vnode DSL -> crater Node
// =============================================================================

///|
fn build_and_render_vnode_n(n : Int) -> Unit {
  let tree = build_vnode_dsl_n(n)
  let ctx = @vnode.RenderContext::new()
  let _crater = @vnode.to_crater_node(ctx, tree)

}

///|
test "render: vnode->crater 100 items" (b : @bench.T) {
  b.bench(fn() { build_and_render_vnode_n(100) })
}

///|
test "render: vnode->crater 1000 items" (b : @bench.T) {
  b.bench(fn() { build_and_render_vnode_n(1000) })
}

// =============================================================================
// Full VNodeApp render pipeline: vnode DSL -> crater -> CharBuffer -> ANSI
// =============================================================================

///|
fn render_vnode_app_n(app : @vnode.VNodeApp, n : Int) -> String {
  let tree = build_vnode_dsl_n(n)
  app.render(tree)
}

///|
test "render: VNodeApp 100 items" (b : @bench.T) {
  let app = @vnode.VNodeApp::new(80, 24)
  b.bench(fn() { b.keep(render_vnode_app_n(app, 100)) })
}

///|
test "render: VNodeApp 1000 items" (b : @bench.T) {
  let app = @vnode.VNodeApp::new(80, 24)
  b.bench(fn() { b.keep(render_vnode_app_n(app, 1000)) })
}
