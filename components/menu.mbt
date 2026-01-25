///|
/// Styled menu components

///|
/// Menubar item component
pub fn menubar_item(
  label : String,
  open : Bool,
  id? : String = "",
) -> @vnode.TuiNode {
  let bg = if open { "rgb(60,80,120)" } else { "" }
  @vnode.row(id~, bg~, padding_x=0.5, children=[
    @vnode.text(" " + label + " ", bold=open),
  ])
}

///|
/// Menu dropdown item component
pub fn menu_item(
  label : String,
  selected : Bool,
  id? : String = "",
  disabled? : Bool = false,
) -> @vnode.TuiNode {
  let bg = if selected && not(disabled) {
    "rgb(40,80,120)"
  } else {
    "rgb(50,50,60)"
  }
  let fg = if disabled {
    "rgb(80,80,80)"
  } else if selected {
    "cyan"
  } else {
    "white"
  }
  @vnode.row(id~, bg~, padding_x=1.0, height=1.0, children=[
    @vnode.text(" " + label + " ", fg~),
  ])
}

///|
/// Menu divider
pub fn menu_divider() -> @vnode.TuiNode {
  @vnode.row(height=1.0, children=[
    @vnode.text("-".repeat(20), fg="rgb(60,60,60)"),
  ])
}
