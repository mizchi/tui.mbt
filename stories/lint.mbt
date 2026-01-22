///|
/// Lint utilities for story best practices
///
/// These functions check stories for common issues.
/// Use `lint_all()` to get all violations, or run specific lint checks.

///|
/// Lint violation with details
pub(all) struct LintViolation {
  rule : String
  story : String
  message : String
}

///|
impl Show for LintViolation with output(self, logger) {
  logger.write_string("[")
  logger.write_string(self.rule)
  logger.write_string("] ")
  logger.write_string(self.story)
  logger.write_string(": ")
  logger.write_string(self.message)
}

///|
/// Categories that typically have bordered components
let bordered_categories : Array[String] = [
  "tabs", "accordion", "menu", "context_menu", "listbox", "select", "bordered", "input",
  "textarea",
]

///|
/// Check if a category typically has bordered UI
fn is_bordered_category(category : String) -> Bool {
  bordered_categories.contains(category)
}

///|
/// Lint: Bordered UI should use odd dimensions for better centering
/// - Border takes 2 chars (left + right, top + bottom)
/// - Odd total = odd inner content = better centering
pub fn lint_odd_dimensions(stories : Array[Story]) -> Array[LintViolation] {
  let violations : Array[LintViolation] = []
  for story in stories {
    if is_bordered_category(story.category) {
      let width_even = story.width % 2 == 0
      let height_even = story.height % 2 == 0
      if width_even || height_even {
        let story_name = story.category + "/" + story.name
        let size = story.width.to_string() + "x" + story.height.to_string()
        let msg = if width_even && height_even {
          "(" + size + ") both width and height should be odd"
        } else if width_even {
          "(" + size + ") width should be odd"
        } else {
          "(" + size + ") height should be odd"
        }
        violations.push({
          rule: "odd-dimensions",
          story: story_name,
          message: msg,
        })
      }
    }
  }
  violations
}

///|
/// Lint: Story dimensions should be reasonable
pub fn lint_dimension_range(stories : Array[Story]) -> Array[LintViolation] {
  let violations : Array[LintViolation] = []
  for story in stories {
    let story_name = story.category + "/" + story.name
    // Width should be at least 5 and at most 100
    if story.width < 5 || story.width > 100 {
      violations.push({
        rule: "dimension-range",
        story: story_name,
        message: "width " + story.width.to_string() + " out of range [5, 100]",
      })
    }
    // Height should be at least 3 and at most 50
    if story.height < 3 || story.height > 50 {
      violations.push({
        rule: "dimension-range",
        story: story_name,
        message: "height " + story.height.to_string() + " out of range [3, 50]",
      })
    }
  }
  violations
}

///|
/// Run all lint checks on stories
pub fn lint_all(stories : Array[Story]) -> Array[LintViolation] {
  let violations : Array[LintViolation] = []
  violations.append(lint_odd_dimensions(stories))
  violations.append(lint_dimension_range(stories))
  violations
}

///|
/// Format violations as a report string
pub fn format_lint_report(violations : Array[LintViolation]) -> String {
  if violations.is_empty() {
    return "All lint checks passed!"
  }
  let lines : Array[String] = ["Lint violations found:"]
  for v in violations {
    lines.push("  - " + v.to_string())
  }
  lines
  .iter()
  .fold(init="", fn(acc, line) {
    if acc == "" {
      line
    } else {
      acc + "\n" + line
    }
  })
}
