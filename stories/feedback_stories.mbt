///|
/// Feedback component stories (Progress, Spinner, Loading) - vnode version

///|
pub fn progress_stories() -> Array[VNodeStory] {
  [
    VNodeStory::new(
      "progress",
      "0_percent",
      fn() { @components.progress_bar(0.0, width=20) },
      width=25,
      height=3,
    ),
    VNodeStory::new(
      "progress",
      "25_percent",
      fn() { @components.progress_bar(0.25, width=20) },
      width=25,
      height=3,
    ),
    VNodeStory::new(
      "progress",
      "50_percent",
      fn() { @components.progress_bar(0.5, width=20) },
      width=25,
      height=3,
    ),
    VNodeStory::new(
      "progress",
      "75_percent",
      fn() { @components.progress_bar(0.75, width=20) },
      width=25,
      height=3,
    ),
    VNodeStory::new(
      "progress",
      "100_percent",
      fn() { @components.progress_bar(1.0, width=20) },
      width=25,
      height=3,
    ),
    VNodeStory::new(
      "progress",
      "with_label",
      fn() { @components.progress_bar(0.5, width=20, show_percent=true) },
      width=25,
      height=3,
    ),
    VNodeStory::new(
      "progress",
      "style_blocks",
      fn() { @components.progress_bar(0.5, width=20) },
      width=25,
      height=3,
    ),
    VNodeStory::new(
      "progress",
      "style_dots",
      fn() { @components.progress_bar(0.5, width=20) },
      width=25,
      height=3,
    ),
  ]
}

///|
pub fn spinner_stories() -> Array[VNodeStory] {
  [
    VNodeStory::new(
      "spinner",
      "frame_0",
      fn() { @components.spinner(0) },
      width=10,
      height=3,
    ),
    VNodeStory::new(
      "spinner",
      "frame_1",
      fn() { @components.spinner(1) },
      width=10,
      height=3,
    ),
    VNodeStory::new(
      "spinner",
      "frame_2",
      fn() { @components.spinner(2) },
      width=10,
      height=3,
    ),
    VNodeStory::new(
      "spinner",
      "with_label",
      fn() { @components.spinner(0, label="Loading...") },
      width=20,
      height=3,
    ),
  ]
}

///|
pub fn loading_dots_stories() -> Array[VNodeStory] {
  [
    VNodeStory::new(
      "loading_dots",
      "frame_0",
      fn() { @vnode.text(".  ", fg="cyan") },
      width=15,
      height=3,
    ),
    VNodeStory::new(
      "loading_dots",
      "frame_1",
      fn() { @vnode.text(".. ", fg="cyan") },
      width=15,
      height=3,
    ),
    VNodeStory::new(
      "loading_dots",
      "frame_2",
      fn() { @vnode.text("...", fg="cyan") },
      width=15,
      height=3,
    ),
    VNodeStory::new(
      "loading_dots",
      "with_label",
      fn() {
        @vnode.row([@vnode.text("Processing"), @vnode.text("...", fg="cyan")])
      },
      width=20,
      height=3,
    ),
  ]
}
