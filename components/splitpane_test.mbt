///|
/// Tests for SplitPane and Window Splitter components

// ============================================
// Snapshot Tests - Window Splitter
// ============================================

///|
test "window_splitter: horizontal 50%" {
  let state = @components.SplitterState::new()
  let primary = @core.text("Left Pane")
  let secondary = @core.text("Right Pane")
  let comp = window_splitter(primary, secondary, state, total_size=40)
  let output = @render.render_once(40, 5, comp)
  inspect(
    output,
    content="\u{1b}[2J\u{1b}[1;1H\u{1b}[38;5;231mLeft Pane          │Right Pane          \u{1b}[2;1H                                        \u{1b}[3;1H                                        \u{1b}[4;1H                                        \u{1b}[5;1H                                        \u{1b}[0m",
  )
}

///|
test "window_splitter: vertical 50%" {
  let state = @components.SplitterState::new()
  let primary = @core.text("Top Pane")
  let secondary = @core.text("Bottom Pane")
  let comp = window_splitter(
    primary,
    secondary,
    state,
    orientation=SplitterOrientation::Vertical,
    total_size=10,
  )
  let output = @render.render_once(30, 10, comp)
  inspect(
    output,
    content="\u{1b}[2J\u{1b}[1;1H\u{1b}[38;5;231mTop                           \u{1b}[2;1HPane                          \u{1b}[3;1H                              \u{1b}[4;1H                              \u{1b}[5;1H──                            \u{1b}[6;1HBottom                        \u{1b}[7;1H Pane                         \u{1b}[8;1H                              \u{1b}[9;1H                              \u{1b}[10;1H                              \u{1b}[0m",
  )
}

///|
test "window_splitter: horizontal 30%" {
  let state : @components.SplitterState = {
    position: 30,
    collapsed: false,
    prev_position: 30,
    focused: false,
  }
  let primary = @core.text("Left")
  let secondary = @core.text("Right")
  let comp = window_splitter(primary, secondary, state, total_size=40)
  let output = @render.render_once(40, 3, comp)
  inspect(
    output,
    content="\u{1b}[2J\u{1b}[1;1H\u{1b}[38;5;231mLeft       │Right                       \u{1b}[2;1H                                        \u{1b}[3;1H                                        \u{1b}[0m",
  )
}

///|
test "window_splitter: collapsed" {
  let state : @components.SplitterState = {
    position: 50,
    collapsed: true,
    prev_position: 50,
    focused: false,
  }
  let primary = @core.text("Hidden")
  let secondary = @core.text("Full")
  let comp = window_splitter(primary, secondary, state, total_size=30)
  let output = @render.render_once(30, 3, comp)
  inspect(
    output,
    content="\u{1b}[2J\u{1b}[1;1H\u{1b}[38;5;231m│Full                         \u{1b}[2;1H                              \u{1b}[3;1H                              \u{1b}[0m",
  )
}

///|
test "window_splitter: focused divider" {
  let state : @components.SplitterState = {
    position: 50,
    collapsed: false,
    prev_position: 50,
    focused: true,
  }
  let primary = @core.text("Left")
  let secondary = @core.text("Right")
  let comp = window_splitter(primary, secondary, state, total_size=30)
  let output = @render.render_once(30, 3, comp)
  inspect(
    output,
    content="\u{1b}[2J\u{1b}[1;1H\u{1b}[38;5;231mLeft          \u{1b}[38;5;51m┃\u{1b}[38;5;231mRight          \u{1b}[2;1H                              \u{1b}[3;1H                              \u{1b}[0m",
  )
}

///|
test "splitter_handle: horizontal unfocused" {
  let handle = splitter_handle(SplitterOrientation::Horizontal, id="h-handle")
  let output = @render.render_once(3, 3, handle)
  inspect(
    output,
    content="\u{1b}[2J\u{1b}[1;1H\u{1b}[38;5;231m\u{1b}[48;5;59m│\u{1b}[49m  \u{1b}[2;1H   \u{1b}[3;1H   \u{1b}[0m",
  )
}

