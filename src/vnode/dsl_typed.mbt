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
    TuiAttrValue::Display(_) => "display"
    TuiAttrValue::GridTemplateColumns(_) => "grid_template_columns"
    TuiAttrValue::GridTemplateRows(_) => "grid_template_rows"
    TuiAttrValue::GridAutoFlow(_) => "grid_auto_flow"
    TuiAttrValue::GridColumn(_) => "grid_column"
    TuiAttrValue::GridRow(_) => "grid_row"
    TuiAttrValue::GridColumnSpan(_) => "grid_column_span"
    TuiAttrValue::GridRowSpan(_) => "grid_row_span"
    TuiAttrValue::GridTemplateAreas(_) => "grid_template_areas"
    TuiAttrValue::GridArea(_) => "grid_area"
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
    TuiAttrValue::TabIndex(_) => "tab_index"
    TuiAttrValue::Role(_) => "role"
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
  tab_index : Int
  role : @core.Role?
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
    tab_index: -1,
    role: None,
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
  if self.tab_index >= 0 {
    attrs.push(TuiAttrValue::TabIndex(self.tab_index))
  }
  match self.role {
    Some(v) => attrs.push(TuiAttrValue::Role(v))
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
  role : @core.Role?
}

///|
pub fn TextProps::default(content : String) -> TextProps {
  { content, fg: None, bold: false, underline: false, role: None }
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
  match self.role {
    Some(v) => attrs.push(TuiAttrValue::Role(v))
    None => ()
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
  role : String,
  tab_index : Int,
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
  if role.length() > 0 {
    attrs.push(("role", attr(TuiAttrValue::Role(parse_role_value(role)))))
  }
  // TabIndex: -1 means not focusable (excluded), 0+ sets tab order
  if tab_index >= 0 {
    attrs.push(("tab_index", attr(TuiAttrValue::TabIndex(tab_index))))
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
  role? : String = "",
  tab_index? : Int = -1,
  on_click? : ((TuiEvent) -> Unit)? = None,
  children : Array[TuiNode],
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
    role,
    tab_index,
    on_click,
  )
  @luna.h("box", attrs, children)
}

///|
/// Column container (vertical flex)
pub fn column(
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
  role? : String = "",
  tab_index? : Int = -1,
  on_click? : ((TuiEvent) -> Unit)? = None,
  children : Array[TuiNode],
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
    role,
    tab_index,
    on_click,
  )
  @luna.h("box", attrs, children)
}

///|
/// Generic view container (flex layout with configurable direction)
/// Default direction is column (React Native style)
pub fn view(
  direction? : String = "column",
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
  role? : String = "",
  tab_index? : Int = -1,
  on_click? : ((TuiEvent) -> Unit)? = None,
  children : Array[TuiNode],
) -> TuiNode {
  let dir = if direction == "row" {
    DirectionValue::Row
  } else {
    DirectionValue::Column
  }
  let attrs = build_box_attrs(
    dir, id, gap, margin, margin_x, margin_y, padding, padding_x, padding_y, width,
    height, min_width, min_height, flex_grow, justify, align, border, border_color,
    bg, role, tab_index, on_click,
  )
  @luna.h("box", attrs, children)
}

