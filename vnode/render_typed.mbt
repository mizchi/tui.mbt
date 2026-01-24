///|
/// Type-safe render: TuiAttrValue -> crater Style
/// No string parsing needed - direct pattern matching
///
/// This will be the main render path when luna supports Attr[E, A]

///|
/// Apply typed attribute to crater style
fn apply_typed_attr(style : @style.Style, attr : TuiAttrValue) -> Unit {
  match attr {
    TuiAttrValue::Direction(v) => style.flex_direction = v.to_flex_direction()
    TuiAttrValue::Width(v) => style.width = v.to_dimension()
    TuiAttrValue::Height(v) => style.height = v.to_dimension()
    TuiAttrValue::MinWidth(v) => style.min_width = v.to_dimension()
    TuiAttrValue::MinHeight(v) => style.min_height = v.to_dimension()
    TuiAttrValue::FlexGrow(v) => style.flex_grow = v
    TuiAttrValue::FlexShrink(v) => style.flex_shrink = v
    TuiAttrValue::Gap(v) => {
      style.row_gap = @types.Dimension::Length(v)
      style.column_gap = @types.Dimension::Length(v)
    }
    TuiAttrValue::Padding(v) => {
      let len = @types.Dimension::Length(v)
      style.padding = @types.Rect::new(len, len, len, len)
    }
    TuiAttrValue::PaddingX(v) => {
      let len = @types.Dimension::Length(v)
      let current = style.padding
      style.padding = @types.Rect::new(current.top, len, current.bottom, len)
    }
    TuiAttrValue::PaddingY(v) => {
      let len = @types.Dimension::Length(v)
      let current = style.padding
      style.padding = @types.Rect::new(len, current.right, len, current.left)
    }
    TuiAttrValue::Margin(v) => {
      let len = @types.Dimension::Length(v)
      style.margin = @types.Rect::new(len, len, len, len)
    }
    TuiAttrValue::MarginX(v) => {
      let len = @types.Dimension::Length(v)
      let current = style.margin
      style.margin = @types.Rect::new(current.top, len, current.bottom, len)
    }
    TuiAttrValue::MarginY(v) => {
      let len = @types.Dimension::Length(v)
      let current = style.margin
      style.margin = @types.Rect::new(len, current.right, len, current.left)
    }
    TuiAttrValue::Justify(v) => style.justify_content = v.to_alignment()
    TuiAttrValue::Align(v) => style.align_items = v.to_alignment()
    TuiAttrValue::Border(v) =>
      match v.to_border_chars() {
        Some(_) => {
          let one = @types.Dimension::Length(1.0)
          style.border = @types.Rect::new(one, one, one, one)
        }
        None => ()
      }
    // Visual attributes are handled separately in RenderStyle
    TuiAttrValue::BorderColor(_) => ()
    TuiAttrValue::Fg(_) => ()
    TuiAttrValue::Bg(_) => ()
    TuiAttrValue::Bold(_) => ()
    TuiAttrValue::Underline(_) => ()
    TuiAttrValue::Id(_) => ()
  }
}

///|
/// Extract visual style from typed attributes
fn extract_render_style(
  attrs : Array[TuiAttrValue],
) -> (
  @core.Color?, // fg
  @core.Color?, // bg
  Bool, // bold
  Bool, // underline
  @core.BorderChars?, // border
  @core.Color?,
) { // border_color
  let mut fg : @core.Color? = None
  let mut bg : @core.Color? = None
  let mut bold = false
  let mut underline = false
  let mut border : @core.BorderChars? = None
  let mut border_color : @core.Color? = None
  for attr in attrs {
    match attr {
      TuiAttrValue::Fg(v) => fg = Some(v.to_color())
      TuiAttrValue::Bg(v) => bg = Some(v.to_color())
      TuiAttrValue::Bold(v) => bold = v
      TuiAttrValue::Underline(v) => underline = v
      TuiAttrValue::Border(v) => border = v.to_border_chars()
      TuiAttrValue::BorderColor(v) => border_color = Some(v.to_color())
      _ => ()
    }
  }
  (fg, bg, bold, underline, border, border_color)
}

// extract_id is not used yet - will be needed when luna supports Attr[E, A]
// fn extract_id(attrs : Array[TuiAttrValue]) -> String? {
//   for attr in attrs {
//     match attr {
//       TuiAttrValue::Id(id) => return Some(id)
//       _ => continue
//     }
//   }
//   None
// }

///|
/// Context for typed rendering
pub struct TypedRenderContext {
  styles : Map[String, @core.RenderStyle]
  texts : Map[String, String]
  handlers : Map[String, (TuiEvent) -> Unit]
  mut id_counter : Int
}

///|
pub fn TypedRenderContext::new() -> TypedRenderContext {
  { styles: {}, texts: {}, handlers: {}, id_counter: 0 }
}

///|
fn TypedRenderContext::gen_id(self : TypedRenderContext) -> String {
  self.id_counter = self.id_counter + 1
  "t" + self.id_counter.to_string()
}

///|
/// Convert BoxProps directly to crater node (type-safe path)
pub fn box_to_crater(
  ctx : TypedRenderContext,
  props : BoxProps,
  children : Array[TuiNode],
) -> @node.Node {
  let id = if props.id.length() > 0 { props.id } else { ctx.gen_id() }
  let attrs = props.to_attrs()
  // Apply layout attributes to style
  let style = @style.Style::default()
  style.display = @types.Display::Flex
  for attr in attrs {
    apply_typed_attr(style, attr)
  }
  // Extract visual style
  let (fg, bg, bold, underline, border, border_color) = extract_render_style(
    attrs,
  )
  if fg is Some(_) || bg is Some(_) || bold || underline || border is Some(_) {
    ctx.styles[id] = {
      fg: fg.unwrap_or(@core.Color::white()),
      bg: bg.unwrap_or(@core.Color::transparent()),
      bold,
      underline,
      border,
      border_fg: border_color.unwrap_or(@core.Color::white()),
    }
  }
  // Convert children recursively
  let crater_children = children.map(fn(c) { typed_to_crater_node(ctx, c) })
  @node.Node::new(id, style, crater_children)
}

///|
/// Convert TuiNode to crater node using typed render context
/// This version still parses strings but uses TypedRenderContext
/// Will be replaced when luna supports Attr[E, A]
fn typed_to_crater_node(ctx : TypedRenderContext, node : TuiNode) -> @node.Node {
  // Delegate to string-based render for now
  // This will be replaced with typed rendering when luna is updated
  let string_ctx : RenderContext = {
    styles: ctx.styles,
    texts: ctx.texts,
    handlers: ctx.handlers,
    id_counter: ctx.id_counter,
  }
  let result = to_crater_node(string_ctx, node)
  ctx.id_counter = string_ctx.id_counter
  result
}
