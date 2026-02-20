# tui.mbt Tutorial

Terminal UI library for MoonBit with virtual DOM-based rendering.

## Basic Concepts

### TuiNode

`TuiNode` is the basic building block for UI. All layout functions return `TuiNode`.

```moonbit nocheck
///|
let node : @vnode.TuiNode = @vnode.text("Hello")
```

### text()

Display text content with optional styling.

```moonbit nocheck
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

```moonbit nocheck
// Vertical stack (default)

///|
let vertical = @vnode.view([@vnode.text("Line 1"), @vnode.text("Line 2")])

// Horizontal with direction parameter

///|
let horizontal = @vnode.view(direction="row", gap=1.0, [
  @vnode.text("A"),
  @vnode.text("B"),
])
```

### row() / column()

Shorthand for `view()` with fixed direction.

```moonbit nocheck
// row() = view(..., direction="row")

///|
let r = @vnode.row(gap=2.0, justify="space-between", [
  @vnode.text("Left"),
  @vnode.text("Right"),
])

// column() = view(..., direction="column")

///|
let c = @vnode.column(gap=1.0, [@vnode.text("Top"), @vnode.text("Bottom")])
```

### grid()

CSS Grid-like layout with `columns` and `rows` as fr values.

```moonbit nocheck
// 3-column grid

///|
let g = @vnode.grid(
  columns=[1.0, 2.0, 1.0], // 1fr 2fr 1fr
  gap=1.0,
  [
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

```moonbit nocheck
///|
let dashboard = @vnode.grid(columns=[1.0, 2.0, 1.0], [
  // Header spans all 3 columns
  @vnode.grid_item(column_span=3, child=@vnode.text("Header")),
  // Sidebar spans 2 rows
  @vnode.grid_item(row_span=2, child=@vnode.text("Sidebar")),
  @vnode.text("Main"),
  @vnode.text("Right"),
  @vnode.text("Footer"),
])
```

### grid_area()

Use named areas for semantic grid layouts (like CSS grid-template-areas).

```moonbit nocheck
///|
let semantic_layout = @vnode.grid(
  areas=["header header", "sidebar main", "footer footer"],
  gap=1.0,
  [
    @vnode.grid_area("header", @vnode.text("Header")),
    @vnode.grid_area("sidebar", @vnode.text("Sidebar")),
    @vnode.grid_area("main", @vnode.text("Main Content")),
    @vnode.grid_area("footer", @vnode.text("Footer")),
  ],
)
```

## Styling

### Borders

Available border styles: `single`, `double`, `rounded`, `ascii`.

```moonbit nocheck
///|
let bordered = @vnode.view(border="rounded", border_color="cyan", padding=1.0, [
  @vnode.text("Content"),
])
```

### Colors

Colors can be specified as named colors or RGB values.

```moonbit nocheck
// Named colors: red, green, blue, yellow, cyan, magenta, white, black

///|
let named = @vnode.text("Warning", fg="yellow")

// RGB format

///|
let custom = @vnode.row(bg="rgb(255,200,100)", [
  @vnode.text("Highlight", fg="black"),
])
```

### Alignment

Use `justify` (main axis) and `align` (cross axis).

```moonbit nocheck
///|
let centered = @vnode.view(
  justify="center", // start, center, end, space-between, space-around
  align="center", // start, center, end, stretch
  width=40.0,
  height=10.0,
  [@vnode.text("Centered")],
)
```

## Spacing

### vspace() / hspace()

Flexible spacers that grow to fill available space.

```moonbit nocheck
///|
let layout = @vnode.view([
  @vnode.text("Top"),
  @vnode.vspace(1.0), // Pushes footer to bottom
  @vnode.text("Footer"),
])
```

### spacer()

Convenience for `vspace(1.0)`.

```moonbit nocheck
///|
let with_spacer = @vnode.column([
  @vnode.text("Header"),
  @vnode.spacer(),
  @vnode.text("Footer"),
])
```

## Sizing

### Fixed dimensions

```moonbit nocheck
///|
let fixed = @vnode.view(width=30.0, height=5.0, [@vnode.text("Fixed size")])
```

### Flexible sizing with flex_grow

```moonbit nocheck
///|
let flexible = @vnode.row([
  @vnode.view(width=20.0, [@vnode.text("Sidebar")]),
  @vnode.view(flex_grow=1.0, [@vnode.text("Main")]), // Takes remaining space
])
```

## Example: Card Component

Combining primitives to build reusable patterns.

```moonbit nocheck
///|
fn card(title : String, content : String) -> @vnode.TuiNode {
  @vnode.view(
    border="rounded",
    border_color="rgb(60,60,80)",
    padding=1.0,
    gap=1.0,
    [@vnode.text(title, fg="cyan", bold=true), @vnode.text(content)],
  )
}

///|
let my_card = card("Title", "Card content here")
```

## Example: Dashboard Layout

```moonbit nocheck
///|
fn dashboard_layout(width : Int, height : Int) -> @vnode.TuiNode {
  @vnode.grid(
    columns=[1.0, 3.0, 1.0],
    rows=[1.0, 1.0, 1.0, 1.0],
    width=width.to_double(),
    height=height.to_double(),
    [
      // Header - spans all columns
      @vnode.grid_item(
        column_span=3,
        child=@vnode.row(bg="rgb(40,40,60)", [
          @vnode.text("Dashboard", fg="yellow", bold=true),
        ]),
      ),
      // Sidebar
      @vnode.grid_item(
        row_span=2,
        child=@vnode.view(border="single", [
          @vnode.text("Menu", fg="cyan"),
          @vnode.text("> Home"),
          @vnode.text("  Settings"),
        ]),
      ),
      // Main content
      @vnode.view(border="single", flex_grow=1.0, [@vnode.text("Main Content")]),
      // Right panel
      @vnode.view(border="single", [@vnode.text("Stats")]),
      // Bottom panels
      @vnode.text("Activity"),
      @vnode.text("Actions"),
      // Footer
      @vnode.grid_item(
        column_span=3,
        child=@vnode.row(justify="center", [@vnode.text("Status")]),
      ),
    ],
  )
}

///|
let layout_ = dashboard_layout(80, 24)
```
