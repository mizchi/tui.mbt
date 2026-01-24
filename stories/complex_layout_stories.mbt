///|
/// Complex layout pattern stories for visual regression testing
///
/// These stories test edge cases and complex compositions that are
/// prone to layout bugs. Useful for:
/// - Detecting regressions in nested layouts
/// - Validating flex distribution
/// - CJK character width handling
/// - Overflow and clipping behavior

///|
/// Nested row/column combinations
pub fn nested_layout_stories() -> Array[Story] {
  [
    // Basic nesting: row inside column
    Story::new(
      "nested",
      "row_in_column",
      fn() {
        @components.column([
          @components.text("Header"),
          @components.row(
            [@components.text("Left"), @components.text("Right")],
            height=@components.dim_length(1.0),
          ),
          @components.text("Footer"),
        ])
      },
      width=20,
      height=5,
    ),
    // Basic nesting: column inside row
    Story::new(
      "nested",
      "column_in_row",
      fn() {
        @components.row(
          [
            @components.column([
              @components.text("Top"),
              @components.text("Bottom"),
            ]),
            @components.vdivider(),
            @components.column([@components.text("A"), @components.text("B")]),
          ],
          height=@components.dim_length(4.0),
        )
      },
      width=25,
      height=5,
    ),
    // Deep nesting (3 levels)
    Story::new(
      "nested",
      "deep_3_levels",
      fn() {
        @components.bordered([
          @components.row(
            [
              @components.column([@components.text("1"), @components.text("2")]),
              @components.column([@components.text("A"), @components.text("B")]),
            ],
            height=@components.dim_length(2.0),
          ),
        ])
      },
      width=20,
      height=5,
    ),
  ]
}

///|
/// Flex distribution patterns
pub fn flex_layout_stories() -> Array[Story] {
  [
    // Equal flex (1:1:1)
    Story::new(
      "flex",
      "equal_3_columns",
      fn() {
        @components.row(
          [
            @components.bordered([@components.text("A")]),
            @components.bordered([@components.text("B")]),
            @components.bordered([@components.text("C")]),
          ],
          height=@components.dim_length(3.0),
        )
      },
      width=30,
      height=4,
    ),
    // Unequal flex (1:2:1)
    Story::new(
      "flex",
      "ratio_1_2_1",
      fn() {
        @components.row(
          [
            @components.column(
              [@components.text("1")],
              border=Some(@core.BorderChars::rounded()),
              flex_grow=1.0,
            ),
            @components.column(
              [@components.text("2")],
              border=Some(@core.BorderChars::rounded()),
              flex_grow=2.0,
            ),
            @components.column(
              [@components.text("1")],
              border=Some(@core.BorderChars::rounded()),
              flex_grow=1.0,
            ),
          ],
          height=@components.dim_length(3.0),
        )
      },
      width=32,
      height=4,
    ),
    // Fixed + flexible
    Story::new(
      "flex",
      "fixed_and_flex",
      fn() {
        @components.row(
          [
            @components.column(
              [@components.text("Fix")],
              border=Some(@core.BorderChars::rounded()),
              width=@components.dim_length(8.0),
            ),
            @components.column(
              [@components.text("Flexible")],
              border=Some(@core.BorderChars::rounded()),
              flex_grow=1.0,
            ),
          ],
          height=@components.dim_length(3.0),
        )
      },
      width=30,
      height=4,
    ),
  ]
}

///|
/// Sidebar layout patterns (common in TUI apps)
pub fn sidebar_layout_stories() -> Array[Story] {
  [
    // Left sidebar
    Story::new(
      "sidebar",
      "left_fixed",
      fn() {
        @components.row(
          [
            @components.column(
              [@components.text("Nav")],
              border=Some(@core.BorderChars::rounded()),
              width=@components.dim_length(8.0),
            ),
            @components.column(
              [@components.text("Content")],
              border=Some(@core.BorderChars::rounded()),
              flex_grow=1.0,
            ),
          ],
          height=@components.dim_length(5.0),
        )
      },
      width=30,
      height=6,
    ),
    // Dual sidebar
    Story::new(
      "sidebar",
      "dual",
      fn() {
        @components.row(
          [
            @components.column(
              [@components.text("L")],
              border=Some(@core.BorderChars::rounded()),
              width=@components.dim_length(6.0),
            ),
            @components.column(
              [@components.text("Main")],
              border=Some(@core.BorderChars::rounded()),
              flex_grow=1.0,
            ),
            @components.column(
              [@components.text("R")],
              border=Some(@core.BorderChars::rounded()),
              width=@components.dim_length(6.0),
            ),
          ],
          height=@components.dim_length(5.0),
        )
      },
      width=30,
      height=6,
    ),
  ]
}

