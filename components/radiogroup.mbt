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
/// Create a radio group component
pub fn radiogroup(
  options : Array[RadioOption],
  selected_id : String,
  id? : String = "",
  orientation? : RadioOrientation = RadioOrientation::Vertical,
  // Style
  fg? : @core.Color = @core.Color::white(),
  selected_fg? : @core.Color = @core.Color::cyan(),
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
    let (icon, color) = if is_selected {
      (selected_icon, selected_fg)
    } else {
      (unselected_icon, fg)
    }
    let item = row(
      [text(icon, fg=color), hspace(item_gap), text(option.label, fg=color)],
      id=option.id,
    )
    items.push(item)
  }
  match orientation {
    RadioOrientation::Horizontal => {
      // Use larger gap for horizontal layout if not specified
      let actual_gap = if gap == 0.0 { 2.0 } else { gap }
      row(items, id~, gap=actual_gap)
    }
    RadioOrientation::Vertical => column(items, id~, gap~)
  }
}

///|
/// Single radio button
pub fn radio(
  label : String,
  selected : Bool,
  id? : String = "",
  fg? : @core.Color = @core.Color::white(),
  selected_fg? : @core.Color = @core.Color::cyan(),
  selected_icon? : String = "◉",
  unselected_icon? : String = "○",
  gap? : Double = 1.0,
) -> @core.Component {
  let (icon, color) = if selected {
    (selected_icon, selected_fg)
  } else {
    (unselected_icon, fg)
  }
  row([text(icon, fg=color), hspace(gap), text(label, fg=color)], id~)
}
