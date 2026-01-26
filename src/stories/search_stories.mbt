///|
/// Search component stories - search input, highlight text, result items

///|
pub fn search_input_stories() -> Array[VNodeStory] {
  [
    VNodeStory::new(
      "search_input",
      "empty",
      fn() { @components.search_input("") },
      width=30,
      height=3,
    ),
    VNodeStory::new(
      "search_input",
      "with_query",
      fn() { @components.search_input("hello") },
      width=30,
      height=3,
    ),
    VNodeStory::new(
      "search_input",
      "custom_prompt",
      fn() { @components.search_input("test", prompt="$ ") },
      width=30,
      height=3,
    ),
    VNodeStory::new(
      "search_input",
      "no_cursor",
      fn() { @components.search_input("query", show_cursor=false) },
      width=30,
      height=3,
    ),
    VNodeStory::new(
      "search_input",
      "custom_placeholder",
      fn() { @components.search_input("", placeholder="Search files...") },
      width=30,
      height=3,
    ),
  ]
}

///|
pub fn highlight_text_stories() -> Array[VNodeStory] {
  [
    VNodeStory::new(
      "highlight_text",
      "no_highlight",
      fn() { @components.highlight_text("hello world", 0) },
      width=20,
      height=3,
    ),
    VNodeStory::new(
      "highlight_text",
      "partial_highlight",
      fn() { @components.highlight_text("hello world", 5) },
      width=20,
      height=3,
    ),
    VNodeStory::new(
      "highlight_text",
      "full_highlight",
      fn() { @components.highlight_text("hello", 5) },
      width=20,
      height=3,
    ),
    VNodeStory::new(
      "highlight_text",
      "custom_colors",
      fn() {
        @components.highlight_text(
          "rainbow",
          4,
          highlight_fg="yellow",
          text_fg="magenta",
        )
      },
      width=20,
      height=3,
    ),
  ]
}

///|
pub fn search_result_stories() -> Array[VNodeStory] {
  [
    VNodeStory::new(
      "search_result",
      "normal",
      fn() { @components.search_result_item("document.txt", false) },
      width=25,
      height=3,
    ),
    VNodeStory::new(
      "search_result",
      "selected",
      fn() { @components.search_result_item("document.txt", true) },
      width=25,
      height=3,
    ),
    VNodeStory::new(
      "search_result",
      "with_highlight",
      fn() {
        @components.search_result_item("document.txt", false, highlight_len=4)
      },
      width=25,
      height=3,
    ),
    VNodeStory::new(
      "search_result",
      "selected_with_highlight",
      fn() {
        @components.search_result_item("document.txt", true, highlight_len=4)
      },
      width=25,
      height=3,
    ),
    VNodeStory::new(
      "search_result",
      "with_icon",
      fn() { @components.search_result_item("main.mbt", false, icon="📄") },
      width=25,
      height=3,
    ),
    VNodeStory::new(
      "search_result",
      "selected_with_icon",
      fn() { @components.search_result_item("main.mbt", true, icon="📄") },
      width=25,
      height=3,
    ),
    VNodeStory::new(
      "search_result",
      "full_featured",
      fn() {
        @components.search_result_item(
          "moonbit.txt",
          true,
          icon="🌙",
          highlight_len=4,
        )
      },
      width=25,
      height=3,
    ),
  ]
}
