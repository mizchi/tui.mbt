///|
/// Complex layout pattern stories for visual regression testing - vnode version

///|
pub fn nested_layout_stories() -> Array[VNodeStory] {
  [
    VNodeStory::new(
      "nested",
      "row_in_column",
      fn() {
        @vnode.column([
          @vnode.text("Header"),
          @vnode.row(height=1.0, [@vnode.text("Left"), @vnode.text("Right")]),
          @vnode.text("Footer"),
        ])
      },
      width=20,
      height=5,
    ),
    VNodeStory::new(
      "nested",
      "column_in_row",
      fn() {
        @vnode.row(height=4.0, [
          @vnode.column([@vnode.text("Top"), @vnode.text("Bottom")]),
          @vnode.text("|", fg="gray"),
          @vnode.column([@vnode.text("A"), @vnode.text("B")]),
        ])
      },
      width=25,
      height=5,
    ),
    VNodeStory::new(
      "nested",
      "deep_3_levels",
      fn() {
        @vnode.column(border="single", [
          @vnode.row(height=2.0, [
            @vnode.column([@vnode.text("1"), @vnode.text("2")]),
            @vnode.column([@vnode.text("A"), @vnode.text("B")]),
          ]),
        ])
      },
      width=20,
      height=5,
    ),
  ]
}

///|
pub fn flex_layout_stories() -> Array[VNodeStory] {
  [
    VNodeStory::new(
      "flex",
      "equal_3_columns",
      fn() {
        @vnode.row(height=3.0, [
          @vnode.column(border="rounded", [@vnode.text("A")]),
          @vnode.column(border="rounded", [@vnode.text("B")]),
          @vnode.column(border="rounded", [@vnode.text("C")]),
        ])
      },
      width=30,
      height=4,
    ),
    VNodeStory::new(
      "flex",
      "ratio_1_2_1",
      fn() {
        @vnode.row(height=3.0, [
          @vnode.column(border="rounded", flex_grow=1.0, [@vnode.text("1")]),
          @vnode.column(border="rounded", flex_grow=2.0, [@vnode.text("2")]),
          @vnode.column(border="rounded", flex_grow=1.0, [@vnode.text("1")]),
        ])
      },
      width=32,
      height=4,
    ),
    VNodeStory::new(
      "flex",
      "fixed_and_flex",
      fn() {
        @vnode.row(height=3.0, [
          @vnode.column(border="rounded", width=8.0, [@vnode.text("Fix")]),
          @vnode.column(border="rounded", flex_grow=1.0, [
            @vnode.text("Flexible"),
          ]),
        ])
      },
      width=30,
      height=4,
    ),
  ]
}

///|
pub fn sidebar_layout_stories() -> Array[VNodeStory] {
  [
    VNodeStory::new(
      "sidebar",
      "left_fixed",
      fn() {
        @vnode.row(height=5.0, [
          @vnode.column(border="rounded", width=8.0, [@vnode.text("Nav")]),
          @vnode.column(border="rounded", flex_grow=1.0, [
            @vnode.text("Content"),
          ]),
        ])
      },
      width=30,
      height=6,
    ),
    VNodeStory::new(
      "sidebar",
      "dual",
      fn() {
        @vnode.row(height=5.0, [
          @vnode.column(border="rounded", width=6.0, [@vnode.text("L")]),
          @vnode.column(border="rounded", flex_grow=1.0, [@vnode.text("Main")]),
          @vnode.column(border="rounded", width=6.0, [@vnode.text("R")]),
        ])
      },
      width=30,
      height=6,
    ),
  ]
}

///|
pub fn header_footer_stories() -> Array[VNodeStory] {
  [
    VNodeStory::new(
      "header_footer",
      "basic",
      fn() {
        @vnode.column([
          @vnode.column(border="rounded", height=3.0, [@vnode.text("Header")]),
          @vnode.column(border="rounded", flex_grow=1.0, [
            @vnode.text("Content"),
          ]),
          @vnode.column(border="rounded", height=3.0, [@vnode.text("Footer")]),
        ])
      },
      width=25,
      height=10,
    ),
    VNodeStory::new(
      "header_footer",
      "with_sidebar",
      fn() {
        @vnode.column([
          @vnode.column(border="rounded", height=3.0, [@vnode.text("Header")]),
          @vnode.row(flex_grow=1.0, [
            @vnode.column(border="rounded", width=8.0, [@vnode.text("Nav")]),
            @vnode.column(border="rounded", flex_grow=1.0, [@vnode.text("Main")]),
          ]),
        ])
      },
      width=30,
      height=8,
    ),
  ]
}

