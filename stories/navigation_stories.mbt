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
    Story::new(
      "tabs",
      "default_first",
      fn() { @components.tabs(items, "home") },
      width=35,
      height=3,
    ),
    Story::new(
      "tabs",
      "default_middle",
      fn() { @components.tabs(items, "profile") },
      width=35,
      height=3,
    ),
    Story::new(
      "tabs",
      "underline_first",
      fn() { @components.tabs_underline(items, "home") },
      width=35,
      height=3,
    ),
    Story::new(
      "tabs",
      "underline_middle",
      fn() { @components.tabs_underline(items, "profile") },
      width=35,
      height=3,
    ),
    Story::new(
      "tabs",
      "boxed_first",
      fn() { @components.tabs_boxed(items, "home") },
      width=35,
      height=5,
    ),
    Story::new(
      "tabs",
      "boxed_middle",
      fn() { @components.tabs_boxed(items, "profile") },
      width=35,
      height=5,
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
      width=30,
      height=8,
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
      width=30,
      height=15,
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
      width=30,
      height=15,
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
      width=20,
      height=15,
    ),
    Story::new(
      "menu",
      "first_focused",
      fn() { @components.menu(items, focused_id="cut") },
      width=20,
      height=15,
    ),
    Story::new(
      "menu",
      "middle_focused",
      fn() { @components.menu(items, focused_id="copy") },
      width=20,
      height=15,
    ),
    Story::new(
      "menu",
      "disabled_focused",
      fn() { @components.menu(items, focused_id="delete") },
      width=20,
      height=15,
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
      width=20,
      height=6,
    ),
    Story::new(
      "context_menu",
      "focused",
      fn() { @components.context_menu(items, focused_id="refresh") },
      width=20,
      height=6,
    ),
  ]
}
