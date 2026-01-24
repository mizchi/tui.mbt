///|
/// I/O implementation for native target using C FFI
/// Provides raw mode, terminal size, and character-by-character input

// --- C FFI declarations ---

///|
extern "C" fn tui_enable_raw_mode() -> Int = "tui_enable_raw_mode"

///|
extern "C" fn tui_disable_raw_mode() -> Int = "tui_disable_raw_mode"

///|
extern "C" fn tui_is_raw_mode() -> Int = "tui_is_raw_mode"

///|
extern "C" fn tui_get_terminal_cols() -> Int = "tui_get_terminal_cols"

///|
extern "C" fn tui_get_terminal_rows() -> Int = "tui_get_terminal_rows"

///|
extern "C" fn tui_read_byte() -> Int = "tui_read_byte"

///|
#borrow(buf)
extern "C" fn tui_write_bytes_ffi(buf : FixedArray[Byte], len : Int) = "tui_write_bytes"

///|
extern "C" fn tui_flush() = "tui_flush"

///|
extern "C" fn tui_is_tty() -> Int = "tui_is_tty"

///|
extern "C" fn tui_sleep_ms(ms : Int) = "tui_sleep_ms"

///|
extern "C" fn tui_get_time_ms() -> Int = "tui_get_time_ms"

// --- Helper functions ---

///|
/// Decode UTF-8 bytes to a MoonBit String (UTF-16)
fn bytes_to_string(buf : FixedArray[Byte], len : Int) -> String {
  let chars : Array[Char] = []
  let mut i = 0
  while i < len {
    let b0 = buf[i].to_int()
    if b0 < 0x80 {
      // ASCII (single byte)
      chars.push(b0.unsafe_to_char())
      i = i + 1
    } else if (b0 & 0xE0) == 0xC0 && i + 1 < len {
      // 2-byte UTF-8 sequence
      let b1 = buf[i + 1].to_int()
      let code = ((b0 & 0x1F) << 6) | (b1 & 0x3F)
      chars.push(code.unsafe_to_char())
      i = i + 2
    } else if (b0 & 0xF0) == 0xE0 && i + 2 < len {
      // 3-byte UTF-8 sequence
      let b1 = buf[i + 1].to_int()
      let b2 = buf[i + 2].to_int()
      let code = ((b0 & 0x0F) << 12) | ((b1 & 0x3F) << 6) | (b2 & 0x3F)
      chars.push(code.unsafe_to_char())
      i = i + 3
    } else if (b0 & 0xF8) == 0xF0 && i + 3 < len {
      // 4-byte UTF-8 sequence (outside BMP, needs surrogate pair)
      let b1 = buf[i + 1].to_int()
      let b2 = buf[i + 2].to_int()
      let b3 = buf[i + 3].to_int()
      let code = ((b0 & 0x07) << 18) |
        ((b1 & 0x3F) << 12) |
        ((b2 & 0x3F) << 6) |
        (b3 & 0x3F)
      // Encode as UTF-16 surrogate pair
      let adjusted = code - 0x10000
      let high = 0xD800 + (adjusted >> 10)
      let low = 0xDC00 + (adjusted & 0x3FF)
      chars.push(high.unsafe_to_char())
      chars.push(low.unsafe_to_char())
      i = i + 4
    } else {
      // Invalid or unexpected byte, skip
      i = i + 1
    }
  }

  // Convert Array[Char] to String
  chars.iter().map(fn(c) { c.to_string() }).fold(init="", fn(a, b) { a + b })
}

// --- Public API ---

///|
/// Enable raw mode for character-by-character input
pub fn enable_raw_mode() -> Unit {
  let _ = tui_enable_raw_mode()

}

///|
/// Disable raw mode and restore terminal settings
pub fn cleanup_stdin() -> Unit {
  let _ = tui_disable_raw_mode()

}

///|
/// Check if terminal is in raw mode
pub fn is_raw_mode() -> Bool {
  tui_is_raw_mode() != 0
}

///|
/// Get terminal size (columns, rows)
pub fn get_terminal_size() -> (Int, Int) {
  let cols = tui_get_terminal_cols()
  let rows = tui_get_terminal_rows()
  (cols, rows)
}

