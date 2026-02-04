///|
let kitty_prefix : String = "\u001b_G"

///|
let kitty_suffix : String = "\u001b\\"

///|
/// Crop rectangle in pixels.
pub(all) struct CropRect {
  x : Int
  y : Int
  w : Int
  h : Int
} derive(Show, Eq)

///|
pub fn kitty_command(params : Array[String], payload? : String = "") -> String {
  let head = params.join(",")
  kitty_prefix + head + ";" + payload + kitty_suffix
}

///|
pub fn split_payload(
  payload : String,
  chunk_size? : Int = 4096,
) -> Array[String] {
  let size = if chunk_size <= 0 { payload.length() } else { chunk_size }
  let len = payload.length()
  if len == 0 {
    return [""]
  }
  let out : Array[String] = []
  for i = 0; i < len; {
    let end = if i + size < len { i + size } else { len }
    out.push(payload.unsafe_substring(start=i, end~))
    continue end
  }
  out
}

///|
/// Build PNG transmit commands (base64 payload).
/// Subsequent chunks only include m (and q) per kitty protocol.
pub fn kitty_transmit_png(
  id : Int,
  payload : String,
  chunk_size? : Int = 4096,
) -> Array[String] {
  let chunks = split_payload(payload, chunk_size~)
  let total = chunks.length()
  if total == 0 {
    return []
  }
  let out : Array[String] = []
  for i in 0..<total {
    let more = if i + 1 < total { 1 } else { 0 }
    let params = if i == 0 {
      ["a=t", "f=100", "i=\{id}", "m=\{more}", "q=1"]
    } else {
      ["m=\{more}", "q=1"]
    }
    out.push(kitty_command(params, payload=chunks[i]))
  }
  out
}

///|
/// Build raw RGB transmit commands (base64 payload).
/// `width`/`height` are pixel dimensions, `f=24` for RGB.
pub fn kitty_transmit_rgb(
  id : Int,
  width : Int,
  height : Int,
  payload : String,
  chunk_size? : Int = 4096,
) -> Array[String] {
  let chunks = split_payload(payload, chunk_size~)
  let total = chunks.length()
  if total == 0 {
    return []
  }
  let out : Array[String] = []
  for i in 0..<total {
    let more = if i + 1 < total { 1 } else { 0 }
    let params = if i == 0 {
      [
        "a=t",
        "f=24",
        "s=\{width}",
        "v=\{height}",
        "i=\{id}",
        "m=\{more}",
        "q=1",
      ]
    } else {
      ["m=\{more}", "q=1"]
    }
    out.push(kitty_command(params, payload=chunks[i]))
  }
  out
}

///|
/// Place an image at the current cursor position.
/// Uses C=1 to avoid moving the cursor after placement.
pub fn kitty_place(
  id~ : Int,
  placement_id~ : Int,
  crop? : CropRect,
  cols? : Int,
  rows? : Int,
) -> String {
  let params = ["a=p", "i=\{id}", "p=\{placement_id}", "C=1"]
  match crop {
    Some(rect) => {
      params.push("x=\{rect.x}")
      params.push("y=\{rect.y}")
      params.push("w=\{rect.w}")
      params.push("h=\{rect.h}")
    }
    None => ()
  }
  match cols {
    Some(cols) => params.push("c=\{cols}")
    None => ()
  }
  match rows {
    Some(rows) => params.push("r=\{rows}")
    None => ()
  }
  params.push("q=1")
  kitty_command(params)
}

///|
/// Delete image data (and all placements).
pub fn kitty_delete_image_data(id : Int) -> String {
  kitty_command(["a=d", "d=I", "i=\{id}", "q=1"])
}

///|
/// Delete all visible image placements.
pub fn kitty_delete_all_visible() -> String {
  kitty_command(["a=d", "q=1"])
}