///|
/// Header/footer layout patterns
pub fn header_footer_stories() -> Array[Story] {
  [
    // Header + content + footer
    Story::new(
      "header_footer",
      "basic",
      fn() {
        @components.column([
          @components.column(
            [@components.text("Header")],
            border=Some(@core.BorderChars::rounded()),
            height=@components.dim_length(3.0),
          ),
          @components.column(
            [@components.text("Content")],
            border=Some(@core.BorderChars::rounded()),
            flex_grow=1.0,
          ),
          @components.column(
            [@components.text("Footer")],
            border=Some(@core.BorderChars::rounded()),
            height=@components.dim_length(3.0),
          ),
        ])
      },
      width=25,
      height=10,
    ),
    // Header + sidebar + content
    Story::new(
      "header_footer",
      "with_sidebar",
      fn() {
        @components.column([
          @components.column(
            [@components.text("Header")],
            border=Some(@core.BorderChars::rounded()),
            height=@components.dim_length(3.0),
          ),
          @components.row(
            [
              @components.column(
                [@components.text("Nav")],
                border=Some(@core.BorderChars::rounded()),
                width=@components.dim_length(8.0),
              ),
              @components.column(
                [@components.text("Main")],
                border=Some(@core.BorderChars::rounded()),
                flex_grow=1.0,
              ),
            ],
            flex_grow=1.0,
          ),
        ])
      },
      width=30,
      height=8,
    ),
  ]
}

///|
/// CJK and mixed-width character handling
pub fn cjk_layout_stories() -> Array[Story] {
  [
    // Japanese text in bordered box
    Story::new(
      "cjk",
      "japanese_bordered",
      fn() { @components.bordered([@components.text("日本語テスト")]) },
      width=18,
      height=4,
    ),
    // Mixed ASCII and CJK
    Story::new(
      "cjk",
      "mixed_width",
      fn() {
        @components.column([
          @components.text("Hello 世界"),
          @components.text("Width: 漢字"),
          @components.text("ABC あいう"),
        ])
      },
      width=20,
      height=5,
    ),
    // CJK in table-like layout
    Story::new(
      "cjk",
      "aligned_columns",
      fn() {
        @components.column([
          @components.row(
            [@components.text("名前"), @components.text("値")],
            height=@components.dim_length(1.0),
          ),
          @components.hdivider(),
          @components.row(
            [@components.text("項目A"), @components.text("100")],
            height=@components.dim_length(1.0),
          ),
          @components.row(
            [@components.text("項目B"), @components.text("200")],
            height=@components.dim_length(1.0),
          ),
        ])
      },
      width=20,
      height=6,
    ),
    // Emoji handling
    Story::new(
      "cjk",
      "emoji",
      fn() {
        @components.row(
          [@components.text("Status:"), @components.text("✓ Done")],
          height=@components.dim_length(1.0),
        )
      },
      width=20,
      height=3,
    ),
  ]
}

///|
/// Grid-like multi-cell layouts
pub fn grid_layout_stories() -> Array[Story] {
  [
    // 2x2 grid
    Story::new(
      "grid",
      "2x2",
      fn() {
        @components.column([
          @components.row(
            [
              @components.bordered([@components.text("1")]),
              @components.bordered([@components.text("2")]),
            ],
            height=@components.dim_length(3.0),
          ),
          @components.row(
            [
              @components.bordered([@components.text("3")]),
              @components.bordered([@components.text("4")]),
            ],
            height=@components.dim_length(3.0),
          ),
        ])
      },
      width=24,
      height=7,
    ),
    // 3x2 grid
    Story::new(
      "grid",
      "3x2",
      fn() {
        @components.column([
          @components.row(
            [
              @components.bordered([@components.text("A")]),
              @components.bordered([@components.text("B")]),
              @components.bordered([@components.text("C")]),
            ],
            height=@components.dim_length(3.0),
          ),
          @components.row(
            [
              @components.bordered([@components.text("D")]),
              @components.bordered([@components.text("E")]),
              @components.bordered([@components.text("F")]),
            ],
            height=@components.dim_length(3.0),
          ),
        ])
      },
      width=30,
      height=7,
    ),
  ]
}

