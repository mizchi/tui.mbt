///|
/// Navigation component stories (Tabs, Accordion, Menu)

///|
pub fn tabs_stories() -> Array[Story] {
  let items = [
    @components.TabItem::{ id: "home", label: "Home" },
    @components.TabItem::{ id: "profile", label: "Profile" },
    @components.TabItem::{ id: "settings", label: "Settings" },
  ]
  [
    // Default tabs with content (odd dimensions for better centering)
    Story::new(
      "tabs",
      "default_home",
      fn() {
        @components.tab_container(
          items,
          "home",
          @components.text("Welcome to Home"),
        )
      },
      width=41,
      height=9,
    ),
    Story::new(
      "tabs",
      "default_profile",
      fn() {
        @components.tab_container(
          items,
          "profile",
          @components.text("User Profile"),
        )
      },
      width=41,
      height=9,
    ),
    Story::new(
      "tabs",
      "default_focused",
      fn() {
        @components.tab_container(
          items,
          "home",
          @components.text("Home (Settings focused)"),
          focused_id="settings",
        )
      },
      width=41,
      height=9,
    ),
    // Underline style
    Story::new(
      "tabs",
      "underline",
      fn() {
        @components.column([
          @components.tabs_underline(items, "home"),
          @components.tab_panel(@components.text("Underline style content")),
        ])
      },
      width=41,
      height=11,
    ),
    // Boxed style
    Story::new(
      "tabs",
      "boxed",
      fn() {
        @components.column([
          @components.tabs_boxed(items, "profile"),
          @components.tab_panel(@components.text("Boxed style content")),
        ])
      },
      width=41,
      height=11,
    ),
  ]
}

///|
pub fn accordion_stories() -> Array[Story] {
  [
    Story::new(
      "accordion",
      "collapsed",
      fn() {
        @components.accordion([
          @components.AccordionItem::{
            id: "sec1",
            title: "Section 1",
            content: @components.text("Content 1"),
            expanded: false,
          },
          @components.AccordionItem::{
            id: "sec2",
            title: "Section 2",
            content: @components.text("Content 2"),
            expanded: false,
          },
        ])
      },
      width=31,
      height=7,
    ),
    Story::new(
      "accordion",
      "first_expanded",
      fn() {
        @components.accordion([
          @components.AccordionItem::{
            id: "sec1",
            title: "Section 1",
            content: @components.text("Content 1"),
            expanded: true,
          },
          @components.AccordionItem::{
            id: "sec2",
            title: "Section 2",
            content: @components.text("Content 2"),
            expanded: false,
          },
        ])
      },
      width=31,
      height=13,
    ),
    Story::new(
      "accordion",
      "second_expanded",
      fn() {
        @components.accordion([
          @components.AccordionItem::{
            id: "sec1",
            title: "Section 1",
            content: @components.text("Content 1"),
            expanded: false,
          },
          @components.AccordionItem::{
            id: "sec2",
            title: "Section 2",
            content: @components.text("Content 2"),
            expanded: true,
          },
        ])
      },
      width=31,
      height=13,
    ),
  ]
}

///|
pub fn menu_stories() -> Array[Story] {
  let items = [
    @components.menu_item("cut", "Cut"),
    @components.menu_item("copy", "Copy"),
    @components.menu_item("paste", "Paste"),
    @components.menu_separator(),
    @components.menu_item("delete", "Delete", disabled=true),
  ]
  [
    Story::new(
      "menu",
      "no_focus",
      fn() { @components.menu(items) },
      width=21,
      height=13,
    ),
    Story::new(
      "menu",
      "first_focused",
      fn() { @components.menu(items, focused_id="cut") },
      width=21,
      height=13,
    ),
    Story::new(
      "menu",
      "middle_focused",
      fn() { @components.menu(items, focused_id="copy") },
      width=21,
      height=13,
    ),
    Story::new(
      "menu",
      "disabled_focused",
      fn() { @components.menu(items, focused_id="delete") },
      width=21,
      height=13,
    ),
  ]
}

///|
pub fn context_menu_stories() -> Array[Story] {
  let items = [
    @components.menu_item("refresh", "Refresh"),
    @components.menu_item("inspect", "Inspect"),
  ]
  [
    Story::new(
      "context_menu",
      "default",
      fn() { @components.context_menu(items) },
      width=21,
      height=7,
    ),
    Story::new(
      "context_menu",
      "focused",
      fn() { @components.context_menu(items, focused_id="refresh") },
      width=21,
      height=7,
    ),
  ]
}
