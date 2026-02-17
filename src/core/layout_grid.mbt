///|
/// Integer-grid normalization helpers for terminal layout coordinates.
/// Converts floating-point layout output into stable monospace cell rects.

///|
pub struct GridRect {
  x : Int
  y : Int
  width : Int
  height : Int
} derive(Eq, Show)

///|
/// Snap a floating-point coordinate to the nearest terminal cell.
pub fn snap_to_grid(value : Double) -> Int {
  if value >= 0.0 {
    (value + 0.5).to_int()
  } else {
    (value - 0.5).to_int()
  }
}

///|
/// Normalize a rectangle by snapping both start and end edges.
/// Width/height are derived from snapped edges to keep geometry consistent.
pub fn normalize_grid_rect(
  abs_x : Double,
  abs_y : Double,
  width : Double,
  height : Double,
) -> GridRect {
  let left = snap_to_grid(abs_x)
  let top = snap_to_grid(abs_y)
  let right = snap_to_grid(abs_x + width)
  let bottom = snap_to_grid(abs_y + height)
  {
    x: left,
    y: top,
    width: if right > left { right - left } else { 0 },
    height: if bottom > top { bottom - top } else { 0 },
  }
}

///|
/// Normalize an inner rectangle by applying insets before edge snapping.
pub fn normalize_grid_rect_with_inset(
  abs_x : Double,
  abs_y : Double,
  width : Double,
  height : Double,
  inset_left : Double,
  inset_top : Double,
  inset_right : Double,
  inset_bottom : Double,
) -> GridRect {
  let left = snap_to_grid(abs_x + inset_left)
  let top = snap_to_grid(abs_y + inset_top)
  let right = snap_to_grid(abs_x + width - inset_right)
  let bottom = snap_to_grid(abs_y + height - inset_bottom)
  {
    x: left,
    y: top,
    width: if right > left { right - left } else { 0 },
    height: if bottom > top { bottom - top } else { 0 },
  }
}
