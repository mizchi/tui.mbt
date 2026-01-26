///|
/// Grid Area Example - demonstrates named grid areas
fn main {
  // Get terminal size
  let (cols, rows) = @tui.get_terminal_size()

  // Dashboard with named areas
  let layout = @vnode.grid(
    areas=[
      "header header header", "nav content content", "nav content content", "footer footer footer",
    ],
    gap=1.0,
    width=cols.to_double(),
    height=rows.to_double(),
    [
      // Header area
      @vnode.grid_area(
        "header",
        @vnode.row(bg="rgb(40,60,80)", padding=1.0, [
          @vnode.text("Dashboard", fg="yellow", bold=true),
        ]),
      ),
      // Navigation area
      @vnode.grid_area(
        "nav",
        @vnode.column(border="single", padding=1.0, gap=1.0, [
          @vnode.text("Menu", fg="cyan", bold=true),
          @vnode.text("> Home"),
          @vnode.text("  Settings"),
          @vnode.text("  Profile"),
        ]),
      ),
      // Content area
      @vnode.grid_area(
        "content",
        @vnode.column(border="rounded", padding=1.0, [
          @vnode.text("Main Content", fg="green", bold=true),
          @vnode.vspace(1.0),
          @vnode.text("This layout uses grid-template-areas"),
          @vnode.text("for semantic positioning."),
          @vnode.vspace(1.0),
          @vnode.text("Areas: header, nav, content, footer"),
        ]),
      ),
      // Footer area
      @vnode.grid_area(
        "footer",
        @vnode.row(bg="rgb(30,30,30)", padding=1.0, justify="center", [
          @vnode.text("Press 'q' to quit", fg="white"),
        ]),
      ),
    ],
  )

  // Render once (for demo/snapshot)
  let output = @vnode.render_vnode_once(cols, rows, layout)
  @tui.print_raw(output)
}
