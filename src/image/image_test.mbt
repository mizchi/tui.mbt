///|
test "base64_encode bytes" {
  let bytes = Bytes::from_array([
    Int::to_byte(1),
    Int::to_byte(2),
    Int::to_byte(3),
  ])
  let view = bytes.sub()
  assert_eq(base64_encode(view), "AQID")
}

///|
test "clamp_rect keeps bounds" {
  let rect = image_rect(-5, 10, 20, 20)
  let clamped = clamp_rect(30, 25, rect)
  assert_eq(clamped, image_rect(0, 5, 20, 20))
}

///|
test "center_rect positions" {
  let rect = center_rect(100, 80, 30, 10)
  assert_eq(rect, image_rect(35, 35, 30, 10))
}
