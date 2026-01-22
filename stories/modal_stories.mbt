///|
/// Modal and overlay component stories
/// Note: Flex centering may not render correctly in plain text snapshots
/// due to layout calculation limitations. Visual testing in terminal is recommended.

///|
pub fn modal_stories() -> Array[Story] {
  [
    // Simple box overlay test - demonstrates stacking
    Story::new(
      "modal",
      "simple_overlay",
      fn() {
        @core.box(
          [
            // Base layer
            @components.text("BASE"),
            // Overlay layer (renders on top)
            @core.box(
              [@components.text("OVER")],
              bg=@core.Color::rgb(80, 80, 100),
            ),
          ],
          width=@components.dim_percent(100.0),
          height=@components.dim_percent(100.0),
        )
      },
      width=20,
      height=5,
    ),
    // Modal box styling (border only, no bg)
    Story::new(
      "modal",
      "modal_box",
      fn() {
        @core.box(
          [@components.text("Modal Content")],
          border=Some(@core.BorderChars::rounded()),
          border_color=@core.Color::cyan(),
          padding=1.0,
        )
      },
      width=25,
      height=7,
    ),
    // Bordered content with padding
    Story::new(
      "modal",
      "bordered_content",
      fn() {
        @core.box(
          [@components.text("Content")],
          border=Some(@core.BorderChars::single()),
          padding=1.0,
        )
      },
      width=15,
      height=5,
    ),
    // Stacked text overlay (simplest form)
    Story::new(
      "modal",
      "text_overlay",
      fn() {
        // Multiple children in same box = overlay
        @core.box(
          [
            @components.text("AAAA"),
            @components.text("BB"),
          ],
          width=@components.dim_percent(100.0),
          height=@components.dim_length(3.0),
        )
      },
      width=15,
      height=5,
    ),
    // Dialog layout (column with row)
    Story::new(
      "modal",
      "dialog_layout",
      fn() {
        @core.box(
          [
            @components.column(
              [
                @components.text("Title", bold=true),
                @components.text("Message text"),
                @components.row(
                  [@components.text("[OK]"), @components.text("[Cancel]")],
                  gap=1.0,
                ),
              ],
              gap=1.0,
            ),
          ],
          border=Some(@core.BorderChars::rounded()),
          border_color=@core.Color::cyan(),
          padding=1.0,
        )
      },
      width=25,
      height=9,
    ),
  ]
}
