///|
pub struct RectSprite {
  id : Int
  placement_id : Int
  x : Int
  y : Int
  w : Int
  h : Int
  vx : Int
  vy : Int
} derive(Show, Eq)

///|
pub fn rect_sprite(
  id : Int,
  placement_id : Int,
  x : Int,
  y : Int,
  w : Int,
  h : Int,
  vx : Int,
  vy : Int,
) -> RectSprite {
  RectSprite::{ id, placement_id, x, y, w, h, vx, vy }
}

///|
pub struct ImageSprite {
  id : Int
  placement_id : Int
  x : Int
  y : Int
  cols : Int
  rows : Int
  vx : Int
  vy : Int
} derive(Show, Eq)

///|
pub fn image_sprite(
  id : Int,
  placement_id : Int,
  x : Int,
  y : Int,
  cols : Int,
  rows : Int,
  vx : Int,
  vy : Int,
) -> ImageSprite {
  ImageSprite::{ id, placement_id, x, y, cols, rows, vx, vy }
}

///|
fn clamp_range(value : Int, min_value : Int, max_value : Int) -> Int {
  if value < min_value {
    min_value
  } else if value > max_value {
    max_value
  } else {
    value
  }
}

///|
fn max_pos(total : Int, size : Int) -> Int {
  let total_clamped = if total <= 0 { 0 } else { total }
  let size_clamped = if size <= 0 { 1 } else { size }
  if total_clamped <= size_clamped {
    0
  } else {
    total_clamped - size_clamped
  }
}

///|
pub fn step_rect(
  rect : RectSprite,
  max_cols : Int,
  max_rows : Int,
) -> RectSprite {
  let max_x = max_pos(max_cols, rect.w)
  let max_y = max_pos(max_rows, rect.h)
  let step_x = advance_position(rect.x, rect.vx, 0, max_x)
  let step_y = advance_position(rect.y, rect.vy, 0, max_y)
  RectSprite::{
    id: rect.id,
    placement_id: rect.placement_id,
    x: clamp_range(step_x.pos, 0, max_x),
    y: clamp_range(step_y.pos, 0, max_y),
    w: rect.w,
    h: rect.h,
    vx: step_x.vel,
    vy: step_y.vel,
  }
}

///|
pub fn step_image(
  image : ImageSprite,
  max_cols : Int,
  max_rows : Int,
) -> ImageSprite {
  let max_x = max_pos(max_cols, image.cols)
  let max_y = max_pos(max_rows, image.rows)
  let step_x = advance_position(image.x, image.vx, 0, max_x)
  let step_y = advance_position(image.y, image.vy, 0, max_y)
  ImageSprite::{
    id: image.id,
    placement_id: image.placement_id,
    x: clamp_range(step_x.pos, 0, max_x),
    y: clamp_range(step_y.pos, 0, max_y),
    cols: image.cols,
    rows: image.rows,
    vx: step_x.vel,
    vy: step_y.vel,
  }
}
