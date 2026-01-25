///|
/// Grid Layout Demo - Demonstrates CSS Grid-like layouts
/// Shows column_span, row_span, and complex dashboard layouts

///|
using @vnode {
  type TuiNode,
  type VNodeApp,
  view,
  grid,
  grid_item,
  row,
  text,
  vspace,
}

// =============================================================================
// Demo Views
// =============================================================================

///|
/// Dashboard layout with header, sidebar, main content, and footer
fn render_dashboard(width : Int, height : Int) -> TuiNode {
  let content_height = height - 4 // Header(1) + Footer(1) + borders(2)
  grid(
    [
      // Header - spans all 3 columns
      grid_item(
        row([text(" Dashboard", fg="yellow", bold=true)], bg="rgb(40,40,60)"),
        column_span=3,
      ),
      // Sidebar - spans 2 rows
      grid_item(
        view(
          [
            text(" Menu", fg="cyan", bold=true),
            text(" > Home", fg="white"),
            text("   Users", fg="rgb(128,128,128)"),
            text("   Settings", fg="rgb(128,128,128)"),
            text("   Reports", fg="rgb(128,128,128)"),
            vspace(1.0), // Push remaining space to bottom
          ],
          border="single",
          border_color="rgb(60,60,80)",
          height=(content_height - 2).to_double(),
        ),
        row_span=2,
      ),
      // Main content area
      view(
        [
          text(" Main Content", fg="green", bold=true),
          text(" Welcome to the Grid Layout demo!"),
          text(" This panel demonstrates column_span"),
          text(" and row_span capabilities."),
          vspace(1.0),
        ],
        border="single",
        border_color="rgb(60,60,80)",
        flex_grow=1.0,
      ),
      // Stats panel
      view(
        [
          text(" Stats", fg="magenta", bold=true),
          text(" Users: 1,234"),
          text(" Active: 567"),
          vspace(1.0),
        ],
        border="single",
        border_color="rgb(60,60,80)",
        flex_grow=1.0,
      ),
      // Activity panel (below main content)
      view(
        [
          text(" Recent Activity", fg="cyan", bold=true),
          text(" - User logged in"),
          text(" - Report generated"),
          vspace(1.0),
        ],
        border="single",
        border_color="rgb(60,60,80)",
        flex_grow=1.0,
      ),
      // Quick actions panel
      view(
        [
          text(" Quick Actions", fg="yellow", bold=true),
          text(" [N] New"),
          text(" [E] Export"),
          vspace(1.0),
        ],
        border="single",
        border_color="rgb(60,60,80)",
        flex_grow=1.0,
      ),
      // Footer - spans all 3 columns
      grid_item(
        row(
          [text("Press 1-3 to switch views | q to quit", fg="rgb(100,100,100)")],
          bg="rgb(30,30,40)",
          justify="center",
        ),
        column_span=3,
      ),
    ],
    columns=[1.0, 3.0, 1.0], // sidebar: 1fr, main: 3fr, right: 1fr
    rows=[1.0, 1.0, 1.0, 1.0], // header, content row 1, content row 2, footer
    gap=0.0,
    width=width.to_double(),
    height=height.to_double(),
  )
}

///|
/// Calendar-like grid layout
fn render_calendar(width : Int, height : Int) -> TuiNode {
  let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
  let header_items : Array[TuiNode] = days.map(fn(d) {
    row([text(d, fg="cyan", bold=true)], justify="center")
  })

  // Generate calendar days (simplified)
  let day_items : Array[TuiNode] = []
  for i = 1; i <= 28; i = i + 1 {
    let fg = if i == 15 { "black" } else { "white" }
    let bg = if i == 15 { "cyan" } else { "" }
    day_items.push(
      row([text(i.to_string(), fg~, bold=i == 15)], justify="center", bg~),
    )
  }
  view(
    [
      row([text(" Calendar View", fg="yellow", bold=true)], padding_y=0.5),
      // Day headers
      grid(header_items, columns=[1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]),
      // Calendar days
      grid(day_items, columns=[1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0], gap=0.0),
      vspace(1.0),
      row(
        [text("Press 1-3 to switch views | q to quit", fg="rgb(100,100,100)")],
        justify="center",
      ),
    ],
    border="rounded",
    border_color="rgb(80,80,100)",
    padding=1.0,
    width=width.to_double(),
    height=height.to_double(),
  )
}

