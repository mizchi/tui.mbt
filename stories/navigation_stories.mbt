///|
/// Navigation component stories (Tabs, Accordion, Menu) - vnode version

///|
pub fn tabs_stories() -> Array[VNodeStory] {
  let tabs = [
    ("Home", "home"),
    ("Profile", "profile"),
    ("Settings", "settings"),
  ]
  [
    VNodeStory::new(
      "tabs",
      "default_home",
      fn() {
        @vnode.column(
          [
            @components.tab_bar(tabs, "home"),
            @vnode.row([@vnode.text("Welcome to Home")], padding=1.0),
          ],
          border="rounded",
          border_color="rgb(60,60,80)",
        )
      },
      width=41,
      height=9,
    ),
    VNodeStory::new(
      "tabs",
      "default_profile",
      fn() {
        @vnode.column(
          [
            @components.tab_bar(tabs, "profile"),
            @vnode.row([@vnode.text("User Profile")], padding=1.0),
          ],
          border="rounded",
          border_color="rgb(60,60,80)",
        )
      },
      width=41,
      height=9,
    ),
    VNodeStory::new(
      "tabs",
      "default_focused",
      fn() {
        @vnode.column(
          [
            @components.tab_bar(tabs, "home"),
            @vnode.row([@vnode.text("Home (Settings focused)")], padding=1.0),
          ],
          border="rounded",
          border_color="rgb(60,60,80)",
        )
      },
      width=41,
      height=9,
    ),
    VNodeStory::new(
      "tabs",
      "underline",
      fn() {
        @vnode.column([
          @components.tab_bar(tabs, "home"),
          @vnode.row([@vnode.text("Underline style content")], padding=1.0),
        ])
      },
      width=41,
      height=11,
    ),
    VNodeStory::new(
      "tabs",
      "boxed",
      fn() {
        @vnode.column([
          @components.tab_bar(tabs, "profile"),
          @vnode.row([@vnode.text("Boxed style content")], padding=1.0),
        ])
      },
      width=41,
      height=11,
    ),
  ]
}

///|
pub fn accordion_stories() -> Array[VNodeStory] {
  [
    VNodeStory::new(
      "accordion",
      "collapsed",
      fn() {
        @vnode.column([
          @components.accordion_section("Section 1", @vnode.text("Content 1"), false),
          @components.accordion_section("Section 2", @vnode.text("Content 2"), false),
        ])
      },
      width=31,
      height=7,
    ),
    VNodeStory::new(
      "accordion",
      "first_expanded",
      fn() {
        @vnode.column([
          @components.accordion_section("Section 1", @vnode.text("Content 1"), true),
          @components.accordion_section("Section 2", @vnode.text("Content 2"), false),
        ])
      },
      width=31,
      height=13,
    ),
    VNodeStory::new(
      "accordion",
      "second_expanded",
      fn() {
        @vnode.column([
          @components.accordion_section("Section 1", @vnode.text("Content 1"), false),
          @components.accordion_section("Section 2", @vnode.text("Content 2"), true),
        ])
      },
      width=31,
      height=13,
    ),
  ]
}

///|
pub fn menu_stories() -> Array[VNodeStory] {
  [
    VNodeStory::new(
      "menu",
      "no_focus",
      fn() {
        @vnode.column(
          [
            @components.menu_item("Cut", false),
            @components.menu_item("Copy", false),
            @components.menu_item("Paste", false),
            @components.menu_divider(),
            @components.menu_item("Delete", false, disabled=true),
          ],
          border="single",
          border_color="rgb(60,60,80)",
          bg="rgb(40,40,50)",
        )
      },
      width=21,
      height=13,
    ),
    VNodeStory::new(
      "menu",
      "first_focused",
      fn() {
        @vnode.column(
          [
            @components.menu_item("Cut", true),
            @components.menu_item("Copy", false),
            @components.menu_item("Paste", false),
            @components.menu_divider(),
            @components.menu_item("Delete", false, disabled=true),
          ],
          border="single",
          border_color="rgb(60,60,80)",
          bg="rgb(40,40,50)",
        )
      },
      width=21,
      height=13,
    ),
    VNodeStory::new(
      "menu",
      "middle_focused",
      fn() {
        @vnode.column(
          [
            @components.menu_item("Cut", false),
            @components.menu_item("Copy", true),
            @components.menu_item("Paste", false),
            @components.menu_divider(),
            @components.menu_item("Delete", false, disabled=true),
          ],
          border="single",
          border_color="rgb(60,60,80)",
          bg="rgb(40,40,50)",
        )
      },
      width=21,
      height=13,
    ),
    VNodeStory::new(
      "menu",
      "disabled_focused",
      fn() {
        @vnode.column(
          [
            @components.menu_item("Cut", false),
            @components.menu_item("Copy", false),
            @components.menu_item("Paste", false),
            @components.menu_divider(),
            @components.menu_item("Delete", true, disabled=true),
          ],
          border="single",
          border_color="rgb(60,60,80)",
          bg="rgb(40,40,50)",
        )
      },
      width=21,
      height=13,
    ),
  ]
}

///|
pub fn context_menu_stories() -> Array[VNodeStory] {
  [
    VNodeStory::new(
      "context_menu",
      "default",
      fn() {
        @vnode.column(
          [
            @components.menu_item("Refresh", false),
            @components.menu_item("Inspect", false),
          ],
          border="single",
          border_color="rgb(60,60,80)",
          bg="rgb(40,40,50)",
        )
      },
      width=21,
      height=7,
    ),
    VNodeStory::new(
      "context_menu",
      "focused",
      fn() {
        @vnode.column(
          [
            @components.menu_item("Refresh", true),
            @components.menu_item("Inspect", false),
          ],
          border="single",
          border_color="rgb(60,60,80)",
          bg="rgb(40,40,50)",
        )
      },
      width=21,
      height=7,
    ),
  ]
}
