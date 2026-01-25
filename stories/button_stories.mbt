///|
/// Button component stories (vnode version)

///|
pub fn button_stories() -> Array[VNodeStory] {
  [
    // Basic states
    VNodeStory::new("button", "normal", fn() {
      @components.button(
        "Submit",
        state=@headless.ButtonState::Default,
        min_width=12.0,
      )
    }),
    VNodeStory::new("button", "hover", fn() {
      // TUI has no hover state, use Focused instead
      @components.button(
        "Submit",
        state=@headless.ButtonState::Focused,
        min_width=12.0,
      )
    }),
    VNodeStory::new("button", "pressed", fn() {
      @components.button(
        "Submit",
        state=@headless.ButtonState::Pressed,
        min_width=12.0,
      )
    }),
    VNodeStory::new("button", "focused", fn() {
      @components.button(
        "Submit",
        state=@headless.ButtonState::Focused,
        min_width=12.0,
      )
    }),
    VNodeStory::new("button", "disabled", fn() {
      @components.button(
        "Submit",
        state=@headless.ButtonState::Disabled,
        min_width=12.0,
      )
    }),
    // Variants
    VNodeStory::new("button", "short_label", fn() {
      @components.button(
        "OK",
        state=@headless.ButtonState::Default,
        min_width=6.0,
      )
    }),
    VNodeStory::new(
      "button",
      "long_label",
      fn() {
        @components.button(
          "Click to Continue",
          state=@headless.ButtonState::Default,
          min_width=20.0,
        )
      },
      width=25,
    ),
    // Icon button
    VNodeStory::new("button", "icon_normal", fn() {
      @components.icon_button("✕", state=@headless.ButtonState::Default)
    }),
    VNodeStory::new("button", "icon_hover", fn() {
      @components.icon_button("✕", state=@headless.ButtonState::Focused)
    }),
  ]
}
