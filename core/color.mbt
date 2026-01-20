///|
/// TUI Color type (RGBA)
pub(all) struct Color {
  r : Int
  g : Int
  b : Int
  a : Double
}

///|
pub fn Color::rgb(r : Int, g : Int, b : Int) -> Color {
  { r, g, b, a: 1.0 }
}

///|
pub fn Color::rgba(r : Int, g : Int, b : Int, a : Double) -> Color {
  { r, g, b, a }
}

///|
pub fn Color::white() -> Color {
  { r: 255, g: 255, b: 255, a: 1.0 }
}

///|
pub fn Color::black() -> Color {
  { r: 0, g: 0, b: 0, a: 1.0 }
}

///|
pub fn Color::transparent() -> Color {
  { r: 0, g: 0, b: 0, a: 0.0 }
}

///|
pub fn Color::red() -> Color {
  { r: 255, g: 0, b: 0, a: 1.0 }
}

///|
pub fn Color::green() -> Color {
  { r: 0, g: 255, b: 0, a: 1.0 }
}

///|
pub fn Color::blue() -> Color {
  { r: 0, g: 0, b: 255, a: 1.0 }
}

///|
pub fn Color::yellow() -> Color {
  { r: 255, g: 255, b: 0, a: 1.0 }
}

///|
pub fn Color::cyan() -> Color {
  { r: 0, g: 255, b: 255, a: 1.0 }
}

///|
pub fn Color::magenta() -> Color {
  { r: 255, g: 0, b: 255, a: 1.0 }
}

///|
pub fn Color::is_transparent(self : Color) -> Bool {
  self.a < 0.01
}

///|
pub impl Eq for Color with equal(self, other) {
  self.r == other.r &&
  self.g == other.g &&
  self.b == other.b &&
  self.a == other.a
}

///|
/// Convert from crater Color
pub fn Color::from_crater(c : @types.Color) -> Color {
  { r: c.r, g: c.g, b: c.b, a: c.a }
}
