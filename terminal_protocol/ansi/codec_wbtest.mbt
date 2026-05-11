///|
test "ansi basic escapes" {
  inspect(ansi_reset(), content="\u{1b}[0m")
  inspect(ansi_bold(), content="\u{1b}[1m")
  inspect(ansi_dim(), content="\u{1b}[2m")
  inspect(ansi_underline(), content="\u{1b}[4m")
  inspect(ansi_reverse(), content="\u{1b}[7m")
}

///|
test "ansi color and cursor escapes" {
  inspect(ansi_fg_256(196), content="\u{1b}[38;5;196m")
  inspect(ansi_bg_256(21), content="\u{1b}[48;5;21m")
  inspect(ansi_move_to(0, 0), content="\u{1b}[1;1H")
  inspect(ansi_move_to(10, 5), content="\u{1b}[11;6H")
  inspect(rgb_to_256(255, 0, 0), content="196")
}

///|
test "ansi terminal mode escapes" {
  inspect(ansi_clear_screen(), content="\u{1b}[2J")
  inspect(ansi_clear_line(), content="\u{1b}[2K")
  inspect(ansi_hide_cursor(), content="\u{1b}[?25l")
  inspect(ansi_show_cursor(), content="\u{1b}[?25h")
  inspect(enable_mouse(), content="\u{1b}[?1000h\u{1b}[?1006h")
  inspect(disable_mouse(), content="\u{1b}[?1006l\u{1b}[?1000l")
  inspect(enable_mouse_all(), content="\u{1b}[?1003h\u{1b}[?1006h")
  inspect(disable_mouse_all(), content="\u{1b}[?1006l\u{1b}[?1003l")
}
