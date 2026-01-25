///|
/// Styled accordion components

///|
/// Re-export AccordionState from headless
pub using @headless {type AccordionState}

///|
/// Accordion section component
pub fn accordion_section(
  title : String,
  content : @vnode.TuiNode,
  expanded : Bool,
  id? : String = "",
) -> @vnode.TuiNode {
  let icon = if expanded { "[-]" } else { "[+]" }
  let header_bg = if expanded { "rgb(40,60,90)" } else { "rgb(50,50,60)" }
  let children : Array[@vnode.TuiNode] = [
    @vnode.row(id~, bg=header_bg, padding_x=1.0, children=[
      @vnode.text(icon + " " + title, fg="cyan", bold=expanded),
    ]),
  ]
  if expanded {
    children.push(
      @vnode.row(padding_x=2.0, bg="rgb(30,30,40)", children=[content]),
    )
  }
  @vnode.column(border="single", border_color="rgb(60,60,80)", children~)
}
