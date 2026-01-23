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
