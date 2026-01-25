///|
/// Styled button components

///|
/// Re-export ButtonState from headless
pub using @headless {type ButtonState}

///|
/// Styled button component
pub fn button(
  label : String,
  id? : String = "",
  state? : @headless.ButtonState = @headless.ButtonState::Default,
  min_width? : Double = 0.0,
) -> @vnode.TuiNode {
  let (fg, bg, border_color) = match state {
    Default => ("white", "", "cyan")
    Focused => ("black", "cyan", "cyan")
    Pressed => ("black", "rgb(0,180,180)", "rgb(0,180,180)")
    Disabled => ("rgb(100,100,100)", "", "rgb(60,60,60)")
  }
  @vnode.row(
    id~,
    bg~,
    border="rounded",
    border_color~,
    padding_x=1.0,
    height=3.0,
    min_width~,
    justify="center",
    align="center",
    children=[@vnode.text(" " + label + " ", fg~)],
  )
}

///|
/// Icon button (smaller, no border)
pub fn icon_button(
  icon : String,
  id? : String = "",
  state? : @headless.ButtonState = @headless.ButtonState::Default,
) -> @vnode.TuiNode {
  let (fg, bg) = match state {
    Default => ("white", "")
    Focused => ("cyan", "rgb(60,60,80)")
    Pressed => ("black", "cyan")
    Disabled => ("rgb(80,80,80)", "")
  }
  @vnode.row(id~, bg~, padding_x=0.5, children=[@vnode.text(icon, fg~)])
}

///|
/// Text button (no background, just text)
pub fn text_button(
  label : String,
  id? : String = "",
  state? : @headless.ButtonState = @headless.ButtonState::Default,
) -> @vnode.TuiNode {
  let _ = id // ID reserved for future ARIA support
  let (fg, underline) = match state {
    Default => ("cyan", false)
    Focused => ("white", true)
    Pressed => ("rgb(0,180,180)", false)
    Disabled => ("rgb(80,80,80)", false)
  }
  // Note: underline not supported in vnode yet, using bold as visual indicator
  @vnode.text(label, fg~, bold=underline)
}
