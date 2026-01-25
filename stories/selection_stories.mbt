///|
/// Selection component stories (Radio, Listbox, Select) - vnode version

///|
pub fn radio_stories() -> Array[VNodeStory] {
  [
    VNodeStory::new(
      "radio",
      "single_selected",
      fn() { @components.radio("Option A", true) },
      width=15,
      height=3,
    ),
    VNodeStory::new(
      "radio",
      "single_unselected",
      fn() { @components.radio("Option A", false) },
      width=15,
      height=3,
    ),
    VNodeStory::new(
      "radio",
      "group_first",
      fn() {
        @vnode.column(children=[
          @components.radio("Small", true),
          @components.radio("Medium", false),
          @components.radio("Large", false),
        ])
      },
      width=15,
      height=6,
    ),
    VNodeStory::new(
      "radio",
      "group_middle",
      fn() {
        @vnode.column(children=[
          @components.radio("Small", false),
          @components.radio("Medium", true),
          @components.radio("Large", false),
        ])
      },
      width=15,
      height=6,
    ),
    VNodeStory::new(
      "radio",
      "group_focused",
      fn() {
        @vnode.column(children=[
          @components.radio("Small", true),
          @components.radio("Medium", false),
          @components.radio("Large", false),
        ])
      },
      width=15,
      height=6,
    ),
    VNodeStory::new(
      "radio",
      "group_horizontal",
      fn() {
        @vnode.row(gap=1.0, children=[
          @components.radio("Small", false),
          @components.radio("Medium", true),
          @components.radio("Large", false),
        ])
      },
      width=30,
      height=3,
    ),
  ]
}

///|
pub fn listbox_stories() -> Array[VNodeStory] {
  let items = [
    ("Apple", "apple"),
    ("Banana", "banana"),
    ("Cherry", "cherry"),
    ("Date", "date"),
  ]
  [
    VNodeStory::new(
      "listbox",
      "first_selected",
      fn() { @components.listbox(items, "apple") },
      width=21,
      height=7,
    ),
    VNodeStory::new(
      "listbox",
      "middle_selected",
      fn() { @components.listbox(items, "banana") },
      width=21,
      height=7,
    ),
    VNodeStory::new(
      "listbox",
      "with_focus",
      fn() { @components.listbox(items, "cherry") },
      width=21,
      height=7,
    ),
    VNodeStory::new(
      "listbox",
      "with_disabled",
      fn() {
        @components.listbox(
          [("Enabled", "a"), ("Disabled", "b"), ("Enabled", "c")],
          "a",
        )
      },
      width=21,
      height=5,
    ),
  ]
}

///|
pub fn select_stories() -> Array[VNodeStory] {
  [
    VNodeStory::new(
      "select",
      "closed",
      fn() { @components.combobox_trigger("JavaScript", false) },
      width=21,
      height=5,
    ),
    VNodeStory::new(
      "select",
      "closed_ts",
      fn() { @components.combobox_trigger("TypeScript", false) },
      width=21,
      height=5,
    ),
    VNodeStory::new(
      "select",
      "open",
      fn() {
        @vnode.column(children=[
          @components.combobox_trigger("JavaScript", true),
          @components.combobox_item("JavaScript", true),
          @components.combobox_item("TypeScript", false),
          @components.combobox_item("Python", false),
        ])
      },
      width=21,
      height=13,
    ),
    VNodeStory::new(
      "select",
      "placeholder",
      fn() { @components.combobox_trigger("Choose...", false) },
      width=21,
      height=5,
    ),
  ]
}
