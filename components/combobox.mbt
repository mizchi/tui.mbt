///|
/// Combobox - Dropdown with text input and autocomplete

///|
/// Combobox option
pub(all) struct ComboboxOption {
  id : String
  label : String
} derive(Eq)

///|
/// Combobox state
pub(all) enum ComboboxState {
  Closed
  Open
  Editing
  Disabled
}

///|
/// Create a combobox component with autocomplete
pub fn combobox(
  options : Array[ComboboxOption],
  selected_id : String,
  id? : String = "",
  state? : ComboboxState = ComboboxState::Closed,
  filter? : String = "",
  placeholder? : String = "Select...",
  // Style
  fg? : @core.Color = @core.Color::white(),
  bg? : @core.Color = @core.Color::rgb(40, 40, 50),
  selected_fg? : @core.Color = @core.Color::black(),
  selected_bg? : @core.Color = @core.Color::cyan(),
  border_color? : @core.Color = @core.Color::rgb(80, 80, 80),
  focus_border_color? : @core.Color = @core.Color::cyan(),
  // Size
  width? : @types.Dimension = @types.Dimension::Auto,
  min_width? : Double = 15.0,
  max_visible? : Int = 5,
  // Icons
  dropdown_icon? : String = "▼",
  dropdown_icon_open? : String = "▲",
) -> @core.Component {
  // Find selected option label
  let selected_label = options.iter().find_first(fn(o) { o.id == selected_id })
    |> Option::map(fn(o) { o.label })
    |> Option::unwrap_or(placeholder)

  // Display text based on state
  let display_text = match state {
    ComboboxState::Editing => filter + "_"
    ComboboxState::Open | ComboboxState::Closed | ComboboxState::Disabled =>
      selected_label
  }

  // Border color based on state
  let actual_border = match state {
    ComboboxState::Open | ComboboxState::Editing => focus_border_color
    ComboboxState::Disabled => @core.Color::rgb(60, 60, 60)
    _ => border_color
  }

  // Icon based on state
  let icon = match state {
    ComboboxState::Open | ComboboxState::Editing => dropdown_icon_open
    _ => dropdown_icon
  }

  // Build header (input field with dropdown icon)
  let header = row(
    [
      text(display_text, fg~),
      spacer(),
      text(icon, fg=@core.Color::rgb(150, 150, 150)),
    ],
    id=id + "-header",
    width~,
    min_width=@types.Dimension::Length(min_width),
    padding_x=1.0,
    bg~,
    border=Some(@core.BorderChars::rounded()),
    border_color=actual_border,
  )

  // Build dropdown list if open
  match state {
    ComboboxState::Open | ComboboxState::Editing => {
      // Filter options based on input
      let filtered = if filter.length() > 0 {
        options
        .iter()
        .filter(fn(o) { o.label.to_lower().contains(filter.to_lower()) })
        |> Iter::collect
      } else {
        options
      }

      // Limit visible options
      let visible_count = if filtered.length() > max_visible {
        max_visible
      } else {
        filtered.length()
      }
      let option_items : Array[@core.Component] = []
      for i = 0; i < visible_count; i = i + 1 {
        let opt = filtered[i]
        let is_selected = opt.id == selected_id
        let (opt_fg, opt_bg) = if is_selected {
          (selected_fg, selected_bg)
        } else {
          (fg, bg)
        }
        option_items.push(
          row([text(opt.label, fg=opt_fg)], id=opt.id, bg=opt_bg, padding_x=1.0),
        )
      }

      // Show "no results" if filter matches nothing
      if option_items.is_empty() {
        option_items.push(
          row(
            [text("No matches", fg=@core.Color::rgb(100, 100, 100))],
            padding_x=1.0,
          ),
        )
      }

      // Add scroll indicator if more items
      if filtered.length() > max_visible {
        option_items.push(
          row(
            [
              text(
                "... " + (filtered.length() - max_visible).to_string() + " more",
                fg=@core.Color::rgb(100, 100, 100),
              ),
            ],
            padding_x=1.0,
          ),
        )
      }
      let dropdown = column(
        option_items,
        id=id + "-dropdown",
        width~,
        min_width=@types.Dimension::Length(min_width),
        bg~,
        border=Some(@core.BorderChars::rounded()),
        border_color=actual_border,
      )
      column([header, dropdown], id~)
    }
    _ => column([header], id~)
  }
}

///|
/// Simple select dropdown (no text input)
pub fn select(
  options : Array[ComboboxOption],
  selected_id : String,
  id? : String = "",
  open? : Bool = false,
  placeholder? : String = "Select...",
  // Style
  fg? : @core.Color = @core.Color::white(),
  bg? : @core.Color = @core.Color::rgb(40, 40, 50),
  selected_fg? : @core.Color = @core.Color::black(),
  selected_bg? : @core.Color = @core.Color::cyan(),
  border_color? : @core.Color = @core.Color::rgb(80, 80, 80),
  // Size
  min_width? : Double = 15.0,
  max_visible? : Int = 5,
) -> @core.Component {
  let state = if open { ComboboxState::Open } else { ComboboxState::Closed }
  combobox(
    options,
    selected_id,
    id~,
    state~,
    placeholder~,
    fg~,
    bg~,
    selected_fg~,
    selected_bg~,
    border_color~,
    min_width~,
    max_visible~,
  )
}

///|
/// Autocomplete input (text input with suggestions)
pub fn autocomplete(
  options : Array[ComboboxOption],
  value : String,
  id? : String = "",
  placeholder? : String = "Type to search...",
  // Style
  fg? : @core.Color = @core.Color::white(),
  bg? : @core.Color = @core.Color::rgb(40, 40, 50),
  selected_bg? : @core.Color = @core.Color::cyan(),
  border_color? : @core.Color = @core.Color::cyan(),
  // Size
  min_width? : Double = 20.0,
  max_visible? : Int = 5,
) -> @core.Component {
  let state = if value.length() > 0 {
    ComboboxState::Editing
  } else {
    ComboboxState::Closed
  }
  combobox(
    options,
    "",
    id~,
    state~,
    filter=value,
    placeholder~,
    fg~,
    bg~,
    border_color~,
    focus_border_color=border_color,
    min_width~,
    max_visible~,
    selected_bg~,
  )
}
