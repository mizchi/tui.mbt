///|
/// Styled selection components (Listbox, Combobox, Tabs)

///|
/// Re-export SelectionState from headless
pub using @headless {type SelectionState}

///|
/// Tab item component
pub fn tab(
  label : String,
  selected : Bool,
  id? : String = "",
) -> @vnode.TuiNode {
  let fg = if selected { "black" } else { "white" }
  let bg = if selected { "cyan" } else { "rgb(60,60,70)" }
  @vnode.row(id~, bg~, padding_x=0.5, children=[
    @vnode.text(" " + label + " ", fg~),
  ])
}

///|
/// Tab bar component
pub fn tab_bar(
  tabs : Array[(String, String)],
  selected_id : String,
) -> @vnode.TuiNode {
  let items : Array[@vnode.TuiNode] = []
  for t in tabs {
    items.push(tab(t.0, t.1 == selected_id, id=t.1))
  }
  @vnode.row(gap=0.5, children=items)
}

///|
/// Listbox item component
pub fn listbox_item(
  label : String,
  selected : Bool,
  id? : String = "",
) -> @vnode.TuiNode {
  let prefix = if selected { "> " } else { "  " }
  let fg = if selected { "cyan" } else { "white" }
  let bg = if selected { "rgb(40,60,90)" } else { "" }
  @vnode.row(id~, bg~, padding_x=1.0, children=[
    @vnode.text(prefix + label, fg~, bold=selected),
  ])
}

///|
/// Listbox component
pub fn listbox(
  items : Array[(String, String)],
  selected_id : String,
  id? : String = "",
) -> @vnode.TuiNode {
  let nodes : Array[@vnode.TuiNode] = []
  for item in items {
    nodes.push(listbox_item(item.0, item.1 == selected_id, id=item.1))
  }
  @vnode.column(
    id~,
    border="single",
    border_color="rgb(60,60,80)",
    children=nodes,
  )
}

///|
/// Combobox trigger component
pub fn combobox_trigger(
  label : String,
  open : Bool,
  id? : String = "",
) -> @vnode.TuiNode {
  let arrow = if open { "^" } else { "v" }
  @vnode.row(
    id~,
    border="single",
    border_color="rgb(80,80,100)",
    padding_x=0.5,
    children=[
      @vnode.text(" " + label + " ", fg="white"),
      @vnode.text(arrow, fg="cyan"),
    ],
  )
}

///|
/// Combobox dropdown item component
pub fn combobox_item(
  label : String,
  selected : Bool,
  id? : String = "",
) -> @vnode.TuiNode {
  let bg = if selected { "rgb(40,80,120)" } else { "rgb(40,40,50)" }
  let fg = if selected { "cyan" } else { "white" }
  @vnode.row(id~, bg~, padding_x=0.5, children=[
    @vnode.text(" " + label + " ", fg~),
  ])
}
