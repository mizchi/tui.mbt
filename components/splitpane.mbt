///|
/// SplitPane - Split layout component for dividing screen into two sections

///|
/// Split direction
pub(all) enum SplitDirection {
  Horizontal // Top and bottom
  Vertical // Left and right
}

///|
/// Split size specification
pub(all) enum SplitSize {
  Fixed(Double) // Fixed size in characters/rows
  Percent(Double) // Percentage of total (0.0 to 1.0)
  Flex(Double) // Flex grow factor
}

///|
/// Calculate actual sizes for split pane
/// Returns (first_size, second_size)
pub fn calc_split_sizes(
  total : Int,
  first : SplitSize,
  second : SplitSize,
  divider_size? : Int = 1,
) -> (Int, Int) {
  let available = total - divider_size
  if available <= 0 {
    return (0, 0)
  }
  let avail = available.to_double()
  match (first, second) {
    // Both fixed
    (SplitSize::Fixed(f1), SplitSize::Fixed(f2)) => {
      let s1 = f1.to_int()
      let s2 = f2.to_int()
      // Clamp to available space
      if s1 + s2 <= available {
        (s1, s2)
      } else {
        // Proportionally reduce
        let ratio = avail / (f1 + f2)
        ((f1 * ratio).to_int(), (f2 * ratio).to_int())
      }
    }
    // First fixed, second fills remaining
    (SplitSize::Fixed(f1), SplitSize::Flex(_)) => {
      let s1 = f1.to_int().min(available)
      (s1, available - s1)
    }
    (SplitSize::Fixed(f1), SplitSize::Percent(p2)) => {
      let s1 = f1.to_int().min(available)
      let s2 = (avail * p2).to_int().min(available - s1)
      (s1, s2)
    }
    // Second fixed, first fills remaining
    (SplitSize::Flex(_), SplitSize::Fixed(f2)) => {
      let s2 = f2.to_int().min(available)
      (available - s2, s2)
    }
    (SplitSize::Percent(p1), SplitSize::Fixed(f2)) => {
      let s2 = f2.to_int().min(available)
      let s1 = (avail * p1).to_int().min(available - s2)
      (s1, s2)
    }
    // Both percent
    (SplitSize::Percent(p1), SplitSize::Percent(p2)) => {
      let total_pct = p1 + p2
      if total_pct > 0.0 {
        let s1 = (avail * p1 / total_pct).to_int()
        (s1, available - s1)
      } else {
        (available / 2, available - available / 2)
      }
    }
    // Both flex
    (SplitSize::Flex(g1), SplitSize::Flex(g2)) => {
      let total_grow = g1 + g2
      if total_grow > 0.0 {
        let s1 = (avail * g1 / total_grow).to_int()
        (s1, available - s1)
      } else {
        (available / 2, available - available / 2)
      }
    }
    // Percent and flex (treat flex as remaining)
    (SplitSize::Percent(p1), SplitSize::Flex(_)) => {
      let s1 = (avail * p1).to_int().min(available)
      (s1, available - s1)
    }
    (SplitSize::Flex(_), SplitSize::Percent(p2)) => {
      let s2 = (avail * p2).to_int().min(available)
      (available - s2, s2)
    }
  }
}

///|
/// Horizontal split pane (top and bottom)
pub fn hsplit(
  top : Array[@core.Component],
  bottom : Array[@core.Component],
  total_height : Int,
  top_size : SplitSize,
  bottom_size : SplitSize,
  divider? : @core.Component? = None,
  divider_size? : Int = 1,
) -> @core.Component {
  let (top_h, bottom_h) = calc_split_sizes(
    total_height,
    top_size,
    bottom_size,
    divider_size~,
  )
  let divider_component = match divider {
    Some(d) => d
    None => hdivider()
  }
  @core.box(
    [
      @core.box(top, height=@types.Dimension::Length(top_h.to_double())),
      divider_component,
      @core.box(bottom, height=@types.Dimension::Length(bottom_h.to_double())),
    ],
    flex_direction=@types.FlexDirection::Column,
    height=@types.Dimension::Length(total_height.to_double()),
  )
}