///|
/// Read a single key from stdin (raw mode)
/// Returns the key as a string (may be escape sequence)
pub fn read_key() -> String {
  let first = tui_read_byte()
  if first < 0 {
    return ""
  }

  // Check for escape sequence
  if first == 0x1b {
    // Try to read more bytes for escape sequence
    let buf = FixedArray::make(16, b'\x00')
    buf[0] = first.to_byte()
    let mut len = 1

    // Read second byte
    let second = tui_read_byte()
    if second < 0 {
      // Just ESC
      return bytes_to_string(buf, len)
    }
    buf[1] = second.to_byte()
    len = 2

    // Check if it's a CSI sequence (ESC [)
    if second == 0x5b {
      // CSI sequence - read until final byte (0x40-0x7E, excluding '[')
      for i = 2; i < 16; i = i + 1 {
        let b = tui_read_byte()
        if b < 0 {
          break
        }
        buf[i] = b.to_byte()
        len = len + 1
        // Final byte of CSI is in 0x40-0x7E range (letters and some symbols)
        // But not '[' (0x5B) and not intermediate/parameter bytes (0x20-0x3F)
        if b >= 0x40 && b <= 0x7e && b != 0x5b {
          break
        }
      }
    } else if second == 0x4f {
      // SS3 sequence (ESC O) - read one more byte
      let b = tui_read_byte()
      if b >= 0 {
        buf[2] = b.to_byte()
        len = 3
      }
    }
    // Other escape sequences: just return what we have

    // Convert to string
    return bytes_to_string(buf, len)
  } else {
    // Single byte character
    let buf = FixedArray::make(4, b'\x00')
    buf[0] = first.to_byte()
    let mut len = 1

    // Helper to read a continuation byte with retry
    // Returns the byte value, or -1 if still not available after retries
    fn read_continuation_byte() -> Int {
      // First try without delay
      let b = tui_read_byte()
      if b >= 0 {
        return b
      }
      // Retry a few times with small delays (IME may send bytes with slight delay)
      for retry = 0; retry < 5; retry = retry + 1 {
        tui_sleep_ms(1) // 1ms delay
        let b = tui_read_byte()
        if b >= 0 {
          return b
        }
      }
      -1
    }

    // Check for UTF-8 multi-byte sequence
    if (first & 0xe0) == 0xc0 {
      // 2-byte sequence
      let b = read_continuation_byte()
      if b >= 0 {
        buf[1] = b.to_byte()
        len = 2
      }
    } else if (first & 0xf0) == 0xe0 {
      // 3-byte sequence
      for i = 1; i < 3; i = i + 1 {
        let b = read_continuation_byte()
        if b < 0 {
          break
        }
        buf[i] = b.to_byte()
        len = len + 1
      }
    } else if (first & 0xf8) == 0xf0 {
      // 4-byte sequence
      for i = 1; i < 4; i = i + 1 {
        let b = read_continuation_byte()
        if b < 0 {
          break
        }
        buf[i] = b.to_byte()
        len = len + 1
      }
    }
    bytes_to_string(buf, len)
  }
}

///|
/// Detect Shift+Enter or Alt+Enter escape sequences
fn is_shift_enter_sequence(key : String) -> Bool {
  key == "\u001b[13;2u" ||
  key == "\u001b[27;2;13~" ||
  key == "\u001bOM" ||
  key == "\u001b\r" ||
  key == "\u001b\n"
}

