///|
/// Input component stories (Input, Textarea) - vnode version

///|
pub fn input_stories() -> Array[VNodeStory] {
  [
    // States
    VNodeStory::new(
      "input",
      "idle",
      fn() { @vnode.input("value", state=@vnode.InputState::Idle, min_width=20.0) },
      width=25,
      height=5,
    ),
    VNodeStory::new(
      "input",
      "focused",
      fn() { @vnode.input("value", state=@vnode.InputState::Focused, min_width=20.0) },
      width=25,
      height=5,
    ),
    VNodeStory::new(
      "input",
      "editing",
      fn() { @vnode.input("value", state=@vnode.InputState::Editing, min_width=20.0) },
      width=25,
      height=5,
    ),
    VNodeStory::new(
      "input",
      "disabled",
      fn() { @vnode.input("value", state=@vnode.InputState::Disabled, min_width=20.0) },
      width=25,
      height=5,
    ),
    // With placeholder
    VNodeStory::new(
      "input",
      "placeholder",
      fn() {
        @vnode.input("", placeholder="Enter name...", state=@vnode.InputState::Idle, min_width=20.0)
      },
      width=25,
      height=5,
    ),
    // Plain input (no border)
    VNodeStory::new(
      "input",
      "plain_idle",
      fn() { @vnode.input_plain("text", state=@vnode.InputState::Idle) },
      width=15,
      height=3,
    ),
    VNodeStory::new(
      "input",
      "plain_focused",
      fn() { @vnode.input_plain("text", state=@vnode.InputState::Focused) },
      width=15,
      height=3,
    ),
  ]
}

///|
pub fn textarea_stories() -> Array[VNodeStory] {
  [
    VNodeStory::new(
      "textarea",
      "idle",
      fn() {
        @vnode.textarea("Line 1\nLine 2", rows=3, state=@vnode.InputState::Idle, min_width=25.0)
      },
      width=31,
      height=9,
    ),
    VNodeStory::new(
      "textarea",
      "focused",
      fn() {
        @vnode.textarea("Line 1\nLine 2", rows=3, state=@vnode.InputState::Focused, min_width=25.0)
      },
      width=31,
      height=9,
    ),
    VNodeStory::new(
      "textarea",
      "editing",
      fn() {
        @vnode.textarea("Line 1\nLine 2", rows=3, state=@vnode.InputState::Editing, min_width=25.0)
      },
      width=31,
      height=9,
    ),
    VNodeStory::new(
      "textarea",
      "placeholder",
      fn() {
        @vnode.textarea("", rows=3, placeholder="Enter description...", state=@vnode.InputState::Idle, min_width=25.0)
      },
      width=31,
      height=9,
    ),
  ]
}
