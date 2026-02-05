///|
/// Tree data structure for hierarchical views

///|
/// A node in a tree structure
pub(all) struct TreeNode[T] {
  id : String
  label : String
  children : Array[TreeNode[T]]
  data : T?
}

///|
/// Create a leaf node (no children)
pub fn[T] TreeNode::leaf(id : String, label : String, data? : T) -> TreeNode[T] {
  { id, label, children: [], data }
}

///|
/// Create a branch node (with children)
pub fn[T] TreeNode::branch(
  id : String,
  label : String,
  children : Array[TreeNode[T]],
) -> TreeNode[T] {
  { id, label, children, data: None }
}

///|
/// Check if node is a leaf
pub fn[T] TreeNode::is_leaf(self : TreeNode[T]) -> Bool {
  self.children.length() == 0
}

///|
/// Flatten tree into a list of (depth, node) pairs,
/// only expanding nodes whose ids are in expanded_ids.
pub fn[T] TreeNode::flatten(
  self : TreeNode[T],
  expanded_ids : Array[String],
) -> Array[(Int, TreeNode[T])] {
  let result : Array[(Int, TreeNode[T])] = []
  fn walk(node : TreeNode[T], depth : Int) {
    result.push((depth, node))
    if node.children.length() > 0 && expanded_ids.contains(node.id) {
      for child in node.children {
        walk(child, depth + 1)
      }
    }
  }

  walk(self, 0)
  result
}

///|
/// Flatten multiple root nodes
pub fn[T] flatten_forest(
  roots : Array[TreeNode[T]],
  expanded_ids : Array[String],
) -> Array[(Int, TreeNode[T])] {
  let result : Array[(Int, TreeNode[T])] = []
  for root in roots {
    let items = root.flatten(expanded_ids)
    for item in items {
      result.push(item)
    }
  }
  result
}

///|
/// Find a node by id in the tree
pub fn[T] TreeNode::find(self : TreeNode[T], id : String) -> TreeNode[T]? {
  if self.id == id {
    return Some(self)
  }
  for child in self.children {
    match child.find(id) {
      Some(found) => return Some(found)
      None => ()
    }
  }
  None
}

///|
/// Collect all ancestor ids for a given node id
pub fn[T] TreeNode::ancestors(
  self : TreeNode[T],
  target_id : String,
) -> Array[String]? {
  if self.id == target_id {
    return Some([])
  }
  for child in self.children {
    match child.ancestors(target_id) {
      Some(path) => {
        let result = [self.id]
        for p in path {
          result.push(p)
        }
        return Some(result)
      }
      None => ()
    }
  }
  None
}