///|
/// Edge cases and stress tests
pub fn edge_case_stories() -> Array[Story] {
  [
    // Very narrow container
    Story::new(
      "edge",
      "narrow",
      fn() { @components.bordered([@components.text("X")]) },
      width=5,
      height=4,
    ),
    // Very short container
    Story::new(
      "edge",
      "short",
      fn() { @components.bordered([@components.text("Hi")]) },
      width=15,
      height=3,
    ),
    // Long text truncation
    Story::new(
      "edge",
      "overflow_text",
      fn() {
        @components.bordered([
          @components.text("This is a very long text that should be truncated"),
        ])
      },
      width=20,
      height=4,
    ),
    // Many small items
    Story::new(
      "edge",
      "many_items",
      fn() {
        @components.row(
          [
            @components.text("A"),
            @components.text("B"),
            @components.text("C"),
            @components.text("D"),
            @components.text("E"),
          ],
          height=@components.dim_length(1.0),
        )
      },
      width=15,
      height=3,
    ),
    // Empty children
    Story::new(
      "edge",
      "empty_column",
      fn() { @components.bordered([@components.column([])]) },
      width=10,
      height=4,
    ),
  ]
}

///|
/// Deep nesting patterns (4+ levels)
pub fn deep_nesting_stories() -> Array[Story] {
  [
    // 4 levels of nested borders
    Story::new(
      "deep",
      "nested_borders_4",
      fn() {
        @components.bordered([
          @components.bordered([
            @components.bordered([
              @components.bordered([@components.text("Deep")]),
            ]),
          ]),
        ])
      },
      width=20,
      height=9,
    ),
    // Alternating row/column nesting
    Story::new(
      "deep",
      "alternating_5_levels",
      fn() {
        @components.column([
          @components.row(
            [
              @components.column([
                @components.row(
                  [
                    @components.column([@components.text("X")]),
                    @components.column([@components.text("Y")]),
                  ],
                  height=@components.dim_length(1.0),
                ),
              ]),
            ],
            height=@components.dim_length(2.0),
          ),
        ])
      },
      width=15,
      height=4,
    ),
    // Complex tree-like structure
    Story::new(
      "deep",
      "tree_structure",
      fn() {
        @components.column([
          @components.text("root/"),
          @components.row(
            [
              @components.text("  "),
              @components.column([
                @components.text("├─ src/"),
                @components.row(
                  [
                    @components.text("│  "),
                    @components.column([
                      @components.text("├─ main.mbt"),
                      @components.text("└─ lib.mbt"),
                    ]),
                  ],
                  height=@components.dim_length(2.0),
                ),
                @components.text("└─ test/"),
              ]),
            ],
            flex_grow=1.0,
          ),
        ])
      },
      width=25,
      height=7,
    ),
  ]
}

///|
/// IDE-like layout patterns
pub fn ide_layout_stories() -> Array[Story] {
  [
    // VSCode-like 3-pane layout
    Story::new(
      "ide",
      "three_pane",
      fn() {
        @components.column([
          // Menu bar
          @components.row(
            [@components.text(" File  Edit  View ")],
            height=@components.dim_length(1.0),
            bg=@core.Color::rgb(50, 50, 50),
          ),
          // Main area
          @components.row(
            [
              // File tree
              @components.column(
                [
                  @components.text("Explorer"),
                  @components.text("─────────"),
                  @components.text(" src/"),
                  @components.text("   main"),
                ],
                width=@components.dim_length(12.0),
              ),
              // Editor
              @components.column(
                [
                  @components.text("main.mbt"),
                  @components.text("─────────────"),
                  @components.text("fn main {"),
                  @components.text("  println()"),
                  @components.text("}"),
                ],
                border=Some(@core.BorderChars::single()),
                flex_grow=1.0,
              ),
            ],
            flex_grow=1.0,
          ),
          // Status bar
          @components.row(
            [@components.text(" Ln 1, Col 1 | UTF-8 | MoonBit")],
            height=@components.dim_length(1.0),
            bg=@core.Color::rgb(0, 122, 204),
          ),
        ])
      },
      width=40,
      height=12,
    ),
    // Terminal split
    Story::new(
      "ide",
      "editor_terminal",
      fn() {
        @components.column([
          @components.column(
            [@components.text("// Editor"), @components.text("let x = 42")],
            border=Some(@core.BorderChars::single()),
            flex_grow=2.0,
          ),
          @components.column(
            [@components.text("$ moon run"), @components.text("Hello, World!")],
            border=Some(@core.BorderChars::single()),
            flex_grow=1.0,
          ),
        ])
      },
      width=30,
      height=10,
    ),
  ]
}

