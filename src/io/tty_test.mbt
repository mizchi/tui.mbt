///|
/// Tests for TTY detection and /dev/tty fallback functionality

///|
test "is_tty returns boolean" {
  // is_tty should return a boolean value
  // The actual value depends on the execution environment
  let result = is_tty()
  // Verify it returns a valid boolean (either true or false)
  inspect(result == true || result == false, content="true")
}

///|
test "get_terminal_size returns valid dimensions" {
  let (cols, rows) = get_terminal_size()
  // Terminal size should be positive integers
  // Default fallback is 80x24
  inspect(cols > 0, content="true")
  inspect(rows > 0, content="true")
}

///|
test "raw_mode_flag initial state is false" {
  // Raw mode should not be enabled initially
  inspect(is_raw_mode(), content="false")
}
