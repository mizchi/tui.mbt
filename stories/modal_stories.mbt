///|
/// Modal and overlay component stories

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
          [@components.text("AAAA"), @components.text("BB")],
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
    // Centered content - text should appear in the middle of the viewport
    Story::new(
      "modal",
      "centered_content",
      fn() {
        @components.column(
          [@components.center([@components.text("CENTER")])],
          width=@components.dim_percent(100.0),
          height=@components.dim_percent(100.0),
        )
      },
      width=17,
      height=5,
    ),
    // Centered modal dialog - common UI pattern for modal overlays
    Story::new(
      "modal",
      "centered_modal",
      fn() {
        @components.column(
          [
            @components.center([
              @core.box(
                [@components.text("Modal")],
                border=Some(@core.BorderChars::rounded()),
                padding=1.0,
              ),
            ]),
          ],
          width=@components.dim_percent(100.0),
          height=@components.dim_percent(100.0),
          bg=@core.Color::rgb(40, 40, 40),
        )
      },
      width=21,
      height=9,
    ),
    // Stacked modal: background content + centered overlay modal using position: absolute
    Story::new(
      "modal",
      "stacked_modal",
      fn() {
        @core.box(
          [
            // Background content layer (normal flow)
            @components.column(
              [
                @components.text("Background"),
                @components.text("Content Here"),
                @components.text("..........."),
              ],
              width=@components.dim_percent(100.0),
              height=@components.dim_percent(100.0),
            ),
            // Modal overlay layer (position: absolute, covers entire parent)
            @core.box(
              [
                @components.center([
                  @core.box(
                    [@components.text("Dialog")],
                    border=Some(@core.BorderChars::rounded()),
                    padding=1.0,
                    bg=@core.Color::rgb(30, 30, 50),
                  ),
                ]),
              ],
              position=@types.Position::Absolute,
              inset_top=@components.dim_length(0.0),
              inset_left=@components.dim_length(0.0),
              inset_right=@components.dim_length(0.0),
              inset_bottom=@components.dim_length(0.0),
            ),
          ],
          width=@components.dim_percent(100.0),
          height=@components.dim_percent(100.0),
        )
      },
      width=25,
      height=9,
    ),
    // Nested modals: confirm dialog over main modal using position: absolute
    Story::new(
      "modal",
      "nested_modals",
      fn() {
        @core.box(
          [
            // Base content (normal flow)
            @components.text("App Content"),
            // First modal layer (position: absolute)
            @core.box(
              [
                @components.center([
                  @core.box(
                    [@components.text("Modal 1")],
                    border=Some(@core.BorderChars::single()),
                    padding=1.0,
                    bg=@core.Color::rgb(40, 40, 60),
                  ),
                ]),
              ],
              position=@types.Position::Absolute,
              inset_top=@components.dim_length(0.0),
              inset_left=@components.dim_length(0.0),
              inset_right=@components.dim_length(0.0),
              inset_bottom=@components.dim_length(0.0),
            ),
            // Second modal layer (position: absolute, on top)
            @core.box(
              [
                @components.center([
                  @core.box(
                    [@components.text("Confirm?")],
                    border=Some(@core.BorderChars::rounded()),
                    padding=1.0,
                    bg=@core.Color::rgb(60, 40, 40),
                  ),
                ]),
              ],
              position=@types.Position::Absolute,
              inset_top=@components.dim_length(0.0),
              inset_left=@components.dim_length(0.0),
              inset_right=@components.dim_length(0.0),
              inset_bottom=@components.dim_length(0.0),
            ),
          ],
          width=@components.dim_percent(100.0),
          height=@components.dim_percent(100.0),
        )
      },
      width=25,
      height=9,
    ),
    // Full overlay modal: dark backdrop + centered dialog (typical modal pattern)
    Story::new(
      "modal",
      "full_overlay",
      fn() {
        @core.box(
          [
            // Background content (simulated app UI)
            @components.column(
              [
                @components.text("=== My App ==="),
                @components.text(""),
                @components.text("[ Menu ]  [ Settings ]"),
                @components.text(""),
                @components.text("Welcome to the app!"),
                @components.text("Click a button above."),
              ],
              width=@components.dim_percent(100.0),
              height=@components.dim_percent(100.0),
            ),
            // Dark backdrop overlay (covers everything)
            @core.box(
              [
                // Centered modal dialog
                @core.box(
                  [
                    @components.column([
                      @components.text(" Confirm ", bold=true),
                      @components.text(""),
                      @components.text(" Save changes? "),
                      @components.text(""),
                      @components.row(
                        [
                          @components.text(" [Yes] "),
                          @components.text(" [No] "),
                        ],
                        gap=2.0,
                      ),
                    ]),
                  ],
                  border=Some(@core.BorderChars::rounded()),
                  bg=@core.Color::rgb(40, 40, 60),
                  padding=1.0,
                ),
              ],
              position=@types.Position::Absolute,
              inset_top=@components.dim_length(0.0),
              inset_left=@components.dim_length(0.0),
              inset_right=@components.dim_length(0.0),
              inset_bottom=@components.dim_length(0.0),
              bg=@core.Color::rgb(20, 20, 20), // Dark backdrop
              justify_content=@types.Alignment::Center,
              align_items=@types.Alignment::Center,
            ),
          ],
          width=@components.dim_percent(100.0),
          height=@components.dim_percent(100.0),
        )
      },
      width=31,
      height=13,
    ),
    // Alert modal with single action
    Story::new(
      "modal",
      "alert_modal",
      fn() {
        @core.box(
          [
            // App content
            @components.column(
              [@components.text("Dashboard"), @components.text("Status: OK")],
              width=@components.dim_percent(100.0),
              height=@components.dim_percent(100.0),
            ),
            // Alert overlay
            @core.box(
              [
                @core.box(
                  [
                    @components.column([
                      @components.text(
                        "! Error !",
                        bold=true,
                        fg=@core.Color::red(),
                      ),
                      @components.text(""),
                      @components.text("Connection lost"),
                      @components.text(""),
                      @components.text("   [OK]   "),
                    ]),
                  ],
                  border=Some(@core.BorderChars::rounded()),
                  border_color=@core.Color::red(),
                  bg=@core.Color::rgb(50, 20, 20),
                  padding=1.0,
                ),
              ],
              position=@types.Position::Absolute,
              inset_top=@components.dim_length(0.0),
              inset_left=@components.dim_length(0.0),
              inset_right=@components.dim_length(0.0),
              inset_bottom=@components.dim_length(0.0),
              bg=@core.Color::rgb(10, 10, 10),
              justify_content=@types.Alignment::Center,
              align_items=@types.Alignment::Center,
            ),
          ],
          width=@components.dim_percent(100.0),
          height=@components.dim_percent(100.0),
        )
      },
      width=25,
      height=11,
    ),
    // Command launcher (Raycast-style) overlay - centered
    Story::new(
      "modal",
      "command_launcher",
      fn() {
        @core.box(
          [
            // Background app content
            @components.column(
              [
                @components.text("Editor"),
                @components.text(
                  "──────────────────",
                ),
                @components.text("fn main { }"),
              ],
              width=@components.dim_percent(100.0),
              height=@components.dim_percent(100.0),
            ),
            // Overlay with launcher (centered using justify/align)
            @core.box(
              [
                @core.box(
                  [
                    @components.column([
                      @components.text("> open"),
                      @components.text("* Open"),
                    ]),
                  ],
                  border=Some(@core.BorderChars::rounded()),
                  border_color=@core.Color::cyan(),
                  bg=@core.Color::rgb(30, 30, 40),
                  padding=1.0,
                ),
              ],
              position=@types.Position::Absolute,
              inset_top=@components.dim_length(0.0),
              inset_left=@components.dim_length(0.0),
              inset_right=@components.dim_length(0.0),
              inset_bottom=@components.dim_length(0.0),
              bg=@core.Color::rgb(20, 20, 20),
              justify_content=@types.Alignment::Center,
              align_items=@types.Alignment::Center,
            ),
          ],
          width=@components.dim_percent(100.0),
          height=@components.dim_percent(100.0),
        )
      },
      width=24,
      height=15,
    ),
    // Spotlight-style: top-center positioning
    Story::new(
      "modal",
      "spotlight_top_center",
      fn() {
        @core.box(
          [
            // Background
            @components.column(
              [
                @components.text("Background"),
                @components.text("Line 2"),
                @components.text("Line 3"),
              ],
              width=@components.dim_percent(100.0),
              height=@components.dim_percent(100.0),
              bg=@core.Color::rgb(40, 40, 40),
            ),
            // Overlay - fill screen, then position content at top-center
            @core.box(
              [
                @core.box(
                  [@components.text("[Popup]")],
                  border=Some(@core.BorderChars::rounded()),
                  border_color=@core.Color::cyan(),
                  bg=@core.Color::rgb(20, 20, 30),
                  padding=1.0,
                ),
              ],
              position=@types.Position::Absolute,
              inset_top=@components.dim_length(1.0),
              inset_left=@components.dim_length(0.0),
              inset_right=@components.dim_length(0.0),
              inset_bottom=@components.dim_length(0.0),
              justify_content=@types.Alignment::Center,
              align_items=@types.Alignment::Start,
            ),
          ],
          width=@components.dim_percent(100.0),
          height=@components.dim_percent(100.0),
        )
      },
      width=20,
      height=10,
    ),
  ]
}
