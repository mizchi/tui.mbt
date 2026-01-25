///|
/// Button component stories (vnode version)

///|
pub fn button_stories() -> Array[VNodeStory] {
  [
    // Basic states
    VNodeStory::new("button", "normal", fn() {
      @vnode.button("Submit", state=@vnode.ButtonState::Default, min_width=12.0)
    }),
    VNodeStory::new("button", "hover", fn() {
      // TUI has no hover state, use Focused instead
      @vnode.button("Submit", state=@vnode.ButtonState::Focused, min_width=12.0)
    }),
    VNodeStory::new("button", "pressed", fn() {
      @vnode.button("Submit", state=@vnode.ButtonState::Pressed, min_width=12.0)
    }),
    VNodeStory::new("button", "focused", fn() {
      @vnode.button("Submit", state=@vnode.ButtonState::Focused, min_width=12.0)
    }),
    VNodeStory::new("button", "disabled", fn() {
      @vnode.button("Submit", state=@vnode.ButtonState::Disabled, min_width=12.0)
    }),
    // Variants
    VNodeStory::new("button", "short_label", fn() {
      @vnode.button("OK", state=@vnode.ButtonState::Default, min_width=6.0)
    }),
    VNodeStory::new(
      "button",
      "long_label",
      fn() {
        @vnode.button(
          "Click to Continue",
          state=@vnode.ButtonState::Default,
          min_width=20.0,
        )
      },
      width=25,
    ),
    // Icon button
    VNodeStory::new("button", "icon_normal", fn() {
      @vnode.icon_button("✕", state=@vnode.ButtonState::Default)
    }),
    VNodeStory::new("button", "icon_hover", fn() {
      @vnode.icon_button("✕", state=@vnode.ButtonState::Focused)
    }),
  ]
}
