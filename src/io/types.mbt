///|
/// Result of an input session
pub(all) enum InputResult {
  Confirmed(String)
  Cancelled
  TabNext(String) // Tab pressed - confirm and move to next
  TabPrev(String) // Shift+Tab pressed - confirm and move to previous
  ForceQuit // Ctrl+C pressed - force quit the app
}
