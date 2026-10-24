///|
/// Tests for terminal color-depth detection

///|
test "ColorMode::from_env: COLORTERM signals true color" {
  assert_true(
    @render.ColorMode::from_env("xterm-256color", "truecolor")
    is @render.ColorMode::TrueColor,
  )
  assert_true(
    @render.ColorMode::from_env("xterm-256color", "24bit")
    is @render.ColorMode::TrueColor,
  )
  assert_true(
    @render.ColorMode::from_env("xterm-256color", "TRUECOLOR")
    is @render.ColorMode::TrueColor,
  )
}

///|
test "ColorMode::from_env: TERM signals true color" {
  assert_true(
    @render.ColorMode::from_env("xterm-direct", "") is @render.ColorMode::TrueColor,
  )
  assert_true(
    @render.ColorMode::from_env("xterm-truecolor", "")
    is @render.ColorMode::TrueColor,
  )
}

///|
test "ColorMode::from_env: unknown terminals fall back to 256 colors" {
  assert_true(
    @render.ColorMode::from_env("xterm-256color", "")
    is @render.ColorMode::Ansi256,
  )
  assert_true(
    @render.ColorMode::from_env("screen", "") is @render.ColorMode::Ansi256,
  )
  assert_true(@render.ColorMode::from_env("", "") is @render.ColorMode::Ansi256)
}

///|
test "ColorMode::is_true_color" {
  assert_true(@render.ColorMode::TrueColor.is_true_color())
  assert_false(@render.ColorMode::Ansi256.is_true_color())
}