///|
/// Parse a raw key string into a KeyEvent
fn parse_raw_key_to_event(key : String) -> @events.KeyEvent {
  // Check for escape sequences first
  if key.length() > 1 && key[0].to_int() == 0x1b {
    // Escape sequences
    if key == "\u001b[Z" {
      return @events.KeyEvent::Special(
        @events.SpecialKey::BackTab,
        @events.KeyModifier::Shift,
      )
    } else if is_shift_enter_sequence(key) {
      return @events.KeyEvent::Special(
        @events.SpecialKey::Enter,
        @events.KeyModifier::Shift,
      )
    } else if key == "\u001b[D" {
      return @events.KeyEvent::Special(
        @events.SpecialKey::Left,
        @events.KeyModifier::None,
      )
    } else if key == "\u001b[C" {
      return @events.KeyEvent::Special(
        @events.SpecialKey::Right,
        @events.KeyModifier::None,
      )
    } else if key == "\u001b[A" {
      return @events.KeyEvent::Special(
        @events.SpecialKey::Up,
        @events.KeyModifier::None,
      )
    } else if key == "\u001b[B" {
      return @events.KeyEvent::Special(
        @events.SpecialKey::Down,
        @events.KeyModifier::None,
      )
    } else if key == "\u001b[H" || key == "\u001b[1~" {
      return @events.KeyEvent::Special(
        @events.SpecialKey::Home,
        @events.KeyModifier::None,
      )
    } else if key == "\u001b[F" || key == "\u001b[4~" {
      return @events.KeyEvent::Special(
        @events.SpecialKey::End,
        @events.KeyModifier::None,
      )
    } else if key == "\u001b[3~" {
      return @events.KeyEvent::Special(
        @events.SpecialKey::Delete,
        @events.KeyModifier::None,
      )
    } else {
      // Unknown escape sequence
      return @events.KeyEvent::Char('\u001b', @events.KeyModifier::None)
    }
  } else if key == "\u001b" {
    // Just Escape
    return @events.KeyEvent::Special(
      @events.SpecialKey::Escape,
      @events.KeyModifier::None,
    )
  } else if key.length() == 1 {
    let code = key[0].to_int()
    // Control characters
    if code == 9 {
      return @events.KeyEvent::Special(
        @events.SpecialKey::Tab,
        @events.KeyModifier::None,
      )
    } else if code == 13 {
      return @events.KeyEvent::Special(
        @events.SpecialKey::Enter,
        @events.KeyModifier::None,
      )
    } else if code == 10 {
      // Ctrl+J (LF)
      return @events.KeyEvent::Char('j', @events.KeyModifier::Ctrl)
    } else if code == 127 || code == 8 {
      return @events.KeyEvent::Special(
        @events.SpecialKey::Backspace,
        @events.KeyModifier::None,
      )
    } else if code == 1 {
      return @events.KeyEvent::Char('a', @events.KeyModifier::Ctrl)
    } else if code == 3 {
      return @events.KeyEvent::Char('c', @events.KeyModifier::Ctrl)
    } else if code == 4 {
      return @events.KeyEvent::Char('d', @events.KeyModifier::Ctrl)
    } else if code == 5 {
      return @events.KeyEvent::Char('e', @events.KeyModifier::Ctrl)
    } else if code == 11 {
      return @events.KeyEvent::Char('k', @events.KeyModifier::Ctrl)
    } else if code == 21 {
      return @events.KeyEvent::Char('u', @events.KeyModifier::Ctrl)
    } else if code >= 32 {
      // Printable character
      let c = Int::unsafe_to_char(code)
      return @events.KeyEvent::Char(c, @events.KeyModifier::None)
    } else {
      // Other control character
      return @events.KeyEvent::Char(
        Int::unsafe_to_char(code),
        @events.KeyModifier::Ctrl,
      )
    }
  } else {
    // Multi-byte UTF-8 character
    let chars = key.iter()
    match chars.next() {
      Some(c) => @events.KeyEvent::Char(c, @events.KeyModifier::None)
      None => @events.KeyEvent::Char(' ', @events.KeyModifier::None)
    }
  }
}