///|
pub fn cjk_layout_stories() -> Array[VNodeStory] {
  [
    VNodeStory::new(
      "cjk",
      "japanese_bordered",
      fn() {
        @vnode.column(border="single", [@vnode.text("日本語テスト")])
      },
      width=18,
      height=4,
    ),
    VNodeStory::new(
      "cjk",
      "mixed_width",
      fn() {
        @vnode.column([
          @vnode.text("Hello 世界"),
          @vnode.text("Width: 漢字"),
          @vnode.text("ABC あいう"),
        ])
      },
      width=20,
      height=5,
    ),
    VNodeStory::new(
      "cjk",
      "aligned_columns",
      fn() {
        @vnode.column([
          @vnode.row(height=1.0, [@vnode.text("名前"), @vnode.text("値")]),
          @components.divider(),
          @vnode.row(height=1.0, [@vnode.text("項目A"), @vnode.text("100")]),
          @vnode.row(height=1.0, [@vnode.text("項目B"), @vnode.text("200")]),
        ])
      },
      width=20,
      height=6,
    ),
    VNodeStory::new(
      "cjk",
      "emoji",
      fn() {
        @vnode.row(height=1.0, [@vnode.text("Status:"), @vnode.text("✓ Done")])
      },
      width=20,
      height=3,
    ),
  ]
}

///|
pub fn grid_layout_stories() -> Array[VNodeStory] {
  [
    VNodeStory::new(
      "grid",
      "2x2",
      fn() {
        @vnode.column([
          @vnode.row(height=3.0, [
            @vnode.column(border="single", [@vnode.text("1")]),
            @vnode.column(border="single", [@vnode.text("2")]),
          ]),
          @vnode.row(height=3.0, [
            @vnode.column(border="single", [@vnode.text("3")]),
            @vnode.column(border="single", [@vnode.text("4")]),
          ]),
        ])
      },
      width=24,
      height=7,
    ),
    VNodeStory::new(
      "grid",
      "3x2",
      fn() {
        @vnode.column([
          @vnode.row(height=3.0, [
            @vnode.column(border="single", [@vnode.text("A")]),
            @vnode.column(border="single", [@vnode.text("B")]),
            @vnode.column(border="single", [@vnode.text("C")]),
          ]),
          @vnode.row(height=3.0, [
            @vnode.column(border="single", [@vnode.text("D")]),
            @vnode.column(border="single", [@vnode.text("E")]),
            @vnode.column(border="single", [@vnode.text("F")]),
          ]),
        ])
      },
      width=30,
      height=7,
    ),
  ]
}

///|
pub fn edge_case_stories() -> Array[VNodeStory] {
  [
    VNodeStory::new(
      "edge",
      "narrow",
      fn() { @vnode.column(border="single", [@vnode.text("X")]) },
      width=5,
      height=4,
    ),
    VNodeStory::new(
      "edge",
      "short",
      fn() { @vnode.column(border="single", [@vnode.text("Hi")]) },
      width=15,
      height=3,
    ),
    VNodeStory::new(
      "edge",
      "overflow_text",
      fn() {
        @vnode.column(border="single", [
          @vnode.text("This is a very long text that should be truncated"),
        ])
      },
      width=20,
      height=4,
    ),
    VNodeStory::new(
      "edge",
      "many_items",
      fn() {
        @vnode.row(height=1.0, [
          @vnode.text("A"),
          @vnode.text("B"),
          @vnode.text("C"),
          @vnode.text("D"),
          @vnode.text("E"),
        ])
      },
      width=15,
      height=3,
    ),
    VNodeStory::new(
      "edge",
      "empty_column",
      fn() { @vnode.column(border="single", [@vnode.column([])]) },
      width=10,
      height=4,
    ),
  ]
}

