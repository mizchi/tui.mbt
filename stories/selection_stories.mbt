///|
/// Selection component stories (Radio, Listbox, Select) - vnode version

///|
pub fn radio_stories() -> Array[VNodeStory] {
  [
    VNodeStory::new(
      "radio",
      "single_selected",
      fn() { @vnode.radio("Option A", true) },
      width=15,
      height=3,
    ),
    VNodeStory::new(
      "radio",
      "single_unselected",
      fn() { @vnode.radio("Option A", false) },
      width=15,
      height=3,
    ),
    VNodeStory::new(
      "radio",
      "group_first",
      fn() {
        @vnode.column([
          @vnode.radio("Small", true),
          @vnode.radio("Medium", false),
          @vnode.radio("Large", false),
        ])
      },
      width=15,
      height=6,
    ),
    VNodeStory::new(
      "radio",
      "group_middle",
      fn() {
        @vnode.column([
          @vnode.radio("Small", false),
          @vnode.radio("Medium", true),
          @vnode.radio("Large", false),
        ])
      },
      width=15,
      height=6,
    ),
    VNodeStory::new(
      "radio",
      "group_focused",
      fn() {
        @vnode.column([
          @vnode.radio("Small", true),
          @vnode.radio("Medium", false),
          @vnode.radio("Large", false),
        ])
      },
      width=15,
      height=6,
    ),
    VNodeStory::new(
      "radio",
      "group_horizontal",
      fn() {
        @vnode.row([
          @vnode.radio("Small", false),
          @vnode.radio("Medium", true),
          @vnode.radio("Large", false),
        ], gap=1.0)
      },
      width=30,
      height=3,
    ),
  ]
}

///|
pub fn listbox_stories() -> Array[VNodeStory] {
  let items = [("Apple", "apple"), ("Banana", "banana"), ("Cherry", "cherry"), ("Date", "date")]
  [
    VNodeStory::new(
      "listbox",
      "first_selected",
      fn() { @vnode.listbox(items, "apple") },
      width=21,
      height=7,
    ),
    VNodeStory::new(
      "listbox",
      "middle_selected",
      fn() { @vnode.listbox(items, "banana") },
      width=21,
      height=7,
    ),
    VNodeStory::new(
      "listbox",
      "with_focus",
      fn() { @vnode.listbox(items, "cherry") },
      width=21,
      height=7,
    ),
    VNodeStory::new(
      "listbox",
      "with_disabled",
      fn() {
        @vnode.listbox([("Enabled", "a"), ("Disabled", "b"), ("Enabled", "c")], "a")
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
      fn() { @vnode.combobox_trigger("JavaScript", false) },
      width=21,
      height=5,
    ),
    VNodeStory::new(
      "select",
      "closed_ts",
      fn() { @vnode.combobox_trigger("TypeScript", false) },
      width=21,
      height=5,
    ),
    VNodeStory::new(
      "select",
      "open",
      fn() {
        @vnode.column([
          @vnode.combobox_trigger("JavaScript", true),
          @vnode.combobox_item("JavaScript", true),
          @vnode.combobox_item("TypeScript", false),
          @vnode.combobox_item("Python", false),
        ])
      },
      width=21,
      height=13,
    ),
    VNodeStory::new(
      "select",
      "placeholder",
      fn() { @vnode.combobox_trigger("Choose...", false) },
      width=21,
      height=5,
    ),
  ]
}
