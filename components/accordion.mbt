///|
/// Accordion - Collapsible sections component

///|
/// Accordion item data
pub(all) struct AccordionItem {
  id : String
  title : String
  content : @core.Component
  expanded : Bool
}

///|
/// Create an accordion component with theme support
///
/// Visual design:
/// - Collapsed: ▶ Section Title
/// - Expanded:  ▼ Section Title (highlighted)
///              ┌─────────────────┐
///              │ Content here    │
///              └─────────────────┘
pub fn accordion(
  items : Array[AccordionItem],
  id? : String = "",
  focused_id? : String = "",
  theme? : Theme = Theme::default(),
  // Icons
  expanded_icon? : String = "▼",
  collapsed_icon? : String = "▶",
  // Spacing
  content_padding? : Double = 1.0,
  gap? : Double = 0.0,
) -> @core.Component {
  let sections : Array[@core.Component] = []
  for item in items {
    let is_focused = item.id == focused_id
    let icon = if item.expanded { expanded_icon } else { collapsed_icon }
    let header_fg = if is_focused {
      theme.focus
    } else if item.expanded {
      theme.primary
    } else {
      theme.fg
    }
    // Header with bold for expanded
    let header = row(
      [text(icon + " " + item.title, fg=header_fg, bold=item.expanded)],
      id=item.id + "-header",
      padding_x=1.0,
    )
    if item.expanded {
      // Build content with proper bordered box
      let content_section = column(
        [item.content],
        id=item.id + "-content",
        padding=content_padding,
        border=Some(@core.BorderChars::single()),
        border_color=theme.border,
      )
      sections.push(column([header, content_section], id=item.id))
    } else {
      sections.push(column([header], id=item.id))
    }
  }
  column(sections, id~, gap~)
}

///|
/// Single accordion section (header only) with theme support
pub fn accordion_header(
  title : String,
  expanded : Bool,
  id? : String = "",
  focused? : Bool = false,
  theme? : Theme = Theme::default(),
  expanded_icon? : String = "▼",
  collapsed_icon? : String = "▶",
  padding_x? : Double = 1.0,
  padding_y? : Double = 0.0,
  // Event handler
  on_click? : (() -> Unit)? = None,
) -> @core.Component {
  let icon = if expanded { expanded_icon } else { collapsed_icon }
  let fg = if focused {
    theme.focus
  } else if expanded {
    theme.primary
  } else {
    theme.fg
  }
  row(
    [text(icon + " " + title, fg~, bold=expanded)],
    id~,
    padding_x~,
    padding_y~,
    on_click~,
    role=Some(@core.Role::Button),
  )
}
