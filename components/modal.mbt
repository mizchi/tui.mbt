///|
/// Styled modal and dialog components

///|
/// Re-export ModalState from headless
pub using @headless {type ModalState}

///|
/// Modal backdrop
pub fn modal_backdrop() -> @vnode.TuiNode {
  @vnode.column(flex_grow=1.0, bg="rgba(0,0,0,0.5)", children=[])
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
    id~,
    width~,
    border="rounded",
    border_color="cyan",
    bg="rgb(30,30,40)",
    padding=1.0,
    children=[
      @vnode.row(padding_x=1.0, padding_y=0.5, children=[
        @vnode.text(title, fg="cyan", bold=true),
      ]),
      @vnode.row(children=[
        @vnode.text("-".repeat(width.to_int() - 4), fg="rgb(60,60,60)"),
      ]),
      ..content,
    ],
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
      @vnode.row(padding_y=1.0, children=[@vnode.text(message)]),
      @vnode.row(justify="center", children=[
        button(button_label, id="alert-ok"),
      ]),
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
      @vnode.row(padding_y=1.0, children=[@vnode.text(message)]),
      @vnode.row(justify="center", children=[
        button(confirm_label, id="confirm-yes"),
        @vnode.hspace(2.0),
        button(cancel_label, id="confirm-no"),
      ]),
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
      @vnode.row(padding_y=0.5, children=[
        @vnode.text(title, fg="cyan", bold=true),
      ]),
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
    children~,
  )
}
