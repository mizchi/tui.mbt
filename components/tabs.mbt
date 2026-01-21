///|
/// Tabs - Tab navigation component

///|
/// Tab item data
pub(all) struct TabItem {
  label : String
  id : String
} derive(Eq)

///|
/// Tab orientation
pub(all) enum TabOrientation {
  Horizontal
  Vertical
}

///|
/// Create a tab bar
pub fn tabs(
  items : Array[TabItem],
  selected_id : String,
  id? : String = "",
  orientation? : TabOrientation = TabOrientation::Horizontal,
  // Style
  fg? : @core.Color = @core.Color::white(),
  bg? : @core.Color = @core.Color::rgb(40, 40, 50),
  selected_fg? : @core.Color = @core.Color::black(),
  selected_bg? : @core.Color = @core.Color::cyan(),
  // Spacing
  gap? : Double = 0.0,
  padding_x? : Double = 2.0,
  padding_y? : Double = 0.0,
) -> @core.Component {
  let tab_components : Array[@core.Component] = []
  for item in items {
    let is_selected = item.id == selected_id
    let (tab_fg, tab_bg) = if is_selected {
      (selected_fg, selected_bg)
    } else {
      (fg, bg)
    }
    tab_components.push(
      row(
        [text(item.label, fg=tab_fg)],
        id=item.id,
        padding_x~,
        padding_y~,
        bg=tab_bg,
      ),
    )
  }
  match orientation {
    TabOrientation::Horizontal => row(tab_components, id~, gap~)
    TabOrientation::Vertical => column(tab_components, id~, gap~)
  }
}

///|
/// Create a tab panel container
pub fn tab_panel(
  content : @core.Component,
  id? : String = "",
  border? : @core.BorderChars? = Some(@core.BorderChars::single()),
  border_color? : @core.Color = @core.Color::rgb(80, 80, 100),
  bg? : @core.Color = @core.Color::transparent(),
  padding? : Double = 1.0,
) -> @core.Component {
  column([content], id~, flex_grow=1.0, border~, border_color~, bg~, padding~)
}

///|
/// Convenience: tabs with panel layout (improved design)
pub fn tab_container(
  items : Array[TabItem],
  selected_id : String,
  content : @core.Component,
  id? : String = "",
  orientation? : TabOrientation = TabOrientation::Horizontal,
  // Style
  fg? : @core.Color = @core.Color::white(),
  bg? : @core.Color = @core.Color::rgb(40, 40, 50),
  selected_fg? : @core.Color = @core.Color::black(),
  selected_bg? : @core.Color = @core.Color::cyan(),
  border_color? : @core.Color = @core.Color::rgb(80, 80, 100),
) -> @core.Component {
  let tabs_component = tabs(
    items,
    selected_id,
    orientation~,
    fg~,
    bg~,
    selected_fg~,
    selected_bg~,
  )
  let panel = tab_panel(content, border_color~)
  match orientation {
    TabOrientation::Horizontal => column([tabs_component, panel], id~)
    TabOrientation::Vertical => row([tabs_component, panel], id~)
  }
}

///|
/// Tab bar with underline style
pub fn tabs_underline(
  items : Array[TabItem],
  selected_id : String,
  id? : String = "",
  // Style
  fg? : @core.Color = @core.Color::white(),
  selected_fg? : @core.Color = @core.Color::cyan(),
  underline_color? : @core.Color = @core.Color::cyan(),
  padding_x? : Double = 2.0,
) -> @core.Component {
  let tab_components : Array[@core.Component] = []
  for item in items {
    let is_selected = item.id == selected_id
    let tab_fg = if is_selected { selected_fg } else { fg }
    let underline_char = if is_selected { "━" } else { " " }
    let underline_len = item.label.length() + (padding_x * 2.0).to_int()
    tab_components.push(
      column([
        row([text(item.label, fg=tab_fg)], id=item.id, padding_x~),
        text(underline_char.repeat(underline_len), fg=underline_color),
      ]),
    )
  }
  row(tab_components, id~)
}

///|
/// Tab bar with boxed style (each tab has its own border)
pub fn tabs_boxed(
  items : Array[TabItem],
  selected_id : String,
  id? : String = "",
  // Style
  fg? : @core.Color = @core.Color::white(),
  bg? : @core.Color = @core.Color::rgb(40, 40, 50),
  selected_fg? : @core.Color = @core.Color::black(),
  selected_bg? : @core.Color = @core.Color::cyan(),
  border_color? : @core.Color = @core.Color::rgb(100, 100, 120),
  selected_border_color? : @core.Color = @core.Color::cyan(),
  padding_x? : Double = 1.0,
) -> @core.Component {
  let tab_components : Array[@core.Component] = []
  for item in items {
    let is_selected = item.id == selected_id
    let (tab_fg, tab_bg, tab_border_color) = if is_selected {
      (selected_fg, selected_bg, selected_border_color)
    } else {
      (fg, bg, border_color)
    }
    tab_components.push(
      row(
        [text(item.label, fg=tab_fg)],
        id=item.id,
        padding_x~,
        bg=tab_bg,
        border=Some(@core.BorderChars::rounded()),
        border_color=tab_border_color,
      ),
    )
  }
  row(tab_components, id~, gap=1.0)
}
