///|
/// Inplace edit helpers - adapt layout bounds to input sessions

///|
fn bounds_to_inplace_area(
  bounds : @events.HitTestResult,
  border : Int,
) -> (Int, Int, Int, Int) {
  let border_size = if border < 0 { 0 } else { border }
  let row = bounds.y + 1 + border_size
  let col = bounds.x + 1 + border_size
  let width = (bounds.width - border_size * 2).max(1)
  let height = (bounds.height - border_size * 2).max(1)
  (row, col, width, height)
}

///|
/// Start editing within bounds (HitTestResult) with border adjustment.
/// bounds.x/y are 0-indexed; row/col for ANSI are 1-indexed.
/// on_completion: optional callback (text, cursor_pos) -> completion_suffix for Tab completion
pub fn start_edit_inplace_in_bounds(
  config : EditConfig,
  current_value : String,
  bounds : @events.HitTestResult,
  multiline : Bool,
  on_complete : () -> Unit,
  confirm_on_shift_enter? : Bool = false,
  esc_cancels? : Bool = true,
  border? : Int = 1,
  on_lines_change? : ((Int) -> Int)? = None,
  on_completion? : ((String, Int) -> String?)? = None,
) -> Unit {
  let (row, col, width, height) = bounds_to_inplace_area(bounds, border)
  start_edit_inplace(
    config,
    current_value,
    row,
    col,
    width,
    height,
    multiline,
    on_complete,
    confirm_on_shift_enter~,
    esc_cancels~,
    on_lines_change~,
    on_completion~,
  )
}
