///|
test "solid_rgb emits expected bytes" {
  let bytes = solid_rgb(2, 1, 10, 20, 30)
  assert_eq(bytes.length(), 6)
  assert_eq(bytes.at(0), Int::to_byte(10))
  assert_eq(bytes.at(1), Int::to_byte(20))
  assert_eq(bytes.at(2), Int::to_byte(30))
  assert_eq(bytes.at(3), Int::to_byte(10))
}

///|
test "pattern_rgb has expected length" {
  let bytes = pattern_rgb(3, 2, 1)
  assert_eq(bytes.length(), 18)
  assert_true(bytes.at(0) != bytes.at(3))
}
