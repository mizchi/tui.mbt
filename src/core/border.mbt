///|
/// Border characters for box drawing
pub(all) struct BorderChars {
  top_left : Char
  top_right : Char
  bottom_left : Char
  bottom_right : Char
  horizontal : Char
  vertical : Char
}

///|
pub fn BorderChars::single() -> BorderChars {
  {
    top_left: '\u250C',
    top_right: '\u2510',
    bottom_left: '\u2514',
    bottom_right: '\u2518',
    horizontal: '\u2500',
    vertical: '\u2502',
  }
}

///|
pub fn BorderChars::double() -> BorderChars {
  {
    top_left: '\u2554',
    top_right: '\u2557',
    bottom_left: '\u255A',
    bottom_right: '\u255D',
    horizontal: '\u2550',
    vertical: '\u2551',
  }
}

///|
pub fn BorderChars::rounded() -> BorderChars {
  {
    top_left: '\u256D',
    top_right: '\u256E',
    bottom_left: '\u2570',
    bottom_right: '\u256F',
    horizontal: '\u2500',
    vertical: '\u2502',
  }
}

///|
pub fn BorderChars::ascii() -> BorderChars {
  {
    top_left: '+',
    top_right: '+',
    bottom_left: '+',
    bottom_right: '+',
    horizontal: '-',
    vertical: '|',
  }
}
