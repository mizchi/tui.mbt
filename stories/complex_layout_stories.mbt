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
          @vnode.row([@vnode.text("Left"), @vnode.text("Right")], height=1.0),
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
        @vnode.row(
          [
            @vnode.column([@vnode.text("Top"), @vnode.text("Bottom")]),
            @vnode.text("|", fg="gray"),
            @vnode.column([@vnode.text("A"), @vnode.text("B")]),
          ],
          height=4.0,
        )
      },
      width=25,
      height=5,
    ),
    VNodeStory::new(
      "nested",
      "deep_3_levels",
      fn() {
        @vnode.column(
          [
            @vnode.row(
              [
                @vnode.column([@vnode.text("1"), @vnode.text("2")]),
                @vnode.column([@vnode.text("A"), @vnode.text("B")]),
              ],
              height=2.0,
            ),
          ],
          border="single",
        )
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
        @vnode.row(
          [
            @vnode.column([@vnode.text("A")], border="rounded"),
            @vnode.column([@vnode.text("B")], border="rounded"),
            @vnode.column([@vnode.text("C")], border="rounded"),
          ],
          height=3.0,
        )
      },
      width=30,
      height=4,
    ),
    VNodeStory::new(
      "flex",
      "ratio_1_2_1",
      fn() {
        @vnode.row(
          [
            @vnode.column([@vnode.text("1")], border="rounded", flex_grow=1.0),
            @vnode.column([@vnode.text("2")], border="rounded", flex_grow=2.0),
            @vnode.column([@vnode.text("1")], border="rounded", flex_grow=1.0),
          ],
          height=3.0,
        )
      },
      width=32,
      height=4,
    ),
    VNodeStory::new(
      "flex",
      "fixed_and_flex",
      fn() {
        @vnode.row(
          [
            @vnode.column([@vnode.text("Fix")], border="rounded", width=8.0),
            @vnode.column(
              [@vnode.text("Flexible")],
              border="rounded",
              flex_grow=1.0,
            ),
          ],
          height=3.0,
        )
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
        @vnode.row(
          [
            @vnode.column([@vnode.text("Nav")], border="rounded", width=8.0),
            @vnode.column(
              [@vnode.text("Content")],
              border="rounded",
              flex_grow=1.0,
            ),
          ],
          height=5.0,
        )
      },
      width=30,
      height=6,
    ),
    VNodeStory::new(
      "sidebar",
      "dual",
      fn() {
        @vnode.row(
          [
            @vnode.column([@vnode.text("L")], border="rounded", width=6.0),
            @vnode.column(
              [@vnode.text("Main")],
              border="rounded",
              flex_grow=1.0,
            ),
            @vnode.column([@vnode.text("R")], border="rounded", width=6.0),
          ],
          height=5.0,
        )
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
          @vnode.column([@vnode.text("Header")], border="rounded", height=3.0),
          @vnode.column(
            [@vnode.text("Content")],
            border="rounded",
            flex_grow=1.0,
          ),
          @vnode.column([@vnode.text("Footer")], border="rounded", height=3.0),
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
          @vnode.column([@vnode.text("Header")], border="rounded", height=3.0),
          @vnode.row(
            [
              @vnode.column([@vnode.text("Nav")], border="rounded", width=8.0),
              @vnode.column(
                [@vnode.text("Main")],
                border="rounded",
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
pub fn cjk_layout_stories() -> Array[VNodeStory] {
  [
    VNodeStory::new(
      "cjk",
      "japanese_bordered",
      fn() {
        @vnode.column([@vnode.text("日本語テスト")], border="single")
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
          @vnode.row([@vnode.text("名前"), @vnode.text("値")], height=1.0),
          @components.divider(),
          @vnode.row([@vnode.text("項目A"), @vnode.text("100")], height=1.0),
          @vnode.row([@vnode.text("項目B"), @vnode.text("200")], height=1.0),
        ])
      },
      width=20,
      height=6,
    ),
    VNodeStory::new(
      "cjk",
      "emoji",
      fn() {
        @vnode.row(
          [@vnode.text("Status:"), @vnode.text("✓ Done")],
          height=1.0,
        )
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
          @vnode.row(
            [
              @vnode.column([@vnode.text("1")], border="single"),
              @vnode.column([@vnode.text("2")], border="single"),
            ],
            height=3.0,
          ),
          @vnode.row(
            [
              @vnode.column([@vnode.text("3")], border="single"),
              @vnode.column([@vnode.text("4")], border="single"),
            ],
            height=3.0,
          ),
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
          @vnode.row(
            [
              @vnode.column([@vnode.text("A")], border="single"),
              @vnode.column([@vnode.text("B")], border="single"),
              @vnode.column([@vnode.text("C")], border="single"),
            ],
            height=3.0,
          ),
          @vnode.row(
            [
              @vnode.column([@vnode.text("D")], border="single"),
              @vnode.column([@vnode.text("E")], border="single"),
              @vnode.column([@vnode.text("F")], border="single"),
            ],
            height=3.0,
          ),
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
      fn() { @vnode.column([@vnode.text("X")], border="single") },
      width=5,
      height=4,
    ),
    VNodeStory::new(
      "edge",
      "short",
      fn() { @vnode.column([@vnode.text("Hi")], border="single") },
      width=15,
      height=3,
    ),
    VNodeStory::new(
      "edge",
      "overflow_text",
      fn() {
        @vnode.column(
          [@vnode.text("This is a very long text that should be truncated")],
          border="single",
        )
      },
      width=20,
      height=4,
    ),
    VNodeStory::new(
      "edge",
      "many_items",
      fn() {
        @vnode.row(
          [
            @vnode.text("A"),
            @vnode.text("B"),
            @vnode.text("C"),
            @vnode.text("D"),
            @vnode.text("E"),
          ],
          height=1.0,
        )
      },
      width=15,
      height=3,
    ),
    VNodeStory::new(
      "edge",
      "empty_column",
      fn() { @vnode.column([@vnode.column([])], border="single") },
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
        @vnode.column(
          [
            @vnode.column(
              [
                @vnode.column(
                  [@vnode.column([@vnode.text("Deep")], border="single")],
                  border="single",
                ),
              ],
              border="single",
            ),
          ],
          border="single",
        )
      },
      width=20,
      height=9,
    ),
    VNodeStory::new(
      "deep",
      "alternating_5_levels",
      fn() {
        @vnode.column([
          @vnode.row(
            [
              @vnode.column([
                @vnode.row(
                  [
                    @vnode.column([@vnode.text("X")]),
                    @vnode.column([@vnode.text("Y")]),
                  ],
                  height=1.0,
                ),
              ]),
            ],
            height=2.0,
          ),
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
          @vnode.row(
            [@vnode.text(" File  Edit  View ")],
            height=1.0,
            bg="rgb(50,50,50)",
          ),
          @vnode.row(
            [
              @vnode.column(
                [
                  @vnode.text("Explorer"),
                  @vnode.text("─────────"),
                  @vnode.text(" src/"),
                ],
                width=12.0,
              ),
              @vnode.column(
                [
                  @vnode.text("main.mbt"),
                  @vnode.text("fn main {"),
                  @vnode.text("  println()"),
                  @vnode.text("}"),
                ],
                border="single",
                flex_grow=1.0,
              ),
            ],
            flex_grow=1.0,
          ),
          @vnode.row(
            [@vnode.text(" Ln 1, Col 1 | UTF-8")],
            height=1.0,
            bg="rgb(0,122,204)",
          ),
        ])
      },
      width=40,
      height=12,
    ),
    VNodeStory::new(
      "ide",
      "editor_terminal",
      fn() {
        @vnode.column([
          @vnode.column(
            [@vnode.text("// Editor"), @vnode.text("let x = 42")],
            border="single",
            flex_grow=2.0,
          ),
          @vnode.column(
            [@vnode.text("$ moon run"), @vnode.text("Hello, World!")],
            border="single",
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
pub fn form_layout_stories() -> Array[VNodeStory] {
  [
    VNodeStory::new(
      "form",
      "login_dialog",
      fn() {
        @vnode.column(
          [
            @vnode.text("  Login  "),
            @components.divider(),
            @vnode.row(
              [@vnode.text("User: "), @vnode.text("[_______]")],
              height=1.0,
            ),
            @vnode.row(
              [@vnode.text("Pass: "), @vnode.text("[*******]")],
              height=1.0,
            ),
            @components.divider(),
            @vnode.row(
              [@vnode.text(" [Cancel] "), @vnode.text(" [ OK ] ")],
              height=1.0,
            ),
          ],
          border="rounded",
          padding=1.0,
        )
      },
      width=25,
      height=10,
    ),
    VNodeStory::new(
      "form",
      "settings",
      fn() {
        @vnode.column([
          @vnode.text("Settings"),
          @components.divider(),
          @vnode.row(
            [
              @vnode.text("Theme:"),
              @vnode.text("    "),
              @vnode.text("[Dark  ▼]"),
            ],
            height=1.0,
          ),
          @vnode.row(
            [
              @vnode.text("Font:"),
              @vnode.text("     "),
              @vnode.text("[Mono  ▼]"),
            ],
            height=1.0,
          ),
          @vnode.row(
            [@vnode.text("[x]"), @vnode.text(" Auto-save")],
            height=1.0,
          ),
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
          @vnode.column(
            [@vnode.text("Top Pane")],
            border="single",
            flex_grow=1.0,
          ),
          @vnode.column(
            [@vnode.text("Bottom Pane")],
            border="single",
            flex_grow=1.0,
          ),
        ])
      },
      width=20,
      height=8,
    ),
    VNodeStory::new(
      "split",
      "vertical",
      fn() {
        @vnode.row(
          [
            @vnode.column([@vnode.text("Left")], border="single", flex_grow=1.0),
            @vnode.column(
              [@vnode.text("Right")],
              border="single",
              flex_grow=1.0,
            ),
          ],
          height=6.0,
        )
      },
      width=24,
      height=7,
    ),
    VNodeStory::new(
      "split",
      "quad",
      fn() {
        @vnode.column([
          @vnode.row(
            [
              @vnode.column([@vnode.text("TL")], border="single", flex_grow=1.0),
              @vnode.column([@vnode.text("TR")], border="single", flex_grow=1.0),
            ],
            flex_grow=1.0,
          ),
          @vnode.row(
            [
              @vnode.column([@vnode.text("BL")], border="single", flex_grow=1.0),
              @vnode.column([@vnode.text("BR")], border="single", flex_grow=1.0),
            ],
            flex_grow=1.0,
          ),
        ])
      },
      width=20,
      height=8,
    ),
    VNodeStory::new(
      "split",
      "asymmetric",
      fn() {
        @vnode.row(
          [
            @vnode.column([@vnode.text("30%")], border="single", flex_grow=0.3),
            @vnode.column([@vnode.text("70%")], border="single", flex_grow=0.7),
          ],
          height=5.0,
        )
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
        @vnode.row(
          [
            @components.card([@vnode.text("Card 1")]),
            @components.card([@vnode.text("Card 2")]),
            @components.card([@vnode.text("Card 3")]),
          ],
          height=4.0,
          gap=1.0,
        )
      },
      width=35,
      height=5,
    ),
    VNodeStory::new(
      "cards",
      "vertical_list",
      fn() {
        @vnode.column(
          [
            @components.card([@vnode.text("Item 1"), @vnode.text("Description")]),
            @components.card([@vnode.text("Item 2"), @vnode.text("Description")]),
          ],
          gap=1.0,
        )
      },
      width=20,
      height=10,
    ),
    VNodeStory::new(
      "cards",
      "sectioned",
      fn() {
        @components.card([
          @vnode.text("Title", bold=true),
          @components.divider(),
          @vnode.text("Content here"),
          @vnode.text("More content"),
          @components.divider(),
          @vnode.text("[Actions]", fg="rgb(128,128,128)"),
        ])
      },
      width=20,
      height=9,
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
          @vnode.column([@vnode.text("Content")], flex_grow=1.0),
          @vnode.row([@vnode.text("Ready")], height=1.0, bg="rgb(50,50,50)"),
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
          @vnode.column([@vnode.text("Editor")], flex_grow=1.0),
          @vnode.row(
            [
              @vnode.text(" INSERT "),
              @vnode.text("│"),
              @vnode.text(" main.mbt "),
              @vnode.text("│"),
              @vnode.text(" 42:10 "),
            ],
            height=1.0,
            bg="rgb(30,30,30)",
          ),
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
          @vnode.column(
            [@vnode.text("~ VIM"), @vnode.text("~"), @vnode.text("~")],
            flex_grow=1.0,
          ),
          @vnode.row([@vnode.text(":wq")], height=1.0),
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
          @vnode.row(
            [
              @components.meter("1", 0.35, width=15),
              @components.meter("2", 0.62, width=15),
            ],
            height=1.0,
          ),
          @vnode.row(
            [
              @components.meter("3", 0.18, width=15),
              @components.meter("4", 0.91, width=15),
            ],
            height=1.0,
          ),
          @vnode.row(
            [@vnode.text("Mem"), @components.gauge("", 0.42, bar_width=20)],
            height=1.0,
          ),
          @components.divider(),
          @vnode.row(
            [@vnode.text("PID   "), @vnode.text("CPU%  "), @vnode.text("CMD")],
            height=1.0,
            bg="rgb(0,100,0)",
          ),
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
          @vnode.row(
            [@vnode.text("  # general")],
            height=1.0,
            bg="rgb(50,50,50)",
          ),
          @vnode.column(
            [
              @vnode.text("Alice: Hello!"),
              @vnode.text("Bob: Hi there"),
              @vnode.text("Alice: How are you?"),
            ],
            flex_grow=1.0,
            padding=1.0,
          ),
          @vnode.row(
            [@vnode.text("> Type message...")],
            height=1.0,
            border="single",
          ),
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
          @vnode.row(
            [@vnode.text(" /home/user/projects ")],
            height=1.0,
            bg="rgb(40,40,40)",
          ),
          @vnode.row(
            [
              @vnode.column(
                [
                  @vnode.text("Left Pane"),
                  @vnode.text(" docs/"),
                  @vnode.text(" src/"),
                ],
                border="single",
                flex_grow=1.0,
              ),
              @vnode.column(
                [
                  @vnode.text("Right Pane"),
                  @vnode.text(" test/"),
                  @vnode.text(" build/"),
                ],
                border="single",
                flex_grow=1.0,
              ),
            ],
            flex_grow=1.0,
          ),
          @vnode.row([@vnode.text(" 5 items | 1 selected ")], height=1.0),
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
          [
            @vnode.text("cpu", fg="cyan", bold=true),
            @components.meter("C0", 0.45, width=20),
            @components.meter("C1", 0.72, width=20),
            @components.meter("C2", 0.23, width=20),
          ],
          border="rounded",
          border_color="cyan",
          padding=1.0,
          min_width=25.0,
        )
      },
      width=30,
      height=7,
    ),
    VNodeStory::new(
      "dashboard",
      "stats_row",
      fn() {
        @vnode.row(
          [
            @components.stat("CPU", "45%"),
            @components.stat("MEM", "8.2G"),
            @components.stat("SWP", "0.0G"),
          ],
          height=1.0,
        )
      },
      width=40,
      height=3,
    ),
    VNodeStory::new(
      "dashboard",
      "mini",
      fn() {
        @vnode.column([
          @vnode.row(
            [
              @vnode.column(
                [
                  @vnode.text("cpu", fg="cyan"),
                  @components.gauge("", 0.65, bar_width=10),
                ],
                border="rounded",
                border_color="cyan",
                min_width=15.0,
              ),
              @vnode.column(
                [
                  @vnode.text("mem", fg="cyan"),
                  @components.gauge("", 0.42, bar_width=10),
                ],
                border="rounded",
                border_color="cyan",
                min_width=15.0,
              ),
            ],
            height=5.0,
          ),
          @vnode.column(
            [
              @vnode.text("net", fg="cyan"),
              @vnode.text("rx: 1.2 MB/s"),
              @vnode.text("tx: 0.5 MB/s"),
            ],
            border="rounded",
            border_color="cyan",
            min_width=30.0,
          ),
        ])
      },
      width=35,
      height=11,
    ),
  ]
}
