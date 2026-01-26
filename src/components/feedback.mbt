///|
/// Styled feedback components (Progress, Spinner)

///|
/// Progress bar component
pub fn progress_bar(
  ratio : Double,
  width? : Int = 20,
  show_percent? : Bool = true,
) -> @vnode.TuiNode {
  let clamped = if ratio < 0.0 {
    0.0
  } else if ratio > 1.0 {
    1.0
  } else {
    ratio
  }
  let bar_width = width - 2 // for [ ]
  let filled = (bar_width.to_double() * clamped).to_int()
  let empty = bar_width - filled
  let bar = "[" + "\u{2588}".repeat(filled) + "\u{2591}".repeat(empty) + "]"
  let color = if ratio > 0.9 {
    "red"
  } else if ratio > 0.7 {
    "yellow"
  } else {
    "cyan"
  }
  if show_percent {
    let pct = (clamped * 100.0).to_int()
    @vnode.row([
      @vnode.text(bar, fg=color),
      @vnode.hspace(1.0),
      @vnode.text(pct.to_string() + "%", fg="gray"),
    ])
  } else {
    @vnode.text(bar, fg=color)
  }
}

///|
/// Spinner frames
let spinner_frames : Array[String] = ["|", "/", "-", "\\"]

///|
/// Get spinner frame by tick
pub fn get_spinner_frame(tick : Int) -> String {
  spinner_frames[tick % 4]
}

///|
/// Spinner component
pub fn spinner(tick : Int, label? : String = "") -> @vnode.TuiNode {
  let frame = get_spinner_frame(tick)
  if label.length() > 0 {
    @vnode.row([
      @vnode.text(frame, fg="cyan"),
      @vnode.hspace(1.0),
      @vnode.text(label),
    ])
  } else {
    @vnode.text(frame, fg="cyan")
  }
}

///|
/// Divider (horizontal line)
pub fn divider(
  width? : Int = 20,
  char? : String = "─",
  fg? : String = "rgb(60,60,60)",
) -> @vnode.TuiNode {
  @vnode.text(char.repeat(width), fg~)
}