///|
/// Vertical split pane (left and right)
pub fn vsplit(
  left : Array[@core.Component],
  right : Array[@core.Component],
  total_width : Int,
  left_size : SplitSize,
  right_size : SplitSize,
  divider? : @core.Component? = None,
  divider_size? : Int = 1,
) -> @core.Component {
  let (left_w, right_w) = calc_split_sizes(
    total_width,
    left_size,
    right_size,
    divider_size~,
  )
  let divider_component = match divider {
    Some(d) => d
    None => vdivider()
  }
  @core.box(
    [
      @core.box(left, width=@types.Dimension::Length(left_w.to_double())),
      divider_component,
      @core.box(right, width=@types.Dimension::Length(right_w.to_double())),
    ],
    flex_direction=@types.FlexDirection::Row,
    width=@types.Dimension::Length(total_width.to_double()),
  )
}

///|
/// Simple horizontal split with fixed bottom height
pub fn hsplit_fixed_bottom(
  top : Array[@core.Component],
  bottom : Array[@core.Component],
  total_height : Int,
  bottom_height : Int,
  divider? : @core.Component? = None,
) -> @core.Component {
  hsplit(
    top,
    bottom,
    total_height,
    SplitSize::Flex(1.0),
    SplitSize::Fixed(bottom_height.to_double()),
    divider~,
  )
}

///|
/// Simple horizontal split with fixed top height
pub fn hsplit_fixed_top(
  top : Array[@core.Component],
  bottom : Array[@core.Component],
  total_height : Int,
  top_height : Int,
  divider? : @core.Component? = None,
) -> @core.Component {
  hsplit(
    top,
    bottom,
    total_height,
    SplitSize::Fixed(top_height.to_double()),
    SplitSize::Flex(1.0),
    divider~,
  )
}

///|
/// Simple vertical split with fixed left width
pub fn vsplit_fixed_left(
  left : Array[@core.Component],
  right : Array[@core.Component],
  total_width : Int,
  left_width : Int,
  divider? : @core.Component? = None,
) -> @core.Component {
  vsplit(
    left,
    right,
    total_width,
    SplitSize::Fixed(left_width.to_double()),
    SplitSize::Flex(1.0),
    divider~,
  )
}

///|
/// Simple vertical split with fixed right width
pub fn vsplit_fixed_right(
  left : Array[@core.Component],
  right : Array[@core.Component],
  total_width : Int,
  right_width : Int,
  divider? : @core.Component? = None,
) -> @core.Component {
  vsplit(
    left,
    right,
    total_width,
    SplitSize::Flex(1.0),
    SplitSize::Fixed(right_width.to_double()),
    divider~,
  )
}

// ============================================
// Window Splitter - Interactive resizable splitter
// ============================================

///|
/// Splitter state
pub(all) struct SplitterState {
  position : Int // percentage 0-100
  collapsed : Bool
  prev_position : Int // position before collapse
  focused : Bool
}

///|
/// Create initial splitter state
pub fn SplitterState::new(
  initial_position? : Int = 50,
  collapsed? : Bool = false,
) -> SplitterState {
  {
    position: initial_position,
    collapsed,
    prev_position: initial_position,
    focused: false,
  }
}

///|
/// Splitter orientation
pub(all) enum SplitterOrientation {
  Horizontal // Left | Right (vertical divider line)
  Vertical // Top | Bottom (horizontal divider line)
}

