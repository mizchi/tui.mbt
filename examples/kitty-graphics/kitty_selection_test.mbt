///|
test "advance_index wraps forward" {
  assert_eq(advance_index(4, 5, 1), 0)
}

///|
test "advance_index wraps backward" {
  assert_eq(advance_index(0, 5, -1), 4)
}

///|
test "advance_index large delta" {
  assert_eq(advance_index(2, 5, 3), 0)
  assert_eq(advance_index(2, 5, -3), 4)
}
