///|
/// Checkbox and Switch component stories (vnode version)

///|
pub fn checkbox_stories() -> Array[VNodeStory] {
  [
    // Checkbox
    VNodeStory::new(
      "checkbox",
      "unchecked",
      fn() { @vnode.row([@vnode.text("[ ]")]) },
      width=10,
      height=3,
    ),
    VNodeStory::new(
      "checkbox",
      "checked",
      fn() { @vnode.row([@vnode.text("[x]", fg="cyan")]) },
      width=10,
      height=3,
    ),
    // Labeled checkbox
    VNodeStory::new(
      "checkbox",
      "labeled_unchecked",
      fn() { @vnode.checkbox("Accept terms", false) },
      width=20,
      height=3,
    ),
    VNodeStory::new(
      "checkbox",
      "labeled_checked",
      fn() { @vnode.checkbox("Accept terms", true) },
      width=20,
      height=3,
    ),
    VNodeStory::new(
      "checkbox",
      "labeled_right",
      fn() { @vnode.checkbox("Remember me", true) },
      width=20,
      height=3,
    ),
    VNodeStory::new(
      "checkbox",
      "focused",
      fn() { @vnode.checkbox("", true, focused=true) },
      width=10,
      height=3,
    ),
  ]
}

///|
pub fn switch_stories() -> Array[VNodeStory] {
  [
    // Switch states
    VNodeStory::new(
      "switch",
      "off",
      fn() { @vnode.switch(false, "") },
      width=10,
      height=3,
    ),
    VNodeStory::new(
      "switch",
      "on",
      fn() { @vnode.switch(true, "") },
      width=10,
      height=3,
    ),
    VNodeStory::new(
      "switch",
      "disabled_off",
      fn() { @vnode.switch(false, "", disabled=true) },
      width=10,
      height=3,
    ),
    VNodeStory::new(
      "switch",
      "disabled_on",
      fn() { @vnode.switch(true, "", disabled=true) },
      width=10,
      height=3,
    ),
    VNodeStory::new(
      "switch",
      "focused",
      fn() { @vnode.switch(true, "") },
      width=10,
      height=3,
    ),
    // Labeled switch
    VNodeStory::new(
      "switch",
      "labeled_off",
      fn() { @vnode.switch(false, "Dark mode") },
      width=20,
      height=3,
    ),
    VNodeStory::new(
      "switch",
      "labeled_on",
      fn() { @vnode.switch(true, "Dark mode") },
      width=20,
      height=3,
    ),
  ]
}
