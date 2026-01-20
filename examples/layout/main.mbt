///|
/// Layout example - demonstrates complex TUI layouts

///|
fn main {
  let (cols, rows) = @io.get_terminal_size()
  let width = cols
  let height = rows

  // Build the complex layout
  let ui = build_dashboard(width, height)

  // Render once
  let output = @render.render_once(width, height, ui)
  println(output)
}

///|
/// Build a dashboard-style layout
fn build_dashboard(width : Int, height : Int) -> @core.Component {
  @c.column(
    [
      // Header
      header(),
      // Main content area
      @c.row([sidebar(), main_content()], flex_grow=1.0),
      // Footer
      footer(),
    ],
    width=@types.Dimension::Length(width.to_double()),
    height=@types.Dimension::Length(height.to_double()),
  )
}

///|
/// Header component
fn header() -> @core.Component {
  @c.row(
    [
      @c.bold("TUI Dashboard"),
      @c.row(
        [
          @c.colored("Home", @core.Color::green()),
          @c.text("Settings"),
          @c.text("Help"),
        ],
        gap=2.0,
      ),
    ],
    height=@types.Dimension::Length(3.0),
    padding_x=1.0,
    justify=@types.Alignment::SpaceBetween,
    align=@types.Alignment::Center,
    border=Some(@core.BorderChars::single()),
    border_color=@core.Color::cyan(),
    bg=@core.Color::rgb(20, 20, 40),
  )
}

///|
/// Sidebar component
fn sidebar() -> @core.Component {
  @c.column(
    [
      @c.bold("Navigation"),
      @c.hdivider(char='─', fg=@core.Color::rgb(60, 60, 60)),
      menu_item("Dashboard", true),
      menu_item("Analytics", false),
      menu_item("Reports", false),
      menu_item("Users", false),
      menu_item("Settings", false),
      @c.spacer(),
      @c.colored("v1.0.0", @core.Color::rgb(100, 100, 100)),
    ],
    width=@types.Dimension::Length(20.0),
    padding=1.0,
    gap=1.0,
    border=Some(@core.BorderChars::single()),
    border_color=@core.Color::rgb(80, 80, 80),
  )
}

///|
/// Menu item component
fn menu_item(label : String, active : Bool) -> @core.Component {
  if active {
    @c.row(
      [@c.colored("▸ " + label, @core.Color::cyan())],
      padding_x=1.0,
      bg=@core.Color::rgb(40, 80, 120),
    )
  } else {
    @c.row([@c.text("  " + label)], padding_x=1.0)
  }
}

///|
/// Main content area
fn main_content() -> @core.Component {
  @c.column(
    [
      // Stats cards
      @c.row(
        [
          stat_card("Users", "1,234", @core.Color::green()),
          stat_card("Revenue", "$5.6K", @core.Color::yellow()),
          stat_card("Orders", "89", @core.Color::cyan()),
          stat_card("Growth", "+12%", @core.Color::magenta()),
        ],
        gap=1.0,
      ),
      // Two-column layout
      @c.row([activity_panel(), grid_panel()], flex_grow=1.0, gap=1.0),
    ],
    flex_grow=1.0,
    padding=1.0,
    gap=1.0,
  )
}

///|
/// Stat card component
fn stat_card(
  title : String,
  value : String,
  color : @core.Color,
) -> @core.Component {
  @c.column(
    [
      @c.colored(value, color),
      @c.colored(title, @core.Color::rgb(128, 128, 128)),
    ],
    flex_grow=1.0,
    padding=1.0,
    align=@types.Alignment::Center,
    border=Some(@core.BorderChars::rounded()),
    border_color=color,
  )
}

///|
/// Activity panel
fn activity_panel() -> @core.Component {
  @c.column(
    [
      @c.bold("Recent Activity"),
      @c.hdivider(char='─', fg=@core.Color::rgb(60, 60, 60)),
      activity_item("User signed up", "2m ago", @core.Color::green()),
      activity_item("Order completed", "5m ago", @core.Color::cyan()),
      activity_item("Payment received", "12m ago", @core.Color::yellow()),
      activity_item("Report generated", "1h ago", @core.Color::magenta()),
      activity_item(
        "Settings updated",
        "2h ago",
        @core.Color::rgb(150, 150, 150),
      ),
      @c.spacer(),
    ],
    flex_grow=1.0,
    padding=1.0,
    gap=0.5,
    border=Some(@core.BorderChars::single()),
    border_color=@core.Color::rgb(60, 60, 60),
  )
}

///|
/// Activity item
fn activity_item(
  text : String,
  time : String,
  color : @core.Color,
) -> @core.Component {
  @c.row(
    [
      @c.row([@c.colored("●", color), @c.text(text)], gap=1.0),
      @c.colored(time, @core.Color::rgb(100, 100, 100)),
    ],
    justify=@types.Alignment::SpaceBetween,
  )
}

///|
/// Grid panel demonstrating grid layout
fn grid_panel() -> @core.Component {
  @c.column(
    [
      @c.bold("Grid Layout"),
      @c.hdivider(char='─', fg=@core.Color::rgb(60, 60, 60)),
      @c.grid(
        [
          grid_cell("A1", @core.Color::red()),
          grid_cell("B1", @core.Color::green()),
          grid_cell("C1", @core.Color::blue()),
          grid_cell("A2", @core.Color::yellow()),
          grid_cell("B2", @core.Color::cyan()),
          grid_cell("C2", @core.Color::magenta()),
          grid_cell("A3", @core.Color::rgb(255, 128, 0)),
          grid_cell("B3", @core.Color::rgb(128, 255, 0)),
          grid_cell("C3", @core.Color::rgb(0, 128, 255)),
        ],
        columns=3,
        column_gap=1.0,
        row_gap=1.0,
      ),
      @c.spacer(),
    ],
    flex_grow=1.0,
    padding=1.0,
    border=Some(@core.BorderChars::single()),
    border_color=@core.Color::rgb(60, 60, 60),
  )
}

///|
/// Grid cell
fn grid_cell(label : String, color : @core.Color) -> @core.Component {
  @c.center([@c.bordered([@c.colored(label, color)], color~)])
}

///|
/// Footer component
fn footer() -> @core.Component {
  @c.row(
    [
      @c.colored("Press 'q' to quit", @core.Color::rgb(100, 100, 100)),
      @c.colored("crater-tui v0.0.1", @core.Color::rgb(100, 100, 100)),
    ],
    height=@types.Dimension::Length(1.0),
    padding_x=1.0,
    justify=@types.Alignment::SpaceBetween,
    bg=@core.Color::rgb(30, 30, 30),
  )
}
