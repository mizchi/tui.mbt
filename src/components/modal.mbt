///|
/// Styled modal and dialog components

///|
/// Re-export ModalState from headless
pub using @headless {type ModalState}

///|
/// Modal backdrop
pub fn modal_backdrop() -> @vnode.TuiNode {
  @vnode.column(flex_grow=1.0, bg="rgba(0,0,0,0.5)", [])
}

///|
fn strip_ansi(s : String) -> String {
  let chars = s.to_array()
  let out : Array[Char] = []
  let mut i = 0
  while i < chars.length() {
    let c = chars[i]
    if c == '\u001b' {
      i = i + 1
      if i < chars.length() && chars[i] == '[' {
        i = i + 1
        let mut done = false
        while i < chars.length() && !done {
          let code = chars[i].to_int()
          if code >= 0x40 && code <= 0x7e {
            done = true
          }
          i = i + 1
        }
      }
    } else {
      out.push(c)
      i = i + 1
    }
  }
  String::from_array(out)
}

///|
fn estimate_node_inner_width(node : @vnode.TuiNode) -> Int {
  let lines = @vnode.render_to_lines(node)
  let mut max_w = 0
  for line in lines {
    let w = @core.string_display_width(strip_ansi(line))
    if w > max_w {
      max_w = w
    }
  }
  max_w
}

///|
fn resolve_modal_width(
  title : String,
  content : Array[@vnode.TuiNode],
  width : Double,
) -> Double {
  if width >= 0.0 {
    return width
  }
  let mut inner_w = @core.string_display_width(title)
  for node in content {
    let w = estimate_node_inner_width(node)
    if w > inner_w {
      inner_w = w
    }
  }
  // border(2) + padding(2) + small safety margin(2)
  let total = inner_w + 6
  if total < 12 {
    12.0
  } else {
    total.to_double()
  }
}

///|
/// Modal container
pub fn modal(
  title : String,
  content : Array[@vnode.TuiNode],
  width? : Double = -1.0,
  id? : String = "",
) -> @vnode.TuiNode {
  let resolved_width = resolve_modal_width(title, content, width)
  let separator_len = resolved_width.to_int() - 4
  let separator = if separator_len > 0 {
    "-".repeat(separator_len)
  } else {
    ""
  }
  let children : Array[@vnode.TuiNode] = [
    @vnode.row(padding_x=1.0, padding_y=0.5, [
      @vnode.text(title, fg="cyan", bold=true),
    ]),
  ]
  if separator.length() > 0 {
    children.push(
      @vnode.row([
        @vnode.text(separator, fg="rgb(60,60,60)"),
      ]),
    )
  }
  for node in content {
    children.push(node)
  }
  @vnode.column(
    id~,
    width=resolved_width,
    border="rounded",
    border_color="cyan",
    bg="rgb(30,30,40)",
    padding=1.0,
    children,
  )
}

///|
/// Alert dialog
pub fn alert_dialog(
  message : String,
  title? : String = "Alert",
  button_label? : String = "OK",
  id? : String = "",
) -> @vnode.TuiNode {
  modal(
    title,
    [
      @vnode.row(padding_y=1.0, [@vnode.text(message)]),
      @vnode.row(justify="center", [button(button_label, id="alert-ok")]),
    ],
    id~,
  )
}

///|
/// Confirm dialog
pub fn confirm_dialog(
  message : String,
  title? : String = "Confirm",
  confirm_label? : String = "Yes",
  cancel_label? : String = "No",
  id? : String = "",
) -> @vnode.TuiNode {
  modal(
    title,
    [
      @vnode.row(padding_y=1.0, [@vnode.text(message)]),
      @vnode.row(justify="center", [
        button(confirm_label, id="confirm-yes"),
        @vnode.hspace(2.0),
        button(cancel_label, id="confirm-no"),
      ]),
    ],
    id~,
  )
}

///|
/// Wrap any TuiNode as an overlay entry
pub fn popup(
  content : @vnode.TuiNode,
  backdrop? : Bool = true,
  position? : @vnode.PopupPosition = Center,
  shrink? : Bool = true,
) -> @vnode.OverlayEntry {
  { node: content, position, backdrop, shrink }
}

///|
/// Create a modal overlay entry
pub fn modal_popup(
  title : String,
  content : Array[@vnode.TuiNode],
  width? : Double = -1.0,
  backdrop? : Bool = true,
  position? : @vnode.PopupPosition = Center,
  shrink? : Bool = true,
  id? : String = "",
) -> @vnode.OverlayEntry {
  popup(modal(title, content, width~, id~), backdrop~, position~, shrink~)
}

///|
/// Create an alert overlay entry
pub fn alert_popup(
  message : String,
  title? : String = "Alert",
  button_label? : String = "OK",
  backdrop? : Bool = true,
  position? : @vnode.PopupPosition = Center,
  shrink? : Bool = true,
  id? : String = "",
) -> @vnode.OverlayEntry {
  popup(
    alert_dialog(message, title~, button_label~, id~),
    backdrop~,
    position~,
    shrink~,
  )
}

///|
/// Create a confirm overlay entry
pub fn confirm_popup(
  message : String,
  title? : String = "Confirm",
  confirm_label? : String = "Yes",
  cancel_label? : String = "No",
  backdrop? : Bool = true,
  position? : @vnode.PopupPosition = Center,
  shrink? : Bool = true,
  id? : String = "",
) -> @vnode.OverlayEntry {
  popup(
    confirm_dialog(message, title~, confirm_label~, cancel_label~, id~),
    backdrop~,
    position~,
    shrink~,
  )
}

///|
/// Card container
pub fn card(
  content : Array[@vnode.TuiNode],
  title? : String = "",
  id? : String = "",
) -> @vnode.TuiNode {
  let children : Array[@vnode.TuiNode] = if title.length() > 0 {
    [
      @vnode.row(padding_y=0.5, [@vnode.text(title, fg="cyan", bold=true)]),
      ..content,
    ]
  } else {
    content
  }
  @vnode.column(
    id~,
    border="rounded",
    border_color="rgb(60,60,80)",
    padding=1.0,
    children,
  )
}
