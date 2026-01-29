///|
struct Selection {
  mut anchor : Position
  mut active : Position
}

///|
fn Selection::caret(pos : Position) -> Selection {
  { anchor: pos, active: pos }
}

///|
fn Selection::is_empty(self : Selection) -> Bool {
  self.anchor == self.active
}

///|
fn position_before_or_equal(a : Position, b : Position) -> Bool {
  if a.line < b.line {
    true
  } else if a.line > b.line {
    false
  } else {
    a.col <= b.col
  }
}

///|
fn Selection::ordered(self : Selection) -> (Position, Position) {
  if position_before_or_equal(self.anchor, self.active) {
    (self.anchor, self.active)
  } else {
    (self.active, self.anchor)
  }
}

///|
fn Selection::set_caret(self : Selection, pos : Position) -> Unit {
  self.anchor = pos
  self.active = pos
}

///|
fn Selection::set_active(self : Selection, pos : Position) -> Unit {
  self.active = pos
}
