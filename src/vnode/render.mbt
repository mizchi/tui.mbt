///|
/// Render TuiNode to crater Layout and CharBuffer

///|
/// Grid area placement info (package-visible for render_typed.mbt)
pub(all) struct GridAreaInfo {
  column : Int
  row : Int
  column_span : Int
  row_span : Int
}

///|
/// Render context holding styles and handlers
pub struct RenderContext {
  styles : Map[String, @core.RenderStyle]
  texts : Map[String, String]
  handlers : Map[String, (TuiEvent) -> Unit]
  mut id_counter : Int
  // Stack of grid area maps (for nested grids)
  area_stack : Array[Map[String, GridAreaInfo]]
}

///|
/// Create a new render context
pub fn RenderContext::new() -> RenderContext {
  { styles: {}, texts: {}, handlers: {}, id_counter: 0, area_stack: [] }
}

///|
/// Parse grid-template-areas and build area map
fn parse_grid_template_areas(
  areas : Array[String],
) -> Map[String, GridAreaInfo] {
  let result : Map[String, GridAreaInfo] = {}
  for row_idx, row_str in areas {
    let cells = row_str.split(" ").filter(fn(s) { s.length() > 0 }).collect()
    for col_idx, name_view in cells {
      let name = name_view.to_string()
      if name == "." {
        continue // Skip empty cells
      }
      match result.get(name) {
        Some(info) => {
          // Extend existing area
          let new_col_span = col_idx + 1 - info.column + 1
          let new_row_span = row_idx + 1 - info.row + 1
          result[name] = {
            column: info.column,
            row: info.row,
            column_span: if new_col_span > info.column_span {
              new_col_span
            } else {
              info.column_span
            },
            row_span: if new_row_span > info.row_span {
              new_row_span
            } else {
              info.row_span
            },
          }
        }
        None =>
          // New area - 1-indexed
          result[name] = {
            column: col_idx + 1,
            row: row_idx + 1,
            column_span: 1,
            row_span: 1,
          }
      }
    }
  }
  result
}

///|
/// Generate a unique ID
fn RenderContext::gen_id(self : RenderContext) -> String {
  self.id_counter = self.id_counter + 1
  "v" + self.id_counter.to_string()
}

///|
/// Visual style accumulator (used during attribute processing)
priv struct VisualStyle {
  mut fg : @core.Color?
  mut bg : @core.Color?
  mut bold : Bool
  mut underline : Bool
  mut border : @core.BorderChars?
  mut border_color : @core.Color?
}

///|
fn VisualStyle::default() -> VisualStyle {
  {
    fg: None,
    bg: None,
    bold: false,
    underline: false,
    border: None,
    border_color: None,
  }
}

///|
/// Convert TuiNode to crater Node
pub fn to_crater_node(ctx : RenderContext, node : TuiNode) -> @node.Node {
  match node {
    @luna.Node::Text(content) => {
      let id = ctx.gen_id()
      ctx.texts[id] = content
      let style = @style.Style::default()
      @node.Node::with_measure(id, style, @core.text_measure_func(content))
    }
    @luna.Node::DynamicText(getter) => {
      let id = ctx.gen_id()
      let content = getter()
      ctx.texts[id] = content
      let style = @style.Style::default()
      @node.Node::with_measure(id, style, @core.text_measure_func(content))
    }
    @luna.Node::Element(el) => convert_element(ctx, el)
    @luna.Node::Fragment(children) => {
      // Fragment becomes a column container
      let id = ctx.gen_id()
      let crater_children = children.map(fn(c) { to_crater_node(ctx, c) })
      let style = @style.Style::default()
      style.flex_direction = @types.FlexDirection::Column
      @node.Node::new(id, style, crater_children)
    }
    @luna.Node::Show(condition~, child~) =>
      if condition() {
        to_crater_node(ctx, child())
      } else {
        // Empty node
        let id = ctx.gen_id()
        let style = @style.Style::default()
        @node.Node::new(id, style, [])
      }
    @luna.Node::For(render~) => {
      let items = render()
      let id = ctx.gen_id()
      let style = @style.Style::default()
      style.flex_direction = @types.FlexDirection::Column
      let crater_children = items.map(fn(item) { to_crater_node(ctx, item) })
      @node.Node::new(id, style, crater_children)
    }
    @luna.Node::Component(render~) => to_crater_node(ctx, render())
    // Ignore SSR-specific nodes
    _ => {
      let id = ctx.gen_id()
      let style = @style.Style::default()
      @node.Node::new(id, style, [])
    }
  }
}

