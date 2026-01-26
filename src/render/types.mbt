///|
/// A single character cell in the terminal
pub(all) struct CharCell {
  char : Char
  fg : @core.Color
  bg : @core.Color
  bold : Bool
  underline : Bool
  reverse : Bool
}

///|
pub fn CharCell::default() -> CharCell {
  {
    char: ' ',
    fg: @core.Color::white(),
    bg: @core.Color::transparent(),
    bold: false,
    underline: false,
    reverse: false,
  }
}

///|
pub fn CharCell::from_char(c : Char) -> CharCell {
  { ..CharCell::default(), char: c }
}

///|
pub fn CharCell::styled(
  c : Char,
  fg : @core.Color,
  bg : @core.Color,
) -> CharCell {
  { ..CharCell::default(), char: c, fg, bg }
}

///|
pub impl Eq for CharCell with equal(self, other) {
  self.char == other.char &&
  self.fg == other.fg &&
  self.bg == other.bg &&
  self.bold == other.bold &&
  self.underline == other.underline &&
  self.reverse == other.reverse
}

///|
/// Text style for writing text
pub(all) struct TextStyle {
  fg : @core.Color
  bg : @core.Color
  bold : Bool
  underline : Bool
}

///|
pub fn TextStyle::default() -> TextStyle {
  {
    fg: @core.Color::white(),
    bg: @core.Color::transparent(),
    bold: false,
    underline: false,
  }
}
