///|
/// Selection component stories (Radio, Listbox, Select)

///|
pub fn radio_stories() -> Array[Story] {
  let options = [
    @components.RadioOption::{ id: "small", label: "Small" },
    @components.RadioOption::{ id: "medium", label: "Medium" },
    @components.RadioOption::{ id: "large", label: "Large" },
  ]
  [
    Story::new(
      "radio",
      "single_selected",
      fn() { @components.radio("Option A", true) },
      width=15,
      height=3,
    ),
    Story::new(
      "radio",
      "single_unselected",
      fn() { @components.radio("Option A", false) },
      width=15,
      height=3,
    ),
    Story::new(
      "radio",
      "group_first",
      fn() { @components.radiogroup(options, "small") },
      width=15,
      height=6,
    ),
    Story::new(
      "radio",
      "group_middle",
      fn() { @components.radiogroup(options, "medium") },
      width=15,
      height=6,
    ),
    Story::new(
      "radio",
      "group_focused",
      fn() { @components.radiogroup(options, "small", focused_id="medium") },
      width=15,
      height=6,
    ),
    Story::new(
      "radio",
      "group_horizontal",
      fn() {
        @components.radiogroup(
          options,
          "medium",
          orientation=@components.RadioOrientation::Horizontal,
        )
      },
      width=30,
      height=3,
    ),
  ]
}

///|
pub fn listbox_stories() -> Array[Story] {
  let options = [
    @components.listbox_option("apple", "Apple"),
    @components.listbox_option("banana", "Banana"),
    @components.listbox_option("cherry", "Cherry"),
    @components.listbox_option("date", "Date"),
  ]
  [
    Story::new(
      "listbox",
      "first_selected",
      fn() { @components.listbox(options, "apple", max_height=4) },
      width=21,
      height=7,
    ),
    Story::new(
      "listbox",
      "middle_selected",
      fn() { @components.listbox(options, "banana", max_height=4) },
      width=21,
      height=7,
    ),
    Story::new(
      "listbox",
      "with_focus",
      fn() {
        @components.listbox(options, "apple", focused_id="cherry", max_height=4)
      },
      width=21,
      height=7,
    ),
    Story::new(
      "listbox",
      "with_disabled",
      fn() {
        @components.listbox(
          [
            @components.listbox_option("a", "Enabled"),
            @components.ListboxOption::{
              id: "b",
              label: "Disabled",
              disabled: true,
            },
            @components.listbox_option("c", "Enabled"),
          ],
          "a",
          max_height=3,
        )
      },
      width=21,
      height=5,
    ),
  ]
}

///|
pub fn select_stories() -> Array[Story] {
  let options = [
    @components.ComboboxOption::{ id: "js", label: "JavaScript" },
    @components.ComboboxOption::{ id: "ts", label: "TypeScript" },
    @components.ComboboxOption::{ id: "py", label: "Python" },
  ]
  [
    Story::new(
      "select",
      "closed",
      fn() { @components.select(options, "js", open=false) },
      width=21,
      height=5,
    ),
    Story::new(
      "select",
      "closed_ts",
      fn() { @components.select(options, "ts", open=false) },
      width=21,
      height=5,
    ),
    Story::new(
      "select",
      "open",
      fn() { @components.select(options, "js", open=true) },
      width=21,
      height=13,
    ),
    Story::new(
      "select",
      "placeholder",
      fn() {
        @components.select(options, "", placeholder="Choose...", open=false)
      },
      width=21,
      height=5,
    ),
  ]
}
