///|
/// Styled modal and dialog components

///|
/// Re-export ModalState from headless
pub using @headless {type ModalState}

///|
/// Modal backdrop
pub fn modal_backdrop() -> @vnode.TuiNode {
  @vnode.column([], flex_grow=1.0, bg="rgba(0,0,0,0.5)")
}

///|
/// Modal container
pub fn modal(
  title : String,
  content : Array[@vnode.TuiNode],
  width? : Double = 40.0,
  id? : String = "",
) -> @vnode.TuiNode {
  @vnode.column(
    [
      @vnode.row(
        [@vnode.text(title, fg="cyan", bold=true)],
        padding_x=1.0,
        padding_y=0.5,
      ),
      @vnode.row([
        @vnode.text("-".repeat(width.to_int() - 4), fg="rgb(60,60,60)"),
      ]),
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
  title? : String = "Alert",
  button_label? : String = "OK",
  id? : String = "",
) -> @vnode.TuiNode {
  modal(
    title,
    [
      @vnode.row([@vnode.text(message)], padding_y=1.0),
      @vnode.row([button(button_label, id="alert-ok")], justify="center"),
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
      @vnode.row([@vnode.text(message)], padding_y=1.0),
      @vnode.row(
        [
          button(confirm_label, id="confirm-yes"),
          @vnode.hspace(2.0),
          button(cancel_label, id="confirm-no"),
        ],
        justify="center",
      ),
    ],
    id~,
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
      @vnode.row([@vnode.text(title, fg="cyan", bold=true)], padding_y=0.5),
      ..content,
    ]
  } else {
    content
  }
  @vnode.column(
    children,
    id~,
    border="rounded",
    border_color="rgb(60,60,80)",
    padding=1.0,
  )
}
