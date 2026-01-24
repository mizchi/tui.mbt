///|
/// Type-safe TUI DSL
/// Produces typed attributes using luna's Attr[E, A] with A = TuiAttrValue

// =============================================================================
// Attribute helpers
// =============================================================================

///|
/// Create a static typed attribute
pub fn attr(value : TuiAttrValue) -> TuiAttr {
  @luna.attr_static(value)
}

///|
/// Create a dynamic typed attribute
pub fn attr_dyn(getter : () -> TuiAttrValue) -> TuiAttr {
  @luna.attr_dynamic(getter)
}

///|
/// Create an event handler attribute
pub fn on(handler : (TuiEvent) -> Unit) -> TuiAttr {
  @luna.attr_handler(@luna.handler(handler))
}

///|
/// Convert typed attributes array to luna attrs array
fn typed_attrs_to_luna(attrs : Array[TuiAttrValue]) -> Array[(String, TuiAttr)] {
  attrs.map(fn(a) {
    let key = attr_key(a)
    (key, @luna.attr_static(a))
  })
}

///|
/// Get the attribute key name from TuiAttrValue
fn attr_key(attr : TuiAttrValue) -> String {
  match attr {
    TuiAttrValue::Direction(_) => "direction"
    TuiAttrValue::Width(_) => "width"
    TuiAttrValue::Height(_) => "height"
    TuiAttrValue::MinWidth(_) => "min_width"
    TuiAttrValue::MinHeight(_) => "min_height"
    TuiAttrValue::FlexGrow(_) => "flex_grow"
    TuiAttrValue::FlexShrink(_) => "flex_shrink"
    TuiAttrValue::Gap(_) => "gap"
    TuiAttrValue::Padding(_) => "padding"
    TuiAttrValue::PaddingX(_) => "padding_x"
    TuiAttrValue::PaddingY(_) => "padding_y"
    TuiAttrValue::Margin(_) => "margin"
    TuiAttrValue::MarginX(_) => "margin_x"
    TuiAttrValue::MarginY(_) => "margin_y"
    TuiAttrValue::Justify(_) => "justify"
    TuiAttrValue::Align(_) => "align"
    TuiAttrValue::Border(_) => "border"
    TuiAttrValue::BorderColor(_) => "border_color"
    TuiAttrValue::Fg(_) => "fg"
    TuiAttrValue::Bg(_) => "bg"
    TuiAttrValue::Bold(_) => "bold"
    TuiAttrValue::Underline(_) => "underline"
    TuiAttrValue::Id(_) => "id"
  }
}

// =============================================================================
// Type-safe container builders
// =============================================================================

///|
/// Box properties for type-safe construction
pub struct BoxProps {
  id : String
  direction : DirectionValue
  width : DimensionValue
  height : DimensionValue
  min_width : DimensionValue
  min_height : DimensionValue
  flex_grow : Double
  flex_shrink : Double
  gap : Double
  padding : Double
  padding_x : Double
  padding_y : Double
  margin : Double
  margin_x : Double
  margin_y : Double
  justify : AlignmentValue?
  align : AlignmentValue?
  border : BorderValue
  border_color : ColorValue?
  bg : ColorValue?
}

///|
pub fn BoxProps::default() -> BoxProps {
  {
    id: "",
    direction: Row,
    width: Auto,
    height: Auto,
    min_width: Auto,
    min_height: Auto,
    flex_grow: 0.0,
    flex_shrink: 1.0,
    gap: 0.0,
    padding: 0.0,
    padding_x: 0.0,
    padding_y: 0.0,
    margin: 0.0,
    margin_x: 0.0,
    margin_y: 0.0,
    justify: None,
    align: None,
    border: None,
    border_color: None,
    bg: None,
  }
}