///|
/// Form and dialog layouts
pub fn form_layout_stories() -> Array[Story] {
  [
    // Login form
    Story::new(
      "form",
      "login_dialog",
      fn() {
        @components.bordered([
          @components.column(
            [
              @components.text("  Login  "),
              @components.hdivider(),
              @components.row(
                [@components.text("User: "), @components.text("[_______]")],
                height=@components.dim_length(1.0),
              ),
              @components.row(
                [@components.text("Pass: "), @components.text("[*******]")],
                height=@components.dim_length(1.0),
              ),
              @components.hdivider(),
              @components.row(
                [@components.text(" [Cancel] "), @components.text(" [ OK ] ")],
                height=@components.dim_length(1.0),
              ),
            ],
            padding=1.0,
          ),
        ])
      },
      width=25,
      height=10,
    ),
    // Settings panel
    Story::new(
      "form",
      "settings",
      fn() {
        @components.column([
          @components.text("Settings"),
          @components.hdivider(),
          @components.row(
            [
              @components.text("Theme:"),
              @components.text("    "),
              @components.text("[Dark  ▼]"),
            ],
            height=@components.dim_length(1.0),
          ),
          @components.row(
            [
              @components.text("Font:"),
              @components.text("     "),
              @components.text("[Mono  ▼]"),
            ],
            height=@components.dim_length(1.0),
          ),
          @components.row(
            [
              @components.text("Size:"),
              @components.text("     "),
              @components.text("[14    ▼]"),
            ],
            height=@components.dim_length(1.0),
          ),
          @components.row(
            [@components.checkbox(true), @components.text(" Auto-save")],
            height=@components.dim_length(1.0),
          ),
        ])
      },
      width=25,
      height=9,
    ),
  ]
}

///|
/// Split pane variations
pub fn split_pane_stories() -> Array[Story] {
  [
    // Horizontal split (top/bottom)
    Story::new(
      "split",
      "horizontal",
      fn() {
        @components.column([
          @components.column(
            [@components.text("Top Pane")],
            border=Some(@core.BorderChars::single()),
            flex_grow=1.0,
          ),
          @components.column(
            [@components.text("Bottom Pane")],
            border=Some(@core.BorderChars::single()),
            flex_grow=1.0,
          ),
        ])
      },
      width=20,
      height=8,
    ),
    // Vertical split (left/right)
    Story::new(
      "split",
      "vertical",
      fn() {
        @components.row(
          [
            @components.column(
              [@components.text("Left")],
              border=Some(@core.BorderChars::single()),
              flex_grow=1.0,
            ),
            @components.column(
              [@components.text("Right")],
              border=Some(@core.BorderChars::single()),
              flex_grow=1.0,
            ),
          ],
          height=@components.dim_length(6.0),
        )
      },
      width=24,
      height=7,
    ),
    // Quad split (2x2)
    Story::new(
      "split",
      "quad",
      fn() {
        @components.column([
          @components.row(
            [
              @components.column(
                [@components.text("TL")],
                border=Some(@core.BorderChars::single()),
                flex_grow=1.0,
              ),
              @components.column(
                [@components.text("TR")],
                border=Some(@core.BorderChars::single()),
                flex_grow=1.0,
              ),
            ],
            flex_grow=1.0,
          ),
          @components.row(
            [
              @components.column(
                [@components.text("BL")],
                border=Some(@core.BorderChars::single()),
                flex_grow=1.0,
              ),
              @components.column(
                [@components.text("BR")],
                border=Some(@core.BorderChars::single()),
                flex_grow=1.0,
              ),
            ],
            flex_grow=1.0,
          ),
        ])
      },
      width=20,
      height=8,
    ),
    // Asymmetric split (30/70)
    Story::new(
      "split",
      "asymmetric",
      fn() {
        @components.row(
          [
            @components.column(
              [@components.text("30%")],
              border=Some(@core.BorderChars::single()),
              flex_grow=0.3,
            ),
            @components.column(
              [@components.text("70%")],
              border=Some(@core.BorderChars::single()),
              flex_grow=0.7,
            ),
          ],
          height=@components.dim_length(5.0),
        )
      },
      width=30,
      height=6,
    ),
  ]
}

