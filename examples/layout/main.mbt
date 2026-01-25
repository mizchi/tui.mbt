///|
/// VNode Layout example - demonstrates complex TUI layouts

///|
fn main {
  let (width, height) = @tui.get_terminal_size()

  // Build and render the dashboard
  let ui = build_dashboard(width, height)
  let output = @vnode.render_vnode_once(width, height, ui)
  println(output)
}

///|
/// Build a dashboard-style layout
fn build_dashboard(width : Int, height : Int) -> @vnode.TuiNode {
  @vnode.column(
    [
      // Header
      header(),
      // Main content area
      @vnode.row([sidebar(), main_content()], flex_grow=1.0),
      // Footer
      footer(),
    ],
    width=width.to_double(),
    height=height.to_double(),
  )
}

///|
/// Header component
fn header() -> @vnode.TuiNode {
  @vnode.row(
    [
      @vnode.text("TUI Dashboard", bold=true),
      @vnode.row([
        @vnode.text("Home", fg="green"),
        @vnode.hspace(2.0),
        @vnode.text("Settings"),
        @vnode.hspace(2.0),
        @vnode.text("Help"),
      ]),
    ],
    height=3.0,
    padding_x=1.0,
    justify="space-between",
    align="center",
    border="single",
    border_color="cyan",
    bg="rgb(20,20,40)",
  )
}

///|
/// Sidebar component
fn sidebar() -> @vnode.TuiNode {
  @vnode.column(
    [
      @vnode.text("Navigation", bold=true),
      hdivider(),
      menu_item("Dashboard", true),
      menu_item("Analytics", false),
      menu_item("Reports", false),
      menu_item("Users", false),
      menu_item("Settings", false),
      @vnode.spacer(),
      @vnode.text("v1.0.0", fg="rgb(100,100,100)"),
    ],
    width=20.0,
    padding=1.0,
    gap=1.0,
    border="single",
    border_color="rgb(80,80,80)",
  )
}

///|
/// Horizontal divider helper
fn hdivider() -> @vnode.TuiNode {
  @vnode.text(
    "────────────────────",
    fg="rgb(60,60,60)",
  )
}

///|
/// Menu item component
fn menu_item(label : String, active : Bool) -> @vnode.TuiNode {
  if active {
    @vnode.row(
      [@vnode.text("▸ " + label, fg="cyan")],
      padding_x=1.0,
      bg="rgb(40,80,120)",
    )
  } else {
    @vnode.row([@vnode.text("  " + label)], padding_x=1.0)
  }
}

///|
/// Main content area
fn main_content() -> @vnode.TuiNode {
  @vnode.column(
    [
      // Stats cards
      @vnode.row(
        [
          stat_card("Users", "1,234", "green"),
          stat_card("Revenue", "$5.6K", "yellow"),
          stat_card("Orders", "89", "cyan"),
          stat_card("Growth", "+12%", "magenta"),
        ],
        gap=1.0,
      ),
      // Two-column layout
      @vnode.row([activity_panel(), grid_panel()], flex_grow=1.0, gap=1.0),
    ],
    flex_grow=1.0,
    padding=1.0,
    gap=1.0,
  )
}

///|
/// Stat card component
fn stat_card(title : String, value : String, color : String) -> @vnode.TuiNode {
  @vnode.column(
    [@vnode.text(value, fg=color), @vnode.text(title, fg="rgb(128,128,128)")],
    flex_grow=1.0,
    padding=1.0,
    align="center",
    border="rounded",
    border_color=color,
  )
}

///|
/// Activity panel
fn activity_panel() -> @vnode.TuiNode {
  @vnode.column(
    [
      @vnode.text("Recent Activity", bold=true),
      hdivider(),
      activity_item("User signed up", "2m ago", "green"),
      activity_item("Order completed", "5m ago", "cyan"),
      activity_item("Payment received", "12m ago", "yellow"),
      activity_item("Report generated", "1h ago", "magenta"),
      activity_item("Settings updated", "2h ago", "rgb(150,150,150)"),
      @vnode.spacer(),
    ],
    flex_grow=1.0,
    padding=1.0,
    border="single",
    border_color="rgb(60,60,60)",
  )
}

///|
/// Activity item
fn activity_item(
  text : String,
  time : String,
  color : String,
) -> @vnode.TuiNode {
  @vnode.row(
    [
      @vnode.row([
        @vnode.text("●", fg=color),
        @vnode.hspace(1.0),
        @vnode.text(text),
      ]),
      @vnode.spacer(),
      @vnode.text(time, fg="rgb(100,100,100)"),
    ],
    justify="space-between",
  )
}

///|
/// Grid panel - using nested rows to simulate grid
fn grid_panel() -> @vnode.TuiNode {
  @vnode.column(
    [
      @vnode.text("Grid Layout", bold=true),
      hdivider(),
      // Row 1
      @vnode.row(
        [
          grid_cell("A1", "red"),
          @vnode.hspace(1.0),
          grid_cell("B1", "green"),
          @vnode.hspace(1.0),
          grid_cell("C1", "blue"),
        ],
        justify="center",
      ),
      @vnode.vspace(1.0),
      // Row 2
      @vnode.row(
        [
          grid_cell("A2", "yellow"),
          @vnode.hspace(1.0),
          grid_cell("B2", "cyan"),
          @vnode.hspace(1.0),
          grid_cell("C2", "magenta"),
        ],
        justify="center",
      ),
      @vnode.vspace(1.0),
      // Row 3
      @vnode.row(
        [
          grid_cell("A3", "rgb(255,128,0)"),
          @vnode.hspace(1.0),
          grid_cell("B3", "rgb(128,255,0)"),
          @vnode.hspace(1.0),
          grid_cell("C3", "rgb(0,128,255)"),
        ],
        justify="center",
      ),
      @vnode.spacer(),
    ],
    flex_grow=1.0,
    padding=1.0,
    border="single",
    border_color="rgb(60,60,60)",
  )
}

///|
/// Grid cell - bordered box with colored text
fn grid_cell(label : String, color : String) -> @vnode.TuiNode {
  @vnode.row(
    [@vnode.text(label, fg=color)],
    padding=1.0,
    border="single",
    border_color=color,
    justify="center",
  )
}

///|
/// Footer component
fn footer() -> @vnode.TuiNode {
  @vnode.row(
    [
      @vnode.text("Press 'q' to quit", fg="rgb(100,100,100)"),
      @vnode.spacer(),
      @vnode.text("vnode-tui v0.2.0", fg="rgb(100,100,100)"),
    ],
    height=1.0,
    padding_x=1.0,
    justify="space-between",
    bg="rgb(30,30,30)",
  )
}
