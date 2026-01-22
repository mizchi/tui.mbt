///|
/// Button component stories

///|
pub fn button_stories() -> Array[Story] {
  [
    // Basic states
    Story::new("button", "normal", fn() {
      @components.button(
        "Submit",
        state=@components.ButtonState::Normal,
        min_width=12.0,
      )
    }),
    Story::new("button", "hover", fn() {
      @components.button(
        "Submit",
        state=@components.ButtonState::Hover,
        min_width=12.0,
      )
    }),
    Story::new("button", "pressed", fn() {
      @components.button(
        "Submit",
        state=@components.ButtonState::Pressed,
        min_width=12.0,
      )
    }),
    Story::new("button", "focused", fn() {
      @components.button(
        "Submit",
        state=@components.ButtonState::Focused,
        min_width=12.0,
      )
    }),
    Story::new("button", "disabled", fn() {
      @components.button(
        "Submit",
        state=@components.ButtonState::Disabled,
        min_width=12.0,
      )
    }),
    // Variants
    Story::new("button", "short_label", fn() {
      @components.button(
        "OK",
        state=@components.ButtonState::Normal,
        min_width=6.0,
      )
    }),
    Story::new(
      "button",
      "long_label",
      fn() {
        @components.button(
          "Click to Continue",
          state=@components.ButtonState::Normal,
          min_width=20.0,
        )
      },
      width=25,
    ),
    // Text button
    Story::new("button", "text_normal", fn() {
      @components.text_button("Link", state=@components.ButtonState::Normal)
    }),
    Story::new("button", "text_hover", fn() {
      @components.text_button("Link", state=@components.ButtonState::Hover)
    }),
    // Icon button
    Story::new("button", "icon_normal", fn() {
      @components.icon_button("✕", state=@components.ButtonState::Normal)
    }),
    Story::new("button", "icon_hover", fn() {
      @components.icon_button("✕", state=@components.ButtonState::Hover)
    }),
  ]
}