///|
pub fn deep_nesting_stories() -> Array[VNodeStory] {
  [
    VNodeStory::new(
      "deep",
      "nested_borders_4",
      fn() {
        @vnode.column(border="single", [
          @vnode.column(border="single", [
            @vnode.column(border="single", [
              @vnode.column(border="single", [@vnode.text("Deep")]),
            ]),
          ]),
        ])
      },
      width=20,
      height=9,
    ),
    VNodeStory::new(
      "deep",
      "alternating_5_levels",
      fn() {
        @vnode.column([
          @vnode.row(height=2.0, [
            @vnode.column([
              @vnode.row(height=1.0, [
                @vnode.column([@vnode.text("X")]),
                @vnode.column([@vnode.text("Y")]),
              ]),
            ]),
          ]),
        ])
      },
      width=15,
      height=4,
    ),
    VNodeStory::new(
      "deep",
      "tree_structure",
      fn() {
        @vnode.column([
          @vnode.text("root/"),
          @vnode.text("├─ src/"),
          @vnode.text("│  ├─ main.mbt"),
          @vnode.text("│  └─ lib.mbt"),
          @vnode.text("└─ test/"),
        ])
      },
      width=25,
      height=7,
    ),
  ]
}

///|
pub fn ide_layout_stories() -> Array[VNodeStory] {
  [
    VNodeStory::new(
      "ide",
      "three_pane",
      fn() {
        @vnode.column([
          // Menu bar
          @vnode.row(height=1.0, bg="rgb(50,50,50)", [
            @vnode.text(" File  Edit  View "),
          ]),
          // Main area
          @vnode.row(flex_grow=1.0, [
            // Explorer sidebar
            @vnode.column(width=12.0, [
              @vnode.text("Explorer"),
              @vnode.text("─────────"),
              @vnode.text(" src/"),
              @vnode.text("   main.mbt"),
              @vnode.vspace(1.0),
            ]),
            // Editor
            @vnode.column(border="single", flex_grow=1.0, [
              @vnode.text("main.mbt", fg="cyan"),
              @vnode.text("fn main {"),
              @vnode.text("  println()"),
              @vnode.text("}"),
              @vnode.vspace(1.0),
            ]),
          ]),
          // Status bar
          @vnode.row(height=1.0, bg="rgb(0,122,204)", [
            @vnode.text(" Ln 1, Col 1 | UTF-8 "),
          ]),
        ])
      },
      width=40,
      height=14,
    ),
    VNodeStory::new(
      "ide",
      "editor_terminal",
      fn() {
        @vnode.column([
          @vnode.column(border="single", flex_grow=2.0, [
            @vnode.text("// Editor"),
            @vnode.text("let x = 42"),
          ]),
          @vnode.column(border="single", flex_grow=1.0, [
            @vnode.text("$ moon run"),
            @vnode.text("Hello, World!"),
          ]),
        ])
      },
      width=30,
      height=12,
    ),
  ]
}

///|
pub fn form_layout_stories() -> Array[VNodeStory] {
  [
    VNodeStory::new(
      "form",
      "login_dialog",
      fn() {
        @vnode.column(border="rounded", padding=1.0, [
          @vnode.text("Login", bold=true),
          @components.divider(),
          @vnode.row(height=1.0, [
            @vnode.text("User: "),
            @vnode.text("[_______]"),
          ]),
          @vnode.row(height=1.0, [
            @vnode.text("Pass: "),
            @vnode.text("[*******]"),
          ]),
          @components.divider(),
          @vnode.row(height=1.0, [
            @vnode.text(" [Cancel] "),
            @vnode.text(" [ OK ] "),
          ]),
        ])
      },
      width=26,
      height=10,
    ),
    VNodeStory::new(
      "form",
      "settings",
      fn() {
        @vnode.column([
          @vnode.text("Settings"),
          @components.divider(),
          @vnode.row(height=1.0, [
            @vnode.text("Theme:"),
            @vnode.text("    "),
            @vnode.text("[Dark  ▼]"),
          ]),
          @vnode.row(height=1.0, [
            @vnode.text("Font:"),
            @vnode.text("     "),
            @vnode.text("[Mono  ▼]"),
          ]),
          @vnode.row(height=1.0, [@vnode.text("[x]"), @vnode.text(" Auto-save")]),
        ])
      },
      width=25,
      height=9,
    ),
  ]
}