///|
/// Encode a Unicode code point to UTF-8 bytes
fn encode_utf8(code : Int, buf : FixedArray[Byte], pos : Int) -> Int {
  if code < 0x80 {
    buf[pos] = code.to_byte()
    1
  } else if code < 0x800 {
    buf[pos] = (0xC0 | (code >> 6)).to_byte()
    buf[pos + 1] = (0x80 | (code & 0x3F)).to_byte()
    2
  } else if code < 0x10000 {
    buf[pos] = (0xE0 | (code >> 12)).to_byte()
    buf[pos + 1] = (0x80 | ((code >> 6) & 0x3F)).to_byte()
    buf[pos + 2] = (0x80 | (code & 0x3F)).to_byte()
    3
  } else {
    buf[pos] = (0xF0 | (code >> 18)).to_byte()
    buf[pos + 1] = (0x80 | ((code >> 12) & 0x3F)).to_byte()
    buf[pos + 2] = (0x80 | ((code >> 6) & 0x3F)).to_byte()
    buf[pos + 3] = (0x80 | (code & 0x3F)).to_byte()
    4
  }
}

///|
/// Print string to stdout without newline
pub fn print_raw(s : String) -> Unit {
  // Convert UTF-16 string to UTF-8 bytes
  let str_len = s.length()
  // Max 4 bytes per code point
  let max_size = str_len * 4
  let buf = FixedArray::make(max_size, b'\x00')
  let mut pos = 0
  let mut i = 0
  while i < str_len {
    let unit = s[i].to_int()

    // Check for surrogate pair (for characters outside BMP)
    if unit >= 0xD800 && unit <= 0xDBFF && i + 1 < str_len {
      let unit2 = s[i + 1].to_int()
      if unit2 >= 0xDC00 && unit2 <= 0xDFFF {
        // Decode surrogate pair to code point
        let code = 0x10000 + ((unit - 0xD800) << 10) + (unit2 - 0xDC00)
        pos = pos + encode_utf8(code, buf, pos)
        i = i + 2
        continue
      }
    }

    // Regular BMP character
    pos = pos + encode_utf8(unit, buf, pos)
    i = i + 1
  }
  tui_write_bytes_ffi(buf, pos)
  tui_flush()
}

///|
/// Sleep for milliseconds
pub fn sleep(ms : Int) -> Unit {
  tui_sleep_ms(ms)
}

///|
/// Get current time in milliseconds (monotonic)
pub fn get_time_ms() -> Int {
  tui_get_time_ms()
}

///|
/// Check if stdin is a TTY
pub fn is_tty() -> Bool {
  tui_is_tty() != 0
}

///|
/// Debug print to stderr
pub fn debug_stderr(s : String) -> Unit {
  println("[DEBUG] " + s)
}

///|
/// Debug stdin state
pub fn debug_stdin_state(_label : String) -> Unit {
  // No-op for native
}

// --- Async versions (using moonbitlang/async) ---

///|
/// Read a line from stdin (line-buffered, cooked mode)
/// Returns the line without trailing newline
pub async fn read_line() -> String {
  let buf = FixedArray::make(1024, b'\x00')
  let n = @stdio.stdin.read(buf, offset=0, max_len=1024)
  if n <= 0 {
    return ""
  }
  let bytes = Bytes::from_array(buf)
  let s = bytes.to_unchecked_string()
  let view = s[:n]
  view.to_string().trim_end(chars="\n\r").to_string()
}

///|
/// Print string to stdout without newline (async version)
pub async fn print_raw_async(s : String) -> Unit {
  @stdio.stdout.write(s)
}

///|
/// Sleep for milliseconds (async version)
pub async fn sleep_async(ms : Int) -> Unit {
  @async.sleep(ms)
}

// --- Input session stubs (would need more complex implementation) ---

///|
/// Keypress handler storage
let keypress_handler : Ref[(String) -> Unit] = Ref::new(fn(_s) {  })

///|
/// Idle handler storage (called when no key input)
let idle_handler : Ref[() -> Unit] = Ref::new(fn() {  })

///|
let keypress_running : Ref[Bool] = Ref::new(false)

///|
let inside_listener_loop : Ref[Bool] = Ref::new(false)

