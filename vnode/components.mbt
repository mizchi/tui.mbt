///|
/// High-level UI components built on vnode primitives

// =============================================================================
// Button
// =============================================================================

///|
/// Button state
pub(all) enum ButtonState {
  Default
  Focused
  Pressed
  Disabled
}

///|
/// Button component
pub fn button(
  label : String,
  id~ : String = "",
  state~ : ButtonState = Default,
  min_width~ : Double = 0.0,
) -> TuiNode {
  let (fg, bg, border_color) = match state {
    Default => ("white", "", "cyan")
    Focused => ("black", "cyan", "cyan")
    Pressed => ("black", "rgb(0,180,180)", "rgb(0,180,180)")
    Disabled => ("rgb(100,100,100)", "", "rgb(60,60,60)")
  }
  row(
    [text(" " + label + " ", fg~)],
    id~,
    bg~,
    border="rounded",
    border_color~,
    padding_x=1.0,
    height=3.0,
    min_width~,
    justify="center",
    align="center",
  )
}

///|
/// Icon button (smaller, no border)
pub fn icon_button(
  icon : String,
  id~ : String = "",
  state~ : ButtonState = Default,
) -> TuiNode {
  let (fg, bg) = match state {
    Default => ("white", "")
    Focused => ("cyan", "rgb(60,60,80)")
    Pressed => ("black", "cyan")
    Disabled => ("rgb(80,80,80)", "")
  }
  row([text(icon, fg~)], id~, bg~, padding_x=0.5)
}

// =============================================================================
// Checkbox / Radio / Switch
// =============================================================================

///|
/// Checkbox component
pub fn checkbox(
  label : String,
  checked : Bool,
  id~ : String = "",
  focused~ : Bool = false,
  disabled~ : Bool = false,
) -> TuiNode {
  let icon = if checked { "[x]" } else { "[ ]" }
  let fg = if disabled {
    "rgb(80,80,80)"
  } else if checked {
    "cyan"
  } else {
    "white"
  }
  let bg = if focused && not(disabled) { "rgb(40,60,90)" } else { "" }
  row([text(icon, fg~), hspace(1.0), text(label, fg="white")], id~, bg~, padding_x=1.0)
}

///|
/// Radio option component
pub fn radio(
  label : String,
  selected : Bool,
  id~ : String = "",
  disabled~ : Bool = false,
) -> TuiNode {
  let icon = if selected { "(*)" } else { "( )" }
  let fg = if disabled {
    "rgb(80,80,80)"
  } else if selected {
    "cyan"
  } else {
    "white"
  }
  let bg = if selected && not(disabled) { "rgb(40,60,90)" } else { "" }
  row([text(icon + " " + label, fg~, bold=selected)], id~, bg~, padding_x=1.0)
}

///|
/// Switch toggle component
pub fn switch(
  on : Bool,
  label : String,
  id~ : String = "",
  disabled~ : Bool = false,
) -> TuiNode {
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
  row(
    [
      text(label, fg="white"),
      hspace(1.0),
      text(track, fg=track_color),
      hspace(1.0),
      text(status, fg=status_color),
    ],
    id~,
  )
}

// =============================================================================
// Tabs
// =============================================================================

///|
/// Tab item component
pub fn tab(
  label : String,
  selected : Bool,
  id~ : String = "",
) -> TuiNode {
  let fg = if selected { "black" } else { "white" }
  let bg = if selected { "cyan" } else { "rgb(60,60,70)" }
  row([text(" " + label + " ", fg~)], id~, bg~, padding_x=0.5)
}

///|
/// Tab bar component
pub fn tab_bar(tabs : Array[(String, String)], selected_id : String) -> TuiNode {
  let items : Array[TuiNode] = []
  for t in tabs {
    items.push(tab(t.0, t.1 == selected_id, id=t.1))
  }
  row(items, gap=0.5)
}

// =============================================================================
// Accordion
// =============================================================================

///|
/// Accordion section component
pub fn accordion_section(
  title : String,
  content : TuiNode,
  expanded : Bool,
  id~ : String = "",
) -> TuiNode {
  let icon = if expanded { "[-]" } else { "[+]" }
  let header_bg = if expanded { "rgb(40,60,90)" } else { "rgb(50,50,60)" }
  let children : Array[TuiNode] = [
    row(
      [text(icon + " " + title, fg="cyan", bold=expanded)],
      id~,
      bg=header_bg,
      padding_x=1.0,
    ),
  ]
  if expanded {
    children.push(
      row([content], padding_x=2.0, bg="rgb(30,30,40)"),
    )
  }
  column(children, border="single", border_color="rgb(60,60,80)")
}

// =============================================================================
// Listbox
// =============================================================================

///|
/// Listbox item component
pub fn listbox_item(
  label : String,
  selected : Bool,
  id~ : String = "",
) -> TuiNode {
  let prefix = if selected { "> " } else { "  " }
  let fg = if selected { "cyan" } else { "white" }
  let bg = if selected { "rgb(40,60,90)" } else { "" }
  row([text(prefix + label, fg~, bold=selected)], id~, bg~, padding_x=1.0)
}

