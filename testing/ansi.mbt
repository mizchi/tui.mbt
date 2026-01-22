///|
/// ANSI escape code utilities for testing

///|
/// Strip all ANSI escape sequences from a string
/// Handles CSI sequences (ESC[...X), OSC sequences (ESC]...BEL/ST), and simple escapes
pub fn strip_ansi(input : String) -> String {
  let result : Array[Char] = []
  let chars = input.to_array()
  let len = chars.length()
  let mut i = 0
  while i < len {
    let c = chars[i]
    if c == '\u001b' && i + 1 < len {
      // ESC sequence
      let next = chars[i + 1]
      if next == '[' {
        // CSI sequence: ESC[ ... final_byte (0x40-0x7E)
        i = i + 2
        while i < len {
          let code = chars[i].to_int()
          i = i + 1
          // Final byte in range 0x40-0x7E (@A-Z[\]^_`a-z{|}~)
          if code >= 0x40 && code <= 0x7E {
            break
          }
        }
      } else if next == ']' {
        // OSC sequence: ESC] ... (BEL or ESC\)
        i = i + 2
        while i < len {
          if chars[i] == '\u0007' {
            // BEL
            i = i + 1
            break
          } else if chars[i] == '\u001b' && i + 1 < len && chars[i + 1] == '\\' {
            // ST (String Terminator)
            i = i + 2
            break
          }
          i = i + 1
        }
      } else if next == '(' || next == ')' {
        // Character set selection: ESC( or ESC)
        i = i + 3
      } else if next == 'O' {
        // SS3 sequence: ESC O X
        i = i + 3
      } else {
        // Simple escape: ESC X
        i = i + 2
      }
    } else {
      result.push(c)
      i = i + 1
    }
  }
  String::from_array(result)
}

///|
/// Check if string contains ANSI escape sequences
pub fn has_ansi(input : String) -> Bool {
  input.contains("\u001b")
}

///|
/// Extract visible text length (excluding ANSI codes)
pub fn visible_length(input : String) -> Int {
  strip_ansi(input).iter().count()
}

///|
/// Split string into lines, stripping ANSI from each
pub fn split_lines_plain(input : String) -> Array[String] {
  let plain = strip_ansi(input)
  plain.split("\n").map(fn(sv) { sv.to_string() }).collect()
}
