///|
/// Toast notification component

///|
/// Re-export toast types from headless
pub using @headless {type ToastLevel, type ToastState}

///|
/// Toast notification component
pub fn toast(state : @headless.ToastState, id? : String = "") -> @vnode.TuiNode {
  if not(state.visible) {
    return @vnode.fragment([])
  }
  let (fg, bg, border_color, icon) = match state.level {
    Info => ("white", "rgb(40,40,60)", "cyan", "i")
    Success => ("white", "rgb(30,60,30)", "green", "v")
    Warning => ("black", "rgb(80,60,20)", "yellow", "!")
    Error => ("white", "rgb(80,30,30)", "red", "x")
  }
  @vnode.row(
    id~,
    bg~,
    border="rounded",
    border_color~,
    padding_x=1.0,
    [
      @vnode.text("[" + icon + "]", fg=border_color),
      @vnode.hspace(1.0),
      @vnode.text(state.message, fg~),
    ],
  )
}
