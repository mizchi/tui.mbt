///|
/// Text measurement utilities for layout engine

///|
/// Create a MeasureFunc for text that uses character width
pub fn text_measure_func(text : String) -> @types.MeasureFunc {
  {
    func: fn(
      available_width : Double,
      _available_height : Double,
    ) -> @types.IntrinsicSize {
      let max_width = available_width.to_int()
      // Calculate min-content (longest word)
      let mut min_width = 0
      let mut current_word = 0
      for c in text {
        if c == ' ' || c == '\n' {
          if current_word > min_width {
            min_width = current_word
          }
          current_word = 0
        } else {
          current_word = current_word + char_display_width(c)
        }
      }
      if current_word > min_width {
        min_width = current_word
      }
      // Calculate max-content (total width without wrapping)
      let max_content = string_display_width(text)
      // Calculate actual width and height based on wrapping
      let actual_width = if max_width > 0 && max_content > max_width {
        max_width
      } else if max_content > 0 {
        max_content
      } else {
        min_width
      }
      // Calculate height with wrapping
      let height = if actual_width > 0 {
        calculate_wrapped_height(text, actual_width)
      } else {
        1
      }
      {
        min_width: min_width.to_double(),
        max_width: max_content.to_double(),
        min_height: 1.0,
        max_height: height.to_double(),
      }
    },
  }
}

///|
fn calculate_wrapped_height(text : String, max_width : Int) -> Int {
  let mut lines = 1
  let mut current_width = 0
  for c in text {
    if c == '\n' {
      lines = lines + 1
      current_width = 0
      continue
    }
    let w = char_display_width(c)
    if current_width + w > max_width {
      lines = lines + 1
      current_width = w
    } else {
      current_width = current_width + w
    }
  }
  lines
}
