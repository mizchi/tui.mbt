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
/// Create a simple tab bar (no content)
pub fn tabs(
  items : Array[TabItem],
  selected_id : String,
  id? : String = "",
  focused_id? : String = "",
  theme? : Theme = Theme::default(),
  padding_x? : Double = 2.0,
) -> @core.Component {
  let tab_components : Array[@core.Component] = []
  for item in items {
    let is_selected = item.id == selected_id
    let is_focused = item.id == focused_id
    let is_active = is_selected || is_focused
    let tab_fg = if is_focused {
      theme.focus
    } else if is_selected {
      theme.primary
    } else {
      theme.fg
    }
    tab_components.push(
      row(
        [text(item.label, fg=tab_fg, bold=is_active)],
        id=item.id,
        padding_x~,
        role=Some(@core.Role::Tab),
      ),
    )
  }
  row(tab_components, id~, role=Some(@core.Role::Tablist))
}

///|
/// Create a tab panel container
pub fn tab_panel(
  content : @core.Component,
  id? : String = "",
  theme? : Theme = Theme::default(),
  border? : @core.BorderChars? = Some(@core.BorderChars::single()),
  padding? : Double = 1.0,
) -> @core.Component {
  column(
    [content],
    id~,
    flex_grow=1.0,
    border~,
    border_color=theme.border,
    padding~,
  )
}

///|
/// Integrated tab container - tabs with border, content panel below
/// Visual design: active tab connects to content panel
///  ╭──────╮
///  │ Home │  Profile   Settings
///  ╰──┬───╯
/// ╭───┴─────────────────────────╮
/// │ Content here                │
/// ╰─────────────────────────────╯
pub fn tab_container(
  items : Array[TabItem],
  selected_id : String,
  content : @core.Component,
  id? : String = "",
  focused_id? : String = "",
  theme? : Theme = Theme::default(),
  padding_x? : Double = 1.0,
) -> @core.Component {
  // Build tab header as text lines
  let mut line1 = "" // Top border (╭──╮ for active)
  let mut line2 = "" // Labels (│XX│ for active)
  let mut line3 = "" // Bottom border with connector (╰─┬─╯ for active)
  let has_focused = items.iter().any(fn(i) { i.id == focused_id })
  let tab_color = if has_focused { theme.focus } else { theme.primary }
  for item in items {
    let is_selected = item.id == selected_id
    let is_focused = item.id == focused_id
    let is_active = is_selected || is_focused
    let label_width = item.label.length() + (padding_x * 2.0).to_int()
    if is_active {
      // Active tab: full border with connector at bottom center
      line1 = line1 + "╭" + "─".repeat(label_width) + "╮"
      line2 = line2 +
        "│" +
        " ".repeat(padding_x.to_int()) +
        item.label +
        " ".repeat(padding_x.to_int()) +
        "│"
      // Bottom with ┬ connector in middle
      let half = label_width / 2
      line3 = line3 +
        "╰" +
        "─".repeat(half) +
        "┬" +
        "─".repeat(label_width - half - 1) +
        "╯"
    } else {
      // Inactive tab: no border
      line1 = line1 + " ".repeat(label_width + 2)
      line2 = line2 +
        " " +
        " ".repeat(padding_x.to_int()) +
        item.label +
        " ".repeat(padding_x.to_int()) +
        " "
      line3 = line3 + " ".repeat(label_width + 2)
    }
  }
  // Content panel with connector at top
  let content_panel = column(
    [content],
    id=id + "-content",
    flex_grow=1.0,
    padding=1.0,
    border=Some({
      top_left: '╭',
      top_right: '╮',
      bottom_left: '╰',
      bottom_right: '╯',
      horizontal: '─',
      vertical: '│',
    }),
    border_color=tab_color,
  )
  // Build component
  column(
    [
      row([text(line1, fg=tab_color)], height=@types.Dimension::Length(1.0)),
      row([text(line2, fg=tab_color)], height=@types.Dimension::Length(1.0)),
      row([text(line3, fg=tab_color)], height=@types.Dimension::Length(1.0)),
      content_panel,
    ],
    id~,
  )
}

///|
/// Tab bar with underline style
/// Visual: active tabs have bold text and thick underline (━)
pub fn tabs_underline(
  items : Array[TabItem],
  selected_id : String,
  id? : String = "",
  focused_id? : String = "",
  theme? : Theme = Theme::default(),
  padding_x? : Double = 1.0,
) -> @core.Component {
  let tab_components : Array[@core.Component] = []
  for item in items {
    let is_selected = item.id == selected_id
    let is_focused = item.id == focused_id
    let is_active = is_selected || is_focused
    let tab_fg = if is_focused {
      theme.focus
    } else if is_selected {
      theme.primary
    } else {
      theme.fg
    }
    // Active tabs have thick underline, inactive have thin line
    let underline_char = if is_active { "━" } else { "─" }
    let underline_color = if is_focused {
      theme.focus
    } else if is_selected {
      theme.primary
    } else {
      theme.border
    }
    let underline_len = item.label.length() + (padding_x * 2.0).to_int()
    tab_components.push(
      column([
        row(
          [text(item.label, fg=tab_fg, bold=is_active)],
          id=item.id,
          padding_x~,
          role=Some(@core.Role::Tab),
        ),
        text(underline_char.repeat(underline_len), fg=underline_color),
      ]),
    )
  }
  row(tab_components, id~, role=Some(@core.Role::Tablist))
}

///|
/// Tab bar with boxed style (each tab has its own border)
/// Visual: active tabs have bold text and colored border
pub fn tabs_boxed(
  items : Array[TabItem],
  selected_id : String,
  id? : String = "",
  focused_id? : String = "",
  theme? : Theme = Theme::default(),
  padding_x? : Double = 1.0,
) -> @core.Component {
  let tab_components : Array[@core.Component] = []
  for item in items {
    let is_selected = item.id == selected_id
    let is_focused = item.id == focused_id
    let is_active = is_selected || is_focused
    let (tab_fg, tab_border) = if is_focused {
      (theme.focus, theme.focus)
    } else if is_selected {
      (theme.primary, theme.primary)
    } else {
      (theme.fg, theme.border)
    }
    tab_components.push(
      row(
        [text(item.label, fg=tab_fg, bold=is_active)],
        id=item.id,
        padding_x~,
        border=Some(@core.BorderChars::rounded()),
        border_color=tab_border,
        role=Some(@core.Role::Tab),
      ),
    )
  }
  row(tab_components, id~, gap=1.0, role=Some(@core.Role::Tablist))
}
