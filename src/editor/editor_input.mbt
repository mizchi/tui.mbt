///|
fn modifier_has_shift(mod : @events.KeyModifier) -> Bool {
  match mod {
    Shift => true
    CtrlShift => true
    ShiftAlt => true
    CtrlShiftAlt => true
    _ => false
  }
}

///|
fn modifier_has_ctrl_or_alt(mod : @events.KeyModifier) -> Bool {
  match mod {
    Ctrl => true
    Alt => true
    CtrlShift => true
    CtrlAlt => true
    ShiftAlt => true
    CtrlShiftAlt => true
    _ => false
  }
}

///|
pub fn handle_key_event(state : EditorState, key : @events.KeyEvent) -> Unit {
  match key {
    @events.KeyEvent::Char(c, mod) =>
      if modifier_has_ctrl_or_alt(mod) {
        ()
      } else if @vnode.is_printable_char(c) {
        state.replace_selection(c.to_string())
      }
    @events.KeyEvent::Special(special, mod) => {
      let extend = modifier_has_shift(mod)
      match special {
        Left => state.move_left(extend)
        Right => state.move_right(extend)
        Up => state.move_up(extend)
        Down => state.move_down(extend)
        Home => state.move_home(extend)
        End => state.move_end(extend)
        PageUp => state.move_page_up(extend)
        PageDown => state.move_page_down(extend)
        Backspace => state.delete_backward()
        Delete => state.delete_forward()
        Enter => state.replace_selection("\n")
        Tab => state.replace_selection("  ")
        _ => ()
      }
    }
  }
}
