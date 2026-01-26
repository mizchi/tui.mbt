///|
/// Integration with crater layout engine
/// Uses character-based measurements (1 char = 1 unit width/height)

///|
/// Compute layout using crater engine with character-based viewport
pub fn compute_layout(
  node : @node.Node,
  width : Int,
  height : Int,
) -> @types.Layout {
  let viewport = @types.Size::new(width.to_double(), height.to_double())
  @crater.compute_layout(node, viewport)
}
