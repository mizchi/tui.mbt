///|
/// Modal and overlay component stories - vnode version

///|
pub fn modal_stories() -> Array[VNodeStory] {
  [
    // Simple box overlay test
    VNodeStory::new(
      "modal",
      "simple_overlay",
      fn() {
        @vnode.column([
          @vnode.text("BASE"),
          @vnode.row([@vnode.text("OVER")], bg="rgb(80,80,100)"),
        ], width=20.0, height=5.0)
      },
      width=20,
      height=5,
    ),
    // Modal box styling
    VNodeStory::new(
      "modal",
      "modal_box",
      fn() {
        @vnode.column(
          [@vnode.text("Modal Content")],
          border="rounded",
          border_color="cyan",
          padding=1.0,
        )
      },
      width=25,
      height=7,
    ),
    // Bordered content with padding
    VNodeStory::new(
      "modal",
      "bordered_content",
      fn() {
        @vnode.column(
          [@vnode.text("Content")],
          border="single",
          padding=1.0,
        )
      },
      width=15,
      height=5,
    ),
    // Text overlay
    VNodeStory::new(
      "modal",
      "text_overlay",
      fn() {
        @vnode.column([
          @vnode.text("AAAA"),
          @vnode.text("BB"),
        ], height=3.0)
      },
      width=15,
      height=5,
    ),
    // Dialog layout
    VNodeStory::new(
      "modal",
      "dialog_layout",
      fn() {
        @vnode.column([
          @vnode.text("Title", bold=true),
          @vnode.text("Message text"),
          @vnode.row([@vnode.text("[OK]"), @vnode.text("[Cancel]")], gap=1.0),
        ], border="rounded", border_color="cyan", padding=1.0, gap=1.0)
      },
      width=25,
      height=9,
    ),
    // Centered content
    VNodeStory::new(
      "modal",
      "centered_content",
      fn() {
        @vnode.column(
          [@vnode.row([@vnode.text("CENTER")], justify="center")],
          width=17.0,
          height=5.0,
          justify="center",
          align="center",
        )
      },
      width=17,
      height=5,
    ),
    // Centered modal dialog
    VNodeStory::new(
      "modal",
      "centered_modal",
      fn() {
        @vnode.column([
          @vnode.row([
            @vnode.column(
              [@vnode.text("Modal")],
              border="rounded",
              padding=1.0,
            ),
          ], justify="center"),
        ], width=21.0, height=9.0, bg="rgb(40,40,40)", justify="center", align="center")
      },
      width=21,
      height=9,
    ),
    // Stacked modal
    VNodeStory::new(
      "modal",
      "stacked_modal",
      fn() {
        @vnode.column([
          @vnode.text("Background"),
          @vnode.text("Content Here"),
          @vnode.text("..........."),
          @vnode.row([
            @vnode.column(
              [@vnode.text("Dialog")],
              border="rounded",
              padding=1.0,
              bg="rgb(30,30,50)",
            ),
          ], justify="center"),
        ], width=25.0, height=9.0)
      },
      width=25,
      height=9,
    ),
    // Nested modals
    VNodeStory::new(
      "modal",
      "nested_modals",
      fn() {
        @vnode.column([
          @vnode.text("App Content"),
          @vnode.row([
            @vnode.column(
              [@vnode.text("Confirm?")],
              border="rounded",
              padding=1.0,
              bg="rgb(60,40,40)",
            ),
          ], justify="center"),
        ], width=25.0, height=9.0)
      },
      width=25,
      height=9,
    ),
    // Full overlay modal
    VNodeStory::new(
      "modal",
      "full_overlay",
      fn() {
        @vnode.modal(
          "Confirm",
          [
            @vnode.text("Save changes?"),
            @vnode.row([
              @vnode.button("Yes"),
              @vnode.hspace(2.0),
              @vnode.button("No"),
            ], justify="center"),
          ],
        )
      },
      width=31,
      height=13,
    ),
    // Alert modal
    VNodeStory::new(
      "modal",
      "alert_modal",
      fn() {
        @vnode.alert_dialog("Connection lost", title="! Error !")
      },
      width=25,
      height=11,
    ),
    // Command launcher
    VNodeStory::new(
      "modal",
      "command_launcher",
      fn() {
        @vnode.column([
          @vnode.text("> open"),
          @vnode.text("* Open"),
        ], border="rounded", border_color="cyan", bg="rgb(30,30,40)", padding=1.0)
      },
      width=24,
      height=15,
    ),
    // Spotlight-style
    VNodeStory::new(
      "modal",
      "spotlight_top_center",
      fn() {
        @vnode.column([
          @vnode.row([
            @vnode.column(
              [@vnode.text("[Popup]")],
              border="rounded",
              border_color="cyan",
              bg="rgb(20,20,30)",
              padding=1.0,
            ),
          ], justify="center"),
          @vnode.text("Background"),
          @vnode.text("Line 2"),
          @vnode.text("Line 3"),
        ], width=20.0, height=10.0, bg="rgb(40,40,40)")
      },
      width=20,
      height=10,
    ),
  ]
}
