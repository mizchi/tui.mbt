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
/// Create a combobox component with theme support
pub fn combobox(
  options : Array[ComboboxOption],
  selected_id : String,
  id? : String = "",
  focused_id? : String = "",
  state? : ComboboxState = ComboboxState::Closed,
  filter? : String = "",
  placeholder? : String = "Select...",
  theme? : Theme = Theme::default(),
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

  // Border and fg color based on state
  let (actual_border, header_fg) = match state {
    ComboboxState::Open | ComboboxState::Editing => (theme.focus, theme.fg)
    ComboboxState::Disabled => (theme.disabled, theme.disabled)
    _ => (theme.border, theme.fg)
  }

  // Icon based on state
  let icon = match state {
    ComboboxState::Open | ComboboxState::Editing => dropdown_icon_open
    _ => dropdown_icon
  }

  // Build header (input field with dropdown icon)
  let header = row(
    [text(display_text, fg=header_fg), spacer(), text(icon, fg=theme.muted)],
    id=id + "-header",
    width~,
    min_width=@types.Dimension::Length(min_width),
    padding_x=1.0,
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
        let is_focused = opt.id == focused_id
        let opt_fg = if is_focused {
          theme.focus
        } else if is_selected {
          theme.primary
        } else {
          theme.fg
        }
        let prefix = if is_focused {
          "▸ "
        } else if is_selected {
          "● "
        } else {
          "  "
        }
        option_items.push(
          row([text(prefix + opt.label, fg=opt_fg)], id=opt.id, padding_x=1.0),
        )
      }

      // Show "no results" if filter matches nothing
      if option_items.is_empty() {
        option_items.push(
          row([text("No matches", fg=theme.disabled)], padding_x=1.0),
        )
      }

      // Add scroll indicator if more items
      if filtered.length() > max_visible {
        option_items.push(
          row(
            [
              text(
                "... " + (filtered.length() - max_visible).to_string() + " more",
                fg=theme.disabled,
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
        border=Some(@core.BorderChars::rounded()),
        border_color=actual_border,
      )
      column([header, dropdown], id~)
    }
    _ => column([header], id~)
  }
}

///|
/// Simple select dropdown (no text input) with theme support
pub fn select(
  options : Array[ComboboxOption],
  selected_id : String,
  id? : String = "",
  focused_id? : String = "",
  open? : Bool = false,
  placeholder? : String = "Select...",
  theme? : Theme = Theme::default(),
  // Size
  min_width? : Double = 15.0,
  max_visible? : Int = 5,
) -> @core.Component {
  let state = if open { ComboboxState::Open } else { ComboboxState::Closed }
  combobox(
    options,
    selected_id,
    id~,
    focused_id~,
    state~,
    placeholder~,
    theme~,
    min_width~,
    max_visible~,
  )
}

///|
/// Autocomplete input (text input with suggestions) with theme support
pub fn autocomplete(
  options : Array[ComboboxOption],
  value : String,
  id? : String = "",
  focused_id? : String = "",
  placeholder? : String = "Type to search...",
  theme? : Theme = Theme::default(),
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
    focused_id~,
    state~,
    filter=value,
    placeholder~,
    theme~,
    min_width~,
    max_visible~,
  )
}
