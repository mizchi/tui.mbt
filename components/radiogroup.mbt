///|
/// RadioGroup - Radio button selection component

///|
/// Radio option data
pub(all) struct RadioOption {
  id : String
  label : String
} derive(Eq)

///|
/// Radio group orientation
pub(all) enum RadioOrientation {
  Horizontal
  Vertical
}

///|
/// Create a radio group component with theme support
pub fn radiogroup(
  options : Array[RadioOption],
  selected_id : String,
  id? : String = "",
  focused_id? : String = "",
  orientation? : RadioOrientation = RadioOrientation::Vertical,
  theme? : Theme = Theme::default(),
  // Icons
  selected_icon? : String = "◉",
  unselected_icon? : String = "○",
  // Spacing
  gap? : Double = 0.0,
  item_gap? : Double = 1.0,
) -> @core.Component {
  let items : Array[@core.Component] = []
  for option in options {
    let is_selected = option.id == selected_id
    let is_focused = option.id == focused_id
    let (icon, color) = if is_focused {
      (if is_selected { selected_icon } else { unselected_icon }, theme.focus)
    } else if is_selected {
      (selected_icon, theme.primary)
    } else {
      (unselected_icon, theme.fg)
    }
    let item = row(
      [text(icon, fg=color), hspace(item_gap), text(option.label, fg=color)],
      id=option.id,
      role=Some(@core.Role::Radio),
    )
    items.push(item)
  }
  match orientation {
    RadioOrientation::Horizontal => {
      // Use larger gap for horizontal layout if not specified
      let actual_gap = if gap == 0.0 { 2.0 } else { gap }
      row(items, id~, gap=actual_gap, role=Some(@core.Role::Radiogroup))
    }
    RadioOrientation::Vertical =>
      column(items, id~, gap~, role=Some(@core.Role::Radiogroup))
  }
}

///|
/// Single radio button
pub fn radio(
  label : String,
  selected : Bool,
  id? : String = "",
  focused? : Bool = false,
  theme? : Theme = Theme::default(),
  selected_icon? : String = "◉",
  unselected_icon? : String = "○",
  gap? : Double = 1.0,
) -> @core.Component {
  let icon = if selected { selected_icon } else { unselected_icon }
  let color = if focused {
    theme.focus
  } else if selected {
    theme.primary
  } else {
    theme.fg
  }
  row(
    [text(icon, fg=color), hspace(gap), text(label, fg=color)],
    id~,
    role=Some(@core.Role::Radio),
  )
}
