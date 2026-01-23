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
/// Create a menubar component with theme support
pub fn menubar(
  items : Array[MenubarItem],
  state : MenubarState,
  id? : String = "",
  theme? : Theme = Theme::default(),
  // Size
  item_padding_x? : Double = 2.0,
  dropdown_min_width? : Double = 15.0,
) -> @core.Component {
  let bar_items : Array[@core.Component] = []
  for menu_item in items {
    let is_open = state.open_menu_id == menu_item.id
    let is_focused = state.focused_item_id == menu_item.id &&
      state.open_menu_id == ""
    let item_fg = if is_focused {
      theme.focus
    } else if is_open {
      theme.primary
    } else {
      theme.fg
    }

    // Menubar item
    let item_component = row(
      [text(menu_item.label, fg=item_fg)],
      id=menu_item.id,
      padding_x=item_padding_x,
      role=Some(@core.Role::Menuitem),
    )
    bar_items.push(item_component)
  }

  // Build the menubar row
  let bar = row(bar_items, id=id + "-bar", role=Some(@core.Role::Menubar))

  // Find open menu and build dropdown
  let open_menu = items.iter().find_first(fn(m) { m.id == state.open_menu_id })
  match open_menu {
    Some(menu) => {
      let dropdown = build_menu_themed(
        menu.items,
        state,
        menu.id + "-menu",
        theme,
        dropdown_min_width,
      )
      column([bar, dropdown], id~)
    }
    None => column([bar], id~)
  }
}

///|
fn build_menu_themed(
  items : Array[MenuItem],
  state : MenubarState,
  id : String,
  theme : Theme,
  dropdown_min_width : Double,
) -> @core.Component {
  let menu_items : Array[@core.Component] = []
  for item in items {
    match item.item_type {
      MenuItemType::Separator =>
        // Separator line
        menu_items.push(
          row(
            [text("─".repeat(dropdown_min_width.to_int()), fg=theme.border)],
            padding_x=0.0,
          ),
        )
      MenuItemType::Checkbox(checked) => {
        let icon = if checked { "[✓]" } else { "[ ]" }
        let item_fg = get_item_color_themed(item, state, theme)
        menu_items.push(
          row(
            [text(icon + " " + item.label, fg=item_fg)],
            id=item.id,
            padding_x=1.0,
            role=Some(@core.Role::Menuitem),
          ),
        )
      }
      MenuItemType::Radio(selected) => {
        let icon = if selected { "◉" } else { "○" }
        let item_fg = get_item_color_themed(item, state, theme)
        menu_items.push(
          row(
            [text(icon + " " + item.label, fg=item_fg)],
            id=item.id,
            padding_x=1.0,
            role=Some(@core.Role::Menuitem),
          ),
        )
      }
      MenuItemType::Submenu(sub_items) => {
        let item_fg = get_item_color_themed(item, state, theme)
        let is_submenu_open = state.open_submenu_path.contains(item.id)
        // Show submenu indicator
        let label_with_arrow = item.label + " ▶"
        let submenu_row = row(
          [text(label_with_arrow, fg=item_fg)],
          id=item.id,
          padding_x=1.0,
          role=Some(@core.Role::Menuitem),
        )
        menu_items.push(submenu_row)

        // Render submenu if open (inline for TUI - simplified)
        if is_submenu_open {
          let submenu = build_menu_themed(
            sub_items,
            state,
            item.id + "-submenu",
            theme,
            dropdown_min_width,
          )
          // Indent submenu
          menu_items.push(
            row([hspace(2.0), submenu], id=item.id + "-submenu-container"),
          )
        }
      }
      MenuItemType::Action => {
        let item_fg = get_item_color_themed(item, state, theme)
        menu_items.push(
          row(
            [text(item.label, fg=item_fg)],
            id=item.id,
            padding_x=1.0,
            role=Some(@core.Role::Menuitem),
          ),
        )
      }
    }
  }
  column(
    menu_items,
    id~,
    min_width=@types.Dimension::Length(dropdown_min_width),
    border=Some(@core.BorderChars::single()),
    border_color=theme.border,
    role=Some(@core.Role::Menu),
  )
}

///|
fn get_item_color_themed(
  item : MenuItem,
  state : MenubarState,
  theme : Theme,
) -> @core.Color {
  if item.disabled {
    return theme.disabled
  }
  let is_focused = state.focused_item_id == item.id
  if is_focused {
    theme.focus
  } else {
    theme.fg
  }
}

///|
/// Simple menu (dropdown menu without menubar) with theme support
pub fn menu(
  items : Array[MenuItem],
  focused_id? : String = "",
  id? : String = "",
  theme? : Theme = Theme::default(),
  min_width? : Double = 15.0,
) -> @core.Component {
  let state : MenubarState = {
    open_menu_id: "",
    focused_item_id: focused_id,
    open_submenu_path: [],
  }
  build_menu_themed(items, state, id, theme, min_width)
}

///|
/// Context menu (positioned menu) with theme support
pub fn context_menu(
  items : Array[MenuItem],
  focused_id? : String = "",
  id? : String = "",
  theme? : Theme = Theme::default(),
  min_width? : Double = 12.0,
) -> @core.Component {
  menu(items, focused_id~, id~, theme~, min_width~)
}
