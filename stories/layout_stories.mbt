///|
/// Layout and container component stories - vnode version

///|
pub fn card_stories() -> Array[VNodeStory] {
  [
    VNodeStory::new(
      "card",
      "simple",
      fn() { @components.card([@vnode.text("Card content")]) },
      width=20,
      height=6,
    ),
    VNodeStory::new(
      "card",
      "with_title",
      fn() { @components.card([@vnode.text("Card content")], title="Title") },
      width=20,
      height=7,
    ),
  ]
}

///|
pub fn panel_stories() -> Array[VNodeStory] {
  [
    VNodeStory::new(
      "panel",
      "simple",
      fn() {
        @vnode.column(
          border="single",
          border_color="rgb(60,60,80)",
          padding=1.0,
          [@vnode.text("Panel content")],
        )
      },
      width=20,
      height=6,
    ),
  ]
}

///|
pub fn divider_stories() -> Array[VNodeStory] {
  [
    VNodeStory::new(
      "divider",
      "horizontal",
      fn() {
        @vnode.column([
          @vnode.text("Above"),
          @components.divider(),
          @vnode.text("Below"),
        ])
      },
      width=15,
      height=5,
    ),
    VNodeStory::new(
      "divider",
      "vertical",
      fn() {
        @vnode.row(gap=1.0, height=3.0, [
          @vnode.text("Left"),
          @vnode.text("|", fg="rgb(60,60,60)"),
          @vnode.text("Right"),
        ])
      },
      width=20,
      height=5,
    ),
  ]
}

///|
pub fn bordered_stories() -> Array[VNodeStory] {
  [
    VNodeStory::new(
      "bordered",
      "rounded",
      fn() {
        @vnode.column(border="rounded", border_color="white", padding=1.0, [
          @vnode.text("Rounded"),
        ])
      },
      width=15,
      height=5,
    ),
    VNodeStory::new(
      "bordered",
      "single",
      fn() {
        @vnode.column(border="single", border_color="white", padding=1.0, [
          @vnode.text("Single"),
        ])
      },
      width=15,
      height=5,
    ),
    VNodeStory::new(
      "bordered",
      "double",
      fn() {
        @vnode.column(border="double", border_color="white", padding=1.0, [
          @vnode.text("Double"),
        ])
      },
      width=15,
      height=5,
    ),
    VNodeStory::new(
      "bordered",
      "ascii",
      fn() {
        @vnode.column(border="ascii", border_color="white", padding=1.0, [
          @vnode.text("ASCII"),
        ])
      },
      width=15,
      height=5,
    ),
  ]
}

///|
pub fn text_stories() -> Array[VNodeStory] {
  [
    VNodeStory::new(
      "text",
      "plain",
      fn() { @vnode.text("Hello World") },
      width=15,
      height=3,
    ),
    VNodeStory::new(
      "text",
      "bold",
      fn() { @vnode.text("Bold Text", bold=true) },
      width=15,
      height=3,
    ),
    VNodeStory::new(
      "text",
      "colored",
      fn() { @vnode.text("Colored", fg="cyan") },
      width=15,
      height=3,
    ),
    VNodeStory::new(
      "text",
      "with_bg",
      fn() { @vnode.row(bg="yellow", [@vnode.text("Highlight", fg="black")]) },
      width=15,
      height=3,
    ),
  ]
}
