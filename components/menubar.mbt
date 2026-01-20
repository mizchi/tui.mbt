///|
/// Menubar - Horizontal menu bar with dropdown menus and submenus

///|
/// Menu item type
pub(all) enum MenuItemType {
  Action
  Checkbox(Bool) // checked state
  Radio(Bool) // selected state
  Separator
  Submenu(Array[MenuItem])
}

///|
/// Menu item
pub(all) struct MenuItem {
  id : String
  label : String
  item_type : MenuItemType
  disabled : Bool
}

///|
/// Create a menu item
pub fn menu_item(
  id : String,
  label : String,
  disabled? : Bool = false,
) -> MenuItem {
  { id, label, item_type: MenuItemType::Action, disabled }
}

///|
/// Create a checkbox menu item
pub fn menu_checkbox(
  id : String,
  label : String,
  checked : Bool,
  disabled? : Bool = false,
) -> MenuItem {
  { id, label, item_type: MenuItemType::Checkbox(checked), disabled }
}

///|
/// Create a radio menu item
pub fn menu_radio(
  id : String,
  label : String,
  selected : Bool,
  disabled? : Bool = false,
) -> MenuItem {
  { id, label, item_type: MenuItemType::Radio(selected), disabled }
}

///|
/// Create a separator
pub fn menu_separator() -> MenuItem {
  { id: "", label: "", item_type: MenuItemType::Separator, disabled: false }
}

///|
/// Create a submenu item
pub fn menu_submenu(
  id : String,
  label : String,
  items : Array[MenuItem],
  disabled? : Bool = false,
) -> MenuItem {
  { id, label, item_type: MenuItemType::Submenu(items), disabled }
}

///|
/// Top-level menubar item
pub(all) struct MenubarItem {
  id : String
  label : String
  items : Array[MenuItem]
}

///|
/// Menubar state
pub(all) struct MenubarState {
  open_menu_id : String // "" means closed
  focused_item_id : String
  open_submenu_path : Array[String] // path of open submenu IDs
}

///|
/// Create initial menubar state
pub fn MenubarState::new() -> MenubarState {
  { open_menu_id: "", focused_item_id: "", open_submenu_path: [] }
}

///|
/// Create a menubar component
pub fn menubar(
  items : Array[MenubarItem],
  state : MenubarState,
  id? : String = "",
  // Style
  fg? : @core.Color = @core.Color::white(),
  bg? : @core.Color = @core.Color::rgb(40, 40, 50),
  selected_fg? : @core.Color = @core.Color::black(),
  selected_bg? : @core.Color = @core.Color::cyan(),
  hover_bg? : @core.Color = @core.Color::rgb(60, 60, 80),
  disabled_fg? : @core.Color = @core.Color::rgb(100, 100, 100),
  separator_fg? : @core.Color = @core.Color::rgb(80, 80, 80),
  // Size
  item_padding_x? : Double = 2.0,
  dropdown_min_width? : Double = 15.0,
) -> @core.Component {
  let bar_items : Array[@core.Component] = []
  for menu_item in items {
    let is_open = state.open_menu_id == menu_item.id
    let is_focused = state.focused_item_id == menu_item.id &&
      state.open_menu_id == ""
    let (item_fg, item_bg) = if is_open || is_focused {
      (selected_fg, selected_bg)
    } else {
      (fg, bg)
    }

    // Menubar item
    let item_component = row(
      [text(menu_item.label, fg=item_fg)],
      id=menu_item.id,
      padding_x=item_padding_x,
      bg=item_bg,
    )
    bar_items.push(item_component)
  }

  // Build the menubar row
  let bar = row(bar_items, id=id + "-bar", bg~)

  // Find open menu and build dropdown
  let open_menu = items.iter().find_first(fn(m) { m.id == state.open_menu_id })
  match open_menu {
    Some(menu) => {
      let dropdown = build_menu(
        menu.items,
        state,
        menu.id + "-menu",
        fg,
        bg,
        selected_fg,
        selected_bg,
        hover_bg,
        disabled_fg,
        separator_fg,
        dropdown_min_width,
      )
      column([bar, dropdown], id~)
    }
    None => column([bar], id~)
  }
}