///|
pub fn split_pane_stories() -> Array[VNodeStory] {
  [
    VNodeStory::new(
      "split",
      "horizontal",
      fn() {
        @vnode.column([
          @vnode.column(border="single", flex_grow=1.0, [
            @vnode.text("Top Pane"),
          ]),
          @vnode.column(border="single", flex_grow=1.0, [
            @vnode.text("Bottom Pane"),
          ]),
        ])
      },
      width=20,
      height=8,
    ),
    VNodeStory::new(
      "split",
      "vertical",
      fn() {
        @vnode.row(height=6.0, [
          @vnode.column(border="single", flex_grow=1.0, [@vnode.text("Left")]),
          @vnode.column(border="single", flex_grow=1.0, [@vnode.text("Right")]),
        ])
      },
      width=24,
      height=7,
    ),
    VNodeStory::new(
      "split",
      "quad",
      fn() {
        @vnode.column([
          @vnode.row(flex_grow=1.0, [
            @vnode.column(border="single", flex_grow=1.0, [@vnode.text("TL")]),
            @vnode.column(border="single", flex_grow=1.0, [@vnode.text("TR")]),
          ]),
          @vnode.row(flex_grow=1.0, [
            @vnode.column(border="single", flex_grow=1.0, [@vnode.text("BL")]),
            @vnode.column(border="single", flex_grow=1.0, [@vnode.text("BR")]),
          ]),
        ])
      },
      width=20,
      height=8,
    ),
    VNodeStory::new(
      "split",
      "asymmetric",
      fn() {
        @vnode.row(height=5.0, [
          @vnode.column(border="single", flex_grow=0.3, [@vnode.text("30%")]),
          @vnode.column(border="single", flex_grow=0.7, [@vnode.text("70%")]),
        ])
      },
      width=30,
      height=6,
    ),
  ]
}

///|
pub fn card_list_stories() -> Array[VNodeStory] {
  [
    VNodeStory::new(
      "cards",
      "horizontal_list",
      fn() {
        @vnode.row(height=4.0, gap=1.0, [
          @components.card([@vnode.text("Card 1")]),
          @components.card([@vnode.text("Card 2")]),
          @components.card([@vnode.text("Card 3")]),
        ])
      },
      width=35,
      height=5,
    ),
    VNodeStory::new(
      "cards",
      "vertical_list",
      fn() {
        @vnode.column(gap=1.0, [
          @components.card([@vnode.text("Item 1"), @vnode.text("Desc")]),
          @components.card([@vnode.text("Item 2"), @vnode.text("Desc")]),
        ])
      },
      width=18,
      height=15,
    ),
    VNodeStory::new(
      "cards",
      "sectioned",
      fn() {
        @components.card([
          @vnode.text("Title", bold=true),
          @components.divider(width=12),
          @vnode.text("Content"),
          @components.divider(width=12),
          @vnode.text("[Actions]", fg="rgb(128,128,128)"),
        ])
      },
      width=20,
      height=10,
    ),
  ]
}

///|
pub fn status_bar_stories() -> Array[VNodeStory] {
  [
    VNodeStory::new(
      "status",
      "simple",
      fn() {
        @vnode.column([
          @vnode.column(flex_grow=1.0, [@vnode.text("Content")]),
          @vnode.row(height=1.0, bg="rgb(50,50,50)", [@vnode.text("Ready")]),
        ])
      },
      width=20,
      height=5,
    ),
    VNodeStory::new(
      "status",
      "multi_section",
      fn() {
        @vnode.column([
          @vnode.column(flex_grow=1.0, [@vnode.text("Editor")]),
          @vnode.row(height=1.0, bg="rgb(30,30,30)", [
            @vnode.text(" INSERT "),
            @vnode.text("│"),
            @vnode.text(" main.mbt "),
            @vnode.text("│"),
            @vnode.text(" 42:10 "),
          ]),
        ])
      },
      width=35,
      height=5,
    ),
    VNodeStory::new(
      "status",
      "vim_style",
      fn() {
        @vnode.column([
          @vnode.column(flex_grow=1.0, [
            @vnode.text("~ VIM"),
            @vnode.text("~"),
            @vnode.text("~"),
          ]),
          @vnode.row(height=1.0, [@vnode.text(":wq")]),
        ])
      },
      width=20,
      height=6,
    ),
  ]
}

