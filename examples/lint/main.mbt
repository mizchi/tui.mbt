///|
/// Run story lints and report violations
fn main {
  let stories = @stories.all_stories()
  let violations = @stories.lint_all(stories)
  println(@stories.format_lint_report(violations))
  if violations.length() > 0 {
    // Exit with error code if violations found
    // (Note: MoonBit doesn't have exit() yet, so we just print)
    println("\nFound " + violations.length().to_string() + " violation(s)")
  }
}
