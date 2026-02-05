///|
/// Grid select component for 2D item selection

///|
/// Re-export GridSelectState from headless
pub using @headless {type GridSelectState}

///|
/// Grid select item
pub fn grid_select_item(
  label : String,
  selected : Bool,
  id? : String = "",
) -> @vnode.TuiNode {
  let fg = if selected { "black" } else { "white" }
  let bg = if selected { "cyan" } else { "rgb(50,50,60)" }
  @vnode.row(id~, bg~, padding_x=1.0, justify="center", align="center", [
    @vnode.text(label, fg~, bold=selected),
  ])
}

///|
/// Grid select component rendering items in a grid layout
pub fn grid_select(
  items : Array[String],
  state : @headless.GridSelectState,
  id? : String = "",
  min_item_width? : Double = 10.0,
) -> @vnode.TuiNode {
  let columns : Array[Double] = []
  for _i = 0; _i < state.columns; _i = _i + 1 {
    columns.push(min_item_width)
  }
  let nodes : Array[@vnode.TuiNode] = []
  for i, item in items {
    let selected = i == state.selected
    nodes.push(grid_select_item(item, selected, id=item))
  }
  @vnode.grid(columns~, id~, gap=0.5, nodes)
}
