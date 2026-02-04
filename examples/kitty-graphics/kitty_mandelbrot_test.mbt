///|
test "mandelbrot escape behavior" {
  assert_eq(mandelbrot_escape(0.0, 0.0, 30), 30)
  let out = mandelbrot_escape(2.0, 2.0, 30)
  assert_true(out < 5)
}