///|
/// Convert BoxProps to typed attributes
pub fn BoxProps::to_attrs(self : BoxProps) -> Array[TuiAttrValue] {
  let attrs : Array[TuiAttrValue] = [TuiAttrValue::Direction(self.direction)]
  if self.id.length() > 0 {
    attrs.push(TuiAttrValue::Id(self.id))
  }
  match self.width {
    Auto => ()
    _ => attrs.push(TuiAttrValue::Width(self.width))
  }
  match self.height {
    Auto => ()
    _ => attrs.push(TuiAttrValue::Height(self.height))
  }
  match self.min_width {
    Auto => ()
    _ => attrs.push(TuiAttrValue::MinWidth(self.min_width))
  }
  match self.min_height {
    Auto => ()
    _ => attrs.push(TuiAttrValue::MinHeight(self.min_height))
  }
  if self.flex_grow > 0.0 {
    attrs.push(TuiAttrValue::FlexGrow(self.flex_grow))
  }
  if self.flex_shrink != 1.0 {
    attrs.push(TuiAttrValue::FlexShrink(self.flex_shrink))
  }
  if self.gap > 0.0 {
    attrs.push(TuiAttrValue::Gap(self.gap))
  }
  if self.padding > 0.0 {
    attrs.push(TuiAttrValue::Padding(self.padding))
  }
  if self.padding_x > 0.0 {
    attrs.push(TuiAttrValue::PaddingX(self.padding_x))
  }
  if self.padding_y > 0.0 {
    attrs.push(TuiAttrValue::PaddingY(self.padding_y))
  }
  if self.margin > 0.0 {
    attrs.push(TuiAttrValue::Margin(self.margin))
  }
  if self.margin_x > 0.0 {
    attrs.push(TuiAttrValue::MarginX(self.margin_x))
  }
  if self.margin_y > 0.0 {
    attrs.push(TuiAttrValue::MarginY(self.margin_y))
  }
  match self.justify {
    Some(v) => attrs.push(TuiAttrValue::Justify(v))
    None => ()
  }
  match self.align {
    Some(v) => attrs.push(TuiAttrValue::Align(v))
    None => ()
  }
  match self.border {
    None => ()
    _ => attrs.push(TuiAttrValue::Border(self.border))
  }
  match self.border_color {
    Some(v) => attrs.push(TuiAttrValue::BorderColor(v))
    None => ()
  }
  match self.bg {
    Some(v) => attrs.push(TuiAttrValue::Bg(v))
    None => ()
  }
  attrs
}

///|
/// Create a box node from typed props
pub fn box_node(props : BoxProps, children : Array[TuiNode]) -> TuiNode {
  let attrs = typed_attrs_to_luna(props.to_attrs())
  @luna.h("box", attrs, children)
}

///|
/// Text properties
pub struct TextProps {
  content : String
  fg : ColorValue?
  bold : Bool
  underline : Bool
}

///|
pub fn TextProps::default(content : String) -> TextProps {
  { content, fg: None, bold: false, underline: false }
}

///|
pub fn TextProps::to_attrs(self : TextProps) -> Array[TuiAttrValue] {
  let attrs : Array[TuiAttrValue] = []
  match self.fg {
    Some(v) => attrs.push(TuiAttrValue::Fg(v))
    None => ()
  }
  if self.bold {
    attrs.push(TuiAttrValue::Bold(true))
  }
  if self.underline {
    attrs.push(TuiAttrValue::Underline(true))
  }
  attrs
}

///|
/// Create a text node from typed props
pub fn text_node(props : TextProps) -> TuiNode {
  let attrs = props.to_attrs()
  if attrs.length() > 0 {
    @luna.h("text", typed_attrs_to_luna(attrs), [@luna.text(props.content)])
  } else {
    @luna.text(props.content)
  }
}

// =============================================================================
// Convenience DSL functions (matching old string-based API)
// =============================================================================

