///|
/// Styled toggle components (Checkbox, Radio, Switch)

///|
/// Re-export ToggleState from headless
pub using @headless {type ToggleState}

///|
/// Checkbox component
pub fn checkbox(
  label : String,
  checked : Bool,
  id? : String = "",
  focused? : Bool = false,
  disabled? : Bool = false,
) -> @vnode.TuiNode {
  let icon = if checked { "[x]" } else { "[ ]" }
  let fg = if disabled {
    "rgb(80,80,80)"
  } else if checked {
    "cyan"
  } else {
    "white"
  }
  let bg = if focused && not(disabled) { "rgb(40,60,90)" } else { "" }
  @vnode.row(id~, bg~, padding_x=1.0, [
    @vnode.text(icon, fg~),
    @vnode.hspace(1.0),
    @vnode.text(label, fg="white"),
  ])
}

///|
/// Radio option component
pub fn radio(
  label : String,
  selected : Bool,
  id? : String = "",
  disabled? : Bool = false,
) -> @vnode.TuiNode {
  let icon = if selected { "(*)" } else { "( )" }
  let fg = if disabled {
    "rgb(80,80,80)"
  } else if selected {
    "cyan"
  } else {
    "white"
  }
  let bg = if selected && not(disabled) { "rgb(40,60,90)" } else { "" }
  @vnode.row(id~, bg~, padding_x=1.0, [
    @vnode.text(icon + " " + label, fg~, bold=selected),
  ])
}

///|
/// Switch toggle component
pub fn switch(
  on : Bool,
  label : String,
  id? : String = "",
  disabled? : Bool = false,
) -> @vnode.TuiNode {
  let track = if on { "[*--]" } else { "[--*]" }
  let track_color = if disabled {
    "rgb(60,60,60)"
  } else if on {
    "green"
  } else {
    "rgb(80,80,80)"
  }
  let status = if on { "ON" } else { "OFF" }
  let status_color = if disabled {
    "rgb(60,60,60)"
  } else if on {
    "green"
  } else {
    "rgb(100,100,100)"
  }
  @vnode.row(id~, [
    @vnode.text(label, fg="white"),
    @vnode.hspace(1.0),
    @vnode.text(track, fg=track_color),
    @vnode.hspace(1.0),
    @vnode.text(status, fg=status_color),
  ])
}