///|
fn build_menu(
  items : Array[MenuItem],
  state : MenubarState,
  id : String,
  fg : @core.Color,
  bg : @core.Color,
  selected_fg : @core.Color,
  selected_bg : @core.Color,
  hover_bg : @core.Color,
  disabled_fg : @core.Color,
  separator_fg : @core.Color,
  dropdown_min_width : Double,
) -> @core.Component {
  let menu_items : Array[@core.Component] = []
  for item in items {
    match item.item_type {
      MenuItemType::Separator =>
        // Separator line
        menu_items.push(
          row(
            [text("─".repeat(dropdown_min_width.to_int()), fg=separator_fg)],
            padding_x=0.0,
          ),
        )
      MenuItemType::Checkbox(checked) => {
        let icon = if checked { "[✓]" } else { "[ ]" }
        let (item_fg, item_bg) = get_item_colors(
          item, state, fg, bg, selected_fg, selected_bg, hover_bg, disabled_fg,
        )
        menu_items.push(
          row(
            [text(icon + " " + item.label, fg=item_fg)],
            id=item.id,
            padding_x=1.0,
            bg=item_bg,
          ),
        )
      }
      MenuItemType::Radio(selected) => {
        let icon = if selected { "◉" } else { "○" }
        let (item_fg, item_bg) = get_item_colors(
          item, state, fg, bg, selected_fg, selected_bg, hover_bg, disabled_fg,
        )
        menu_items.push(
          row(
            [text(icon + " " + item.label, fg=item_fg)],
            id=item.id,
            padding_x=1.0,
            bg=item_bg,
          ),
        )
      }
      MenuItemType::Submenu(sub_items) => {
        let (item_fg, item_bg) = get_item_colors(
          item, state, fg, bg, selected_fg, selected_bg, hover_bg, disabled_fg,
        )
        let is_submenu_open = state.open_submenu_path.contains(item.id)
        // Show submenu indicator
        let label_with_arrow = item.label + " ▶"
        let submenu_row = row(
          [text(label_with_arrow, fg=item_fg)],
          id=item.id,
          padding_x=1.0,
          bg=item_bg,
        )
        menu_items.push(submenu_row)

        // Render submenu if open (inline for TUI - simplified)
        if is_submenu_open {
          let submenu = build_menu(
            sub_items,
            state,
            item.id + "-submenu",
            fg,
            bg,
            selected_fg,
            selected_bg,
            hover_bg,
            disabled_fg,
            separator_fg,
            dropdown_min_width,
          )
          // Indent submenu
          menu_items.push(
            row([hspace(2.0), submenu], id=item.id + "-submenu-container"),
          )
        }
      }
      MenuItemType::Action => {
        let (item_fg, item_bg) = get_item_colors(
          item, state, fg, bg, selected_fg, selected_bg, hover_bg, disabled_fg,
        )
        menu_items.push(
          row(
            [text(item.label, fg=item_fg)],
            id=item.id,
            padding_x=1.0,
            bg=item_bg,
          ),
        )
      }
    }
  }
  column(
    menu_items,
    id~,
    min_width=@types.Dimension::Length(dropdown_min_width),
    bg~,
    border=Some(@core.BorderChars::single()),
    border_color=@core.Color::rgb(80, 80, 80),
  )
}

///|
fn get_item_colors(
  item : MenuItem,
  state : MenubarState,
  fg : @core.Color,
  bg : @core.Color,
  selected_fg : @core.Color,
  selected_bg : @core.Color,
  hover_bg : @core.Color,
  disabled_fg : @core.Color,
) -> (@core.Color, @core.Color) {
  if item.disabled {
    return (disabled_fg, bg)
  }
  let is_focused = state.focused_item_id == item.id
  if is_focused {
    (selected_fg, selected_bg)
  } else {
    // Use hover_bg for potential hover state (managed externally)
    let _ = hover_bg
    (fg, bg)
  }
}

///|
/// Simple menu (dropdown menu without menubar)
pub fn menu(
  items : Array[MenuItem],
  focused_id? : String = "",
  id? : String = "",
  // Style
  fg? : @core.Color = @core.Color::white(),
  bg? : @core.Color = @core.Color::rgb(40, 40, 50),
  selected_fg? : @core.Color = @core.Color::black(),
  selected_bg? : @core.Color = @core.Color::cyan(),
  disabled_fg? : @core.Color = @core.Color::rgb(100, 100, 100),
  separator_fg? : @core.Color = @core.Color::rgb(80, 80, 80),
  min_width? : Double = 15.0,
) -> @core.Component {
  let state : MenubarState = {
    open_menu_id: "",
    focused_item_id: focused_id,
    open_submenu_path: [],
  }
  build_menu(
    items,
    state,
    id,
    fg,
    bg,
    selected_fg,
    selected_bg,
    @core.Color::rgb(60, 60, 80), // hover_bg
    disabled_fg,
    separator_fg,
    min_width,
  )
}

///|
/// Context menu (positioned menu)
pub fn context_menu(
  items : Array[MenuItem],
  focused_id? : String = "",
  id? : String = "",
  fg? : @core.Color = @core.Color::white(),
  bg? : @core.Color = @core.Color::rgb(40, 40, 50),
  min_width? : Double = 12.0,
) -> @core.Component {
  menu(items, focused_id~, id~, fg~, bg~, min_width~)
}
