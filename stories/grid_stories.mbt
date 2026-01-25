///|
/// Grid layout component stories - vnode version

///|
pub fn grid_basic_stories() -> Array[VNodeStory] {
  [
    VNodeStory::new(
      "grid",
      "basic_3col",
      fn() {
        @vnode.grid(columns=[1.0, 1.0, 1.0], gap=1.0, children=[
          @vnode.text("A"),
          @vnode.text("B"),
          @vnode.text("C"),
          @vnode.text("D"),
          @vnode.text("E"),
          @vnode.text("F"),
        ])
      },
      width=20,
      height=5,
    ),
    VNodeStory::new(
      "grid",
      "unequal_columns",
      fn() {
        @vnode.grid(columns=[1.0, 2.0], gap=1.0, children=[
          @vnode.text("Sidebar"),
          @vnode.text("Main Content"),
          @vnode.text("Footer"),
          @vnode.text("Footer"),
        ])
      },
      width=30,
      height=5,
    ),
    VNodeStory::new(
      "grid",
      "with_border",
      fn() {
        @vnode.grid(
          columns=[1.0, 1.0],
          gap=1.0,
          border="rounded",
          padding=1.0,
          children=[
            @vnode.text("1"),
            @vnode.text("2"),
            @vnode.text("3"),
            @vnode.text("4"),
          ],
        )
      },
      width=20,
      height=7,
    ),
  ]
}

///|
pub fn grid_item_stories() -> Array[VNodeStory] {
  [
    VNodeStory::new(
      "grid_item",
      "column_span",
      fn() {
        @vnode.grid(columns=[1.0, 1.0, 1.0], gap=1.0, children=[
          @vnode.grid_item(column_span=3, child=@vnode.text("Header (span 3)")),
          @vnode.text("A"),
          @vnode.text("B"),
          @vnode.text("C"),
        ])
      },
      width=25,
      height=5,
    ),
    VNodeStory::new(
      "grid_item",
      "positioned",
      fn() {
        @vnode.grid(columns=[1.0, 1.0], rows=[1.0, 1.0], children=[
          @vnode.grid_item(column=2, row=1, child=@vnode.text("At (2,1)")),
          @vnode.grid_item(column=1, row=2, child=@vnode.text("At (1,2)")),
        ])
      },
      width=20,
      height=5,
    ),
  ]
}

///|
pub fn view_stories() -> Array[VNodeStory] {
  [
    VNodeStory::new(
      "view",
      "default_column",
      fn() {
        @vnode.view(gap=0.0, children=[
          @vnode.text("Line 1"),
          @vnode.text("Line 2"),
          @vnode.text("Line 3"),
        ])
      },
      width=15,
      height=5,
    ),
    VNodeStory::new(
      "view",
      "row_direction",
      fn() {
        @vnode.view(direction="row", gap=1.0, children=[
          @vnode.text("A"),
          @vnode.text("B"),
          @vnode.text("C"),
        ])
      },
      width=15,
      height=3,
    ),
    VNodeStory::new(
      "view",
      "with_padding",
      fn() {
        @vnode.view(padding=1.0, border="single", children=[
          @vnode.text("Padded content"),
        ])
      },
      width=20,
      height=5,
    ),
  ]
}
