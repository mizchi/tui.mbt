///|
pub(all) struct MotionStep {
  pos : Int
  vel : Int
} derive(Show, Eq)

///|
/// Advance a position by velocity with boundary bounce.
pub fn advance_position(
  pos : Int,
  vel : Int,
  min_pos : Int,
  max_pos : Int,
) -> MotionStep {
  let next = pos + vel
  if next < min_pos {
    MotionStep::{ pos: min_pos, vel: -vel }
  } else if next > max_pos {
    MotionStep::{ pos: max_pos, vel: -vel }
  } else {
    MotionStep::{ pos: next, vel }
  }
}
