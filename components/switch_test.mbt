///|
/// Tests for Switch component

// ============================================
// Snapshot Tests
// ============================================

///|
test "switch: on state" {
  let comp = switch(true)
  let output = @render.render_once(10, 1, comp)
  inspect(
    output,
    content="\u{1b}[2J\u{1b}[1;1H\u{1b}[38;5;78m━━●\u{1b}[38;5;231m       \u{1b}[0m",
  )
}

///|
test "switch: off state" {
  let comp = switch(false)
  let output = @render.render_once(10, 1, comp)
  inspect(
    output,
    content="\u{1b}[2J\u{1b}[1;1H\u{1b}[38;5;247m○━━\u{1b}[38;5;231m       \u{1b}[0m",
  )
}

///|
test "switch: disabled state" {
  let on_disabled = switch(true, disabled=true)
  let off_disabled = switch(false, disabled=true)
  let out_on = @render.render_once(10, 1, on_disabled)
  let out_off = @render.render_once(10, 1, off_disabled)
  inspect(
    out_on,
    content="\u{1b}[2J\u{1b}[1;1H\u{1b}[38;5;241m━━●\u{1b}[38;5;231m       \u{1b}[0m",
  )
  inspect(
    out_off,
    content="\u{1b}[2J\u{1b}[1;1H\u{1b}[38;5;241m○━━\u{1b}[38;5;231m       \u{1b}[0m",
  )
}

///|
test "labeled_switch: label on left" {
  let comp = labeled_switch(
    "Dark Mode",
    true,
    label_position=LabelPosition::Left,
  )
  let output = @render.render_once(25, 1, comp)
  inspect(
    output,
    content="\u{1b}[2J\u{1b}[1;1H\u{1b}[38;5;231mDark Mode \u{1b}[38;5;78m━━●\u{1b}[38;5;231m            \u{1b}[0m",
  )
}

///|
test "labeled_switch: label on right" {
  let comp = labeled_switch(
    "Notifications",
    false,
    label_position=LabelPosition::Right,
  )
  let output = @render.render_once(25, 1, comp)
  inspect(
    output,
    content="\u{1b}[2J\u{1b}[1;1H\u{1b}[38;5;247m○━━\u{1b}[38;5;231m  Notifications       \u{1b}[0m",
  )
}

///|
test "checkbox: checked" {
  let comp = checkbox(true)
  let output = @render.render_once(5, 1, comp)
  inspect(
    output,
    content="\u{1b}[2J\u{1b}[1;1H\u{1b}[38;5;78m[✓]\u{1b}[38;5;231m  \u{1b}[0m",
  )
}

///|
test "checkbox: unchecked" {
  let comp = checkbox(false)
  let output = @render.render_once(5, 1, comp)
  inspect(output, content="\u{1b}[2J\u{1b}[1;1H\u{1b}[38;5;231m[ ]  \u{1b}[0m")
}

///|
test "labeled_checkbox: label on right" {
  let comp = labeled_checkbox("Accept terms", true)
  let output = @render.render_once(20, 1, comp)
  inspect(
    output,
    content="\u{1b}[2J\u{1b}[1;1H\u{1b}[38;5;78m[✓]\u{1b}[38;5;231m Accept terms    \u{1b}[0m",
  )
}

///|
test "labeled_checkbox: label on left" {
  let comp = labeled_checkbox(
    "Enable",
    false,
    label_position=LabelPosition::Left,
  )
  let output = @render.render_once(15, 1, comp)
  inspect(
    output,
    content="\u{1b}[2J\u{1b}[1;1H\u{1b}[38;5;231mEnable [ ]     \u{1b}[0m",
  )
}

// ============================================
// Accessibility Tests
// ============================================

///|
test "a11y: switch - has focusable ID" {
  let sw = switch(true, id="theme-switch")
  inspect(sw.node.id, content="theme-switch")
}

///|
test "a11y: switch - on/off states are visually distinct" {
  let on_out = @render.render_once(10, 1, switch(true))
  let off_out = @render.render_once(10, 1, switch(false))
  // ON state has ● indicator, OFF state has ○ indicator
  inspect(on_out.contains("━━●"), content="true")
  inspect(off_out.contains("○━━"), content="true")
}

///|
test "a11y: labeled_switch - label provides context" {
  let comp = labeled_switch("Auto-save", true)
  let output = @render.render_once(20, 1, comp)
  inspect(output.contains("Auto-save"), content="true")
}

///|
test "a11y: checkbox - checked state visually indicated" {
  let checked = @render.render_once(5, 1, checkbox(true))
  let unchecked = @render.render_once(5, 1, checkbox(false))
  inspect(checked.contains("✓"), content="true")
  inspect(unchecked.contains("✓"), content="false")
}

///|
test "a11y: labeled_checkbox - combines label with state" {
  let comp = labeled_checkbox("Remember me", true)
  let output = @render.render_once(20, 1, comp)
  inspect(output.contains("Remember me"), content="true")
  inspect(output.contains("✓"), content="true")
}

///|
test "a11y: switch - disabled state is visually distinct" {
  let enabled = switch(true)
  let disabled = switch(true, disabled=true)
  let out_enabled = @render.render_once(10, 1, enabled)
  let out_disabled = @render.render_once(10, 1, disabled)
  // Disabled should look different from enabled
  inspect(out_enabled != out_disabled, content="true")
}

///|
test "a11y: labeled_switch - label position options" {
  let left = labeled_switch("Left", true, label_position=LabelPosition::Left)
  let right = labeled_switch("Right", true, label_position=LabelPosition::Right)
  let out_left = @render.render_once(20, 1, left)
  let out_right = @render.render_once(20, 1, right)
  // Both should contain their labels
  inspect(out_left.contains("Left"), content="true")
  inspect(out_right.contains("Right"), content="true")
}

///|
test "a11y: checkbox - binary state (no third state)" {
  let checked = checkbox(true)
  let unchecked = checkbox(false)
  let out_c = @render.render_once(5, 1, checked)
  let out_u = @render.render_once(5, 1, unchecked)
  // Checked should have checkmark
  inspect(out_c.contains("✓"), content="true")
  // Unchecked should have empty brackets
  inspect(out_u.contains("[ ]"), content="true")
}

///|
test "a11y: labeled_checkbox - label position options" {
  let left = labeled_checkbox("L", true, label_position=LabelPosition::Left)
  let right = labeled_checkbox("R", true, label_position=LabelPosition::Right)
  let out_left = @render.render_once(15, 1, left)
  let out_right = @render.render_once(15, 1, right)
  // Both should contain labels and checkmarks
  inspect(out_left.contains("L"), content="true")
  inspect(out_right.contains("R"), content="true")
  inspect(out_left.contains("✓"), content="true")
  inspect(out_right.contains("✓"), content="true")
}

///|
test "a11y: switch - has track indicator for current state" {
  let on = switch(true)
  let off = switch(false)
  let out_on = @render.render_once(10, 1, on)
  let out_off = @render.render_once(10, 1, off)
  // Should contain track characters
  inspect(out_on.contains("━") || out_on.contains("●"), content="true")
  inspect(out_off.contains("━") || out_off.contains("○"), content="true")
}
