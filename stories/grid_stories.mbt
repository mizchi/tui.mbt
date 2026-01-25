///|
/// Grid layout component stories - vnode version

///|
pub fn grid_basic_stories() -> Array[VNodeStory] {
  [
    VNodeStory::new(
      "grid",
      "basic_3col",
      fn() {
        @vnode.grid(
          [
            @vnode.text("A"),
            @vnode.text("B"),
            @vnode.text("C"),
            @vnode.text("D"),
            @vnode.text("E"),
            @vnode.text("F"),
          ],
          columns=[1.0, 1.0, 1.0],
          gap=1.0,
        )
      },
      width=20,
      height=5,
    ),
    VNodeStory::new(
      "grid",
      "unequal_columns",
      fn() {
        @vnode.grid(
          [
            @vnode.text("Sidebar"),
            @vnode.text("Main Content"),
            @vnode.text("Footer"),
            @vnode.text("Footer"),
          ],
          columns=[1.0, 2.0],
          gap=1.0,
        )
      },
      width=30,
      height=5,
    ),
    VNodeStory::new(
      "grid",
      "with_border",
      fn() {
        @vnode.grid(
          [
            @vnode.text("1"),
            @vnode.text("2"),
            @vnode.text("3"),
            @vnode.text("4"),
          ],
          columns=[1.0, 1.0],
          gap=1.0,
          border="rounded",
          padding=1.0,
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
        @vnode.grid(
          [
            @vnode.grid_item(@vnode.text("Header (span 3)"), column_span=3),
            @vnode.text("A"),
            @vnode.text("B"),
            @vnode.text("C"),
          ],
          columns=[1.0, 1.0, 1.0],
          gap=1.0,
        )
      },
      width=25,
      height=5,
    ),
    VNodeStory::new(
      "grid_item",
      "positioned",
      fn() {
        @vnode.grid(
          [
            @vnode.grid_item(@vnode.text("At (2,1)"), column=2, row=1),
            @vnode.grid_item(@vnode.text("At (1,2)"), column=1, row=2),
          ],
          columns=[1.0, 1.0],
          rows=[1.0, 1.0],
        )
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
        @vnode.view(
          [@vnode.text("Line 1"), @vnode.text("Line 2"), @vnode.text("Line 3")],
          gap=0.0,
        )
      },
      width=15,
      height=5,
    ),
    VNodeStory::new(
      "view",
      "row_direction",
      fn() {
        @vnode.view(
          [@vnode.text("A"), @vnode.text("B"), @vnode.text("C")],
          direction="row",
          gap=1.0,
        )
      },
      width=15,
      height=3,
    ),
    VNodeStory::new(
      "view",
      "with_padding",
      fn() {
        @vnode.view(
          [@vnode.text("Padded content")],
          padding=1.0,
          border="single",
        )
      },
      width=20,
      height=5,
    ),
  ]
}
