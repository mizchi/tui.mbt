///|
/// ANSI snapshot generator for component stories
///
/// Usage:
///   moon run examples/snapshot-ansi           # Output ANSI to stdout
///
/// Output:
///   Generates ANSI-colored output with escape sequences preserved

///|
fn main {
  let _ = @stories.all_stories() // for count reference
  let categories = @stories.all_categories()

  // Group stories by category
  for category in categories {
    let category_stories = @stories.stories_by_category(category)
    println("# " + category)
    println("")
    for story in category_stories {
      println(
        "────────────────────────────────────────",
      )
      println(
        "## " +
        story.name +
        " (" +
        story.width.to_string() +
        "x" +
        story.height.to_string() +
        ")",
      )
      println(
        "────────────────────────────────────────",
      )
      // Use to_ansi() to preserve color codes
      println(story.to_ansi())
      println("")
    }
    println("")
  }
}