///|
/// Start keypress listener (raw mode) - blocks until stop_keypress_listener is called
/// This provides the same interface as JS where the listener runs until stopped
/// If called from within a handler (e.g., from restore_tui), just updates the handler
pub fn start_keypress_listener(handler : (String) -> Unit) -> Unit {
  keypress_handler.val = handler
  keypress_running.val = true
  enable_raw_mode()

  // If called from within a handler, just update the handler reference
  // The original loop will continue with the new handler
  if inside_listener_loop.val {
    return
  }
  inside_listener_loop.val = true

  // Run polling loop internally - this blocks until stop_keypress_listener is called
  while keypress_running.val {
    let key = read_key()
    if key.length() > 0 {
      (keypress_handler.val)(key)
    } else {
      // Call idle handler when no key input
      (idle_handler.val)()
      sleep(10)
    }
  }
  inside_listener_loop.val = false
}

///|
/// Set idle handler (called periodically when no key input)
pub fn set_idle_handler(handler : () -> Unit) -> Unit {
  idle_handler.val = handler
}

///|
/// Stop keypress listener
pub fn stop_keypress_listener() -> Unit {
  keypress_running.val = false
  cleanup_stdin()
}

///|
/// Poll for keypress (call this in a loop) - for manual polling if needed
pub fn poll_keypress() -> Bool {
  if not(keypress_running.val) {
    return false
  }
  let key = read_key()
  if key.length() > 0 {
    (keypress_handler.val)(key)
    return true
  }
  false
}

///|
/// Render display state with scroll support
fn render_display_state(
  state : @input.DisplayState,
  start_row : Int,
  start_col : Int,
  max_width : Int,
  max_height : Int,
) -> Unit {
  let mut output = ""
  // Clear area
  for r = 0; r < max_height; r = r + 1 {
    output = output +
      "\u001b[" +
      (start_row + r).to_string() +
      ";" +
      start_col.to_string() +
      "H"
    for w = 0; w < max_width; w = w + 1 {
      output = output + " "
    }
  }
  // Draw visible lines
  for i = 0; i < max_height; i = i + 1 {
    let line_idx = state.scroll_offset + i
    if line_idx >= state.lines.length() {
      break
    }
    let line = state.lines[line_idx]
    output = output +
      "\u001b[" +
      (start_row + i).to_string() +
      ";" +
      start_col.to_string() +
      "H"
    // Show ellipsis for overflow
    if i == 0 && state.has_more_above {
      output = output + "…"
      // Show remaining chars that fit
      let mut w = 1
      for c in line.chars {
        let cw = @core.char_display_width(c)
        if w + cw > max_width {
          break
        }
        output = output + c.to_string()
        w = w + cw
      }
    } else if i == max_height - 1 && state.has_more_below {
      // Show chars that fit, then ellipsis
      let mut w = 0
      for c in line.chars {
        let cw = @core.char_display_width(c)
        if w + cw > max_width - 1 {
          break
        }
        output = output + c.to_string()
        w = w + cw
      }
      output = output + "…"
    } else {
      for c in line.chars {
        output = output + c.to_string()
      }
    }
  }
  print_raw(output)
}

///|
/// Helper to convert buffer to string
fn buf_to_string(buf : Array[Char]) -> String {
  buf.iter().map(fn(c) { c.to_string() }).fold(init="", fn(a, b) { a + b })
}