///|
/// Create a window splitter with draggable divider
pub fn window_splitter(
  primary : @core.Component,
  secondary : @core.Component,
  state : SplitterState,
  orientation? : SplitterOrientation = SplitterOrientation::Horizontal,
  id? : String = "",
  // Constraints
  min? : Int = 10,
  max? : Int = 90,
  // Style
  divider_fg? : @core.Color = @core.Color::white(),
  divider_bg? : @core.Color = @core.Color::rgb(60, 60, 80),
  focused_fg? : @core.Color = @core.Color::cyan(),
  focused_bg? : @core.Color = @core.Color::rgb(40, 80, 100),
  // Size (total container size)
  total_size? : Int = 80,
  divider_width? : Double = 1.0,
) -> @core.Component {
  // Calculate actual position (handle collapsed state)
  let actual_position = if state.collapsed { 0 } else { state.position }

  // Determine divider appearance
  let (div_fg, div_bg) = if state.focused {
    (focused_fg, focused_bg)
  } else {
    (divider_fg, divider_bg)
  }

  // Build divider with grab handle
  let divider_component = match orientation {
    SplitterOrientation::Horizontal => {
      // Vertical line divider with grip
      let grip = if state.focused { "┃" } else { "│" }
      let handle = column(
        [text(grip, fg=div_fg)],
        id=id + "-divider",
        width=@types.Dimension::Length(divider_width),
        height=@types.Dimension::Percent(1.0),
        bg=div_bg,
        justify=@types.Alignment::Center,
        align=@types.Alignment::Center,
      )
      handle
    }
    SplitterOrientation::Vertical => {
      // Horizontal line divider with grip
      let grip = if state.focused { "━" } else { "─" }
      let handle = row(
        [text(grip.repeat(3), fg=div_fg)],
        id=id + "-divider",
        height=@types.Dimension::Length(divider_width),
        width=@types.Dimension::Percent(1.0),
        bg=div_bg,
        justify=@types.Alignment::Center,
        align=@types.Alignment::Center,
      )
      handle
    }
  }

  // Calculate sizes based on position
  let actual_divider_width = divider_width
  let available = total_size.to_double() - actual_divider_width
  let primary_size = if state.collapsed {
    0.0
  } else {
    actual_position.clamp(min~, max~).to_double() / 100.0 * available
  }
  let secondary_size = available - primary_size
  match orientation {
    SplitterOrientation::Horizontal =>
      // Left | Right
      row(
        [
          column(
            [primary],
            width=@types.Dimension::Length(primary_size),
            height=@types.Dimension::Percent(1.0),
          ),
          divider_component,
          column(
            [secondary],
            width=@types.Dimension::Length(secondary_size),
            height=@types.Dimension::Percent(1.0),
          ),
        ],
        id~,
        width=@types.Dimension::Length(total_size.to_double()),
      )
    SplitterOrientation::Vertical =>
      // Top | Bottom
      column(
        [
          row(
            [primary],
            height=@types.Dimension::Length(primary_size),
            width=@types.Dimension::Percent(1.0),
          ),
          divider_component,
          row(
            [secondary],
            height=@types.Dimension::Length(secondary_size),
            width=@types.Dimension::Percent(1.0),
          ),
        ],
        id~,
        height=@types.Dimension::Length(total_size.to_double()),
      )
  }
}

///|
/// Interactive divider handle (standalone)
pub fn splitter_handle(
  orientation : SplitterOrientation,
  focused? : Bool = false,
  id? : String = "",
  fg? : @core.Color = @core.Color::white(),
  bg? : @core.Color = @core.Color::rgb(60, 60, 80),
  focused_fg? : @core.Color = @core.Color::cyan(),
  focused_bg? : @core.Color = @core.Color::rgb(40, 80, 100),
) -> @core.Component {
  let (actual_fg, actual_bg) = if focused {
    (focused_fg, focused_bg)
  } else {
    (fg, bg)
  }
  match orientation {
    SplitterOrientation::Horizontal => {
      let grip = if focused { "┃" } else { "│" }
      column(
        [text(grip, fg=actual_fg)],
        id~,
        width=@types.Dimension::Length(1.0),
        bg=actual_bg,
        justify=@types.Alignment::Center,
      )
    }
    SplitterOrientation::Vertical => {
      let grip = if focused { "━━━" } else { "───" }
      row(
        [text(grip, fg=actual_fg)],
        id~,
        height=@types.Dimension::Length(1.0),
        bg=actual_bg,
        justify=@types.Alignment::Center,
      )
    }
  }
}

///|
/// Resizable pane with visible position indicator
pub fn resizable_pane(
  primary : @core.Component,
  secondary : @core.Component,
  position : Int, // percentage 0-100
  orientation? : SplitterOrientation = SplitterOrientation::Horizontal,
  id? : String = "",
  focused? : Bool = false,
  show_position? : Bool = false,
  total_size? : Int = 80,
) -> @core.Component {
  let state = SplitterState::{
    position,
    collapsed: false,
    prev_position: position,
    focused,
  }
  let splitter = window_splitter(
    primary,
    secondary,
    state,
    orientation~,
    id~,
    total_size~,
  )
  if show_position {
    let indicator = text(
      " " + position.to_string() + "% ",
      fg=@core.Color::rgb(150, 150, 150),
    )
    match orientation {
      SplitterOrientation::Horizontal =>
        column([indicator, splitter], id=id + "-container")
      SplitterOrientation::Vertical =>
        row([splitter, indicator], id=id + "-container")
    }
  } else {
    splitter
  }
}
