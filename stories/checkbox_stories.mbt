///|
/// Checkbox and Switch component stories

///|
pub fn checkbox_stories() -> Array[Story] {
  [
    // Checkbox
    Story::new(
      "checkbox",
      "unchecked",
      fn() { @components.checkbox(false) },
      width=10,
      height=3,
    ),
    Story::new(
      "checkbox",
      "checked",
      fn() { @components.checkbox(true) },
      width=10,
      height=3,
    ),
    // Labeled checkbox
    Story::new(
      "checkbox",
      "labeled_unchecked",
      fn() { @components.labeled_checkbox("Accept terms", false) },
      width=20,
      height=3,
    ),
    Story::new(
      "checkbox",
      "labeled_checked",
      fn() { @components.labeled_checkbox("Accept terms", true) },
      width=20,
      height=3,
    ),
    Story::new(
      "checkbox",
      "labeled_right",
      fn() {
        @components.labeled_checkbox(
          "Remember me",
          true,
          label_position=@components.LabelPosition::Right,
        )
      },
      width=20,
      height=3,
    ),
    Story::new(
      "checkbox",
      "focused",
      fn() { @components.checkbox(true, focused=true) },
      width=10,
      height=3,
    ),
  ]
}

///|
pub fn switch_stories() -> Array[Story] {
  [
    // Switch states
    Story::new(
      "switch",
      "off",
      fn() { @components.switch(false) },
      width=10,
      height=3,
    ),
    Story::new(
      "switch",
      "on",
      fn() { @components.switch(true) },
      width=10,
      height=3,
    ),
    Story::new(
      "switch",
      "disabled_off",
      fn() { @components.switch(false, disabled=true) },
      width=10,
      height=3,
    ),
    Story::new(
      "switch",
      "disabled_on",
      fn() { @components.switch(true, disabled=true) },
      width=10,
      height=3,
    ),
    Story::new(
      "switch",
      "focused",
      fn() { @components.switch(true, focused=true) },
      width=10,
      height=3,
    ),
    // Labeled switch
    Story::new(
      "switch",
      "labeled_off",
      fn() { @components.labeled_switch("Dark mode", false) },
      width=20,
      height=3,
    ),
    Story::new(
      "switch",
      "labeled_on",
      fn() { @components.labeled_switch("Dark mode", true) },
      width=20,
      height=3,
    ),
  ]
}