///|
/// Convert VElement to crater Node (type-safe with TuiAttrValue)
fn convert_element(
  ctx : RenderContext,
  el : @luna.VElement[TuiEvent, TuiAttrValue],
) -> @node.Node {
  // Get or generate ID and check for grid template areas
  let mut id = ""
  let mut grid_areas : Array[String]? = None
  let mut grid_area_name : String? = None
  for attr in el.attrs {
    match attr {
      ("id", @luna.Attr::VStatic(TuiAttrValue::Id(v))) => id = v
      ("id", @luna.Attr::VDynamic(getter)) =>
        match getter() {
          TuiAttrValue::Id(v) => id = v
          _ => ()
        }
      (
        "grid_template_areas",
        @luna.Attr::VStatic(TuiAttrValue::GridTemplateAreas(v)),
      ) => grid_areas = Some(v)
      ("grid_area", @luna.Attr::VStatic(TuiAttrValue::GridArea(v))) =>
        grid_area_name = Some(v)
      _ => ()
    }
  }
  if id.length() == 0 {
    id = ctx.gen_id()
  }

  // Create style
  let style = @style.Style::default()
  style.display = @types.Display::Flex

  // Track visual style
  let visual = VisualStyle::default()

  // Process attributes using typed values
  for attr in el.attrs {
    let (_, value) = attr
    match value {
      @luna.Attr::VStatic(typed_value) => apply_attr(style, visual, typed_value)
      @luna.Attr::VDynamic(getter) => apply_attr(style, visual, getter())
      @luna.Attr::VHandler(handler) => ctx.handlers[id] = handler.get_callback()
    }
  }

  // Resolve grid area from parent context
  match grid_area_name {
    Some(name) =>
      if ctx.area_stack.length() > 0 {
        let current_map = ctx.area_stack[ctx.area_stack.length() - 1]
        match current_map.get(name) {
          Some(info) => {
            style.grid_column = {
              start: @types.GridPlacement::Line(info.column),
              end: @types.GridPlacement::Span(info.column_span),
            }
            style.grid_row = {
              start: @types.GridPlacement::Line(info.row),
              end: @types.GridPlacement::Span(info.row_span),
            }
          }
          None => ()
        }
      }
    None => ()
  }

  // Store style if not default
  if visual.fg is Some(_) ||
    visual.bg is Some(_) ||
    visual.bold ||
    visual.underline ||
    visual.border is Some(_) {
    ctx.styles[id] = {
      fg: visual.fg.unwrap_or(@core.Color::white()),
      bg: visual.bg.unwrap_or(@core.Color::transparent()),
      bold: visual.bold,
      underline: visual.underline,
      border: visual.border,
      border_fg: visual.border_color.unwrap_or(@core.Color::white()),
    }
  }

  // Handle special tags
  match el.tag {
    "text" => {
      // Text wrapper - extract text content from children
      let mut text_content = ""
      for child in el.children {
        match child {
          @luna.Node::Text(content) => text_content = content
          @luna.Node::DynamicText(getter) => text_content = getter()
          _ => ()
        }
      }
      ctx.texts[id] = text_content
      @node.Node::with_measure(id, style, @core.text_measure_func(text_content))
    }
    "spacer" => {
      // Spacer has flex_grow by default
      if style.flex_grow == 0.0 {
        style.flex_grow = 1.0
      }
      @node.Node::new(id, style, [])
    }
    _ => {
      // Push grid area map if this is a grid container
      match grid_areas {
        Some(areas) => ctx.area_stack.push(parse_grid_template_areas(areas))
        None => ()
      }
      // Convert children
      let crater_children = el.children.map(fn(c) { to_crater_node(ctx, c) })
      // Pop grid area map
      match grid_areas {
        Some(_) => {
          let _ = ctx.area_stack.pop()

        }
        None => ()
      }
      @node.Node::new(id, style, crater_children)
    }
  }
}

///|
/// Apply typed attribute value to style and visual properties
fn apply_attr(
  style : @style.Style,
  visual : VisualStyle,
  attr : TuiAttrValue,
) -> Unit {
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
    // Display
    TuiAttrValue::Display(v) => style.display = v.to_display()
    // Grid container
    TuiAttrValue::GridTemplateColumns(v) => style.grid_template_columns = v
    TuiAttrValue::GridTemplateRows(v) => style.grid_template_rows = v
    TuiAttrValue::GridAutoFlow(v) =>
      style.grid_auto_flow = v.to_grid_auto_flow()
    // Grid item
    TuiAttrValue::GridColumn(v) =>
      style.grid_column = {
        start: @types.GridPlacement::Line(v),
        end: @types.GridPlacement::Auto,
      }
    TuiAttrValue::GridRow(v) =>
      style.grid_row = {
        start: @types.GridPlacement::Line(v),
        end: @types.GridPlacement::Auto,
      }
    TuiAttrValue::GridColumnSpan(v) =>
      style.grid_column = {
        start: style.grid_column.start,
        end: @types.GridPlacement::Span(v),
      }
    TuiAttrValue::GridRowSpan(v) =>
      style.grid_row = {
        start: style.grid_row.start,
        end: @types.GridPlacement::Span(v),
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
    TuiAttrValue::Border(v) => {
      visual.border = v.to_border_chars()
      match v.to_border_chars() {
        Some(_) => {
          let one = @types.Dimension::Length(1.0)
          style.border = @types.Rect::new(one, one, one, one)
        }
        None => ()
      }
    }
    TuiAttrValue::BorderColor(v) => visual.border_color = Some(v.to_color())
    TuiAttrValue::Fg(v) => visual.fg = Some(v.to_color())
    TuiAttrValue::Bg(v) => visual.bg = Some(v.to_color())
    TuiAttrValue::Bold(v) => visual.bold = v
    TuiAttrValue::Underline(v) => visual.underline = v
    TuiAttrValue::Id(_) => ()
    // Accessibility: TabIndex is metadata, doesn't affect layout
    TuiAttrValue::TabIndex(_) => ()
    // Grid template areas: handled in convert_element for context passing
    TuiAttrValue::GridTemplateAreas(_) => ()
    // Grid area: resolved in convert_element_with_area
    TuiAttrValue::GridArea(_) => ()
  }
}
