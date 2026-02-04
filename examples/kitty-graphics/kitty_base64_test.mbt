///|
test "base64 encode samples" {
  assert_eq(base64_encode(@utf8.encode("")), "")
  assert_eq(base64_encode(@utf8.encode("M")), "TQ==")
  assert_eq(base64_encode(@utf8.encode("Ma")), "TWE=")
  assert_eq(base64_encode(@utf8.encode("Man")), "TWFu")
}
