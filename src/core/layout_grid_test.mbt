///|
test "normalize_grid_rect: snaps edges and derives size from edges" {
  let rect = normalize_grid_rect(0.49, 1.49, 9.02, 2.02)
  assert_eq(rect.x, 0)
  assert_eq(rect.y, 1)
  assert_eq(rect.width, 10)
  assert_eq(rect.height, 3)
}

///|
test "normalize_grid_rect_with_inset: keeps inner rect on integer grid" {
  let rect = normalize_grid_rect_with_inset(
    0.0, 0.0, 10.0, 4.0, 1.0, 1.0, 1.0, 1.0,
  )
  assert_eq(rect.x, 1)
  assert_eq(rect.y, 1)
  assert_eq(rect.width, 8)
  assert_eq(rect.height, 2)
}

///|
test "normalize_grid_rect: nested absolute coordinates stay stable" {
  let parent_x = 10.6
  let child_local_x = 0.6
  let child = normalize_grid_rect(parent_x + child_local_x, 0.0, 3.2, 1.0)
  assert_eq(child.x, 11)
  assert_eq(child.width, 3)
}
