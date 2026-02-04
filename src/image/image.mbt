///|
/// Image payload format.
pub enum ImageFormat {
  Png
  Rgb
} derive(Show, Eq)

///|
/// Base64 payload image with explicit dimensions.
pub struct ImageAsset {
  width : Int
  height : Int
  format : ImageFormat
  payload_base64 : String
} derive(Show)

///|
/// Rectangle in pixels.
pub struct ImageRect {
  x : Int
  y : Int
  w : Int
  h : Int
} derive(Show, Eq)

///|
/// Construct a rectangle.
pub fn image_rect(x : Int, y : Int, w : Int, h : Int) -> ImageRect {
  ImageRect::{ x, y, w, h }
}

///|
let base64_table : Array[Char] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".to_array()

///|
fn clamp_int(value : Int, min_value : Int, max_value : Int) -> Int {
  if value < min_value {
    min_value
  } else if value > max_value {
    max_value
  } else {
    value
  }
}

///|
fn normalize_dim(value : Int) -> Int {
  if value <= 0 {
    1
  } else {
    value
  }
}

///|
/// Encode bytes into base64.
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

///|
/// Build a raw RGB image asset (payload is base64 encoded).
pub fn image_asset_rgb(
  width : Int,
  height : Int,
  bytes : BytesView,
) -> ImageAsset {
  let w = normalize_dim(width)
  let h = normalize_dim(height)
  ImageAsset::{
    width: w,
    height: h,
    format: ImageFormat::Rgb,
    payload_base64: base64_encode(bytes),
  }
}

///|
/// Build a PNG image asset (payload is base64 encoded).
pub fn image_asset_png(
  width : Int,
  height : Int,
  bytes : BytesView,
) -> ImageAsset {
  let w = normalize_dim(width)
  let h = normalize_dim(height)
  ImageAsset::{
    width: w,
    height: h,
    format: ImageFormat::Png,
    payload_base64: base64_encode(bytes),
  }
}

///|
/// Read a PNG file and return an image asset.
pub fn read_png_asset(path : String, width : Int, height : Int) -> ImageAsset? {
  try @fs.read_file_to_bytes(path) catch {
    _ => None
  } noraise {
    bytes => Some(image_asset_png(width, height, bytes))
  }
}

///|
/// Clamp a rectangle within image bounds.
pub fn clamp_rect(width : Int, height : Int, rect : ImageRect) -> ImageRect {
  let w = clamp_int(rect.w, 1, normalize_dim(width))
  let h = clamp_int(rect.h, 1, normalize_dim(height))
  let max_x = if width <= w { 0 } else { width - w }
  let max_y = if height <= h { 0 } else { height - h }
  let x = clamp_int(rect.x, 0, max_x)
  let y = clamp_int(rect.y, 0, max_y)
  ImageRect::{ x, y, w, h }
}

///|
/// Center a rectangle within image bounds.
pub fn center_rect(
  width : Int,
  height : Int,
  rect_w : Int,
  rect_h : Int,
) -> ImageRect {
  let w = clamp_int(rect_w, 1, normalize_dim(width))
  let h = clamp_int(rect_h, 1, normalize_dim(height))
  let x = if width <= w { 0 } else { (width - w) / 2 }
  let y = if height <= h { 0 } else { (height - h) / 2 }
  ImageRect::{ x, y, w, h }
}
