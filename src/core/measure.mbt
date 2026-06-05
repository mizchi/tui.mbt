///|
/// Text measurement utilities for layout engine

///|
/// Create a MeasureFunc for text that uses character width
pub fn text_measure_func(text : String) -> @ccore.MeasureFunc {
  {
    func: fn(
      available_width : Double,
      _available_height : Double,
    ) -> @ccore.IntrinsicSize {
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
      // Report the natural height (only explicit newlines force extra lines).
      // crater-layout's intrinsic sizing queries this measure at the
      // min-content width; deriving height from that narrow width would wrap
      // text that actually has room, so the reported height must reflect the
      // text laid out at its max-content width. Width-constrained wrapping is
      // handled by the renderer against the resolved box width.
      let _ = max_width
      let natural_height = calculate_wrapped_height(text, max_content)
      {
        min_width: min_width.to_double(),
        max_width: max_content.to_double(),
        min_height: natural_height.to_double(),
        max_height: natural_height.to_double(),
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
