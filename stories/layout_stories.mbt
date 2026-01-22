///|
/// Layout and container component stories

///|
pub fn card_stories() -> Array[Story] {
  [
    Story::new(
      "card",
      "simple",
      fn() { @components.card([@components.text("Card content")], padding=1.0) },
      width=20,
      height=6,
    ),
    Story::new(
      "card",
      "with_title",
      fn() {
        @components.card(
          [
            @components.text("Title", bold=true),
            @components.text("Card content"),
          ],
          padding=1.0,
        )
      },
      width=20,
      height=7,
    ),
  ]
}

///|
pub fn panel_stories() -> Array[Story] {
  [
    Story::new(
      "panel",
      "simple",
      fn() { @components.panel([@components.text("Panel content")]) },
      width=20,
      height=5,
    ),
  ]
}

///|
pub fn divider_stories() -> Array[Story] {
  [
    Story::new(
      "divider",
      "horizontal",
      fn() {
        @components.column([
          @components.text("Above"),
          @components.hdivider(),
          @components.text("Below"),
        ])
      },
      width=15,
      height=5,
    ),
    Story::new(
      "divider",
      "vertical",
      fn() {
        @components.row(
          [
            @components.text("Left"),
            @components.vdivider(),
            @components.text("Right"),
          ],
          height=@components.dim_length(3.0),
        )
      },
      width=20,
      height=5,
    ),
  ]
}

///|
pub fn bordered_stories() -> Array[Story] {
  [
    Story::new(
      "bordered",
      "rounded",
      fn() {
        @components.bordered(
          [@components.text("Rounded")],
          style=@core.BorderChars::rounded(),
        )
      },
      width=15,
      height=5,
    ),
    Story::new(
      "bordered",
      "single",
      fn() {
        @components.bordered(
          [@components.text("Single")],
          style=@core.BorderChars::single(),
        )
      },
      width=15,
      height=5,
    ),
    Story::new(
      "bordered",
      "double",
      fn() {
        @components.bordered(
          [@components.text("Double")],
          style=@core.BorderChars::double(),
        )
      },
      width=15,
      height=5,
    ),
    Story::new(
      "bordered",
      "ascii",
      fn() {
        @components.bordered(
          [@components.text("ASCII")],
          style=@core.BorderChars::ascii(),
        )
      },
      width=15,
      height=5,
    ),
  ]
}

///|
pub fn text_stories() -> Array[Story] {
  [
    Story::new(
      "text",
      "plain",
      fn() { @components.text("Hello World") },
      width=15,
      height=3,
    ),
    Story::new(
      "text",
      "bold",
      fn() { @components.bold("Bold Text") },
      width=15,
      height=3,
    ),
    Story::new(
      "text",
      "colored",
      fn() { @components.colored("Colored", @core.Color::cyan()) },
      width=15,
      height=3,
    ),
    Story::new(
      "text",
      "with_bg",
      fn() {
        @components.text(
          "Highlight",
          fg=@core.Color::black(),
          bg=@core.Color::yellow(),
        )
      },
      width=15,
      height=3,
    ),
  ]
}
