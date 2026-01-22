///|
/// Input component stories (Input, Textarea)
/// Note: Input text content uses texts.set() internally,
/// so the actual text value may not be visible in plain output.
/// These stories test structure and state styling.

///|
pub fn input_stories() -> Array[Story] {
  [
    // States
    Story::new(
      "input",
      "idle",
      fn() {
        @components.input(
          "value",
          state=@components.InputState::Idle,
          min_width=20.0,
        )
      },
      width=25,
      height=5,
    ),
    Story::new(
      "input",
      "focused",
      fn() {
        @components.input(
          "value",
          state=@components.InputState::Focused,
          min_width=20.0,
        )
      },
      width=25,
      height=5,
    ),
    Story::new(
      "input",
      "editing",
      fn() {
        @components.input(
          "value",
          state=@components.InputState::Editing,
          min_width=20.0,
        )
      },
      width=25,
      height=5,
    ),
    Story::new(
      "input",
      "disabled",
      fn() {
        @components.input(
          "value",
          state=@components.InputState::Disabled,
          min_width=20.0,
        )
      },
      width=25,
      height=5,
    ),
    // With placeholder
    Story::new(
      "input",
      "placeholder",
      fn() {
        @components.input(
          "",
          placeholder="Enter name...",
          state=@components.InputState::Idle,
          min_width=20.0,
        )
      },
      width=25,
      height=5,
    ),
    // Plain input (no border)
    Story::new(
      "input",
      "plain_idle",
      fn() {
        @components.input_plain("text", state=@components.InputState::Idle)
      },
      width=15,
      height=3,
    ),
    Story::new(
      "input",
      "plain_focused",
      fn() {
        @components.input_plain(
          "text",
          state=@components.InputState::Focused,
          underline=true,
        )
      },
      width=15,
      height=3,
    ),
  ]
}

///|
pub fn textarea_stories() -> Array[Story] {
  [
    Story::new(
      "textarea",
      "idle",
      fn() {
        @components.textarea(
          "Line 1\nLine 2",
          rows=3,
          state=@components.TextareaState::Idle,
          min_width=25.0,
        )
      },
      width=31,
      height=9,
    ),
    Story::new(
      "textarea",
      "focused",
      fn() {
        @components.textarea(
          "Line 1\nLine 2",
          rows=3,
          state=@components.TextareaState::Focused,
          min_width=25.0,
        )
      },
      width=31,
      height=9,
    ),
    Story::new(
      "textarea",
      "editing",
      fn() {
        @components.textarea(
          "Line 1\nLine 2",
          rows=3,
          state=@components.TextareaState::Editing,
          min_width=25.0,
        )
      },
      width=31,
      height=9,
    ),
    Story::new(
      "textarea",
      "placeholder",
      fn() {
        @components.textarea(
          "",
          rows=3,
          placeholder="Enter description...",
          state=@components.TextareaState::Idle,
          min_width=25.0,
        )
      },
      width=31,
      height=9,
    ),
  ]
}