///|
/// Start inplace input (native implementation with raw mode editing)
/// Blocks until user confirms, cancels, or tabs
/// on_completion: Optional callback (text, cursor_pos) -> completion_suffix
///                If provided and returns Some, Tab inserts the completion
pub fn start_inplace_input(
  row : Int,
  col : Int,
  width : Int,
  height : Int,
  multiline : Bool,
  initial : String,
  on_result : (InputResult) -> Unit,
  confirm_on_shift_enter? : Bool = false,
  esc_cancels? : Bool = true,
  on_lines_change? : ((Int) -> Int)? = None,
  on_completion? : ((String, Int) -> String?)? = None,
) -> Unit {
  // Ensure raw mode is enabled
  let was_raw = is_raw_mode()
  if not(was_raw) {
    enable_raw_mode()
  }

  // Create controller with configuration
  let config = @input.TextInputConfig::new(
    width,
    height,
    multiline~,
    confirm_on_shift_enter~,
    esc_cancels~,
  )
  let controller = @input.TextInputController::new(config, initial)

  // Current height (can change dynamically)
  let mut current_height = height
  // Base row is the bottom of input area (fixed)
  let base_row = row + height - 1

  // Helper to render and position cursor with scroll
  fn do_render() {
    let state = controller.get_display_state()
    // Calculate current start row (grows upward)
    let old_height = current_height
    let old_start_row = base_row - old_height + 1
    // Update height if callback provided
    match on_lines_change {
      Some(callback) => {
        let new_height = callback(state.total_lines)
        if new_height != current_height {
          current_height = new_height
          controller.resize(width, new_height)
        }
      }
      None => ()
    }
    // Calculate new start row
    let start_row = base_row - current_height + 1
    // Clear old area if height changed
    if old_height != current_height {
      if current_height < old_height {
        // Shrinking: clear above
        for r = old_start_row; r < start_row; r = r + 1 {
          print_raw(
            "\u001b[" +
            r.to_string() +
            ";" +
            col.to_string() +
            "H" +
            " ".repeat(width),
          )
        }
      } else {
        // Growing: clear new area above
        for r = start_row; r < old_start_row; r = r + 1 {
          print_raw(
            "\u001b[" +
            r.to_string() +
            ";" +
            col.to_string() +
            "H" +
            " ".repeat(width),
          )
        }
      }
    }
    // Get updated state after potential resize
    let state = controller.get_display_state()
    // Render with scroll (at calculated start row)
    render_display_state(state, start_row, col, width, current_height)
    // Position cursor
    let display_row = start_row + state.cursor_line - state.scroll_offset
    let display_col = col + state.cursor_col
    print_raw(
      "\u001b[" + display_row.to_string() + ";" + display_col.to_string() + "H",
    )
    print_raw(@render.ansi_show_cursor())
  }

  // Initial render
  do_render()

  // Edit loop
  for {
    let key = read_key()
    if key.length() == 0 {
      sleep(10)
      continue
    }
    let mut need_render = false
    let mut done = false
    let mut result : InputResult = InputResult::Cancelled

    // Parse key and interpret as action
    let event = parse_raw_key_to_event(key)
    let action = @input.interpret_key(event, config)

    // Handle special actions that require custom logic
    match action {
      @input.EditAction::Tab => {
        // Tab - try completion first, then confirm and go to next
        let mut handled_by_completion = false
        match on_completion {
          Some(provider) => {
            let text = controller.get_text()
            let completion_result = provider(text, controller.get_cursor_pos())
            match completion_result {
              Some(suffix) =>
                if suffix.length() > 0 {
                  let _ = controller.apply_action(
                    @input.EditAction::Insert(suffix),
                  )
                  need_render = true
                  handled_by_completion = true
                }
              None => ()
            }
          }
          None => ()
        }
        if not(handled_by_completion) {
          done = true
          result = InputResult::TabNext(controller.get_text())
        }
      }
      @input.EditAction::BackTab => {
        done = true
        result = InputResult::TabPrev(controller.get_text())
      }
      @input.EditAction::Confirm => {
        done = true
        result = InputResult::Confirmed(controller.get_text())
      }
      @input.EditAction::Cancel => {
        done = true
        result = InputResult::Cancelled
      }
      @input.EditAction::ForceQuit => {
        done = true
        result = InputResult::ForceQuit
      }
      @input.EditAction::None => ()
      _ => {
        // Apply edit action to controller
        let handled = controller.apply_action(action)
        if handled {
          need_render = true
        }
      }
    }

    // Handle Ctrl+D (confirm) - not captured by interpret_key
    if key.length() == 1 && key[0].to_int() == 4 {
      done = true
      result = InputResult::Confirmed(controller.get_text())
    }
    if need_render {
      do_render()
    }
    if done {
      // Hide cursor before exiting
      print_raw(@render.ansi_hide_cursor())
      // Restore raw mode state if we changed it
      if not(was_raw) {
        cleanup_stdin()
      }
      on_result(result)
      return
    }
  }
}

