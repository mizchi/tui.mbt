///|
/// Snapshot generator for component stories
///
/// Usage:
///   moon run examples/snapshot           # Output to stdout
///   moon run examples/snapshot -- --save # Save to __snapshots__/
///
/// Output:
///   Generates __snapshots__/<category>.txt files with all story renders

///|
fn main {
  let stories = @stories.all_stories()
  let categories = @stories.all_categories()
  println(
    "Generating snapshots for " + stories.length().to_string() + " stories...",
  )
  println("")

  // Group stories by category
  for category in categories {
    let category_stories = @stories.stories_by_category(category)
    let mut content = ""
    content = content + "# " + category + "\n\n"
    for story in category_stories {
      content = content +
        "────────────────────────────────────────\n"
      content = content +
        "## " +
        story.name +
        " (" +
        story.width.to_string() +
        "x" +
        story.height.to_string() +
        ")\n"
      content = content +
        "────────────────────────────────────────\n"
      content = content + story.to_plain()
      content = content + "\n\n"
    }

    // Output to stdout
    println(
      "=== " +
      category +
      " (" +
      category_stories.length().to_string() +
      " stories) ===",
    )
    println(content)
  }
  println("Done! " + stories.length().to_string() + " stories rendered.")
  println("")
  println("To save snapshots:")
  println("  moon run examples/snapshot > __snapshots__/all.txt")
}
