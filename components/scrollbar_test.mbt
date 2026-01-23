///|
/// Tests for scrollbar component

///|
test "build_scrollbar: no scroll needed" {
  let result = build_scrollbar(0, 5, 10, 5)
  // When total <= visible, all lines are track
  inspect(result.length(), content="5")
  inspect(result[0], content="│")
  inspect(result[4], content="│")
}

///|
test "build_scrollbar: at top" {
  let result = build_scrollbar(0, 20, 5, 10)
  // thumb should be at top
  inspect(result.length(), content="10")
  // Thumb height = 10 * 5 / 20 = 2
  // Thumb position at offset=0 should be 0
  inspect(result[0], content="┃") // thumb
  inspect(result[1], content="┃") // thumb
  inspect(result[2], content="│") // track
  inspect(result[9], content="│") // track
}

///|
test "build_scrollbar: at bottom" {
  let result = build_scrollbar(15, 20, 5, 10)
  // max_offset = 20 - 5 = 15
  // thumb_height = 10 * 5 / 20 = 2
  // scrollable_range = 10 - 2 = 8
  // thumb_pos = 15 * 8 / 15 = 8
  inspect(result.length(), content="10")
  inspect(result[0], content="│") // track
  inspect(result[7], content="│") // track
  inspect(result[8], content="┃") // thumb
  inspect(result[9], content="┃") // thumb
}

///|
test "build_scrollbar: in middle" {
  let result = build_scrollbar(7, 20, 5, 10)
  // max_offset = 15
  // thumb_height = 2
  // scrollable_range = 8
  // thumb_pos = 7 * 8 / 15 = 3
  inspect(result.length(), content="10")
  inspect(result[2], content="│") // track
  inspect(result[3], content="┃") // thumb
  inspect(result[4], content="┃") // thumb
  inspect(result[5], content="│") // track
}

///|
test "build_scrollbar: custom characters" {
  let result = build_scrollbar(0, 10, 5, 5, track_char="░", thumb_char="█")
  inspect(result[0], content="█") // thumb
  inspect(result[2], content="░") // track
}

///|
test "build_scrollbar: minimum thumb size is 1" {
  // With 100 items and visible=1, thumb would be 0.1 lines, but minimum is 1
  let result = build_scrollbar(0, 100, 1, 10)
  inspect(result.length(), content="10")
  // Thumb should be at position 0 with size 1
  inspect(result[0], content="┃")
  inspect(result[1], content="│")
}

///|
test "build_scrollbar: full height when no scroll" {
  // When total <= visible, all lines should be track (no thumb movement)
  let result = build_scrollbar(0, 3, 5, 5)
  for i = 0; i < 5; i = i + 1 {
    inspect(result[i], content="│")
  }
}

///|
test "build_scrollbar: thumb moves proportionally" {
  // 20 items, 5 visible, height=10
  // max_offset = 15, thumb_height = 2, scrollable_range = 8

  // At offset 0: thumb_pos = 0
  let r0 = build_scrollbar(0, 20, 5, 10)
  inspect(r0[0], content="┃")
  inspect(r0[1], content="┃")
  inspect(r0[2], content="│")

  // At offset 15 (max): thumb_pos = 8
  let r15 = build_scrollbar(15, 20, 5, 10)
  inspect(r15[7], content="│")
  inspect(r15[8], content="┃")
  inspect(r15[9], content="┃")
}

///|
test "scrollbar: component builds without error" {
  // Just verify the component can be created without error
  let _component = scrollbar(0, 20, 5, 10)
  inspect(true, content="true")
}

///|
test "scrollbar: with custom colors builds without error" {
  let _component = scrollbar(
    5,
    20,
    5,
    10,
    track_color=@core.Color::rgb(30, 30, 30),
    thumb_color=@core.Color::rgb(100, 100, 100),
  )
  inspect(true, content="true")
}

///|
test "scrollbar: renders correctly in row layout" {
  // Simulate chat layout: messages column + scrollbar
  let messages = column(
    [text("Message 1"), text("Message 2"), text("Message 3")],
    width=@types.Dimension::Length(19.0),
    height=@types.Dimension::Length(5.0),
  )
  let scrollbar_comp = scrollbar(
    0,
    10,
    5,
    5,
    track_char="│",
    thumb_char="█",
  )
  let layout = row(
    [messages, scrollbar_comp],
    width=@types.Dimension::Length(20.0),
    height=@types.Dimension::Length(5.0),
  )
  let output = @render.render_once(20, 5, layout)
  println("=== scrollbar in row layout (20x5) ===")
  println(output)
  println("=== end ===")
  // Scrollbar should be on the right side
  assert_true(output.contains("█") || output.contains("│"))
}