///|
/// Shared box attribute builder - extracts common logic from row/column
fn build_box_attrs(
  direction : DirectionValue,
  id : String,
  gap : Double,
  margin : Double,
  margin_x : Double,
  margin_y : Double,
  padding : Double,
  padding_x : Double,
  padding_y : Double,
  width : Double,
  height : Double,
  min_width : Double,
  min_height : Double,
  flex_grow : Double,
  justify : String,
  align : String,
  border : String,
  border_color : String,
  bg : String,
  on_click : ((TuiEvent) -> Unit)?,
) -> Array[(String, TuiAttr)] {
  let attrs : Array[(String, TuiAttr)] = [
    ("direction", attr(TuiAttrValue::Direction(direction))),
  ]
  if id.length() > 0 {
    attrs.push(("id", attr(TuiAttrValue::Id(id))))
  }
  if gap > 0.0 {
    attrs.push(("gap", attr(TuiAttrValue::Gap(gap))))
  }
  if margin > 0.0 {
    attrs.push(("margin", attr(TuiAttrValue::Margin(margin))))
  }
  if margin_x > 0.0 {
    attrs.push(("margin_x", attr(TuiAttrValue::MarginX(margin_x))))
  }
  if margin_y > 0.0 {
    attrs.push(("margin_y", attr(TuiAttrValue::MarginY(margin_y))))
  }
  if padding > 0.0 {
    attrs.push(("padding", attr(TuiAttrValue::Padding(padding))))
  }
  if padding_x > 0.0 {
    attrs.push(("padding_x", attr(TuiAttrValue::PaddingX(padding_x))))
  }
  if padding_y > 0.0 {
    attrs.push(("padding_y", attr(TuiAttrValue::PaddingY(padding_y))))
  }
  if width >= 0.0 {
    attrs.push(
      ("width", attr(TuiAttrValue::Width(DimensionValue::Length(width)))),
    )
  }
  if height >= 0.0 {
    attrs.push(
      ("height", attr(TuiAttrValue::Height(DimensionValue::Length(height)))),
    )
  }
  if min_width >= 0.0 {
    attrs.push(
      (
        "min_width",
        attr(TuiAttrValue::MinWidth(DimensionValue::Length(min_width))),
      ),
    )
  }
  if min_height >= 0.0 {
    attrs.push(
      (
        "min_height",
        attr(TuiAttrValue::MinHeight(DimensionValue::Length(min_height))),
      ),
    )
  }
  if flex_grow > 0.0 {
    attrs.push(("flex_grow", attr(TuiAttrValue::FlexGrow(flex_grow))))
  }
  if justify.length() > 0 {
    attrs.push(
      ("justify", attr(TuiAttrValue::Justify(parse_alignment_value(justify)))),
    )
  }
  if align.length() > 0 {
    attrs.push(
      ("align", attr(TuiAttrValue::Align(parse_alignment_value(align)))),
    )
  }
  if border.length() > 0 {
    attrs.push(
      ("border", attr(TuiAttrValue::Border(parse_border_value(border)))),
    )
  }
  if border_color.length() > 0 {
    attrs.push(
      (
        "border_color",
        attr(TuiAttrValue::BorderColor(parse_color_value(border_color))),
      ),
    )
  }
  if bg.length() > 0 {
    attrs.push(("bg", attr(TuiAttrValue::Bg(parse_color_value(bg)))))
  }
  match on_click {
    Some(handler) => attrs.push(("on_click", on(handler)))
    None => ()
  }
  attrs
}

///|
/// Row container (horizontal flex)
pub fn row(
  children : Array[TuiNode],
  id? : String = "",
  gap? : Double = 0.0,
  margin? : Double = 0.0,
  margin_x? : Double = 0.0,
  margin_y? : Double = 0.0,
  padding? : Double = 0.0,
  padding_x? : Double = 0.0,
  padding_y? : Double = 0.0,
  width? : Double = -1.0,
  height? : Double = -1.0,
  min_width? : Double = -1.0,
  min_height? : Double = -1.0,
  flex_grow? : Double = 0.0,
  justify? : String = "",
  align? : String = "",
  border? : String = "",
  border_color? : String = "",
  bg? : String = "",
  on_click? : ((TuiEvent) -> Unit)? = None,
) -> TuiNode {
  let attrs = build_box_attrs(
    DirectionValue::Row,
    id,
    gap,
    margin,
    margin_x,
    margin_y,
    padding,
    padding_x,
    padding_y,
    width,
    height,
    min_width,
    min_height,
    flex_grow,
    justify,
    align,
    border,
    border_color,
    bg,
    on_click,
  )
  @luna.h("box", attrs, children)
}

///|
/// Column container (vertical flex)
pub fn column(
  children : Array[TuiNode],
  id? : String = "",
  gap? : Double = 0.0,
  margin? : Double = 0.0,
  margin_x? : Double = 0.0,
  margin_y? : Double = 0.0,
  padding? : Double = 0.0,
  padding_x? : Double = 0.0,
  padding_y? : Double = 0.0,
  width? : Double = -1.0,
  height? : Double = -1.0,
  min_width? : Double = -1.0,
  min_height? : Double = -1.0,
  flex_grow? : Double = 0.0,
  justify? : String = "",
  align? : String = "",
  border? : String = "",
  border_color? : String = "",
  bg? : String = "",
  on_click? : ((TuiEvent) -> Unit)? = None,
) -> TuiNode {
  let attrs = build_box_attrs(
    DirectionValue::Column,
    id,
    gap,
    margin,
    margin_x,
    margin_y,
    padding,
    padding_x,
    padding_y,
    width,
    height,
    min_width,
    min_height,
    flex_grow,
    justify,
    align,
    border,
    border_color,
    bg,
    on_click,
  )
  @luna.h("box", attrs, children)
}

