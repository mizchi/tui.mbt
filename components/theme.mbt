///|
/// Theme system for consistent, accessible color palettes
///
/// Provides Light and Dark themes with customizable accent colors.
/// Designed for good contrast ratios and Tab-focus visibility.

///|
/// Theme mode
pub(all) enum ThemeMode {
  Light
  Dark
}

///|
/// Color palette for a theme
pub(all) struct Theme {
  mode : ThemeMode
  /// Primary accent color (customizable)
  primary : @core.Color
  /// Focus indicator color (yellow for visibility)
  focus : @core.Color
  /// Foreground text color
  fg : @core.Color
  /// Muted/secondary text color
  muted : @core.Color
  /// Disabled text color
  disabled : @core.Color
  /// Background color
  bg : @core.Color
  /// Surface color (cards, panels)
  surface : @core.Color
  /// Border color
  border : @core.Color
  /// Success color
  success : @core.Color
  /// Error color
  error : @core.Color
}

///|
/// Create a dark theme with optional primary color
pub fn Theme::dark(primary? : @core.Color = @core.Color::cyan()) -> Theme {
  {
    mode: ThemeMode::Dark,
    primary,
    focus: @core.Color::yellow(),
    fg: @core.Color::white(),
    muted: @core.Color::rgb(160, 160, 160),
    disabled: @core.Color::rgb(100, 100, 100),
    bg: @core.Color::rgb(24, 24, 28),
    surface: @core.Color::rgb(40, 40, 48),
    border: @core.Color::rgb(80, 80, 96),
    success: @core.Color::rgb(80, 200, 120),
    error: @core.Color::rgb(240, 80, 80),
  }
}

///|
/// Create a light theme with optional primary color
pub fn Theme::light(
  primary? : @core.Color = @core.Color::rgb(0, 120, 180),
) -> Theme {
  {
    mode: ThemeMode::Light,
    primary,
    focus: @core.Color::rgb(200, 160, 0), // Darker yellow for light bg
    fg: @core.Color::rgb(32, 32, 32),
    muted: @core.Color::rgb(100, 100, 100),
    disabled: @core.Color::rgb(160, 160, 160),
    bg: @core.Color::rgb(250, 250, 250),
    surface: @core.Color::rgb(255, 255, 255),
    border: @core.Color::rgb(200, 200, 200),
    success: @core.Color::rgb(40, 160, 80),
    error: @core.Color::rgb(200, 60, 60),
  }
}

///|
/// Default theme (dark mode)
pub fn Theme::default() -> Theme {
  Theme::dark()
}

///|
/// Get color for focused state
pub fn Theme::focused_color(self : Theme) -> @core.Color {
  self.focus
}

///|
/// Get color for selected/active state (uses focus for visibility)
pub fn Theme::selected_color(self : Theme) -> @core.Color {
  self.focus
}

///|
/// Get color for normal interactive elements
pub fn Theme::interactive_color(self : Theme) -> @core.Color {
  self.primary
}
