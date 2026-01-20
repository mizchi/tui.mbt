///|
/// Style maps for component rendering

///|
/// Rendering options for a node
pub(all) struct RenderStyle {
  fg : Color
  bg : Color
  bold : Bool
  underline : Bool
  border : BorderChars?
  border_fg : Color
}

///|
pub fn RenderStyle::default() -> RenderStyle {
  {
    fg: Color::white(),
    bg: Color::transparent(),
    bold: false,
    underline: false,
    border: None,
    border_fg: Color::white(),
  }
}

///|
/// Map from node ID to render style
pub struct RenderStyleMap(Map[String, RenderStyle])

///|
pub fn RenderStyleMap::new() -> RenderStyleMap {
  RenderStyleMap(Map::new())
}

///|
pub fn RenderStyleMap::set(
  self : RenderStyleMap,
  id : String,
  style : RenderStyle,
) -> Unit {
  self.0.set(id, style)
}

///|
pub fn RenderStyleMap::get(self : RenderStyleMap, id : String) -> RenderStyle {
  match self.0.get(id) {
    Some(s) => s
    None => RenderStyle::default()
  }
}

///|
/// Map from node ID to text content
pub struct TextContentMap(Map[String, String])

///|
pub fn TextContentMap::new() -> TextContentMap {
  TextContentMap(Map::new())
}

///|
pub fn TextContentMap::set(
  self : TextContentMap,
  id : String,
  text : String,
) -> Unit {
  self.0.set(id, text)
}

///|
pub fn TextContentMap::get(self : TextContentMap, id : String) -> String? {
  self.0.get(id)
}
