# mizchi/tui

Terminal UI library for MoonBit with virtual DOM-based rendering.

## Features

- Virtual DOM with diff-based ANSI rendering
- Flexbox and CSS Grid layout (powered by mizchi/crater)
- Reactive signals integration (mizchi/signals)
- Styled UI components (@components)
- Keyboard and mouse input handling

![alt text](screenshot.png)

## Installation

```json
{
  "import": {
    "mizchi/tui": "0.3.0"
  }
}
```

## Package Structure

```
mizchi/tui/
├── vnode/      # Virtual DOM primitives (row, column, view, grid, text)
├── components/ # Styled UI components (button, modal, table, etc.)
├── headless/   # State types (ButtonState, InputState, etc.)
├── events/     # Input parsing (KeyEvent, MouseEvent)
├── render/     # ANSI rendering engine
├── io/         # Platform I/O (terminal size, keypress)
└── core/       # Low-level types (Component, Color)
```

## Quick Start

```moonbit
fn main {
  let node = @vnode.column(gap=1.0, padding=1.0, border="rounded", [
    @vnode.text("Hello, TUI!", fg="cyan", bold=true),
    @components.button("Click me"),
    @components.progress_bar(0.7),
  ])

  // Render to string
  let output = @vnode.render_vnode_once(80, 24, node)
  println(output)
}
```

## Layout Primitives (@vnode)

```moonbit
// Flex containers
@vnode.view([...])                    // column by default
@vnode.view(direction="row", [...])   // horizontal
@vnode.row([...])                     // shorthand for direction="row"
@vnode.column([...])                  // shorthand for direction="column"

// Grid layout
@vnode.grid(columns=[1.0, 2.0, 1.0], [...])  // 1fr 2fr 1fr
@vnode.grid_item(column_span=2, child=...)   // span multiple cells

// Named grid areas
@vnode.grid(
  areas=["header header", "sidebar main", "footer footer"],
  [
    @vnode.grid_area("header", header_content),
    @vnode.grid_area("sidebar", sidebar_content),
    @vnode.grid_area("main", main_content),
    @vnode.grid_area("footer", footer_content),
  ]
)

// Text
@vnode.text("Hello", fg="cyan", bold=true)

// Spacing
@vnode.spacer()      // flexible space
@vnode.hspace(2.0)   // horizontal space
@vnode.vspace(1.0)   // vertical space
```

## Styled Components (@components)

```moonbit
// Buttons
@components.button("Submit", state=@headless.ButtonState::Focused)
@components.icon_button("✕")
@components.text_button("Learn more")

// Form
@components.checkbox("Remember me", true)
@components.radio("Option A", true)
@components.switch(true, "Dark mode")
@vnode.input("value", placeholder="Enter text...")

// Selection
@components.listbox(items, selected_id)
@components.tab_bar(tabs, selected_id)
@components.combobox_trigger("Select...", open=false)

// Feedback
@components.progress_bar(0.5)
@components.spinner(tick)
@components.gauge("CPU", 0.75)
@components.sparkline(data)

// Modal
@components.modal("Title", [...])
@components.alert_dialog("Error occurred")
@components.confirm_dialog("Delete?")

// Dashboard
@components.table(columns, rows)
@components.stat("Users", "1,234")
@components.meter("Memory", 0.8)
```

## Examples

```bash
moon run examples/counter      # Simple counter
moon run examples/chat         # Chat interface
moon run examples/form         # Form with inputs
moon run examples/grid-layout  # Grid layout demo
moon run examples/components   # Component showcase
```

## Documentation

See [docs/tutorial.mbt.md](docs/tutorial.mbt.md) for detailed API documentation.

## License

MIT
