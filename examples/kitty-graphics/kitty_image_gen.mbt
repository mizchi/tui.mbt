///|
fn clamp_byte(value : Int) -> Byte {
  let v = if value < 0 { 0 } else if value > 255 { 255 } else { value }
  v.to_byte()
}

///|
pub fn solid_rgb(width : Int, height : Int, r : Int, g : Int, b : Int) -> Bytes {
  let w = if width <= 0 { 1 } else { width }
  let h = if height <= 0 { 1 } else { height }
  let buf = @buffer.new(size_hint=w * h * 3)
  let rb = clamp_byte(r)
  let gb = clamp_byte(g)
  let bb = clamp_byte(b)
  for _y in 0..<h {
    for _x in 0..<w {
      buf.write_byte(rb)
      buf.write_byte(gb)
      buf.write_byte(bb)
    }
  }
  buf.to_bytes()
}

///|
pub fn pattern_rgb(width : Int, height : Int, seed : Int) -> Bytes {
  let w = if width <= 0 { 1 } else { width }
  let h = if height <= 0 { 1 } else { height }
  let buf = @buffer.new(size_hint=w * h * 3)
  let seed_base = if seed < 0 { -seed } else { seed }
  for y in 0..<h {
    let yv = y * 23 + seed_base * 13
    for x in 0..<w {
      let xv = x * 19 + seed_base * 31
      let r = (xv + y * 7) % 256
      let g = (yv + x * 11) % 256
      let b = (x + y) * 9 + seed_base * 17
      buf.write_byte(clamp_byte(r))
      buf.write_byte(clamp_byte(g))
      buf.write_byte(clamp_byte(b))
    }
  }
  buf.to_bytes()
}