///|
/// Start inline input with cooked mode (native implementation)
pub fn start_inline_input_cooked(
  field_name : String,
  initial : String,
  on_result : (InputResult) -> Unit,
  confirm_on_shift_enter? : Bool = false,
  esc_cancels? : Bool = true,
) -> Unit {
  // Ensure raw mode is enabled for predictable key handling
  let was_raw = is_raw_mode()
  if not(was_raw) {
    enable_raw_mode()
  }
  let _ = field_name
  print_raw(@render.ansi_show_cursor())
  let mut start_row = 1
  let mut start_col = 1
  let mut can_render = false
  let mut rendered_lines = 1
  let mut max_rows = 1
  let mut max_cols = 1
  let reserve_rows = 1
  fn parse_cursor_pos(resp : String) -> (Int, Int)? {
    if not(resp.has_prefix("\u001b[")) || not(resp.has_suffix("R")) {
      return None
    }
    if resp.length() < 4 {
      return None
    }
    let body = try! resp[2:resp.length() - 1]
    let mut row = 0
    let mut col = 0
    let mut seen_sep = false
    for c in body {
      if c == ';' {
        if seen_sep {
          return None
        }
        seen_sep = true
        continue
      }
      if not(c.is_ascii_digit()) {
        return None
      }
      let digit = c.to_int() - '0'.to_int()
      if not(seen_sep) {
        row = row * 10 + digit
      } else {
        col = col * 10 + digit
      }
    }
    if not(seen_sep) {
      return None
    }
    Some((row, col))
  }

  // Buffer to store any user input that was read while getting cursor position
  let pending_input : Array[String] = []
  fn read_cursor_pos_fn() -> (Int, Int)? {
    print_raw("\u001b[6n")
    // Try to read cursor position response, but save any user input
    for attempt = 0; attempt < 10; attempt = attempt + 1 {
      let resp = read_key()
      if resp.length() == 0 {
        sleep(5)
        continue
      }
      match parse_cursor_pos(resp) {
        Some(pos) => return Some(pos)
        None => {
          // Not a cursor position response - it's user input, save it
          pending_input.push(resp)
          // Keep trying for a bit in case cursor response comes later
          continue
        }
      }
    }
    None
  }

  match read_cursor_pos_fn() {
    Some((row, col)) => {
      start_row = row
      start_col = col
      can_render = true
      let (cols, rows) = get_terminal_size()
      let available = rows - start_row + 1 - reserve_rows
      max_rows = if available > 0 { available } else { 1 }
      let available_cols = cols - start_col + 1
      max_cols = if available_cols > 0 { available_cols } else { 1 }
    }
    None => ()
  }

  // Create controller with configuration
  // For cooked mode, we use multiline mode with confirm_on_shift_enter logic
  let config = @input.TextInputConfig::new(
    max_cols,
    max_rows,
    multiline=true,
    confirm_on_shift_enter~,
    esc_cancels~,
  )
  let controller = @input.TextInputController::new(config, initial)
  fn render_all() -> Bool {
    if not(can_render) {
      return false
    }
    let state = controller.get_display_state()
    let max_visible = if max_rows > 0 { max_rows } else { 1 }
    let start_idx = state.scroll_offset
    let end_idx = if start_idx + max_visible < state.lines.length() {
      start_idx + max_visible
    } else {
      state.lines.length()
    }
    let visible_len = end_idx - start_idx
    let clear_lines = if rendered_lines < max_rows {
      rendered_lines
    } else {
      max_rows
    }
    for i = 0; i < clear_lines; i = i + 1 {
      let row = start_row + i
      print_raw("\u001b[" + row.to_string() + ";" + start_col.to_string() + "H")
      print_raw("\u001b[K")
    }
    for i = start_idx; i < end_idx; i = i + 1 {
      let row = start_row + (i - start_idx)
      print_raw("\u001b[" + row.to_string() + ";" + start_col.to_string() + "H")
      print_raw(buf_to_string(state.lines[i].chars))
    }
    rendered_lines = if visible_len > 0 { visible_len } else { 1 }
    let mut row_offset = state.cursor_line - state.scroll_offset
    if row_offset < 0 {
      row_offset = 0
    }
    if row_offset >= max_visible {
      row_offset = max_visible - 1
    }
    let display_row = start_row + row_offset
    let display_col = start_col + state.cursor_col
    print_raw(
      "\u001b[" + display_row.to_string() + ";" + display_col.to_string() + "H",
    )
    print_raw(@render.ansi_show_cursor())
    true
  }

  if not(render_all()) && controller.get_text().length() > 0 {
    print_raw(controller.get_text())
  }

  // Process any pending input that was captured during cursor position query
  for pending in pending_input {
    let event = parse_raw_key_to_event(pending)
    let action = @input.interpret_key(event, config)
    match action {
      @input.EditAction::Confirm
      | @input.EditAction::Cancel
      | @input.EditAction::ForceQuit => ()
      _ => {
        let handled = controller.apply_action(action)
        if handled {
          let _ = render_all()

        }
      }
    }
  }
  for {
    let key = read_key()
    if key.length() == 0 {
      sleep(10)
      continue
    }
    let mut need_render = false
    let mut done = false
    let mut result : InputResult = InputResult::Cancelled

    // Parse key and interpret as action
    let event = parse_raw_key_to_event(key)
    let action = @input.interpret_key(event, config)

    // Handle special actions
    match action {
      @input.EditAction::Confirm => {
        done = true
        let value = controller.get_text()
        result = InputResult::Confirmed(
          if value.length() == 0 {
            initial
          } else {
            value
          },
        )
      }
      @input.EditAction::Cancel => {
        done = true
        result = InputResult::Cancelled
      }
      @input.EditAction::ForceQuit => {
        done = true
        result = InputResult::ForceQuit
      }
      @input.EditAction::None => ()
      _ => {
        // Apply edit action to controller
        let handled = controller.apply_action(action)
        if handled {
          need_render = true
        }
      }
    }
    if need_render {
      let _ = render_all()

    }
    if done {
      if not(was_raw) {
        cleanup_stdin()
      }
      on_result(result)
      return
    }
  }
}

