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
/// Create an accordion component
pub fn accordion(
  items : Array[AccordionItem],
  id? : String = "",
  // Style
  header_fg? : @core.Color = @core.Color::white(),
  header_bg? : @core.Color = @core.Color::rgb(50, 50, 60),
  content_bg? : @core.Color = @core.Color::transparent(),
  border_color? : @core.Color = @core.Color::rgb(80, 80, 80),
  // Icons
  expanded_icon? : String = "▼",
  collapsed_icon? : String = "▶",
  // Spacing
  header_padding_x? : Double = 1.0,
  header_padding_y? : Double = 0.0,
  content_padding? : Double = 1.0,
  gap? : Double = 0.0,
) -> @core.Component {
  let sections : Array[@core.Component] = []
  for item in items {
    let icon = if item.expanded { expanded_icon } else { collapsed_icon }
    let header = row(
      [text(icon + " " + item.title, fg=header_fg)],
      id=item.id + "-header",
      bg=header_bg,
      padding_x=header_padding_x,
      padding_y=header_padding_y,
    )
    if item.expanded {
      let content_section = column(
        [item.content],
        id=item.id + "-content",
        bg=content_bg,
        padding=content_padding,
        border=Some(@core.BorderChars::single()),
        border_color~,
      )
      sections.push(column([header, content_section], id=item.id))
    } else {
      sections.push(column([header], id=item.id))
    }
  }
  column(sections, id~, gap~)
}

///|
/// Single accordion section (header only)
pub fn accordion_header(
  title : String,
  expanded : Bool,
  id? : String = "",
  fg? : @core.Color = @core.Color::white(),
  bg? : @core.Color = @core.Color::rgb(50, 50, 60),
  expanded_icon? : String = "▼",
  collapsed_icon? : String = "▶",
  padding_x? : Double = 1.0,
  padding_y? : Double = 0.0,
) -> @core.Component {
  let icon = if expanded { expanded_icon } else { collapsed_icon }
  row([text(icon + " " + title, fg~)], id~, bg~, padding_x~, padding_y~)
}
