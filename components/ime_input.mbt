///|
/// IME input helpers - cooked input session + view helpers

///|
pub(all) struct ImeSession {
  is_editing : @signals.Signal[Bool]
}

///|
pub fn ImeSession::new() -> ImeSession {
  { is_editing: @signals.signal(false) }
}

///|
pub fn ImeSession::is_editing(self : ImeSession) -> Bool {
  self.is_editing.get()
}

///|
pub fn ImeSession::start(
  self : ImeSession,
  config : EditConfig,
  current_value : String,
  on_complete : () -> Unit,
  confirm_on_shift_enter? : Bool = false,
  esc_cancels? : Bool = true,
) -> Unit {
  self.is_editing.set(true)
  start_edit(
    config,
    current_value,
    fn() {
      self.is_editing.set(false)
      on_complete()
    },
    confirm_on_shift_enter~,
    esc_cancels~,
  )
}

///|
fn to_input_state(
  is_editing : Bool,
  focused : Bool,
  disabled : Bool,
) -> InputState {
  if disabled {
    InputState::Disabled
  } else if is_editing {
    InputState::Editing
  } else if focused {
    InputState::Focused
  } else {
    InputState::Idle
  }
}

///|
fn to_textarea_state(
  is_editing : Bool,
  focused : Bool,
  disabled : Bool,
) -> TextareaState {
  if disabled {
    TextareaState::Disabled
  } else if is_editing {
    TextareaState::Editing
  } else if focused {
    TextareaState::Focused
  } else {
    TextareaState::Idle
  }
}

///|
/// Single-line IME-friendly input view
pub fn ime_input(
  value : String,
  is_editing : Bool,
  focused? : Bool = false,
  disabled? : Bool = false,
  id? : String = "",
  placeholder? : String = "",
  fg? : @core.Color = @core.Color::white(),
  bg? : @core.Color = @core.Color::rgb(40, 40, 50),
  placeholder_fg? : @core.Color = @core.Color::rgb(100, 100, 100),
  focus_border_color? : @core.Color = @core.Color::cyan(),
  edit_border_color? : @core.Color = @core.Color::green(),
  disabled_fg? : @core.Color = @core.Color::rgb(80, 80, 80),
  disabled_bg? : @core.Color = @core.Color::rgb(30, 30, 35),
  width? : @types.Dimension = @types.Dimension::Auto,
  height? : @types.Dimension = @types.Dimension::Auto,
  min_width? : Double = 10.0,
  min_height? : Double = 1.0,
  padding_x? : Double = 0.0,
  padding_y? : Double = 0.0,
) -> @core.Component {
  let state = to_input_state(is_editing, focused, disabled)
  input(
    value,
    id~,
    placeholder~,
    state~,
    fg~,
    bg~,
    placeholder_fg~,
    focus_border_color~,
    edit_border_color~,
    disabled_fg~,
    disabled_bg~,
    width~,
    height~,
    min_width~,
    min_height~,
    padding_x~,
    padding_y~,
  )
}

///|
/// Multi-line IME-friendly textarea view
pub fn ime_textarea(
  value : String,
  is_editing : Bool,
  focused? : Bool = false,
  disabled? : Bool = false,
  id? : String = "",
  rows? : Int = 3,
  placeholder? : String = "",
  fg? : @core.Color = @core.Color::white(),
  bg? : @core.Color = @core.Color::rgb(40, 40, 50),
  placeholder_fg? : @core.Color = @core.Color::rgb(100, 100, 100),
  focus_border_color? : @core.Color = @core.Color::cyan(),
  edit_border_color? : @core.Color = @core.Color::green(),
  disabled_fg? : @core.Color = @core.Color::rgb(80, 80, 80),
  disabled_bg? : @core.Color = @core.Color::rgb(30, 30, 35),
  width? : @types.Dimension = @types.Dimension::Auto,
  min_width? : Double = 20.0,
  padding_x? : Double = 1.0,
  padding_y? : Double = 0.0,
) -> @core.Component {
  let state = to_textarea_state(is_editing, focused, disabled)
  textarea(
    value,
    id~,
    rows~,
    placeholder~,
    state~,
    fg~,
    bg~,
    placeholder_fg~,
    focus_border_color~,
    edit_border_color~,
    disabled_fg~,
    disabled_bg~,
    width~,
    min_width~,
    padding_x~,
    padding_y~,
  )
}