///|
pub fn real_world_stories() -> Array[VNodeStory] {
  [
    VNodeStory::new(
      "real",
      "htop",
      fn() {
        @vnode.column([
          @vnode.row(height=1.0, [
            @components.meter("1", 0.35, width=15),
            @components.meter("2", 0.62, width=15),
          ]),
          @vnode.row(height=1.0, [
            @components.meter("3", 0.18, width=15),
            @components.meter("4", 0.91, width=15),
          ]),
          @vnode.row(height=1.0, [
            @vnode.text("Mem"),
            @components.gauge("", 0.42, bar_width=20),
          ]),
          @components.divider(),
          @vnode.row(height=1.0, bg="rgb(0,100,0)", [
            @vnode.text("PID   "),
            @vnode.text("CPU%  "),
            @vnode.text("CMD"),
          ]),
          @vnode.text(" 1234  12.3  node"),
          @vnode.text(" 5678   8.1  moon"),
        ])
      },
      width=40,
      height=10,
    ),
    VNodeStory::new(
      "real",
      "chat_app",
      fn() {
        @vnode.column([
          @vnode.row(height=1.0, bg="rgb(50,50,50)", [
            @vnode.text("  # general"),
          ]),
          @vnode.column(flex_grow=1.0, padding=1.0, [
            @vnode.text("Alice: Hello!"),
            @vnode.text("Bob: Hi there"),
            @vnode.text("Alice: How are you?"),
          ]),
          @vnode.row(height=1.0, border="single", [
            @vnode.text("> Type message..."),
          ]),
        ])
      },
      width=30,
      height=10,
    ),
    VNodeStory::new(
      "real",
      "file_manager",
      fn() {
        @vnode.column([
          @vnode.row(height=1.0, bg="rgb(40,40,40)", [
            @vnode.text(" /home/user/projects "),
          ]),
          @vnode.row(flex_grow=1.0, [
            @vnode.column(border="single", flex_grow=1.0, [
              @vnode.text("Left Pane"),
              @vnode.text(" docs/"),
              @vnode.text(" src/"),
            ]),
            @vnode.column(border="single", flex_grow=1.0, [
              @vnode.text("Right Pane"),
              @vnode.text(" test/"),
              @vnode.text(" build/"),
            ]),
          ]),
          @vnode.row(height=1.0, [@vnode.text(" 5 items | 1 selected ")]),
        ])
      },
      width=40,
      height=12,
    ),
  ]
}

///|
pub fn dashboard_layout_stories() -> Array[VNodeStory] {
  [
    VNodeStory::new(
      "dashboard",
      "cpu_panel",
      fn() {
        @vnode.column(
          border="rounded",
          border_color="cyan",
          padding=1.0,
          min_width=25.0,
          [
            @vnode.text("cpu", fg="cyan", bold=true),
            @components.meter("C0", 0.45, width=20),
            @components.meter("C1", 0.72, width=20),
            @components.meter("C2", 0.23, width=20),
          ],
        )
      },
      width=30,
      height=8,
    ),
    VNodeStory::new(
      "dashboard",
      "stats_row",
      fn() {
        @vnode.row(height=1.0, [
          @components.stat("CPU", "45%"),
          @components.stat("MEM", "8.2G"),
          @components.stat("SWP", "0.0G"),
        ])
      },
      width=40,
      height=3,
    ),
    VNodeStory::new(
      "dashboard",
      "mini",
      fn() {
        @vnode.column([
          @vnode.row(height=5.0, [
            @vnode.column(
              border="rounded",
              border_color="cyan",
              min_width=15.0,
              [
                @vnode.text("cpu", fg="cyan"),
                @components.gauge("", 0.65, bar_width=10),
              ],
            ),
            @vnode.column(
              border="rounded",
              border_color="cyan",
              min_width=15.0,
              [
                @vnode.text("mem", fg="cyan"),
                @components.gauge("", 0.42, bar_width=10),
              ],
            ),
          ]),
          @vnode.column(border="rounded", border_color="cyan", min_width=30.0, [
            @vnode.text("net", fg="cyan"),
            @vnode.text("rx: 1.2 MB/s"),
            @vnode.text("tx: 0.5 MB/s"),
          ]),
        ])
      },
      width=35,
      height=14,
    ),
  ]
}