///|
/// Static text node
pub fn text(
  content : String,
  fg? : String = "",
  bold? : Bool = false,
) -> TuiNode {
  if fg.length() > 0 || bold {
    let attrs : Array[(String, TuiAttr)] = []
    if fg.length() > 0 {
      attrs.push(("fg", attr(TuiAttrValue::Fg(parse_color_value(fg)))))
    }
    if bold {
      attrs.push(("bold", attr(TuiAttrValue::Bold(true))))
    }
    @luna.h("text", attrs, [@luna.text(content)])
  } else {
    @luna.text(content)
  }
}

///|
/// Dynamic text node
pub fn text_dyn(
  getter : () -> String,
  fg? : String = "",
  bold? : Bool = false,
) -> TuiNode {
  if fg.length() > 0 || bold {
    let attrs : Array[(String, TuiAttr)] = []
    if fg.length() > 0 {
      attrs.push(("fg", attr(TuiAttrValue::Fg(parse_color_value(fg)))))
    }
    if bold {
      attrs.push(("bold", attr(TuiAttrValue::Bold(true))))
    }
    @luna.h("text", attrs, [@luna.text_dyn(getter)])
  } else {
    @luna.text_dyn(getter)
  }
}

///|
/// Flexible spacer
pub fn spacer() -> TuiNode {
  @luna.h("spacer", [("flex_grow", attr(TuiAttrValue::FlexGrow(1.0)))], [])
}

///|
/// Horizontal space with fixed width
pub fn hspace(width : Double) -> TuiNode {
  @luna.h(
    "spacer",
    [
      ("width", attr(TuiAttrValue::Width(DimensionValue::Length(width)))),
      ("flex_grow", attr(TuiAttrValue::FlexGrow(0.0))),
      ("flex_shrink", attr(TuiAttrValue::FlexShrink(0.0))),
    ],
    [],
  )
}

///|
/// Vertical space with fixed height
pub fn vspace(height : Double) -> TuiNode {
  @luna.h(
    "spacer",
    [
      ("height", attr(TuiAttrValue::Height(DimensionValue::Length(height)))),
      ("flex_grow", attr(TuiAttrValue::FlexGrow(0.0))),
      ("flex_shrink", attr(TuiAttrValue::FlexShrink(0.0))),
    ],
    [],
  )
}

///|
/// Conditional rendering
pub fn show(when : () -> Bool, child : () -> TuiNode) -> TuiNode {
  @luna.show(when, child)
}

///|
/// List rendering
pub fn for_each(items : () -> Array[TuiNode]) -> TuiNode {
  @luna.for_each(items)
}

///|
/// Component boundary
pub fn component(render : () -> TuiNode) -> TuiNode {
  @luna.component(render)
}

///|
/// Fragment
pub fn fragment(children : Array[TuiNode]) -> TuiNode {
  @luna.fragment(children)
}

// =============================================================================
// String parsing helpers (for backward compatibility with string-based API)
// =============================================================================

///|
fn parse_alignment_value(s : String) -> AlignmentValue {
  match s {
    "start" => AlignmentValue::Start
    "center" => AlignmentValue::Center
    "end" => AlignmentValue::End
    "stretch" => AlignmentValue::Stretch
    "space-between" => AlignmentValue::SpaceBetween
    "space-around" => AlignmentValue::SpaceAround
    "space-evenly" => AlignmentValue::SpaceEvenly
    "flex-start" => AlignmentValue::FlexStart
    "flex-end" => AlignmentValue::FlexEnd
    _ => AlignmentValue::FlexStart
  }
}

///|
fn parse_border_value(s : String) -> BorderValue {
  match s {
    "single" => BorderValue::Single
    "double" => BorderValue::Double
    "rounded" => BorderValue::Rounded
    "ascii" => BorderValue::Ascii
    "none" => BorderValue::None
    _ => BorderValue::Single
  }
}