///|
/// Card and list patterns
pub fn card_list_stories() -> Array[Story] {
  [
    // Horizontal card list
    Story::new(
      "cards",
      "horizontal_list",
      fn() {
        @components.row(
          [
            @components.card([@components.text("Card 1")], padding=0.5),
            @components.card([@components.text("Card 2")], padding=0.5),
            @components.card([@components.text("Card 3")], padding=0.5),
          ],
          height=@components.dim_length(4.0),
          gap=1.0,
        )
      },
      width=35,
      height=5,
    ),
    // Vertical card list
    Story::new(
      "cards",
      "vertical_list",
      fn() {
        @components.column(
          [
            @components.card(
              [@components.text("Item 1"), @components.text("Description")],
              padding=0.5,
            ),
            @components.card(
              [@components.text("Item 2"), @components.text("Description")],
              padding=0.5,
            ),
          ],
          gap=1.0,
        )
      },
      width=20,
      height=10,
    ),
    // Card with sections
    Story::new(
      "cards",
      "sectioned",
      fn() {
        @components.card([
          @components.bold("Title"),
          @components.hdivider(),
          @components.text("Content here"),
          @components.text("More content"),
          @components.hdivider(),
          @components.text("[Actions]", fg=@core.Color::rgb(128, 128, 128)),
        ])
      },
      width=20,
      height=9,
    ),
  ]
}

///|
/// Status bar patterns
pub fn status_bar_stories() -> Array[Story] {
  [
    // Simple status bar
    Story::new(
      "status",
      "simple",
      fn() {
        @components.column([
          @components.column([@components.text("Content")], flex_grow=1.0),
          @components.row(
            [@components.text("Ready")],
            height=@components.dim_length(1.0),
            bg=@core.Color::rgb(50, 50, 50),
          ),
        ])
      },
      width=20,
      height=5,
    ),
    // Multi-section status bar
    Story::new(
      "status",
      "multi_section",
      fn() {
        @components.column([
          @components.column([@components.text("Editor")], flex_grow=1.0),
          @components.row(
            [
              @components.text(" INSERT "),
              @components.text("│"),
              @components.text(" main.mbt "),
              @components.text("│"),
              @components.text(" 42:10 "),
            ],
            height=@components.dim_length(1.0),
            bg=@core.Color::rgb(30, 30, 30),
          ),
        ])
      },
      width=35,
      height=5,
    ),
    // Vim-like status
    Story::new(
      "status",
      "vim_style",
      fn() {
        @components.column([
          @components.column(
            [
              @components.text("~ VIM"),
              @components.text("~"),
              @components.text("~"),
            ],
            flex_grow=1.0,
          ),
          @components.row(
            [@components.text(":wq")],
            height=@components.dim_length(1.0),
          ),
        ])
      },
      width=20,
      height=6,
    ),
  ]
}

