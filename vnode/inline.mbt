///|
/// Inline rendering for TuiNodes
/// Renders nodes to an array of lines with ANSI colors
/// No screen clearing or cursor positioning - suitable for inline CLI prompts

///|
/// Inline visual context for tracking text styles
priv struct InlineStyle {
  fg : @core.Color?
  bg : @core.Color?
  bold : Bool
  underline : Bool
}

///|
fn InlineStyle::default() -> InlineStyle {
  { fg: None, bg: None, bold: false, underline: false }
}

///|
/// Merge two optional colors (child overrides parent)
fn merge_color(child : @core.Color?, parent : @core.Color?) -> @core.Color? {
  match child {
    Some(_) => child
    None => parent
  }
}

///|
/// Apply inline style to text, returning ANSI-escaped string
fn apply_inline_style(text : String, style : InlineStyle) -> String {
  let mut prefix = ""
  if style.bold {
    prefix = prefix + @render.ansi_bold()
  }
  if style.underline {
    prefix = prefix + @render.ansi_underline()
  }
  match style.fg {
    Some(color) => prefix = prefix + @render.ansi_fg_color(color)
    None => ()
  }
  match style.bg {
    Some(color) => prefix = prefix + @render.ansi_bg_color(color)
    None => ()
  }
  if prefix.length() > 0 {
    prefix + text + @render.ansi_reset()
  } else {
    text
  }
}

///|
/// Extract inline style from element attributes
fn extract_inline_style(
  el : @luna.VElement[TuiEvent, TuiAttrValue],
) -> InlineStyle {
  let mut fg : @core.Color? = None
  let mut bg : @core.Color? = None
  let mut bold = false
  let mut underline = false
  for attr in el.attrs {
    let (_, value) = attr
    match value {
      @luna.Attr::VStatic(typed_value) =>
        match typed_value {
          TuiAttrValue::Fg(v) => fg = Some(v.to_color())
          TuiAttrValue::Bg(v) => bg = Some(v.to_color())
          TuiAttrValue::Bold(v) => bold = v
          TuiAttrValue::Underline(v) => underline = v
          _ => ()
        }
      @luna.Attr::VDynamic(getter) =>
        match getter() {
          TuiAttrValue::Fg(v) => fg = Some(v.to_color())
          TuiAttrValue::Bg(v) => bg = Some(v.to_color())
          TuiAttrValue::Bold(v) => bold = v
          TuiAttrValue::Underline(v) => underline = v
          _ => ()
        }
      _ => ()
    }
  }
  { fg, bg, bold, underline }
}

///|
/// Check if element is a row (horizontal layout)
fn is_row(el : @luna.VElement[TuiEvent, TuiAttrValue]) -> Bool {
  for attr in el.attrs {
    let (_, value) = attr
    match value {
      @luna.Attr::VStatic(TuiAttrValue::Direction(Row)) => return true
      @luna.Attr::VStatic(TuiAttrValue::Direction(Column)) => return false
      @luna.Attr::VDynamic(getter) =>
        match getter() {
          TuiAttrValue::Direction(Row) => return true
          TuiAttrValue::Direction(Column) => return false
          _ => ()
        }
      _ => ()
    }
  }
  // Default: row tag is row, everything else is column
  el.tag == "row"
}

