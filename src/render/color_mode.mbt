///|
/// How colors are encoded into ANSI SGR sequences.
pub(all) enum ColorMode {
  /// 256-color palette (`38;5;n` / `48;5;n`). Safe default.
  Ansi256
  /// 24-bit direct color (`38;2;r;g;b` / `48;2;r;g;b`).
  TrueColor
}

///|
/// Resolve the color mode supported by the current terminal.
///
/// Only `COLORTERM` and `TERM` are consulted; anything unknown falls back to
/// `Ansi256` so output stays valid on terminals without 24-bit support.
pub fn ColorMode::detect() -> ColorMode {
  ColorMode::from_env(
    @env.get_env_var("TERM").unwrap_or(""),
    @env.get_env_var("COLORTERM").unwrap_or(""),
  )
}

///|
/// Pure helper behind `detect`, kept separate so it is testable.
pub fn ColorMode::from_env(term : String, colorterm : String) -> ColorMode {
  let colorterm = colorterm.to_lower()
  let term = term.to_lower()
  if colorterm.contains("truecolor") ||
    colorterm.contains("24bit") ||
    colorterm.contains("24-bit") ||
    term.contains("truecolor") ||
    term.contains("24bit") ||
    term.contains("direct") {
    TrueColor
  } else {
    Ansi256
  }
}

///|
pub fn ColorMode::is_true_color(self : ColorMode) -> Bool {
  self is TrueColor
}
