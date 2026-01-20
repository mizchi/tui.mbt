///|
/// Listbox - Selection list component (single/multi select)

///|
/// Listbox option
pub(all) struct ListboxOption {
  id : String
  label : String
  disabled : Bool
} derive(Eq)

///|
/// Create a listbox option
pub fn listbox_option(
  id : String,
  label : String,
  disabled? : Bool = false,
) -> ListboxOption {
  { id, label, disabled }
}

///|
/// Listbox orientation
pub(all) enum ListboxOrientation {
  Vertical
  Horizontal
}

///|
/// Listbox state
pub(all) struct ListboxState {
  focused_id : String
  selected_ids : Array[String]
  anchor_id : String // for shift+click range selection
}

///|
/// Create initial listbox state
pub fn ListboxState::new(
  initial_selected? : Array[String] = [],
) -> ListboxState {
  { focused_id: "", selected_ids: initial_selected, anchor_id: "" }
}

///|
/// Create a single-select listbox
pub fn listbox(
  options : Array[ListboxOption],
  selected_id : String,
  id? : String = "",
  focused_id? : String = "",
  orientation? : ListboxOrientation = ListboxOrientation::Vertical,
  // Style
  fg? : @core.Color = @core.Color::white(),
  bg? : @core.Color = @core.Color::rgb(40, 40, 50),
  selected_fg? : @core.Color = @core.Color::black(),
  selected_bg? : @core.Color = @core.Color::cyan(),
  focused_border? : @core.Color = @core.Color::yellow(),
  disabled_fg? : @core.Color = @core.Color::rgb(100, 100, 100),
  border_color? : @core.Color = @core.Color::rgb(80, 80, 80),
  // Size
  min_width? : Double = 20.0,
  max_height? : Int = 10,
  padding_x? : Double = 1.0,
) -> @core.Component {
  let state : ListboxState = {
    focused_id,
    selected_ids: [selected_id],
    anchor_id: selected_id,
  }
  build_listbox(
    options, state, false, // multiselectable
     orientation, id, fg, bg, selected_fg, selected_bg, focused_border, disabled_fg,
    border_color, min_width, max_height, padding_x,
  )
}

///|
/// Create a multi-select listbox
pub fn listbox_multi(
  options : Array[ListboxOption],
  state : ListboxState,
  id? : String = "",
  orientation? : ListboxOrientation = ListboxOrientation::Vertical,
  // Style
  fg? : @core.Color = @core.Color::white(),
  bg? : @core.Color = @core.Color::rgb(40, 40, 50),
  selected_fg? : @core.Color = @core.Color::black(),
  selected_bg? : @core.Color = @core.Color::cyan(),
  focused_border? : @core.Color = @core.Color::yellow(),
  disabled_fg? : @core.Color = @core.Color::rgb(100, 100, 100),
  border_color? : @core.Color = @core.Color::rgb(80, 80, 80),
  // Size
  min_width? : Double = 20.0,
  max_height? : Int = 10,
  padding_x? : Double = 1.0,
) -> @core.Component {
  build_listbox(
    options, state, true, // multiselectable
     orientation, id, fg, bg, selected_fg, selected_bg, focused_border, disabled_fg,
    border_color, min_width, max_height, padding_x,
  )
}

///|
fn build_listbox(
  options : Array[ListboxOption],
  state : ListboxState,
  multiselectable : Bool,
  orientation : ListboxOrientation,
  id : String,
  fg : @core.Color,
  bg : @core.Color,
  selected_fg : @core.Color,
  selected_bg : @core.Color,
  focused_border : @core.Color,
  disabled_fg : @core.Color,
  border_color : @core.Color,
  min_width : Double,
  max_height : Int,
  padding_x : Double,
) -> @core.Component {
  let items : Array[@core.Component] = []
  let visible_count = if options.length() > max_height {
    max_height
  } else {
    options.length()
  }
  for i = 0; i < visible_count; i = i + 1 {
    let opt = options[i]
    let is_selected = state.selected_ids.contains(opt.id)
    let is_focused = state.focused_id == opt.id

    // Determine colors
    let (item_fg, item_bg) = if opt.disabled {
      (disabled_fg, bg)
    } else if is_selected {
      (selected_fg, selected_bg)
    } else {
      (fg, bg)
    }

    // Build option item
    let label_text = if multiselectable {
      // Show checkbox for multi-select
      let check_icon = if is_selected { "[✓]" } else { "[ ]" }
      check_icon + " " + opt.label
    } else {
      opt.label
    }

    // Add focus indicator
    let focus_indicator = if is_focused { "▸ " } else { "  " }
    let item = row(
      [text(focus_indicator + label_text, fg=item_fg)],
      id=opt.id,
      padding_x~,
      bg=item_bg,
      border=if is_focused { Some(@core.BorderChars::single()) } else { None },
      border_color=focused_border,
    )
    items.push(item)
  }

  // Add scroll indicator if needed
  if options.length() > max_height {
    let remaining = options.length() - max_height
    items.push(
      row(
        [text("  ... " + remaining.to_string() + " more", fg=disabled_fg)],
        padding_x~,
      ),
    )
  }

  // Build container based on orientation
  match orientation {
    ListboxOrientation::Vertical =>
      column(
        items,
        id~,
        min_width=@types.Dimension::Length(min_width),
        bg~,
        border=Some(@core.BorderChars::single()),
        border_color~,
      )
    ListboxOrientation::Horizontal =>
      row(
        items,
        id~,
        min_width=@types.Dimension::Length(min_width),
        bg~,
        border=Some(@core.BorderChars::single()),
        border_color~,
      )
  }
}

///|
/// Simple option list without border (for embedding)
pub fn option_list(
  options : Array[ListboxOption],
  selected_ids : Array[String],
  focused_id? : String = "",
  multiselectable? : Bool = false,
  // Style
  fg? : @core.Color = @core.Color::white(),
  bg? : @core.Color = @core.Color::transparent(),
  selected_fg? : @core.Color = @core.Color::black(),
  selected_bg? : @core.Color = @core.Color::cyan(),
  disabled_fg? : @core.Color = @core.Color::rgb(100, 100, 100),
) -> @core.Component {
  let items : Array[@core.Component] = []
  for opt in options {
    let is_selected = selected_ids.contains(opt.id)
    let is_focused = focused_id == opt.id
    let (item_fg, item_bg) = if opt.disabled {
      (disabled_fg, bg)
    } else if is_selected {
      (selected_fg, selected_bg)
    } else {
      (fg, bg)
    }
    let label_text = if multiselectable {
      let check = if is_selected { "[✓]" } else { "[ ]" }
      check + " " + opt.label
    } else {
      opt.label
    }
    let focus_prefix = if is_focused { "▸ " } else { "  " }
    items.push(
      row([text(focus_prefix + label_text, fg=item_fg)], id=opt.id, bg=item_bg),
    )
  }
  column(items)
}

///|
/// Inline selectable list (no box styling)
pub fn selectable_list(
  items_data : Array[(String, String)], // (id, label)
  selected_id : String,
  focused_id? : String = "",
  fg? : @core.Color = @core.Color::white(),
  selected_fg? : @core.Color = @core.Color::black(),
  selected_bg? : @core.Color = @core.Color::cyan(),
) -> @core.Component {
  let options = items_data.map(fn(item) {
    { id: item.0, label: item.1, disabled: false }
  })
  option_list(
    options,
    [selected_id],
    focused_id~,
    fg~,
    selected_fg~,
    selected_bg~,
  )
}