///|
/// Render a TuiNode to a single string (for horizontal concatenation)
fn render_inline_text(node : TuiNode, parent_style : InlineStyle) -> String {
  match node {
    @luna.Node::Text(content) => apply_inline_style(content, parent_style)
    @luna.Node::DynamicText(getter) =>
      apply_inline_style(getter(), parent_style)
    @luna.Node::Element(el) => {
      let style = extract_inline_style(el)
      // Merge with parent style (child overrides)
      let merged : InlineStyle = {
        fg: merge_color(style.fg, parent_style.fg),
        bg: merge_color(style.bg, parent_style.bg),
        bold: style.bold || parent_style.bold,
        underline: style.underline || parent_style.underline,
      }
      match el.tag {
        "text" => {
          // Text element - extract text content from children
          let mut text_content = ""
          for child in el.children {
            match child {
              @luna.Node::Text(content) => text_content = content
              @luna.Node::DynamicText(getter) => text_content = getter()
              _ => ()
            }
          }
          apply_inline_style(text_content, merged)
        }
        "spacer" => " "
        "hspace" => " "
        _ => {
          // Container - concatenate children
          let parts : Array[String] = []
          for child in el.children {
            parts.push(render_inline_text(child, merged))
          }
          parts.join("")
        }
      }
    }
    @luna.Node::Fragment(children) => {
      let parts : Array[String] = []
      for child in children {
        parts.push(render_inline_text(child, parent_style))
      }
      parts.join("")
    }
    @luna.Node::Show(condition~, child~) =>
      if condition() {
        render_inline_text(child(), parent_style)
      } else {
        ""
      }
    @luna.Node::For(render~) => {
      let items = render()
      let parts : Array[String] = []
      for item in items {
        parts.push(render_inline_text(item, parent_style))
      }
      parts.join("")
    }
    @luna.Node::Component(render~) => render_inline_text(render(), parent_style)
    _ => ""
  }
}

///|
/// Render a TuiNode to an array of lines
/// Each line is a complete string with ANSI escape codes
pub fn render_to_lines(node : TuiNode) -> Array[String] {
  render_to_lines_with_style(node, InlineStyle::default())
}

///|
/// Render with inherited style
fn render_to_lines_with_style(
  node : TuiNode,
  parent_style : InlineStyle,
) -> Array[String] {
  match node {
    @luna.Node::Text(content) => [apply_inline_style(content, parent_style)]
    @luna.Node::DynamicText(getter) =>
      [apply_inline_style(getter(), parent_style)]
    @luna.Node::Element(el) => {
      let style = extract_inline_style(el)
      let merged : InlineStyle = {
        fg: merge_color(style.fg, parent_style.fg),
        bg: merge_color(style.bg, parent_style.bg),
        bold: style.bold || parent_style.bold,
        underline: style.underline || parent_style.underline,
      }
      match el.tag {
        "text" => {
          let mut text_content = ""
          for child in el.children {
            match child {
              @luna.Node::Text(content) => text_content = content
              @luna.Node::DynamicText(getter) => text_content = getter()
              _ => ()
            }
          }
          [apply_inline_style(text_content, merged)]
        }
        "spacer" => [""]
        "hspace" => [""]
        "vspace" => [""]
        _ =>
          if is_row(el) {
            // Row: concatenate children horizontally into one line
            let parts : Array[String] = []
            for child in el.children {
              parts.push(render_inline_text(child, merged))
            }
            [parts.join("")]
          } else {
            // Column: each child becomes one or more lines
            let lines : Array[String] = []
            for child in el.children {
              let child_lines = render_to_lines_with_style(child, merged)
              for line in child_lines {
                lines.push(line)
              }
            }
            lines
          }
      }
    }
    @luna.Node::Fragment(children) => {
      let lines : Array[String] = []
      for child in children {
        let child_lines = render_to_lines_with_style(child, parent_style)
        for line in child_lines {
          lines.push(line)
        }
      }
      lines
    }
    @luna.Node::Show(condition~, child~) =>
      if condition() {
        render_to_lines_with_style(child(), parent_style)
      } else {
        []
      }
    @luna.Node::For(render~) => {
      let items = render()
      let lines : Array[String] = []
      for item in items {
        let item_lines = render_to_lines_with_style(item, parent_style)
        for line in item_lines {
          lines.push(line)
        }
      }
      lines
    }
    @luna.Node::Component(render~) =>
      render_to_lines_with_style(render(), parent_style)
    _ => []
  }
}
