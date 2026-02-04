///|
pub struct MandelState {
  center_x : Double
  center_y : Double
  mut scale : Double
  mut phase : Double
} derive(Show)

///|
pub fn mandelbrot_escape(cx : Double, cy : Double, max_iter : Int) -> Int {
  let mut zr = 0.0
  let mut zi = 0.0
  let mut iter = 0
  while iter < max_iter {
    let zr2 = zr * zr - zi * zi + cx
    let zi2 = 2.0 * zr * zi + cy
    zr = zr2
    zi = zi2
    if zr * zr + zi * zi > 4.0 {
      break
    }
    iter = iter + 1
  }
  iter
}

///|
fn clamp_double(
  value : Double,
  min_value : Double,
  max_value : Double,
) -> Double {
  if value < min_value {
    min_value
  } else if value > max_value {
    max_value
  } else {
    value
  }
}

///|
fn to_color_byte(value : Double) -> Byte {
  let v = (value * 255.0).to_int()
  let clamped = if v < 0 { 0 } else if v > 255 { 255 } else { v }
  clamped.to_byte()
}

///|
fn palette(iter : Int, max_iter : Int, phase : Double) -> (Byte, Byte, Byte) {
  if iter >= max_iter {
    return (Int::to_byte(0), Int::to_byte(0), Int::to_byte(0))
  }
  let t = Double::from_int(iter) / Double::from_int(max_iter)
  let shift = 0.15 * @math.sin(phase)
  let t1 = clamp_double(t + shift, 0.0, 1.0)
  let t2 = t1 * t1
  let t3 = t2 * t1
  let one_minus = 1.0 - t1
  let r = 9.0 * one_minus * t3
  let g = 15.0 * one_minus * one_minus * t2
  let b = 8.5 * one_minus * one_minus * one_minus * t1
  (to_color_byte(r), to_color_byte(g), to_color_byte(b))
}

///|
pub fn mandelbrot_frame(
  state : MandelState,
  width : Int,
  height : Int,
  max_iter : Int,
) -> Bytes {
  let w = if width <= 1 { 1 } else { width }
  let h = if height <= 1 { 1 } else { height }
  let aspect = Double::from_int(w) / Double::from_int(h)
  let buf = @buffer.new(size_hint=w * h * 3)
  let scale = state.scale
  let center_x = state.center_x + 0.2 * scale * @math.cos(state.phase)
  let center_y = state.center_y + 0.1 * scale * @math.sin(state.phase * 0.7)
  for y in 0..<h {
    let ny = (Double::from_int(y) / Double::from_int(h) - 0.5) * 2.0
    let cy = center_y + ny * scale
    for x in 0..<w {
      let nx = (Double::from_int(x) / Double::from_int(w) - 0.5) * 2.0
      let cx = center_x + nx * scale * aspect
      let iter = mandelbrot_escape(cx, cy, max_iter)
      let (r, g, b) = palette(iter, max_iter, state.phase)
      buf.write_byte(r)
      buf.write_byte(g)
      buf.write_byte(b)
    }
  }
  buf.to_bytes()
}

///|
pub fn advance_mandel(state : MandelState) -> Unit {
  state.scale = state.scale * 0.965
  state.phase = state.phase + 0.045
  if state.scale < 0.003 {
    state.scale = 2.8
    state.phase = 0.0
  }
}
