///|
/// Feedback component stories (Progress, Spinner, Loading)

///|
pub fn progress_stories() -> Array[Story] {
  [
    Story::new(
      "progress",
      "0_percent",
      fn() { @components.progress_bar(0.0, 20) },
      width=25,
      height=3,
    ),
    Story::new(
      "progress",
      "25_percent",
      fn() { @components.progress_bar(0.25, 20) },
      width=25,
      height=3,
    ),
    Story::new(
      "progress",
      "50_percent",
      fn() { @components.progress_bar(0.5, 20) },
      width=25,
      height=3,
    ),
    Story::new(
      "progress",
      "75_percent",
      fn() { @components.progress_bar(0.75, 20) },
      width=25,
      height=3,
    ),
    Story::new(
      "progress",
      "100_percent",
      fn() { @components.progress_bar(1.0, 20) },
      width=25,
      height=3,
    ),
    Story::new(
      "progress",
      "with_label",
      fn() { @components.progress_bar(0.5, 20, show_percent=true) },
      width=25,
      height=3,
    ),
    // Different styles
    Story::new(
      "progress",
      "style_blocks",
      fn() {
        @components.progress_bar(
          0.5,
          20,
          style=@components.ProgressStyle::Blocks,
        )
      },
      width=25,
      height=3,
    ),
    Story::new(
      "progress",
      "style_dots",
      fn() {
        @components.progress_bar(0.5, 20, style=@components.ProgressStyle::Dots)
      },
      width=25,
      height=3,
    ),
  ]
}

///|
pub fn spinner_stories() -> Array[Story] {
  [
    Story::new(
      "spinner",
      "frame_0",
      fn() { @components.spinner(0) },
      width=10,
      height=3,
    ),
    Story::new(
      "spinner",
      "frame_1",
      fn() { @components.spinner(1) },
      width=10,
      height=3,
    ),
    Story::new(
      "spinner",
      "frame_2",
      fn() { @components.spinner(2) },
      width=10,
      height=3,
    ),
    Story::new(
      "spinner",
      "with_label",
      fn() { @components.spinner(0, label="Loading...") },
      width=20,
      height=3,
    ),
  ]
}

///|
pub fn loading_dots_stories() -> Array[Story] {
  [
    Story::new(
      "loading_dots",
      "frame_0",
      fn() { @components.loading_dots(0) },
      width=15,
      height=3,
    ),
    Story::new(
      "loading_dots",
      "frame_1",
      fn() { @components.loading_dots(1) },
      width=15,
      height=3,
    ),
    Story::new(
      "loading_dots",
      "frame_2",
      fn() { @components.loading_dots(2) },
      width=15,
      height=3,
    ),
    Story::new(
      "loading_dots",
      "with_label",
      fn() { @components.loading_dots(0, label="Processing") },
      width=20,
      height=3,
    ),
  ]
}
