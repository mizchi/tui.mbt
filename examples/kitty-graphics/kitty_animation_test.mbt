///|
test "advance_position within bounds" {
  let step = advance_position(5, 1, 1, 10)
  assert_eq(step, MotionStep::{ pos: 6, vel: 1 })
}

///|
test "advance_position bounce at min" {
  let step = advance_position(1, -1, 1, 10)
  assert_eq(step, MotionStep::{ pos: 1, vel: 1 })
}

///|
test "advance_position bounce at max" {
  let step = advance_position(10, 1, 1, 10)
  assert_eq(step, MotionStep::{ pos: 10, vel: -1 })
}
