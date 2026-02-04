///|
let base64_table : Array[Char] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".to_array()

///|
pub fn base64_encode(bytes : BytesView) -> String {
  let len = bytes.length()
  if len == 0 {
    return ""
  }
  let sb = StringBuilder::new(size_hint=(len + 2) / 3 * 4)
  let mut i = 0
  while i < len {
    let b0 = bytes[i].to_int()
    let b1 = if i + 1 < len { bytes[i + 1].to_int() } else { 0 }
    let b2 = if i + 2 < len { bytes[i + 2].to_int() } else { 0 }
    let triple = (b0 << 16) | (b1 << 8) | b2
    let c0 = base64_table[(triple >> 18) & 0x3f]
    let c1 = base64_table[(triple >> 12) & 0x3f]
    let c2 = base64_table[(triple >> 6) & 0x3f]
    let c3 = base64_table[triple & 0x3f]
    sb.write_char(c0)
    sb.write_char(c1)
    if i + 1 < len {
      sb.write_char(c2)
    } else {
      sb.write_char('=')
    }
    if i + 2 < len {
      sb.write_char(c3)
    } else {
      sb.write_char('=')
    }
    i = i + 3
  }
  sb.to_string()
}
