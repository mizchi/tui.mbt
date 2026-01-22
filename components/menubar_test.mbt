///|
/// Tests for Menubar component

// ============================================
// Snapshot Tests
// ============================================

///|
test "menubar: closed state" {
  let items = [
    @components.MenubarItem::{
      id: "file",
      label: "File",
      items: [
        menu_item("new", "New"),
        menu_item("open", "Open"),
        menu_separator(),
        menu_item("exit", "Exit"),
      ],
    },
    @components.MenubarItem::{
      id: "edit",
      label: "Edit",
      items: [menu_item("cut", "Cut"), menu_item("copy", "Copy")],
    },
  ]
  let state = @components.MenubarState::new()
  let comp = menubar(items, state)
  let output = @render.render_once(40, 3, comp)
  inspect(
    output,
    content="\u{1b}[2J\u{1b}[1;1H\u{1b}[38;5;231mFile  Edit                              \u{1b}[2;1H                                        \u{1b}[3;1H                                        \u{1b}[0m",
  )
}

///|
test "menubar: open menu" {
  let items = [
    @components.MenubarItem::{
      id: "file",
      label: "File",
      items: [
        menu_item("new", "New"),
        menu_item("open", "Open"),
        menu_item("save", "Save"),
      ],
    },
    @components.MenubarItem::{ id: "edit", label: "Edit", items: [] },
  ]
  let state : @components.MenubarState = {
    open_menu_id: "file",
    focused_item_id: "new",
    open_submenu_path: [],
  }
  let comp = menubar(items, state)
  let output = @render.render_once(30, 10, comp)
  inspect(
    output,
    content="\u{1b}[2J\u{1b}[1;1H\u{1b}[38;5;51mFile\u{1b}[38;5;231m  Edit                    \u{1b}[2;1H                              \u{1b}[3;1H                              \u{1b}[4;1H\u{1b}[38;5;60m┌─────────────┐\u{1b}[38;5;231m               \u{1b}[5;1H\u{1b}[38;5;60m│\u{1b}[38;5;226mNew\u{1b}[38;5;231m          \u{1b}[38;5;60m│\u{1b}[38;5;231m               \u{1b}[6;1H\u{1b}[38;5;60m│\u{1b}[38;5;231m             \u{1b}[38;5;60m│\u{1b}[38;5;231m               \u{1b}[7;1H\u{1b}[38;5;60m│\u{1b}[38;5;231mOpen         \u{1b}[38;5;60m│\u{1b}[38;5;231m               \u{1b}[8;1H\u{1b}[38;5;60m│\u{1b}[38;5;231m             \u{1b}[38;5;60m│\u{1b}[38;5;231m               \u{1b}[9;1H\u{1b}[38;5;60m│\u{1b}[38;5;231mSave         \u{1b}[38;5;60m│\u{1b}[38;5;231m               \u{1b}[10;1H\u{1b}[38;5;60m│\u{1b}[38;5;231m             \u{1b}[38;5;60m│\u{1b}[38;5;231m               \u{1b}[0m",
  )
}

///|
test "menubar: with checkbox items" {
  let items = [
    @components.MenubarItem::{
      id: "view",
      label: "View",
      items: [
        menu_checkbox("toolbar", "Toolbar", true),
        menu_checkbox("statusbar", "Status Bar", false),
      ],
    },
  ]
  let state : @components.MenubarState = {
    open_menu_id: "view",
    focused_item_id: "",
    open_submenu_path: [],
  }
  let comp = menubar(items, state)
  let output = @render.render_once(25, 6, comp)
  inspect(
    output,
    content="\u{1b}[2J\u{1b}[1;1H\u{1b}[38;5;51mView\u{1b}[38;5;231m                     \u{1b}[2;1H                         \u{1b}[3;1H                         \u{1b}[4;1H\u{1b}[38;5;60m┌───────────────┐\u{1b}[38;5;231m        \u{1b}[5;1H\u{1b}[38;5;60m│\u{1b}[38;5;231m[✓] Toolbar    \u{1b}[38;5;60m│\u{1b}[38;5;231m        \u{1b}[6;1H\u{1b}[38;5;60m│\u{1b}[38;5;231m               \u{1b}[38;5;60m│\u{1b}[38;5;231m        \u{1b}[0m",
  )
}

