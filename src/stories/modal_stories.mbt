///|
/// Modal and overlay component stories - vnode version

///|
/// Render main content with overlays to plain text for testing
pub fn render_overlay_plain(
  width : Int,
  height : Int,
  main : @vnode.TuiNode,
  overlays : Array[@vnode.OverlayEntry],
) -> String {
  let app = @vnode.VNodeApp::new(width, height)
  let frame = app.render_frame_with_overlays(main, overlays)
  let plain = @testing.strip_ansi(frame)

  // Parse by width accounting for CJK characters
  let chars = plain.to_array()
  let lines : Array[String] = []
  let mut pos = 0
  for row = 0; row < height; row = row + 1 {
    let line_chars : Array[Char] = []
    let mut col = 0
    while col < width && pos < chars.length() {
      let c = chars[pos]
      line_chars.push(c)
      pos = pos + 1
      col = col + @core.char_display_width(c)
    }
    lines.push(trim_end(String::from_array(line_chars)))
  }

  // Remove trailing empty lines
  while lines.length() > 0 && lines[lines.length() - 1] == "" {
    let _ = lines.pop()

  }
  lines
  .iter()
  .fold(init="", fn(acc, line) {
    if acc == "" {
      line
    } else {
      acc + "\n" + line
    }
  })
}

///|
pub fn modal_stories() -> Array[VNodeStory] {
  [
    // Simple box overlay test
    VNodeStory::new(
      "modal",
      "simple_overlay",
      fn() {
        @vnode.column(width=20.0, height=5.0, [
          @vnode.text("BASE"),
          @vnode.row(bg="rgb(80,80,100)", [@vnode.text("OVER")]),
        ])
      },
      width=20,
      height=5,
    ),
    // Modal box styling
    VNodeStory::new(
      "modal",
      "modal_box",
      fn() {
        @vnode.column(border="rounded", border_color="cyan", padding=1.0, [
          @vnode.text("Modal Content"),
        ])
      },
      width=25,
      height=7,
    ),
    // Bordered content with padding
    VNodeStory::new(
      "modal",
      "bordered_content",
      fn() {
        @vnode.column(border="single", padding=1.0, [@vnode.text("Content")])
      },
      width=15,
      height=5,
    ),
    // Text overlay
    VNodeStory::new(
      "modal",
      "text_overlay",
      fn() {
        @vnode.column(height=3.0, [@vnode.text("AAAA"), @vnode.text("BB")])
      },
      width=15,
      height=5,
    ),
    // Dialog layout
    VNodeStory::new(
      "modal",
      "dialog_layout",
      fn() {
        @vnode.column(
          border="rounded",
          border_color="cyan",
          padding=1.0,
          gap=1.0,
          [
            @vnode.text("Title", bold=true),
            @vnode.text("Message text"),
            @vnode.row(gap=1.0, [@vnode.text("[OK]"), @vnode.text("[Cancel]")]),
          ],
        )
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
          width=17.0,
          height=5.0,
          justify="center",
          align="center",
          [@vnode.row(justify="center", [@vnode.text("CENTER")])],
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
        @vnode.column(
          width=21.0,
          height=9.0,
          bg="rgb(40,40,40)",
          justify="center",
          align="center",
          [
            @vnode.row(justify="center", [
              @vnode.column(border="rounded", padding=1.0, [
                @vnode.text("Modal"),
              ]),
            ]),
          ],
        )
      },
      width=21,
      height=9,
    ),
    // Stacked modal
    VNodeStory::new(
      "modal",
      "stacked_modal",
      fn() {
        @vnode.column(width=25.0, height=9.0, [
          @vnode.text("Background"),
          @vnode.text("Content Here"),
          @vnode.text("..........."),
          @vnode.row(justify="center", [
            @vnode.column(border="rounded", padding=1.0, bg="rgb(30,30,50)", [
              @vnode.text("Dialog"),
            ]),
          ]),
        ])
      },
      width=25,
      height=9,
    ),
    // Nested modals
    VNodeStory::new(
      "modal",
      "nested_modals",
      fn() {
        @vnode.column(width=25.0, height=9.0, [
          @vnode.text("App Content"),
          @vnode.row(justify="center", [
            @vnode.column(border="rounded", padding=1.0, bg="rgb(60,40,40)", [
              @vnode.text("Confirm?"),
            ]),
          ]),
        ])
      },
      width=25,
      height=9,
    ),
    // Full overlay modal
    VNodeStory::new(
      "modal",
      "full_overlay",
      fn() {
        @components.modal("Confirm", [
          @vnode.text("Save changes?"),
          @vnode.row(justify="center", [
            @components.button("Yes"),
            @vnode.hspace(2.0),
            @components.button("No"),
          ]),
        ])
      },
      width=31,
      height=13,
    ),
    // Alert modal
    VNodeStory::new(
      "modal",
      "alert_modal",
      fn() { @components.alert_dialog("Connection lost", title="! Error !") },
      width=25,
      height=11,
    ),
    // Confirm dialog
    VNodeStory::new(
      "modal",
      "confirm_dialog",
      fn() { @components.confirm_dialog("Delete this file?", title="Confirm") },
      width=31,
      height=13,
    ),
    VNodeStory::new(
      "modal",
      "confirm_dialog_custom",
      fn() {
        @components.confirm_dialog(
          "Save changes?",
          title="Unsaved Changes",
          confirm_label="Save",
          cancel_label="Discard",
        )
      },
      width=31,
      height=13,
    ),
    // Command launcher
    VNodeStory::new(
      "modal",
      "command_launcher",
      fn() {
        @vnode.column(
          border="rounded",
          border_color="cyan",
          bg="rgb(30,30,40)",
          padding=1.0,
          [@vnode.text("> open"), @vnode.text("* Open")],
        )
      },
      width=24,
      height=15,
    ),
    // Spotlight-style
    VNodeStory::new(
      "modal",
      "spotlight_top_center",
      fn() {
        @vnode.column(width=20.0, height=10.0, bg="rgb(40,40,40)", [
          @vnode.row(justify="center", [
            @vnode.column(
              border="rounded",
              border_color="cyan",
              bg="rgb(20,20,30)",
              padding=1.0,
              [@vnode.text("[Popup]")],
            ),
          ]),
          @vnode.text("Background"),
          @vnode.text("Line 2"),
          @vnode.text("Line 3"),
        ])
      },
      width=20,
      height=10,
    ),
  ]
}
