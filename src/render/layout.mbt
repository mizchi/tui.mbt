///|
/// Integration with layout tree engine
/// Uses character-based measurements (1 char = 1 unit width/height)

///|
/// Compute layout using layout tree with character-based viewport
pub fn compute_layout(
  node : @node.Node,
  width : Int,
  height : Int,
) -> @types.Layout {
  let tree = @ltree.LayoutTree::from_node(
    node,
    width.to_double(),
    height.to_double(),
  )
  tree.compute_full()
}

///|
/// Compute layout in intrinsic (MaxContent) mode.
/// Useful for shrink-wrapped overlays/popups.
pub fn compute_layout_max_content(
  node : @node.Node,
  width : Int,
  height : Int,
) -> @types.Layout {
  let viewport = @types.Size::new(width.to_double(), height.to_double())
  @lengine.compute_layout(node, viewport)
}
