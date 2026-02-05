///|
test "TreeNode leaf creation" {
  let node : @logics.TreeNode[String] = @logics.TreeNode::leaf(
    "1",
    "hello",
    data="world",
  )
  assert_eq(node.id, "1")
  assert_eq(node.label, "hello")
  assert_true(node.is_leaf())
  assert_eq(node.data, Some("world"))
}

///|
test "TreeNode branch creation" {
  let tree : @logics.TreeNode[Int] = @logics.TreeNode::branch("root", "Root", [
    @logics.TreeNode::leaf("a", "A"),
    @logics.TreeNode::leaf("b", "B"),
  ])
  assert_eq(tree.id, "root")
  assert_false(tree.is_leaf())
  assert_eq(tree.children.length(), 2)
}

///|
test "TreeNode flatten collapsed" {
  let tree : @logics.TreeNode[Int] = @logics.TreeNode::branch("root", "Root", [
    @logics.TreeNode::leaf("a", "A"),
    @logics.TreeNode::leaf("b", "B"),
  ])
  let flat = tree.flatten([])
  // Only root should be visible when collapsed
  assert_eq(flat.length(), 1)
  assert_eq(flat[0].0, 0)
  assert_eq(flat[0].1.id, "root")
}

///|
test "TreeNode flatten expanded" {
  let tree : @logics.TreeNode[Int] = @logics.TreeNode::branch("root", "Root", [
    @logics.TreeNode::leaf("a", "A"),
    @logics.TreeNode::leaf("b", "B"),
  ])
  let flat = tree.flatten(["root"])
  assert_eq(flat.length(), 3)
  assert_eq(flat[0].0, 0)
  assert_eq(flat[0].1.id, "root")
  assert_eq(flat[1].0, 1)
  assert_eq(flat[1].1.id, "a")
  assert_eq(flat[2].0, 1)
  assert_eq(flat[2].1.id, "b")
}

///|
test "TreeNode flatten nested" {
  let tree : @logics.TreeNode[Int] = @logics.TreeNode::branch("root", "Root", [
    @logics.TreeNode::branch("sub", "Sub", [
      @logics.TreeNode::leaf("leaf", "Leaf"),
    ]),
  ])
  // Expand root but not sub
  let flat1 = tree.flatten(["root"])
  assert_eq(flat1.length(), 2)
  // Expand both
  let flat2 = tree.flatten(["root", "sub"])
  assert_eq(flat2.length(), 3)
  assert_eq(flat2[2].0, 2)
  assert_eq(flat2[2].1.id, "leaf")
}

///|
test "TreeNode find" {
  let tree : @logics.TreeNode[Int] = @logics.TreeNode::branch("root", "Root", [
    @logics.TreeNode::branch("sub", "Sub", [
      @logics.TreeNode::leaf("leaf", "Leaf"),
    ]),
  ])
  assert_eq(tree.find("leaf").unwrap().label, "Leaf")
  assert_eq(tree.find("root").unwrap().label, "Root")
  assert_true(tree.find("nonexistent") is None)
}

///|
test "TreeNode ancestors" {
  let tree : @logics.TreeNode[Int] = @logics.TreeNode::branch("root", "Root", [
    @logics.TreeNode::branch("sub", "Sub", [
      @logics.TreeNode::leaf("leaf", "Leaf"),
    ]),
  ])
  let path = tree.ancestors("leaf")
  assert_eq(path, Some(["root", "sub"]))
  let root_path = tree.ancestors("root")
  assert_eq(root_path, Some([]))
}

///|
test "flatten_forest" {
  let roots : Array[@logics.TreeNode[Int]] = [
    @logics.TreeNode::branch("r1", "Root1", [@logics.TreeNode::leaf("a", "A")]),
    @logics.TreeNode::leaf("r2", "Root2"),
  ]
  let flat = @logics.flatten_forest(roots, ["r1"])
  assert_eq(flat.length(), 3)
  assert_eq(flat[0].1.id, "r1")
  assert_eq(flat[1].1.id, "a")
  assert_eq(flat[2].1.id, "r2")
}