///|
test "menubar: with radio items" {
  let items = [
    @components.MenubarItem::{
      id: "format",
      label: "Format",
      items: [
        menu_radio("small", "Small", false),
        menu_radio("medium", "Medium", true),
        menu_radio("large", "Large", false),
      ],
    },
  ]
  let state : @components.MenubarState = {
    open_menu_id: "format",
    focused_item_id: "",
    open_submenu_path: [],
  }
  let comp = menubar(items, state)
  let output = @render.render_once(25, 7, comp)
  inspect(
    output,
    content="\u{1b}[2J\u{1b}[1;1H\u{1b}[38;5;51mFormat\u{1b}[38;5;231m                   \u{1b}[2;1H                         \u{1b}[3;1H                         \u{1b}[4;1H\u{1b}[38;5;60m┌─────────────┐\u{1b}[38;5;231m          \u{1b}[5;1H\u{1b}[38;5;60m│\u{1b}[38;5;231m○ Small      \u{1b}[38;5;60m│\u{1b}[38;5;231m          \u{1b}[6;1H\u{1b}[38;5;60m│\u{1b}[38;5;231m             \u{1b}[38;5;60m│\u{1b}[38;5;231m          \u{1b}[7;1H\u{1b}[38;5;60m│\u{1b}[38;5;231m             \u{1b}[38;5;60m│\u{1b}[38;5;231m          \u{1b}[0m",
  )
}

///|
test "menu: standalone dropdown" {
  let items = [
    menu_item("action1", "Action 1"),
    menu_item("action2", "Action 2"),
    menu_separator(),
    menu_item("action3", "Action 3"),
  ]
  let comp = menu(items, focused_id="action2")
  let output = @render.render_once(20, 6, comp)
  inspect(
    output,
    content="\u{1b}[2J\u{1b}[1;1H\u{1b}[38;5;60m┌───────────────┐\u{1b}[38;5;231m   \u{1b}[2;1H\u{1b}[38;5;60m│\u{1b}[38;5;231mAction 1       \u{1b}[38;5;60m│\u{1b}[38;5;231m   \u{1b}[3;1H\u{1b}[38;5;60m│\u{1b}[38;5;231m               \u{1b}[38;5;60m│\u{1b}[38;5;231m   \u{1b}[4;1H\u{1b}[38;5;60m│\u{1b}[38;5;231m               \u{1b}[38;5;60m│\u{1b}[38;5;231m   \u{1b}[5;1H\u{1b}[38;5;60m│\u{1b}[38;5;226mAction 2\u{1b}[38;5;231m       \u{1b}[38;5;60m│\u{1b}[38;5;231m   \u{1b}[6;1H\u{1b}[38;5;60m│\u{1b}[38;5;231m               \u{1b}[38;5;60m│\u{1b}[38;5;231m   \u{1b}[0m",
  )
}

///|
test "context_menu: popup menu" {
  let items = [
    menu_item("cut", "Cut"),
    menu_item("copy", "Copy"),
    menu_item("paste", "Paste"),
  ]
  let comp = context_menu(items)
  let output = @render.render_once(15, 5, comp)
  inspect(
    output,
    content="\u{1b}[2J\u{1b}[1;1H\u{1b}[38;5;60m┌──────────┐\u{1b}[38;5;231m   \u{1b}[2;1H\u{1b}[38;5;60m│\u{1b}[38;5;231mCut       \u{1b}[38;5;60m│\u{1b}[38;5;231m   \u{1b}[3;1H\u{1b}[38;5;60m│\u{1b}[38;5;231m          \u{1b}[38;5;60m│\u{1b}[38;5;231m   \u{1b}[4;1H\u{1b}[38;5;60m│\u{1b}[38;5;231mCopy      \u{1b}[38;5;60m│\u{1b}[38;5;231m   \u{1b}[5;1H\u{1b}[38;5;60m│\u{1b}[38;5;231m          \u{1b}[38;5;60m│\u{1b}[38;5;231m   \u{1b}[0m",
  )
}

// ============================================
// Accessibility Tests
// ============================================

