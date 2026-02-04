///|
/// Advance a selection index with wraparound.
pub fn advance_index(index : Int, total : Int, delta : Int) -> Int {
  if total <= 0 {
    0
  } else {
    let mut next = index + delta
    while next < 0 {
      next = next + total
    }
    while next >= total {
      next = next - total
    }
    next
  }
}