///|
/// Positioned grid items demo
fn render_positioned(width : Int, height : Int) -> TuiNode {
  view(
    [
      row(
        [text(" Positioned Items Demo", fg="yellow", bold=true)],
        padding_y=0.5,
      ),
      grid(
        [
          // Explicitly positioned items (can overlap or leave gaps)
          grid_item(
            view(
              [text("A", fg="cyan", bold=true)],
              border="single",
              border_color="cyan",
              padding=1.0,
            ),
            column=1,
            row=1,
          ),
          grid_item(
            view(
              [text("B (2,1)", fg="green", bold=true)],
              border="single",
              border_color="green",
              padding=1.0,
            ),
            column=2,
            row=1,
          ),
          grid_item(
            view(
              [text("C (3,1)", fg="magenta", bold=true)],
              border="single",
              border_color="magenta",
              padding=1.0,
            ),
            column=3,
            row=1,
          ),
          grid_item(
            view(
              [text("D (1,2) span 2 cols", fg="yellow", bold=true)],
              border="single",
              border_color="yellow",
              padding=1.0,
            ),
            column=1,
            row=2,
            column_span=2,
          ),
          grid_item(
            view(
              [text("E (3,2)", fg="red", bold=true)],
              border="single",
              border_color="red",
              padding=1.0,
            ),
            column=3,
            row=2,
          ),
          grid_item(
            view(
              [text("F (1,3) span 3 cols", fg="white", bold=true)],
              border="double",
              border_color="white",
              padding=1.0,
            ),
            column=1,
            row=3,
            column_span=3,
          ),
        ],
        columns=[1.0, 1.0, 1.0],
        rows=[1.0, 1.0, 1.0],
        gap=1.0,
        height=(height - 8).to_double(),
      ),
      vspace(1.0),
      row(
        [text("Press 1-3 to switch views | q to quit", fg="rgb(100,100,100)")],
        justify="center",
      ),
    ],
    border="rounded",
    border_color="rgb(80,80,100)",
    padding=1.0,
    width=width.to_double(),
    height=height.to_double(),
  )
}

// =============================================================================
// Main
// =============================================================================

///|
async fn main {
  let (width, height) = @tui.get_terminal_size()

  // State
  let current_view = @signals.signal(0)
  let view_names = ["Dashboard", "Calendar", "Positioned"]

  // Create the vnode app
  let app = VNodeApp::new(width, height)

  // Render function
  fn render_ui() -> TuiNode {
    match current_view.get() {
      0 => render_dashboard(width, height)
      1 => render_calendar(width, height)
      2 => render_positioned(width, height)
      _ => render_dashboard(width, height)
    }
  }

  // Initialize terminal
  @tui.print_raw(VNodeApp::init_terminal())
  @tui.enable_raw_mode()

  // Initial render
  @tui.print_raw(app.render_frame(render_ui()))

  // Event loop
  let mut running = true
  while running {
    let key = @tui.read_key()
    if key.length() == 0 {
      continue
    }
    let event = @tui.parse_input(key)
    let mut need_render = true
    match event {
      @tui.InputEvent::Key(key_event) =>
        match key_event {
          // Quit
          @tui.KeyEvent::Char('q', @tui.KeyModifier::None) => running = false
          @tui.KeyEvent::Char('c', @tui.KeyModifier::Ctrl) => running = false
          @tui.KeyEvent::Special(@tui.SpecialKey::Escape, _) => running = false
          // Switch views
          @tui.KeyEvent::Char('1', _) => current_view.set(0)
          @tui.KeyEvent::Char('2', _) => current_view.set(1)
          @tui.KeyEvent::Char('3', _) => current_view.set(2)
          // Arrow keys to cycle views
          @tui.KeyEvent::Special(@tui.SpecialKey::Left, _) => {
            let v = current_view.get()
            current_view.set(if v > 0 { v - 1 } else { 2 })
          }
          @tui.KeyEvent::Special(@tui.SpecialKey::Right, _) => {
            let v = current_view.get()
            current_view.set(if v < 2 { v + 1 } else { 0 })
          }
          _ => need_render = false
        }
      _ => need_render = false
    }

    // Re-render
    if need_render && running {
      @tui.print_raw(app.render_frame(render_ui()))
    }
  }

  // Restore terminal
  @tui.cleanup_stdin()
  @tui.print_raw(VNodeApp::restore_terminal())
  println("View: " + view_names[current_view.get()])
}
