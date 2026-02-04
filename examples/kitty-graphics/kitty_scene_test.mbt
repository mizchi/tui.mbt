///|
test "step_rect within bounds" {
  let rect = rect_sprite(1, 10, 1, 1, 2, 2, 1, 1)
  let next = step_rect(rect, 10, 10)
  assert_eq(next, rect_sprite(1, 10, 2, 2, 2, 2, 1, 1))
}

///|
test "step_rect bounce at max with size" {
  let rect = rect_sprite(2, 20, 7, 6, 3, 4, 1, 1)
  let next = step_rect(rect, 10, 10)
  assert_eq(next, rect_sprite(2, 20, 7, 6, 3, 4, -1, -1))
}

///|
test "step_rect clamps when larger than bounds" {
  let rect = rect_sprite(3, 30, 1, 1, 5, 5, 1, 1)
  let next = step_rect(rect, 2, 2)
  assert_eq(next, rect_sprite(3, 30, 0, 0, 5, 5, -1, -1))
}

///|
test "step_image within bounds" {
  let image = image_sprite(10, 100, 2, 3, 4, 2, -1, 1)
  let next = step_image(image, 20, 10)
  assert_eq(next, image_sprite(10, 100, 1, 4, 4, 2, -1, 1))
}
