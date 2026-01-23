///|
/// Type aliases and helpers for layout dimensions and alignment
/// These provide a cleaner API without exposing crater's internal types

///|
// Dimension helpers - avoid @types.Dimension::Length(...) verbosity

///|
/// Create a fixed-length dimension in characters/pixels
pub fn dim_length(value : Double) -> @types.Dimension {
  @types.Dimension::Length(value)
}

///|
/// Create a percentage-based dimension (0.0 to 100.0)
/// Converts user-friendly percentage (e.g., 100.0 = 100%) to crater's normalized form (1.0 = 100%)
pub fn dim_percent(value : Double) -> @types.Dimension {
  @types.Dimension::Percent(value / 100.0)
}

///|
/// Auto dimension - size based on content
pub fn dim_auto() -> @types.Dimension {
  @types.Dimension::Auto
}

///|
// Alignment helpers - avoid @types.Alignment::Center verbosity

///|
/// Align items to the start of the container
pub fn align_start() -> @types.Alignment {
  @types.Alignment::FlexStart
}

///|
/// Align items to the end of the container
pub fn align_end() -> @types.Alignment {
  @types.Alignment::FlexEnd
}

///|
/// Center items in the container
pub fn align_center() -> @types.Alignment {
  @types.Alignment::Center
}

///|
/// Distribute items with equal space between them
pub fn align_space_between() -> @types.Alignment {
  @types.Alignment::SpaceBetween
}

///|
/// Distribute items with equal space around them
pub fn align_space_around() -> @types.Alignment {
  @types.Alignment::SpaceAround
}

///|
/// Distribute items with equal space (including edges)
pub fn align_space_evenly() -> @types.Alignment {
  @types.Alignment::SpaceEvenly
}

///|
/// Stretch items to fill the container
pub fn align_stretch() -> @types.Alignment {
  @types.Alignment::Stretch
}