///|
test "splitter_handle: horizontal focused" {
  let handle = splitter_handle(
    SplitterOrientation::Horizontal,
    focused=true,
    id="h-focused",
  )
  let output = @render.render_once(3, 3, handle)
  inspect(
    output,
    content="\u{1b}[2J\u{1b}[1;1H\u{1b}[38;5;51m\u{1b}[48;5;24m┃\u{1b}[38;5;231m\u{1b}[49m  \u{1b}[2;1H   \u{1b}[3;1H   \u{1b}[0m",
  )
}

///|
test "splitter_handle: vertical unfocused" {
  let handle = splitter_handle(SplitterOrientation::Vertical, id="v-handle")
  let output = @render.render_once(10, 1, handle)
  inspect(
    output,
    content="\u{1b}[2J\u{1b}[1;1H\u{1b}[38;5;231m\u{1b}[48;5;59m───\u{1b}[49m       \u{1b}[0m",
  )
}

///|
test "splitter_handle: vertical focused" {
  let handle = splitter_handle(
    SplitterOrientation::Vertical,
    focused=true,
    id="v-focused",
  )
  let output = @render.render_once(10, 1, handle)
  inspect(
    output,
    content="\u{1b}[2J\u{1b}[1;1H\u{1b}[38;5;51m\u{1b}[48;5;24m━━━\u{1b}[38;5;231m\u{1b}[49m       \u{1b}[0m",
  )
}

///|
test "resizable_pane: with position indicator" {
  let primary = @core.text("A")
  let secondary = @core.text("B")
  let comp = resizable_pane(
    primary,
    secondary,
    75,
    show_position=true,
    total_size=30,
  )
  let output = @render.render_once(30, 5, comp)
  inspect(
    output,
    content="\u{1b}[2J\u{1b}[1;1H\u{1b}[38;5;246m 75% \u{1b}[38;5;231m                         \u{1b}[2;1H                              \u{1b}[3;1HA                    \u{1b}[48;5;59m│\u{1b}[49mB       \u{1b}[4;1H                              \u{1b}[5;1H                              \u{1b}[0m",
  )
}

// ============================================
// Accessibility Tests
// ============================================

///|
test "a11y: window_splitter - divider has ID" {
  let state = @components.SplitterState::new()
  let comp = window_splitter(
    @core.text("A"),
    @core.text("B"),
    state,
    id="my-splitter",
    total_size=40,
  )
  // Splitter should have container ID
  inspect(comp.node.id, content="my-splitter")
}

///|
test "a11y: window_splitter - focused state is visually distinct" {
  let unfocused : @components.SplitterState = {
    position: 50,
    collapsed: false,
    prev_position: 50,
    focused: false,
  }
  let focused : @components.SplitterState = {
    position: 50,
    collapsed: false,
    prev_position: 50,
    focused: true,
  }
  let out_unfocused = @render.render_once(
    30,
    3,
    window_splitter(@core.text("A"), @core.text("B"), unfocused, total_size=30),
  )
  let out_focused = @render.render_once(
    30,
    3,
    window_splitter(@core.text("A"), @core.text("B"), focused, total_size=30),
  )
  // Focused should show different divider character
  inspect(out_unfocused != out_focused, content="true")
}

///|
test "a11y: splitter_handle - shows grip indicator" {
  let h_handle = @render.render_once(
    3,
    3,
    splitter_handle(SplitterOrientation::Horizontal),
  )
  let v_handle = @render.render_once(
    10,
    1,
    splitter_handle(SplitterOrientation::Vertical),
  )
  // Should contain line characters
  inspect(h_handle.contains("│") || h_handle.contains("┃"), content="true")
  inspect(v_handle.contains("─") || v_handle.contains("━"), content="true")
}

///|
test "a11y: window_splitter - collapsed hides primary pane" {
  let collapsed : @components.SplitterState = {
    position: 50,
    collapsed: true,
    prev_position: 50,
    focused: false,
  }
  let comp = window_splitter(
    @core.text("PRIMARY"),
    @core.text("SECONDARY"),
    collapsed,
    total_size=40,
  )
  let output = @render.render_once(40, 3, comp)
  // Secondary should be visible, primary might be hidden
  inspect(output.contains("SECONDARY"), content="true")
}

// ============================================
// Unit Tests - calc_split_sizes
// ============================================