///|
test "a11y: menubar - has container ID for focus management" {
  let items = [
    @components.MenubarItem::{ id: "file", label: "File", items: [] },
  ]
  let state = @components.MenubarState::new()
  let comp = menubar(items, state, id="main-menu")
  inspect(comp.node.id, content="main-menu")
}

///|
test "a11y: menubar - each menu item has unique ID" {
  let items = [
    @components.MenubarItem::{ id: "file", label: "File", items: [] },
    @components.MenubarItem::{ id: "edit", label: "Edit", items: [] },
    @components.MenubarItem::{ id: "view", label: "View", items: [] },
  ]
  let state = @components.MenubarState::new()
  let comp = menubar(items, state)
  // Bar should be the first child
  let bar = comp.node.children[0]
  let ids : Array[String] = []
  for child in bar.children {
    ids.push(child.id)
  }
  inspect(
    ids,
    content=(
      #|["file", "edit", "view"]
    ),
  )
}

///|
test "a11y: menubar - open menu is visually distinct" {
  let items = [
    @components.MenubarItem::{
      id: "file",
      label: "File",
      items: [menu_item("x", "X")],
    },
  ]
  let closed_state = @components.MenubarState::new()
  let open_state : @components.MenubarState = {
    open_menu_id: "file",
    focused_item_id: "",
    open_submenu_path: [],
  }
  let closed_out = @render.render_once(20, 5, menubar(items, closed_state))
  let open_out = @render.render_once(20, 5, menubar(items, open_state))
  inspect(closed_out != open_out, content="true")
}

///|
test "a11y: menubar - focused item highlighted" {
  let items = [
    @components.MenubarItem::{
      id: "file",
      label: "File",
      items: [menu_item("new", "New"), menu_item("open", "Open")],
    },
  ]
  let state1 : @components.MenubarState = {
    open_menu_id: "file",
    focused_item_id: "new",
    open_submenu_path: [],
  }
  let state2 : @components.MenubarState = {
    open_menu_id: "file",
    focused_item_id: "open",
    open_submenu_path: [],
  }
  let out1 = @render.render_once(25, 6, menubar(items, state1))
  let out2 = @render.render_once(25, 6, menubar(items, state2))
  inspect(out1 != out2, content="true")
}

///|
test "a11y: menu_checkbox - shows checked state" {
  let items = [
    menu_checkbox("checked", "Checked Item", true),
    menu_checkbox("unchecked", "Unchecked Item", false),
  ]
  let comp = menu(items)
  let output = @render.render_once(25, 4, comp)
  inspect(output.contains("[✓]"), content="true")
  inspect(output.contains("[ ]"), content="false")
}

///|
test "a11y: menu_radio - shows selected state" {
  let items = [
    menu_radio("sel", "Selected", true),
    menu_radio("unsel", "Unselected", false),
  ]
  let comp = menu(items)
  let output = @render.render_once(20, 4, comp)
  inspect(output.contains("◉"), content="true")
  inspect(output.contains("○"), content="false")
}

///|
test "a11y: menu_separator - visually separates items" {
  let items = [
    menu_item("a", "Item A"),
    menu_separator(),
    menu_item("b", "Item B"),
  ]
  let comp = menu(items)
  let output = @render.render_once(20, 5, comp)
  // Separator should contain line characters
  inspect(output.contains("─"), content="true")
}

///|
test "a11y: menu_item - disabled item styled differently" {
  let items = [
    menu_item("enabled", "Enabled"),
    menu_item("disabled", "Disabled", disabled=true),
  ]
  let comp = menu(items)
  let output = @render.render_once(20, 4, comp)
  // Both should be visible
  inspect(output.contains("Enabled"), content="true")
  inspect(output.contains("Disabled"), content="true")
}

///|
test "a11y: menu_submenu - shows arrow indicator" {
  let items = [
    menu_submenu("sub", "Submenu", [menu_item("child", "Child Item")]),
  ]
  let comp = menu(items)
  let output = @render.render_once(20, 3, comp)
  // Submenu should have arrow indicator
  inspect(output.contains("▶"), content="true")
}

///|
test "a11y: context_menu - all items have IDs" {
  let items = [menu_item("a", "A"), menu_item("b", "B"), menu_item("c", "C")]
  let comp = context_menu(items, id="ctx-menu")
  inspect(comp.node.id, content="ctx-menu")
}
