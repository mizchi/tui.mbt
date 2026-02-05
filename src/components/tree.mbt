///|
/// Tree view component for hierarchical data display

///|
/// Re-export TreeState from headless
pub using @headless {type TreeState}

///|
/// Build a single line string for a tree node
fn tree_line(
  depth : Int,
  node : @logics.TreeNode[String],
  state : @headless.TreeState,
) -> String {
  let is_focused = state.focused_id == node.id
  let is_selected = state.selected_id == node.id
  let marker = if is_focused || is_selected { ">" } else { " " }
  let indent_str = String::make(depth * 2, ' ')
  let icon = if node.is_leaf() {
    "  "
  } else if state.is_expanded(node.id) {
    "v "
  } else {
    "> "
  }
  let label = if is_selected { "[" + node.label + "]" } else { node.label }
  marker + " " + indent_str + icon + label
}

///|
/// Tree view component — renders as single multiline text to avoid flex gaps
pub fn tree_view(
  root : @logics.TreeNode[String],
  state : @headless.TreeState,
  id? : String = "",
) -> @vnode.TuiNode {
  let flat = root.flatten(state.expanded_ids)
  let mut content = ""
  for i, item in flat {
    if i > 0 {
      content = content + "\n"
    }
    content = content + tree_line(item.0, item.1, state)
  }
  @vnode.column(id~, [@vnode.text(content, fg="rgb(180,180,180)")])
}

///|
/// Tree view component with multiple roots
pub fn tree_view_forest(
  roots : Array[@logics.TreeNode[String]],
  state : @headless.TreeState,
  id? : String = "",
) -> @vnode.TuiNode {
  let flat = @logics.flatten_forest(roots, state.expanded_ids)
  let mut content = ""
  for i, item in flat {
    if i > 0 {
      content = content + "\n"
    }
    content = content + tree_line(item.0, item.1, state)
  }
  @vnode.column(id~, [@vnode.text(content, fg="rgb(180,180,180)")])
}
