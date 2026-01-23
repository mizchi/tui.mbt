///|
/// Key to EditAction mapping

///|
/// Convert a KeyEvent to an EditAction based on configuration
pub fn interpret_key(
  event : @events.KeyEvent,
  config : TextInputConfig,
) -> EditAction {
  match event {
    // Special keys
    @events.KeyEvent::Special(special, modifier) =>
      interpret_special_key(special, modifier, config)
    // Character input
    @events.KeyEvent::Char(c, modifier) =>
      interpret_char_key(c, modifier, config)
  }
}

///|
fn interpret_special_key(
  key : @events.SpecialKey,
  modifier : @events.KeyModifier,
  config : TextInputConfig,
) -> EditAction {
  match key {
    // Navigation
    @events.SpecialKey::Left => MoveCursorLeft
    @events.SpecialKey::Right => MoveCursorRight
    @events.SpecialKey::Up => MoveCursorUp
    @events.SpecialKey::Down => MoveCursorDown
    @events.SpecialKey::Home => MoveToLineStart
    @events.SpecialKey::End => MoveToLineEnd
    // Deletion
    @events.SpecialKey::Backspace => DeleteBackward
    @events.SpecialKey::Delete => DeleteForward
    // Tab navigation
    @events.SpecialKey::Tab => Tab
    @events.SpecialKey::BackTab => BackTab
    // Enter handling
    @events.SpecialKey::Enter => interpret_enter(modifier, config)
    // Escape
    @events.SpecialKey::Escape => if config.esc_cancels { Cancel } else { None }
    // Unhandled special keys
    _ => None
  }
}

///|
fn interpret_enter(
  modifier : @events.KeyModifier,
  config : TextInputConfig,
) -> EditAction {
  let is_shift = match modifier {
    @events.KeyModifier::Shift => true
    _ => false
  }
  if config.multiline {
    if config.confirm_on_shift_enter {
      // Shift+Enter confirms, Enter inserts newline
      if is_shift {
        Confirm
      } else {
        NewLine
      }
      // Enter confirms, Shift+Enter inserts newline
    } else if is_shift {
      NewLine
    } else {
      Confirm
    }
  } else {
    Confirm
  }
  // Single-line: always confirm
}

///|
fn interpret_char_key(
  c : Char,
  modifier : @events.KeyModifier,
  config : TextInputConfig,
) -> EditAction {
  match modifier {
    @events.KeyModifier::Ctrl =>
      match c {
        'a' | 'A' => MoveToLineStart
        'e' | 'E' => MoveToLineEnd
        'k' | 'K' => DeleteToLineEnd
        'u' | 'U' => DeleteToLineStart
        'c' | 'C' => ForceQuit
        'j' | 'J' => if config.multiline { NewLine } else { None }
        _ => None
      }
    @events.KeyModifier::Alt =>
      match c {
        '\n' => if config.multiline { NewLine } else { None }
        _ => None
      }
    @events.KeyModifier::None | @events.KeyModifier::Shift =>
      // Regular character input
      Insert(c.to_string())
    _ => None
  }
}
