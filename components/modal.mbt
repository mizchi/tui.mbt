///|
/// Modal - Overlay component for displaying content above the main UI

///|
/// Modal state for controlling visibility
pub(all) struct ModalState {
  is_open : @signals.Signal[Bool]
}

///|
/// Create a new modal state
pub fn ModalState::new(initial_open? : Bool = false) -> ModalState {
  { is_open: @signals.signal(initial_open) }
}

///|
/// Open the modal
pub fn ModalState::open(self : ModalState) -> Unit {
  self.is_open.set(true)
}

///|
/// Close the modal
pub fn ModalState::close(self : ModalState) -> Unit {
  self.is_open.set(false)
}

///|
/// Toggle the modal open/closed
pub fn ModalState::toggle(self : ModalState) -> Unit {
  self.is_open.set(not(self.is_open.get()))
}

///|
/// Check if the modal is open
pub fn ModalState::get_is_open(self : ModalState) -> Bool {
  self.is_open.get()
}

///|
/// Create a backdrop overlay that fills the available space
/// Used as a semi-transparent background behind modals
pub fn backdrop(
  bg? : @core.Color = @core.Color::rgba(0, 0, 0, 128),
) -> @core.Component {
  @core.box(
    [],
    width=@types.Dimension::Percent(100.0),
    height=@types.Dimension::Percent(100.0),
    bg~,
  )
}

///|
/// Create a modal container that centers its content
/// The modal takes full screen and centers the content within it
pub fn modal(
  content : @core.Component,
  // ID
  id? : String = "",
  // Size constraints for the modal box
  width? : @types.Dimension = @types.Dimension::Auto,
  height? : @types.Dimension = @types.Dimension::Auto,
  min_width? : @types.Dimension = @types.Dimension::Auto,
  min_height? : @types.Dimension = @types.Dimension::Auto,
  max_width? : @types.Dimension = @types.Dimension::Percent(80.0),
  max_height? : @types.Dimension = @types.Dimension::Percent(80.0),
  // Style
  bg? : @core.Color = @core.Color::rgb(40, 40, 50),
  fg? : @core.Color = @core.Color::white(),
  border? : @core.BorderChars? = Some(@core.BorderChars::rounded()),
  border_color? : @core.Color = @core.Color::cyan(),
  // Padding inside the modal box
  padding? : Double = 1.0,
  padding_x? : Double = 2.0,
  padding_y? : Double = 1.0,
) -> @core.Component {
  // Modal box with content
  let modal_box = @core.box(
    [content],
    id~,
    width~,
    height~,
    min_width~,
    min_height~,
    max_width~,
    max_height~,
    bg~,
    fg~,
    border~,
    border_color~,
    padding~,
    padding_x~,
    padding_y~,
    role=Some(@core.Role::Dialog),
  )

  // Full-screen container that centers the modal
  @core.box(
    [modal_box],
    width=@types.Dimension::Percent(100.0),
    height=@types.Dimension::Percent(100.0),
    justify_content=@types.Alignment::Center,
    align_items=@types.Alignment::Center,
  )
}

///|
/// Create a modal with backdrop overlay
/// This is the most common usage - a semi-transparent backdrop with centered modal
pub fn modal_with_backdrop(
  content : @core.Component,
  // ID
  id? : String = "",
  // Size constraints for the modal box
  width? : @types.Dimension = @types.Dimension::Auto,
  height? : @types.Dimension = @types.Dimension::Auto,
  min_width? : @types.Dimension = @types.Dimension::Auto,
  min_height? : @types.Dimension = @types.Dimension::Auto,
  max_width? : @types.Dimension = @types.Dimension::Percent(80.0),
  max_height? : @types.Dimension = @types.Dimension::Percent(80.0),
  // Modal style
  bg? : @core.Color = @core.Color::rgb(40, 40, 50),
  fg? : @core.Color = @core.Color::white(),
  border? : @core.BorderChars? = Some(@core.BorderChars::rounded()),
  border_color? : @core.Color = @core.Color::cyan(),
  padding? : Double = 1.0,
  padding_x? : Double = 2.0,
  padding_y? : Double = 1.0,
  // Backdrop style
  backdrop_bg? : @core.Color = @core.Color::rgba(0, 0, 0, 128),
  // Container size (for full-screen modal, pass terminal dimensions)
  container_width? : @types.Dimension = @types.Dimension::Percent(100.0),
  container_height? : @types.Dimension = @types.Dimension::Percent(100.0),
) -> @core.Component {
  // Modal box with content
  let modal_box = @core.box(
    [content],
    id~,
    width~,
    height~,
    min_width~,
    min_height~,
    max_width~,
    max_height~,
    bg~,
    fg~,
    border~,
    border_color~,
    padding~,
    padding_x~,
    padding_y~,
    role=Some(@core.Role::Dialog),
  )

  // Full-screen container with backdrop color that centers the modal
  @core.box(
    [modal_box],
    width=container_width,
    height=container_height,
    justify_content=@types.Alignment::Center,
    align_items=@types.Alignment::Center,
    bg=backdrop_bg,
  )
}

///|
/// Helper to conditionally render a modal overlay on top of base content
/// Returns the base content with modal overlaid if modal is open
pub fn with_modal(
  base : @core.Component,
  modal_content : @core.Component,
  is_open : Bool,
) -> @core.Component {
  if is_open {
    // Stack base and modal - modal renders on top
    @core.box(
      [base, modal_content],
      width=@types.Dimension::Percent(100.0),
      height=@types.Dimension::Percent(100.0),
    )
  } else {
    base
  }
}

///|
/// Confirmation dialog modal
pub fn confirm_dialog(
  message : String,
  title? : String = "Confirm",
  confirm_label? : String = "OK",
  cancel_label? : String = "Cancel",
  // Style
  bg? : @core.Color = @core.Color::rgb(40, 40, 50),
  border_color? : @core.Color = @core.Color::cyan(),
) -> @core.Component {
  let content = column(
    [
      // Title
      text(title, fg=@core.Color::cyan(), bold=true),
      // Message
      @core.spacer(flex_grow=0.5),
      text(message),
      @core.spacer(flex_grow=1.0),
      // Buttons row
      row(
        [
          button(cancel_label, id="modal-cancel"),
          @core.spacer(flex_grow=1.0),
          button(confirm_label, id="modal-confirm"),
        ],
        gap=2.0,
      ),
    ],
    gap=1.0,
    min_width=@types.Dimension::Length(30.0),
  )
  modal_with_backdrop(content, bg~, border_color~)
}

///|
/// Alert dialog modal (single button)
pub fn alert_dialog(
  message : String,
  title? : String = "Alert",
  button_label? : String = "OK",
  // Style
  bg? : @core.Color = @core.Color::rgb(40, 40, 50),
  border_color? : @core.Color = @core.Color::yellow(),
) -> @core.Component {
  let content = column(
    [
      // Title
      text(title, fg=@core.Color::yellow(), bold=true),
      // Message
      @core.spacer(flex_grow=0.5),
      text(message),
      @core.spacer(flex_grow=1.0),
      // Button centered
      row(
        [button(button_label, id="modal-ok")],
        justify=@types.Alignment::Center,
      ),
    ],
    gap=1.0,
    min_width=@types.Dimension::Length(30.0),
  )
  modal_with_backdrop(content, bg~, border_color~)
}
