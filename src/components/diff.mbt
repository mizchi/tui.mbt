///|
/// Diff view component for displaying text differences

///|
/// Render a single diff operation line
fn diff_line(op : @logics.DiffOp) -> @vnode.TuiNode {
  match op {
    Equal(s) => @vnode.row([@vnode.text("  " + s, fg="rgb(180,180,180)")])
    Insert(s) =>
      @vnode.row(bg="rgb(30,60,30)", [@vnode.text("+ " + s, fg="green")])
    Delete(s) =>
      @vnode.row(bg="rgb(60,30,30)", [@vnode.text("- " + s, fg="red")])
  }
}

///|
/// Unified diff view component
pub fn diff_view(
  old_lines : Array[String],
  new_lines : Array[String],
  id? : String = "",
) -> @vnode.TuiNode {
  let ops = @logics.diff_lines(old_lines, new_lines)
  let nodes : Array[@vnode.TuiNode] = []
  for op in ops {
    nodes.push(diff_line(op))
  }
  @vnode.column(id~, border="single", border_color="rgb(60,60,80)", nodes)
}

///|
/// Diff view from pre-computed diff operations
pub fn diff_view_from_ops(
  ops : Array[@logics.DiffOp],
  id? : String = "",
) -> @vnode.TuiNode {
  let nodes : Array[@vnode.TuiNode] = []
  for op in ops {
    nodes.push(diff_line(op))
  }
  @vnode.column(id~, border="single", border_color="rgb(60,60,80)", nodes)
}
