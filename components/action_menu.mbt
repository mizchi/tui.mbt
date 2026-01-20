///|
/// ActionMenu - Reusable action menu with key bindings

///|
/// A single action item in the menu
pub(all) struct ActionItem {
  key : Char
  label : String
  handler : () -> Unit
}

///|
/// Create an action item
pub fn ActionItem::new(
  key : Char,
  label : String,
  handler : () -> Unit,
) -> ActionItem {
  { key, label, handler }
}

///|
/// Action menu state and configuration
pub(all) struct ActionMenu {
  /// Modal state for visibility
  modal : ModalState
  /// Title of the menu
  title : String
  /// List of actions
  actions : Array[ActionItem]
  /// Key to toggle the menu (default: None, must be handled externally)
  toggle_key : Char?
  /// Callback when menu closes
  on_close : () -> Unit
}

///|
/// Create a new action menu
pub fn ActionMenu::new(
  title : String,
  actions : Array[ActionItem],
  toggle_key? : Char? = None,
  on_close? : () -> Unit = fn() {  },
) -> ActionMenu {
  { modal: ModalState::new(), title, actions, toggle_key, on_close }
}

///|
/// Open the menu
pub fn ActionMenu::open(self : ActionMenu) -> Unit {
  self.modal.open()
}

///|
/// Close the menu
pub fn ActionMenu::close(self : ActionMenu) -> Unit {
  self.modal.close()
  (self.on_close)()
}

///|
/// Check if menu is open
pub fn ActionMenu::is_open(self : ActionMenu) -> Bool {
  self.modal.get_is_open()
}

///|
/// Handle a key event when menu is open
/// Returns true if the key was handled, false otherwise
pub fn ActionMenu::handle_key(self : ActionMenu, key : Char) -> Bool {
  // Check toggle key
  match self.toggle_key {
    Some(toggle) =>
      if key == toggle || key == toggle_case(toggle) {
        self.close()
        return true
      }
    None => ()
  }

  // Check action keys
  for action in self.actions {
    if key == action.key || key == toggle_case(action.key) {
      (action.handler)()
      self.close()
      return true
    }
  }
  false
}

///|
/// Handle escape key (closes menu)
pub fn ActionMenu::handle_escape(self : ActionMenu) -> Bool {
  if self.is_open() {
    self.close()
    true
  } else {
    false
  }
}

///|
/// Build the menu component
pub fn ActionMenu::build(
  self : ActionMenu,
  container_width : Int,
  container_height : Int,
) -> @core.Component {
  let items : Array[@core.Component] = []

  // Title
  items.push(text(self.title, fg=@core.Color::cyan(), bold=true))
  items.push(@core.spacer(flex_grow=0.5))

  // Action items
  for action in self.actions {
    let label = "[" + action.key.to_string() + "] " + action.label
    items.push(text(label))
  }
  items.push(@core.spacer(flex_grow=1.0))

  // Close hint
  let close_hint = match self.toggle_key {
    Some(k) => "[Esc/" + k.to_string() + "] Close"
    None => "[Esc] Close"
  }
  items.push(text(close_hint, fg=@core.Color::rgb(100, 100, 100)))
  let content = column(items, gap=0.0, min_width=@types.Dimension::Length(25.0))
  modal_with_backdrop(
    content,
    container_width=@types.Dimension::Length(container_width.to_double()),
    container_height=@types.Dimension::Length(container_height.to_double()),
  )
}

///|
fn toggle_case(c : Char) -> Char {
  let code = c.to_int()
  if code >= 65 && code <= 90 {
    // A-Z -> a-z
    (code + 32).unsafe_to_char()
  } else if code >= 97 && code <= 122 {
    // a-z -> A-Z
    (code - 32).unsafe_to_char()
  } else {
    c
  }
}

///|
/// Result of handling a key event with action menu
pub(all) enum MenuKeyResult {
  /// Key was handled by the menu
  Handled
  /// Key was not handled, pass to normal handler
  NotHandled
  /// Menu was closed
  Closed
}

///|
/// Handle key event for action menu with automatic App buffer management
/// Call this at the start of your key handler
/// Returns MenuKeyResult indicating how the event was processed
pub fn ActionMenu::handle_event(
  self : ActionMenu,
  app : @render.App,
  event : @events.InputEvent,
) -> MenuKeyResult {
  if not(self.is_open()) {
    return MenuKeyResult::NotHandled
  }
  match event {
    @events.InputEvent::Key(key_event) =>
      match key_event {
        @events.KeyEvent::Special(@events.SpecialKey::Escape, _) => {
          self.close()
          app.clear_prev_buffer()
          MenuKeyResult::Closed
        }
        @events.KeyEvent::Char(ch, _) => {
          let handled = self.handle_key(ch)
          if handled {
            app.clear_prev_buffer()
            MenuKeyResult::Closed
          } else {
            MenuKeyResult::Handled // Still consume key when menu is open
          }
        }
        _ => MenuKeyResult::Handled // Consume other keys when menu is open
      }
    _ => MenuKeyResult::NotHandled // Let mouse events through
  }
}

///|
/// Open the menu and clear app buffer for clean render
pub fn ActionMenu::open_with_app(self : ActionMenu, app : @render.App) -> Unit {
  self.open()
  app.clear_prev_buffer()
}
