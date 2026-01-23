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
/// Create a single-select listbox with theme support
pub fn listbox(
  options : Array[ListboxOption],
  selected_id : String,
  id? : String = "",
  focused_id? : String = "",
  orientation? : ListboxOrientation = ListboxOrientation::Vertical,
  theme? : Theme = Theme::default(),
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
    options, state, false, orientation, id, theme, min_width, max_height, padding_x,
  )
}

///|
/// Create a multi-select listbox with theme support
pub fn listbox_multi(
  options : Array[ListboxOption],
  state : ListboxState,
  id? : String = "",
  orientation? : ListboxOrientation = ListboxOrientation::Vertical,
  theme? : Theme = Theme::default(),
  // Size
  min_width? : Double = 20.0,
  max_height? : Int = 10,
  padding_x? : Double = 1.0,
) -> @core.Component {
  build_listbox(
    options, state, true, orientation, id, theme, min_width, max_height, padding_x,
  )
}

///|
fn build_listbox(
  options : Array[ListboxOption],
  state : ListboxState,
  multiselectable : Bool,
  orientation : ListboxOrientation,
  id : String,
  theme : Theme,
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

    // Determine colors - no background, use text color
    let item_fg = if opt.disabled {
      theme.disabled
    } else if is_focused {
      theme.focus
    } else if is_selected {
      theme.primary
    } else {
      theme.fg
    }

    // Build option item
    let label_text = if multiselectable {
      // Show checkbox for multi-select
      let check_icon = if is_selected { "[✓]" } else { "[ ]" }
      check_icon + " " + opt.label
    } else {
      opt.label
    }

    // Selection and focus indicators
    let prefix = if is_focused {
      "▸ "
    } else if is_selected {
      "● "
    } else {
      "  "
    }
    // Text with padding
    let padded_text = text(
      " ".repeat(padding_x.to_int()) + prefix + label_text,
      fg=item_fg,
    )
    let item = row(
      [padded_text],
      id=opt.id,
      height=@types.Dimension::Length(1.0),
      role=Some(@core.Role::Option),
    )
    items.push(item)
  }

  // Add scroll indicator if needed
  if options.length() > max_height {
    let remaining = options.length() - max_height
    let scroll_text = text(
      " ".repeat(padding_x.to_int()) +
      "  ... " +
      remaining.to_string() +
      " more",
      fg=theme.disabled,
    )
    items.push(row([scroll_text], height=@types.Dimension::Length(1.0)))
  }

  // Build container based on orientation
  match orientation {
    ListboxOrientation::Vertical =>
      column(
        items,
        id~,
        min_width=@types.Dimension::Length(min_width),
        // Auto-size to content
        border=Some(@core.BorderChars::single()),
        border_color=theme.border,
        role=Some(@core.Role::Listbox),
      )
    ListboxOrientation::Horizontal =>
      row(
        items,
        id~,
        min_width=@types.Dimension::Length(min_width),
        border=Some(@core.BorderChars::single()),
        border_color=theme.border,
        role=Some(@core.Role::Listbox),
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
  theme? : Theme = Theme::default(),
) -> @core.Component {
  let items : Array[@core.Component] = []
  for opt in options {
    let is_selected = selected_ids.contains(opt.id)
    let is_focused = focused_id == opt.id
    let item_fg = if opt.disabled {
      theme.disabled
    } else if is_focused {
      theme.focus
    } else if is_selected {
      theme.primary
    } else {
      theme.fg
    }
    let label_text = if multiselectable {
      let check = if is_selected { "[✓]" } else { "[ ]" }
      check + " " + opt.label
    } else {
      opt.label
    }
    let focus_prefix = if is_focused { "▸ " } else { "  " }
    items.push(
      row(
        [text(focus_prefix + label_text, fg=item_fg)],
        id=opt.id,
        role=Some(@core.Role::Option),
      ),
    )
  }
  column(items, role=Some(@core.Role::Listbox))
}

///|
/// Inline selectable list (no box styling)
pub fn selectable_list(
  items_data : Array[(String, String)], // (id, label)
  selected_id : String,
  focused_id? : String = "",
  theme? : Theme = Theme::default(),
) -> @core.Component {
  let options = items_data.map(fn(item) {
    { id: item.0, label: item.1, disabled: false }
  })
  option_list(options, [selected_id], focused_id~, theme~)
}