///|
/// Grid container with CSS Grid layout
/// Supports both explicit columns/rows and named areas
pub fn grid(
  columns? : Array[Double] = [],
  rows? : Array[Double] = [],
  areas? : Array[String] = [],
  auto_flow? : String = "row",
  id? : String = "",
  gap? : Double = 0.0,
  padding? : Double = 0.0,
  padding_x? : Double = 0.0,
  padding_y? : Double = 0.0,
  width? : Double = -1.0,
  height? : Double = -1.0,
  border? : String = "",
  border_color? : String = "",
  bg? : String = "",
  role? : String = "",
  tab_index? : Int = -1,
  children : Array[TuiNode],
) -> TuiNode {
  let attrs : Array[(String, TuiAttr)] = [
    ("display", attr(TuiAttrValue::Display(DisplayValue::Grid))),
  ]
  // Grid template areas (takes precedence for column/row count if provided)
  if areas.length() > 0 {
    attrs.push(
      ("grid_template_areas", attr(TuiAttrValue::GridTemplateAreas(areas))),
    )
    // Auto-generate rows based on areas count
    if rows.length() == 0 {
      let row_tracks = Array::makei(areas.length(), fn(_i) {
        @types.TrackSizingFunction::Fr(1.0)
      })
      attrs.push(
        ("grid_template_rows", attr(TuiAttrValue::GridTemplateRows(row_tracks))),
      )
    }
    // Auto-generate columns based on first area row
    if columns.length() == 0 && areas.length() > 0 {
      let first_row = areas[0]
        .split(" ")
        .filter(fn(s) { s.length() > 0 })
        .collect()
      let col_count = first_row.length()
      let col_tracks = Array::makei(col_count, fn(_i) {
        @types.TrackSizingFunction::Fr(1.0)
      })
      attrs.push(
        (
          "grid_template_columns",
          attr(TuiAttrValue::GridTemplateColumns(col_tracks)),
        ),
      )
    }
  }
  // Grid template columns (convert Double array to fr values)
  if columns.length() > 0 {
    let tracks = columns.map(fn(v) { @types.TrackSizingFunction::Fr(v) })
    attrs.push(
      ("grid_template_columns", attr(TuiAttrValue::GridTemplateColumns(tracks))),
    )
  }
  // Grid template rows
  if rows.length() > 0 {
    let tracks = rows.map(fn(v) { @types.TrackSizingFunction::Fr(v) })
    attrs.push(
      ("grid_template_rows", attr(TuiAttrValue::GridTemplateRows(tracks))),
    )
  }
  // Grid auto flow
  let flow = match auto_flow {
    "column" => GridAutoFlowValue::Column
    "row-dense" => GridAutoFlowValue::RowDense
    "column-dense" => GridAutoFlowValue::ColumnDense
    _ => GridAutoFlowValue::Row
  }
  attrs.push(("grid_auto_flow", attr(TuiAttrValue::GridAutoFlow(flow))))
  // Common attributes
  if id.length() > 0 {
    attrs.push(("id", attr(TuiAttrValue::Id(id))))
  }
  if gap > 0.0 {
    attrs.push(("gap", attr(TuiAttrValue::Gap(gap))))
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
  if role.length() > 0 {
    attrs.push(("role", attr(TuiAttrValue::Role(parse_role_value(role)))))
  }
  if tab_index >= 0 {
    attrs.push(("tab_index", attr(TuiAttrValue::TabIndex(tab_index))))
  }
  @luna.h("box", attrs, children)
}

///|
/// Grid item with placement control (explicit column/row positioning)
pub fn grid_item(
  column? : Int = 0,
  row? : Int = 0,
  column_span? : Int = 1,
  row_span? : Int = 1,
  tab_index? : Int = -1,
  child~ : TuiNode,
) -> TuiNode {
  let attrs : Array[(String, TuiAttr)] = []
  // Column placement (1-indexed)
  if column > 0 {
    attrs.push(("grid_column", attr(TuiAttrValue::GridColumn(column))))
  }
  // Row placement (1-indexed)
  if row > 0 {
    attrs.push(("grid_row", attr(TuiAttrValue::GridRow(row))))
  }
  // Column span
  if column_span > 1 {
    attrs.push(
      ("grid_column_span", attr(TuiAttrValue::GridColumnSpan(column_span))),
    )
  }
  // Row span
  if row_span > 1 {
    attrs.push(("grid_row_span", attr(TuiAttrValue::GridRowSpan(row_span))))
  }
  // Tab index for focus management
  if tab_index >= 0 {
    attrs.push(("tab_index", attr(TuiAttrValue::TabIndex(tab_index))))
  }
  @luna.h("box", attrs, [child])
}

///|
/// Grid area - place child in a named grid area
/// Used with grid(areas=[...]) for semantic layout
pub fn grid_area(name : String, child : TuiNode) -> TuiNode {
  let attrs : Array[(String, TuiAttr)] = [
    ("grid_area", attr(TuiAttrValue::GridArea(name))),
  ]
  @luna.h("box", attrs, [child])
}

///|
/// Static text node
pub fn text(
  content : String,
  fg? : String = "",
  bold? : Bool = false,
  role? : String = "",
) -> TuiNode {
  if fg.length() > 0 || bold || role.length() > 0 {
    let attrs : Array[(String, TuiAttr)] = []
    if fg.length() > 0 {
      attrs.push(("fg", attr(TuiAttrValue::Fg(parse_color_value(fg)))))
    }
    if bold {
      attrs.push(("bold", attr(TuiAttrValue::Bold(true))))
    }
    if role.length() > 0 {
      attrs.push(("role", attr(TuiAttrValue::Role(parse_role_value(role)))))
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
  role? : String = "",
) -> TuiNode {
  if fg.length() > 0 || bold || role.length() > 0 {
    let attrs : Array[(String, TuiAttr)] = []
    if fg.length() > 0 {
      attrs.push(("fg", attr(TuiAttrValue::Fg(parse_color_value(fg)))))
    }
    if bold {
      attrs.push(("bold", attr(TuiAttrValue::Bold(true))))
    }
    if role.length() > 0 {
      attrs.push(("role", attr(TuiAttrValue::Role(parse_role_value(role)))))
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

///|
fn parse_role_value(s : String) -> @core.Role {
  let v = s.to_lower()
  if v.has_prefix("custom:") && v.length() > 7 {
    return @core.Role::Custom(v.view(start_offset=7).to_string())
  }
  match v {
    "button" => @core.Role::Button
    "checkbox" => @core.Role::Checkbox
    "link" => @core.Role::Link
    "menuitem" => @core.Role::Menuitem
    "option" => @core.Role::Option
    "radio" => @core.Role::Radio
    "slider" => @core.Role::Slider
    "switch" => @core.Role::Switch
    "tab" => @core.Role::Tab
    "textbox" => @core.Role::Textbox
    "listbox" => @core.Role::Listbox
    "menu" => @core.Role::Menu
    "menubar" => @core.Role::Menubar
    "radiogroup" => @core.Role::Radiogroup
    "tablist" => @core.Role::Tablist
    "tree" => @core.Role::Tree
    "treegrid" => @core.Role::Treegrid
    "article" => @core.Role::Article
    "cell" => @core.Role::Cell
    "columnheader" => @core.Role::Columnheader
    "definition" => @core.Role::Definition
    "directory" => @core.Role::Directory
    "document" => @core.Role::Document
    "group" => @core.Role::Group
    "heading" => @core.Role::Heading
    "img" => @core.Role::Img
    "list" => @core.Role::List
    "listitem" => @core.Role::Listitem
    "row" => @core.Role::Row
    "rowgroup" => @core.Role::Rowgroup
    "rowheader" => @core.Role::Rowheader
    "separator" => @core.Role::Separator
    "table" => @core.Role::Table
    "term" => @core.Role::Term
    "banner" => @core.Role::Banner
    "complementary" => @core.Role::Complementary
    "contentinfo" => @core.Role::Contentinfo
    "form" => @core.Role::Form
    "main" => @core.Role::Main
    "navigation" => @core.Role::Navigation
    "region" => @core.Role::Region
    "search" => @core.Role::Search
    "alert" => @core.Role::Alert
    "log" => @core.Role::Log
    "marquee" => @core.Role::Marquee
    "status" => @core.Role::Status
    "timer" => @core.Role::Timer
    "alertdialog" => @core.Role::Alertdialog
    "dialog" => @core.Role::Dialog
    _ => @core.Role::Custom(s)
  }
}

///|
fn role_to_string(role : @core.Role) -> String {
  match role {
    Button => "button"
    Checkbox => "checkbox"
    Link => "link"
    Menuitem => "menuitem"
    Option => "option"
    Radio => "radio"
    Slider => "slider"
    Switch => "switch"
    Tab => "tab"
    Textbox => "textbox"
    Listbox => "listbox"
    Menu => "menu"
    Menubar => "menubar"
    Radiogroup => "radiogroup"
    Tablist => "tablist"
    Tree => "tree"
    Treegrid => "treegrid"
    Article => "article"
    Cell => "cell"
    Columnheader => "columnheader"
    Definition => "definition"
    Directory => "directory"
    Document => "document"
    Group => "group"
    Heading => "heading"
    Img => "img"
    List => "list"
    Listitem => "listitem"
    Row => "row"
    Rowgroup => "rowgroup"
    Rowheader => "rowheader"
    Separator => "separator"
    Table => "table"
    Term => "term"
    Banner => "banner"
    Complementary => "complementary"
    Contentinfo => "contentinfo"
    Form => "form"
    Main => "main"
    Navigation => "navigation"
    Region => "region"
    Search => "search"
    Alert => "alert"
    Log => "log"
    Marquee => "marquee"
    Status => "status"
    Timer => "timer"
    Alertdialog => "alertdialog"
    Dialog => "dialog"
    Custom(name) => name
  }
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
    TuiAttrValue::Display(v) => display_to_string(v)
    TuiAttrValue::GridTemplateColumns(v) => track_list_to_string(v)
    TuiAttrValue::GridTemplateRows(v) => track_list_to_string(v)
    TuiAttrValue::GridAutoFlow(v) => grid_auto_flow_to_string(v)
    TuiAttrValue::GridColumn(v) => v.to_string()
    TuiAttrValue::GridRow(v) => v.to_string()
    TuiAttrValue::GridColumnSpan(v) => v.to_string()
    TuiAttrValue::GridRowSpan(v) => v.to_string()
    TuiAttrValue::GridTemplateAreas(v) =>
      v.map(fn(s) { "\"" + s + "\"" }).join(" ")
    TuiAttrValue::GridArea(v) => v
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
    TuiAttrValue::TabIndex(v) => v.to_string()
    TuiAttrValue::Role(v) => role_to_string(v)
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

///|
fn display_to_string(v : DisplayValue) -> String {
  match v {
    DisplayValue::Flex => "flex"
    DisplayValue::Grid => "grid"
  }
}

///|
fn grid_auto_flow_to_string(v : GridAutoFlowValue) -> String {
  match v {
    GridAutoFlowValue::Row => "row"
    GridAutoFlowValue::Column => "column"
    GridAutoFlowValue::RowDense => "row-dense"
    GridAutoFlowValue::ColumnDense => "column-dense"
  }
}

///|
fn track_list_to_string(tracks : Array[@types.TrackSizingFunction]) -> String {
  tracks.map(fn(t) { track_sizing_to_string(t) }).join(" ")
}

///|
fn track_sizing_to_string(t : @types.TrackSizingFunction) -> String {
  match t {
    @types.TrackSizingFunction::Length(v) => v.to_int().to_string() + "px"
    @types.TrackSizingFunction::Percent(v) =>
      (v * 100.0).to_int().to_string() + "%"
    @types.TrackSizingFunction::Fr(v) => v.to_string() + "fr"
    @types.TrackSizingFunction::Auto => "auto"
    @types.TrackSizingFunction::MinContent => "min-content"
    @types.TrackSizingFunction::MaxContent => "max-content"
    _ => "auto"
  }
}
