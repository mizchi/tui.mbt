# tui.mbt Tutorial

Terminal UI library for MoonBit with virtual DOM-based rendering.

## Basic Concepts

### TuiNode

`TuiNode` is the basic building block for UI. All layout functions return `TuiNode`.

```moonbit
///|
let node : @vnode.TuiNode = @vnode.text("Hello")
```

### text()

Display text content with optional styling.

```moonbit
// Plain text
///|
let plain = @vnode.text("Hello World")

// Styled text

///|
let styled = @vnode.text("Error", fg="red", bold=true)

// RGB color

///|
let rgb = @vnode.text("Custom", fg="rgb(100,150,200)")
```

## Layout Primitives

### view()

Generic flex container. Default direction is `column`.

```moonbit
// Vertical stack (default)
///|
let vertical = @vnode.view(children=[
  @vnode.text("Line 1"),
  @vnode.text("Line 2"),
])

// Horizontal with direction parameter

///|
let horizontal = @vnode.view(direction="row", gap=1.0, children=[
  @vnode.text("A"),
  @vnode.text("B"),
])
```

### row() / column()

Shorthand for `view()` with fixed direction.

```moonbit
// row() = view(..., direction="row")
///|
let r = @vnode.row(gap=2.0, justify="space-between", children=[
  @vnode.text("Left"),
  @vnode.text("Right"),
])

// column() = view(..., direction="column")

///|
let c = @vnode.column(gap=1.0, children=[
  @vnode.text("Top"),
  @vnode.text("Bottom"),
])
```

### grid()

CSS Grid-like layout with `columns` and `rows` as fr values.

```moonbit
// 3-column grid
///|
let g = @vnode.grid(
  columns=[1.0, 2.0, 1.0], // 1fr 2fr 1fr
  gap=1.0,
  children=[
    @vnode.text("A"),
    @vnode.text("B"),
    @vnode.text("C"),
    @vnode.text("D"),
    @vnode.text("E"),
    @vnode.text("F"),
  ],
)
```

### grid_item()

Position or span grid items explicitly.

```moonbit
///|
let dashboard = @vnode.grid(columns=[1.0, 2.0, 1.0], children=[
  // Header spans all 3 columns
  @vnode.grid_item(column_span=3, child=@vnode.text("Header")),
  // Sidebar spans 2 rows
  @vnode.grid_item(row_span=2, child=@vnode.text("Sidebar")),
  @vnode.text("Main"),
  @vnode.text("Right"),
  @vnode.text("Footer"),
])
```

## Styling

### Borders

Available border styles: `single`, `double`, `rounded`, `ascii`.

```moonbit
///|
let bordered = @vnode.view(border="rounded", border_color="cyan", padding=1.0, children=[
  @vnode.text("Content"),
])
```

### Colors

Colors can be specified as named colors or RGB values.

```moonbit
// Named colors: red, green, blue, yellow, cyan, magenta, white, black
///|
let named = @vnode.text("Warning", fg="yellow")

// RGB format

///|
let custom = @vnode.row(bg="rgb(255,200,100)", children=[
  @vnode.text("Highlight", fg="black"),
])
```

### Alignment

Use `justify` (main axis) and `align` (cross axis).

```moonbit
///|
let centered = @vnode.view(
  justify="center", // start, center, end, space-between, space-around
  align="center", // start, center, end, stretch
  width=40.0,
  height=10.0,
  children=[@vnode.text("Centered")],
)
```

## Spacing

### vspace() / hspace()

Flexible spacers that grow to fill available space.

```moonbit
///|
let layout = @vnode.view(children=[
  @vnode.text("Top"),
  @vnode.vspace(1.0), // Pushes footer to bottom
  @vnode.text("Footer"),
])
```

### spacer()

Convenience for `vspace(1.0)`.

```moonbit
///|
let with_spacer = @vnode.column(children=[
  @vnode.text("Header"),
  @vnode.spacer(),
  @vnode.text("Footer"),
])
```

## Sizing

### Fixed dimensions

```moonbit
///|
let fixed = @vnode.view(width=30.0, height=5.0, children=[
  @vnode.text("Fixed size"),
])
```

### Flexible sizing with flex_grow

```moonbit
///|
let flexible = @vnode.row(children=[
  @vnode.view(width=20.0, children=[@vnode.text("Sidebar")]),
  @vnode.view(flex_grow=1.0, children=[@vnode.text("Main")]), // Takes remaining space
])
```

## Example: Card Component

Combining primitives to build reusable patterns.

```moonbit
///|
fn card(title : String, content : String) -> @vnode.TuiNode {
  @vnode.view(
    border="rounded",
    border_color="rgb(60,60,80)",
    padding=1.0,
    gap=1.0,
    children=[@vnode.text(title, fg="cyan", bold=true), @vnode.text(content)],
  )
}

///|
let my_card = card("Title", "Card content here")
```

## Example: Dashboard Layout

```moonbit
///|
fn dashboard_layout(width : Int, height : Int) -> @vnode.TuiNode {
  @vnode.grid(
    columns=[1.0, 3.0, 1.0],
    rows=[1.0, 1.0, 1.0, 1.0],
    width=width.to_double(),
    height=height.to_double(),
    children=[
      // Header - spans all columns
      @vnode.grid_item(
        column_span=3,
        child=@vnode.row(bg="rgb(40,40,60)", children=[
          @vnode.text("Dashboard", fg="yellow", bold=true),
        ]),
      ),
      // Sidebar
      @vnode.grid_item(
        row_span=2,
        child=@vnode.view(border="single", children=[
          @vnode.text("Menu", fg="cyan"),
          @vnode.text("> Home"),
          @vnode.text("  Settings"),
        ]),
      ),
      // Main content
      @vnode.view(border="single", flex_grow=1.0, children=[
        @vnode.text("Main Content"),
      ]),
      // Right panel
      @vnode.view(border="single", children=[@vnode.text("Stats")]),
      // Bottom panels
      @vnode.text("Activity"),
      @vnode.text("Actions"),
      // Footer
      @vnode.grid_item(
        column_span=3,
        child=@vnode.row(justify="center", children=[@vnode.text("Status")]),
      ),
    ],
  )
}

///|
let layout = dashboard_layout(80, 24)
```