// --- Functions for JS compatibility ---

///|
/// Keep alive non-blocking (no-op for native, used in JS for event loop)
pub fn keep_alive_nonblocking(_ms : Int) -> Unit {
  // No-op for native - native uses blocking loop
}

///|
/// Start inline input (same as inplace input for native)
pub fn start_inline_input(
  row : Int,
  col : Int,
  width : Int,
  height : Int,
  multiline : Bool,
  initial : String,
  on_result : (InputResult) -> Unit,
) -> Unit {
  start_inplace_input(row, col, width, height, multiline, initial, on_result)
}

///|
/// Start render ticker (stub - native uses polling loop instead)
pub fn start_render_ticker(_ms : Int, _callback : () -> Unit) -> Int {
  // Native doesn't need a render ticker - it uses a polling loop
  0
}

///|
/// Stop render ticker (stub)
pub fn stop_render_ticker(_ticker_id : Int) -> Unit {
  // No-op for native
}

///|
/// Start resize listener (stub - native does not emit resize events)
pub fn start_resize_listener(_callback : (Int, Int) -> Unit) -> Unit {
  // No-op for native
}

///|
/// Stop resize listener (stub)
pub fn stop_resize_listener() -> Unit {
  // No-op for native
}

///|
/// Start input session with callback (wrapper for start_inplace_input)
pub fn start_input_session_cb(
  row : Int,
  col : Int,
  width : Int,
  height : Int,
  multiline : Bool,
  initial : String,
  on_result : (InputResult) -> Unit,
) -> Unit {
  start_inplace_input(row, col, width, height, multiline, initial, on_result)
}

///|
/// Abort input session (stub)
pub fn abort_input_session() -> Unit {
  // Native input is blocking, cannot be aborted externally
}

// --- Environment and Arguments ---

///|
/// Get command line arguments (not available in native mode)
pub fn get_args() -> Array[String] {
  // Native mode doesn't have easy access to argv
  []
}

///|
/// Get environment variable value (not available in native mode)
pub fn get_env(_name : String) -> String {
  // Native mode doesn't have easy access to getenv
  ""
}

///|
/// Check if running in headless mode (always false for native)
pub fn is_headless() -> Bool {
  false
}