///|
fn parse_color_value(s : String) -> ColorValue {
  if s.has_prefix("rgb(") && s.has_suffix(")") && s.length() > 5 {
    let inner = s.view(start_offset=4, end_offset=s.length() - 1)
    let parts = inner.split(",").collect()
    if parts.length() == 3 {
      let r = try? @strconv.parse_int(parts[0].to_string().trim(chars=" "))
      let g = try? @strconv.parse_int(parts[1].to_string().trim(chars=" "))
      let b = try? @strconv.parse_int(parts[2].to_string().trim(chars=" "))
      match (r, g, b) {
        (Ok(r), Ok(g), Ok(b)) => return ColorValue::Rgb(r, g, b)
        _ => ()
      }
    }
  }
  ColorValue::Named(s)
}

// =============================================================================
// Attribute to string conversion (for debugging/testing)
// =============================================================================

///|
/// Convert TuiAttrValue to (key, value) string pair
pub fn attr_to_string(attr : TuiAttrValue) -> (String, String) {
  let key = attr_key(attr)
  let value = match attr {
    TuiAttrValue::Direction(v) =>
      match v {
        DirectionValue::Row => "row"
        DirectionValue::Column => "column"
      }
    TuiAttrValue::Width(v) => dimension_to_string(v)
    TuiAttrValue::Height(v) => dimension_to_string(v)
    TuiAttrValue::MinWidth(v) => dimension_to_string(v)
    TuiAttrValue::MinHeight(v) => dimension_to_string(v)
    TuiAttrValue::FlexGrow(v) => v.to_int().to_string()
    TuiAttrValue::FlexShrink(v) => v.to_int().to_string()
    TuiAttrValue::Gap(v) => v.to_int().to_string()
    TuiAttrValue::Padding(v) => v.to_int().to_string()
    TuiAttrValue::PaddingX(v) => v.to_int().to_string()
    TuiAttrValue::PaddingY(v) => v.to_int().to_string()
    TuiAttrValue::Margin(v) => v.to_int().to_string()
    TuiAttrValue::MarginX(v) => v.to_int().to_string()
    TuiAttrValue::MarginY(v) => v.to_int().to_string()
    TuiAttrValue::Justify(v) => alignment_to_string(v)
    TuiAttrValue::Align(v) => alignment_to_string(v)
    TuiAttrValue::Border(v) => border_to_string(v)
    TuiAttrValue::BorderColor(v) => color_to_string(v)
    TuiAttrValue::Fg(v) => color_to_string(v)
    TuiAttrValue::Bg(v) => color_to_string(v)
    TuiAttrValue::Bold(v) => if v { "true" } else { "false" }
    TuiAttrValue::Underline(v) => if v { "true" } else { "false" }
    TuiAttrValue::Id(v) => v
  }
  (key, value)
}

///|
fn dimension_to_string(v : DimensionValue) -> String {
  match v {
    DimensionValue::Auto => "auto"
    DimensionValue::Length(n) => n.to_int().to_string()
    DimensionValue::Percent(n) => n.to_int().to_string() + "%"
  }
}

///|
fn alignment_to_string(v : AlignmentValue) -> String {
  match v {
    AlignmentValue::Start => "start"
    AlignmentValue::Center => "center"
    AlignmentValue::End => "end"
    AlignmentValue::Stretch => "stretch"
    AlignmentValue::SpaceBetween => "space-between"
    AlignmentValue::SpaceAround => "space-around"
    AlignmentValue::SpaceEvenly => "space-evenly"
    AlignmentValue::FlexStart => "flex-start"
    AlignmentValue::FlexEnd => "flex-end"
  }
}

///|
fn border_to_string(v : BorderValue) -> String {
  match v {
    BorderValue::None => "none"
    BorderValue::Single => "single"
    BorderValue::Double => "double"
    BorderValue::Rounded => "rounded"
    BorderValue::Ascii => "ascii"
  }
}

///|
fn color_to_string(v : ColorValue) -> String {
  match v {
    ColorValue::Transparent => "transparent"
    ColorValue::Named(name) => name
    ColorValue::Rgb(r, g, b) =>
      "rgb(" + r.to_string() + "," + g.to_string() + "," + b.to_string() + ")"
  }
}
