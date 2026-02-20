///|
/// Render crater Layout to CharBuffer

///|
/// Render Layout to CharBuffer
pub fn render_layout(
  buf : CharBuffer,
  layout : @types.Layout,
  styles : @core.RenderStyleMap,
  texts : @core.TextContentMap,
  offset_x : Int,
  offset_y : Int,
) -> Unit {
  render_layout_f(
    buf,
    layout,
    styles,
    texts,
    offset_x.to_double(),
    offset_y.to_double(),
  )
}

///|
fn render_layout_f(
  buf : CharBuffer,
  layout : @types.Layout,
  styles : @core.RenderStyleMap,
  texts : @core.TextContentMap,
  offset_x : Double,
  offset_y : Double,
) -> Unit {
  let abs_x = offset_x + layout.x
  let abs_y = offset_y + layout.y
  let rect = @core.normalize_grid_rect(
    abs_x,
    abs_y,
    layout.width,
    layout.height,
  )
  let x = rect.x
  let y = rect.y
  let w = rect.width
  let h = rect.height
  let style = styles.get(layout.id)
  // Fill background if not transparent
  if not(style.bg.is_transparent()) {
    buf.fill_bg(x, y, w, h, style.bg)
  }
  // Draw border if specified
  match style.border {
    Some(border) => draw_border(buf, x, y, w, h, border, style.border_fg)
    None => ()
  }
  // Draw text content if present
  match texts.get(layout.id) {
    Some(text) => {
      let has_border = style.border is Some(_)
      let border_inset = if has_border { 1.0 } else { 0.0 }
      let content_rect = @core.normalize_grid_rect_with_inset(
        abs_x,
        abs_y,
        layout.width,
        layout.height,
        border_inset + layout.padding.left,
        border_inset + layout.padding.top,
        border_inset + layout.padding.right,
        border_inset + layout.padding.bottom,
      )
      let content_x = content_rect.x
      let content_y = content_rect.y
      let content_w = content_rect.width
      let content_h = content_rect.height
      if content_w > 0 && content_h > 0 {
        let text_style : TextStyle = {
          fg: style.fg,
          bg: @core.Color::transparent(),
          bold: style.bold,
          underline: style.underline,
        }
        let _ = buf.write_text_wrapped(
          content_x, content_y, text, text_style, content_w, content_h,
        )
      }
    }
    None => ()
  }
  // Render children
  for child in layout.children {
    render_layout_f(buf, child, styles, texts, abs_x, abs_y)
  }
}

///|
fn draw_border(
  buf : CharBuffer,
  x : Int,
  y : Int,
  w : Int,
  h : Int,
  border : @core.BorderChars,
  fg : @core.Color,
) -> Unit {
  if w < 2 || h < 2 {
    return
  }
  // Top-left corner
  buf.set_cell(x, y, { ..CharCell::default(), char: border.top_left, fg })
  // Top-right corner
  buf.set_cell(x + w - 1, y, {
    ..CharCell::default(),
    char: border.top_right,
    fg,
  })
  // Bottom-left corner
  buf.set_cell(x, y + h - 1, {
    ..CharCell::default(),
    char: border.bottom_left,
    fg,
  })
  // Bottom-right corner
  buf.set_cell(x + w - 1, y + h - 1, {
    ..CharCell::default(),
    char: border.bottom_right,
    fg,
  })
  // Top and bottom edges
  for col = x + 1; col < x + w - 1; col = col + 1 {
    buf.set_cell(col, y, { ..CharCell::default(), char: border.horizontal, fg })
    buf.set_cell(col, y + h - 1, {
      ..CharCell::default(),
      char: border.horizontal,
      fg,
    })
  }
  // Left and right edges
  for row = y + 1; row < y + h - 1; row = row + 1 {
    buf.set_cell(x, row, { ..CharCell::default(), char: border.vertical, fg })
    buf.set_cell(x + w - 1, row, {
      ..CharCell::default(),
      char: border.vertical,
      fg,
    })
  }
}

///|
/// Quick render function: Layout -> ANSI string
pub fn render_to_ansi(
  layout : @types.Layout,
  styles : @core.RenderStyleMap,
  texts : @core.TextContentMap,
  width : Int,
  height : Int,
) -> String {
  let buf = CharBuffer::new(width, height)
  render_layout(buf, layout, styles, texts, 0, 0)
  buf.to_ansi()
}
