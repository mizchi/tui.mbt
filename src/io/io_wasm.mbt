///|
/// MoonBit wasm1 terminal I/O through moonrun and moonbitlang/async.
/// WASI does not expose termios or terminal-size ioctls, so the host must put
/// stdin in raw mode and may provide COLUMNS/LINES.

///|
fn read_char_ffi() -> Int = "__moonbit_io_unstable" "read_char"

///|
fn write_char_ffi(fd : Int, char : Int) -> Unit = "__moonbit_io_unstable" "write_char"

///|
fn flush_ffi(fd : Int) -> Unit = "__moonbit_io_unstable" "flush"

///|
let raw_mode_flag : Ref[Bool] = Ref(false)

///|
let keypress_running : Ref[Bool] = Ref(false)

///|
let keypress_handler : Ref[(String) -> Unit] = Ref(fn(_key) {  })

///|
fn env_positive_int(name : String, fallback : Int) -> Int {
  match @env.get_env_var(name) {
    Some(value) => {
      let parsed = @string.parse_int(value) catch { _ => fallback }
      if parsed > 0 {
        parsed
      } else {
        fallback
      }
    }
    None => fallback
  }
}

///|
pub fn print_raw(text : String) -> Unit {
  for char in text {
    write_char_ffi(1, char.to_int())
  }
  flush_ffi(1)
}

///|
pub fn debug_stderr(text : String) -> Unit {
  for char in text {
    write_char_ffi(2, char.to_int())
  }
  write_char_ffi(2, '\n'.to_int())
  flush_ffi(2)
}

///|
pub fn debug_stdin_state(_label : String) -> Unit {

}

///|
pub fn enable_raw_mode() -> Unit {
  raw_mode_flag.val = true
}

///|
pub fn cleanup_stdin() -> Unit {
  raw_mode_flag.val = false
}

///|
pub fn is_raw_mode() -> Bool {
  raw_mode_flag.val
}

///|
pub fn get_terminal_size() -> (Int, Int) {
  (env_positive_int("COLUMNS", 80), env_positive_int("LINES", 24))
}

///|
pub async fn read_key() -> String {
  match @stdio.stdin.read_some(max_len=16) {
    Some(bytes) => @utf8.decode(bytes) catch { _ => "" }
    None => ""
  }
}

///|
pub async fn sleep(ms : Int) -> Unit {
  @async.sleep(ms)
}

///|
pub fn get_time_ms() -> Int {
  @async.now().to_int()
}

///|
pub fn is_tty() -> Bool {
  get_env("TERM") != "" && !is_headless()
}

///|
pub fn start_keypress_listener(handler : (String) -> Unit) -> Unit {
  keypress_handler.val = handler
  keypress_running.val = true
  enable_raw_mode()
  while keypress_running.val {
    let char = read_char_ffi()
    if char < 0 {
      break
    }
    (keypress_handler.val)(char.unsafe_to_char().to_string())
  }
  keypress_running.val = false
}

///|
pub fn stop_keypress_listener() -> Unit {
  keypress_running.val = false
  cleanup_stdin()
}

///|
pub fn set_idle_handler(_handler : () -> Unit) -> Unit {

}

///|
pub fn poll_keypress() -> Bool {
  false
}

///|
pub fn keep_alive_nonblocking(_ms : Int) -> Unit {

}

///|
pub fn start_inline_input_cooked(
  _field_name : String,
  _initial : String,
  on_result : (InputResult) -> Unit,
  confirm_on_shift_enter? : Bool = false,
  esc_cancels? : Bool = true,
) -> Unit {
  ignore(confirm_on_shift_enter)
  ignore(esc_cancels)
  on_result(InputResult::Cancelled)
}

///|
pub fn start_inplace_input(
  _row : Int,
  _col : Int,
  _width : Int,
  _height : Int,
  _multiline : Bool,
  _initial : String,
  on_result : (InputResult) -> Unit,
  confirm_on_shift_enter? : Bool = false,
  esc_cancels? : Bool = true,
  on_lines_change? : ((Int) -> Int)? = None,
  on_completion? : ((String, Int) -> String?)? = None,
) -> Unit {
  ignore(confirm_on_shift_enter)
  ignore(esc_cancels)
  ignore(on_lines_change)
  ignore(on_completion)
  on_result(InputResult::Cancelled)
}

///|
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
pub fn start_render_ticker(_ms : Int, _callback : () -> Unit) -> Int {
  0
}

///|
pub fn stop_render_ticker(_ticker_id : Int) -> Unit {

}

///|
pub fn start_resize_listener(_callback : (Int, Int) -> Unit) -> Unit {

}

///|
pub fn stop_resize_listener() -> Unit {

}

///|
pub fn abort_input_session() -> Unit {

}

///|
pub fn get_args() -> Array[String] {
  @env.args()
}

///|
pub fn get_env(name : String) -> String {
  @env.get_env_var(name).unwrap_or("")
}

///|
pub fn is_headless() -> Bool {
  if get_env("TUI_HEADLESS") == "1" {
    return true
  }
  for arg in get_args() {
    if arg == "--headless" {
      return true
    }
  }
  false
}
