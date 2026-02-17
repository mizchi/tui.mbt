///|
/// Overlay types for popup/modal rendering

///|
pub(all) enum PopupPosition {
  Center
  Top
  Bottom
  At(Int, Int)
}

///|
pub(all) struct OverlayEntry {
  node : TuiNode
  position : PopupPosition
  backdrop : Bool
  shrink : Bool
}