///|
/// Complex real-world layouts
pub fn real_world_stories() -> Array[Story] {
  [
    // htop-like layout
    Story::new(
      "real",
      "htop",
      fn() {
        @components.column([
          // CPU meters
          @components.row(
            [
              @composed.meter("1", 0.35, width=15),
              @composed.meter("2", 0.62, width=15),
            ],
            height=@components.dim_length(1.0),
          ),
          @components.row(
            [
              @composed.meter("3", 0.18, width=15),
              @composed.meter("4", 0.91, width=15),
            ],
            height=@components.dim_length(1.0),
          ),
          // Memory/Swap
          @components.row(
            [@components.text("Mem"), @composed.gauge("", 0.42, bar_width=20)],
            height=@components.dim_length(1.0),
          ),
          @components.hdivider(),
          // Process list header
          @components.row(
            [
              @components.text("PID   "),
              @components.text("CPU%  "),
              @components.text("MEM%  "),
              @components.text("CMD"),
            ],
            height=@components.dim_length(1.0),
            bg=@core.Color::rgb(0, 100, 0),
          ),
          // Process entries
          @components.text(" 1234  12.3   4.5  node"),
          @components.text(" 5678   8.1   2.3  moon"),
        ])
      },
      width=40,
      height=10,
    ),
    // Chat app layout
    Story::new(
      "real",
      "chat_app",
      fn() {
        @components.column([
          // Header
          @components.row(
            [@components.text("  # general")],
            height=@components.dim_length(1.0),
            bg=@core.Color::rgb(50, 50, 50),
          ),
          // Messages
          @components.column(
            [
              @components.text("Alice: Hello!"),
              @components.text("Bob: Hi there"),
              @components.text("Alice: How are you?"),
            ],
            flex_grow=1.0,
            padding=1.0,
          ),
          // Input
          @components.row(
            [@components.text("> Type message...")],
            height=@components.dim_length(1.0),
            border=Some(@core.BorderChars::single()),
          ),
        ])
      },
      width=30,
      height=10,
    ),
    // File manager layout
    Story::new(
      "real",
      "file_manager",
      fn() {
        @components.column([
          // Path bar
          @components.row(
            [@components.text(" /home/user/projects ")],
            height=@components.dim_length(1.0),
            bg=@core.Color::rgb(40, 40, 40),
          ),
          // Dual pane
          @components.row(
            [
              @components.column(
                [
                  @components.text("Left Pane"),
                  @components.text("─────────"),
                  @components.text(" docs/"),
                  @components.text(" src/"),
                  @components.text("> main.mbt"),
                ],
                border=Some(@core.BorderChars::single()),
                flex_grow=1.0,
              ),
              @components.column(
                [
                  @components.text("Right Pane"),
                  @components.text("──────────"),
                  @components.text(" test/"),
                  @components.text(" build/"),
                  @components.text(" README"),
                ],
                border=Some(@core.BorderChars::single()),
                flex_grow=1.0,
              ),
            ],
            flex_grow=1.0,
          ),
          // Status
          @components.row(
            [@components.text(" 5 items | 1 selected ")],
            height=@components.dim_length(1.0),
          ),
        ])
      },
      width=40,
      height=12,
    ),
  ]
}

///|
/// Dashboard-style composite layouts
pub fn dashboard_layout_stories() -> Array[Story] {
  [
    // btop-like CPU section
    Story::new(
      "dashboard",
      "cpu_panel",
      fn() {
        @composed.titled_box(
          "cpu",
          [
            @composed.meter("C0", 0.45, width=20),
            @composed.meter("C1", 0.72, width=20),
            @composed.meter("C2", 0.23, width=20),
          ],
          width=25,
        )
      },
      width=30,
      height=7,
    ),
    // Stats row
    Story::new(
      "dashboard",
      "stats_row",
      fn() {
        @components.row(
          [
            @composed.stat("CPU", "45%"),
            @composed.stat("MEM", "8.2G"),
            @composed.stat("SWP", "0.0G"),
          ],
          height=@components.dim_length(1.0),
        )
      },
      width=40,
      height=3,
    ),
    // Mini dashboard
    Story::new(
      "dashboard",
      "mini",
      fn() {
        @components.column([
          @components.row(
            [
              @composed.titled_box(
                "cpu",
                [@composed.gauge("", 0.65, bar_width=10)],
                width=15,
              ),
              @composed.titled_box(
                "mem",
                [@composed.gauge("", 0.42, bar_width=10)],
                width=15,
              ),
            ],
            height=@components.dim_length(5.0),
          ),
          @composed.titled_box(
            "net",
            [@components.text("rx: 1.2 MB/s"), @components.text("tx: 0.5 MB/s")],
            width=30,
          ),
        ])
      },
      width=35,
      height=11,
    ),
  ]
}