///|
/// Listbox component
pub fn listbox(
  items : Array[(String, String)],
  selected_id : String,
  id~ : String = "",
) -> TuiNode {
  let nodes : Array[TuiNode] = []
  for item in items {
    nodes.push(listbox_item(item.0, item.1 == selected_id, id=item.1))
  }
  column(nodes, id~, border="single", border_color="rgb(60,60,80)")
}

// =============================================================================
// Combobox
// =============================================================================

///|
/// Combobox trigger component
pub fn combobox_trigger(
  label : String,
  open : Bool,
  id~ : String = "",
) -> TuiNode {
  let arrow = if open { "^" } else { "v" }
  row(
    [text(" " + label + " ", fg="white"), text(arrow, fg="cyan")],
    id~,
    border="single",
    border_color="rgb(80,80,100)",
    padding_x=0.5,
  )
}

///|
/// Combobox dropdown item component
pub fn combobox_item(
  label : String,
  selected : Bool,
  id~ : String = "",
) -> TuiNode {
  let bg = if selected { "rgb(40,80,120)" } else { "rgb(40,40,50)" }
  let fg = if selected { "cyan" } else { "white" }
  row([text(" " + label + " ", fg~)], id~, bg~, padding_x=0.5)
}

// =============================================================================
// Menu
// =============================================================================

///|
/// Menubar item component
pub fn menubar_item(
  label : String,
  open : Bool,
  id~ : String = "",
) -> TuiNode {
  let bg = if open { "rgb(60,80,120)" } else { "" }
  row([text(" " + label + " ", bold=open)], id~, bg~, padding_x=0.5)
}

///|
/// Menu dropdown item component
pub fn menu_item(
  label : String,
  selected : Bool,
  id~ : String = "",
  disabled~ : Bool = false,
) -> TuiNode {
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
  row([text(" " + label + " ", fg~)], id~, bg~, padding_x=1.0, height=1.0)
}

///|
/// Menu divider
pub fn menu_divider() -> TuiNode {
  row([text("-".repeat(20), fg="rgb(60,60,60)")], height=1.0)
}

// =============================================================================
// Progress / Spinner
// =============================================================================

///|
/// Progress bar component
pub fn progress_bar(
  ratio : Double,
  width~ : Int = 20,
  show_percent~ : Bool = true,
) -> TuiNode {
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
    row([text(bar, fg=color), hspace(1.0), text(pct.to_string() + "%", fg="gray")])
  } else {
    text(bar, fg=color)
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
pub fn spinner(tick : Int, label~ : String = "") -> TuiNode {
  let frame = get_spinner_frame(tick)
  if label.length() > 0 {
    row([text(frame, fg="cyan"), hspace(1.0), text(label)])
  } else {
    text(frame, fg="cyan")
  }
}

// =============================================================================
// Modal / Dialog
// =============================================================================

///|
/// Modal backdrop
pub fn modal_backdrop() -> TuiNode {
  column([], flex_grow=1.0, bg="rgba(0,0,0,0.5)")
}

///|
/// Modal container
pub fn modal(
  title : String,
  content : Array[TuiNode],
  width~ : Double = 40.0,
  id~ : String = "",
) -> TuiNode {
  column(
    [
      row([text(title, fg="cyan", bold=true)], padding_x=1.0, padding_y=0.5),
      row([text("-".repeat(width.to_int() - 4), fg="rgb(60,60,60)")]),
      ..content,
    ],
    id~,
    width~,
    border="rounded",
    border_color="cyan",
    bg="rgb(30,30,40)",
    padding=1.0,
  )
}

///|
/// Alert dialog
pub fn alert_dialog(
  message : String,
  title~ : String = "Alert",
  button_label~ : String = "OK",
  id~ : String = "",
) -> TuiNode {
  modal(
    title,
    [
      row([text(message)], padding_y=1.0),
      row([button(button_label, id="alert-ok")], justify="center"),
    ],
    id~,
  )
}

///|
/// Confirm dialog
pub fn confirm_dialog(
  message : String,
  title~ : String = "Confirm",
  confirm_label~ : String = "Yes",
  cancel_label~ : String = "No",
  id~ : String = "",
) -> TuiNode {
  modal(
    title,
    [
      row([text(message)], padding_y=1.0),
      row(
        [
          button(confirm_label, id="confirm-yes"),
          hspace(2.0),
          button(cancel_label, id="confirm-no"),
        ],
        justify="center",
      ),
    ],
    id~,
  )
}

// =============================================================================
// Layout Helpers
// =============================================================================

///|
/// Divider (horizontal)
pub fn divider(char~ : String = "-", fg~ : String = "rgb(60,60,60)") -> TuiNode {
  text(char.repeat(80), fg~)
}

///|
/// Card container
pub fn card(
  content : Array[TuiNode],
  title~ : String = "",
  id~ : String = "",
) -> TuiNode {
  let children : Array[TuiNode] = if title.length() > 0 {
    [row([text(title, fg="cyan", bold=true)], padding_y=0.5), ..content]
  } else {
    content
  }
  column(
    children,
    id~,
    border="rounded",
    border_color="rgb(60,60,80)",
    padding=1.0,
  )
}