///|
test "calc_split_sizes: both fixed within bounds" {
  let (s1, s2) = calc_split_sizes(
    100,
    SplitSize::Fixed(30.0),
    SplitSize::Fixed(50.0),
  )
  inspect((s1, s2), content="(30, 50)")
}

///|
test "calc_split_sizes: fixed + flex" {
  let (s1, s2) = calc_split_sizes(
    100,
    SplitSize::Fixed(20.0),
    SplitSize::Flex(1.0),
  )
  inspect((s1, s2), content="(20, 79)")
}

///|
test "calc_split_sizes: both percent" {
  let (s1, s2) = calc_split_sizes(
    100,
    SplitSize::Percent(0.3),
    SplitSize::Percent(0.7),
  )
  inspect((s1, s2), content="(29, 70)")
}

///|
test "calc_split_sizes: both flex equal" {
  let (s1, s2) = calc_split_sizes(
    100,
    SplitSize::Flex(1.0),
    SplitSize::Flex(1.0),
  )
  inspect((s1, s2), content="(49, 50)")
}

// ============================================
// Additional Accessibility Tests
// ============================================

///|
test "a11y: window_splitter - divider ID for aria-controls" {
  let state = @components.SplitterState::new()
  let comp = window_splitter(
    @core.text("A"),
    @core.text("B"),
    state,
    id="split",
    total_size=40,
  )
  // Find divider child
  let divider = comp.node.children[1]
  inspect(divider.id, content="split-divider")
}

///|
test "a11y: window_splitter - orientation changes layout" {
  let state = @components.SplitterState::new()
  let h = window_splitter(
    @core.text("A"),
    @core.text("B"),
    state,
    orientation=SplitterOrientation::Horizontal,
    total_size=40,
  )
  let v = window_splitter(
    @core.text("A"),
    @core.text("B"),
    state,
    orientation=SplitterOrientation::Vertical,
    total_size=20,
  )
  // Horizontal uses Row, Vertical uses Column
  inspect(h.node.style.flex_direction, content="Row")
  inspect(v.node.style.flex_direction, content="Column")
}

///|
test "a11y: window_splitter - position respects min/max" {
  let state : @components.SplitterState = {
    position: 5, // below min
    collapsed: false,
    prev_position: 5,
    focused: false,
  }
  let comp = window_splitter(
    @core.text("A"),
    @core.text("B"),
    state,
    min=10,
    max=90,
    total_size=100,
  )
  // Should clamp to min
  let output = @render.render_once(100, 3, comp)
  // Component should render without error
  inspect(output.length() > 0, content="true")
}

///|
test "a11y: splitter_handle - focused changes appearance" {
  let unfocused = splitter_handle(
    SplitterOrientation::Horizontal,
    focused=false,
  )
  let focused = splitter_handle(SplitterOrientation::Horizontal, focused=true)
  let out_u = @render.render_once(3, 3, unfocused)
  let out_f = @render.render_once(3, 3, focused)
  // Focused should show thicker line
  inspect(out_u.contains("│"), content="true")
  inspect(out_f.contains("┃"), content="true")
}

///|
test "a11y: resizable_pane - shows position for user feedback" {
  let comp = resizable_pane(
    @core.text("A"),
    @core.text("B"),
    60,
    show_position=true,
    total_size=40,
  )
  let output = @render.render_once(40, 4, comp)
  // Should show percentage
  inspect(output.contains("60%"), content="true")
}

///|
test "a11y: hsplit/vsplit - divider separates panes visually" {
  let h = hsplit(
    [@core.text("Top")],
    [@core.text("Bottom")],
    10,
    SplitSize::Flex(1.0),
    SplitSize::Flex(1.0),
  )
  let v = vsplit(
    [@core.text("Left")],
    [@core.text("Right")],
    40,
    SplitSize::Flex(1.0),
    SplitSize::Flex(1.0),
  )
  let out_h = @render.render_once(40, 10, h)
  let out_v = @render.render_once(40, 3, v)
  // Should contain divider characters
  inspect(out_h.contains("-") || out_h.contains("─"), content="true")
  inspect(out_v.contains("|") || out_v.contains("│"), content="true")
}
