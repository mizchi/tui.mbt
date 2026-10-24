///|
/// Tests for true color (24-bit) SGR output

///|
test "ansi_fg_rgb and ansi_bg_rgb: 24-bit sequences" {
  inspect(
    @render.ansi_fg_rgb(255, 0, 0),
    content="\u{1b}[38;2;255;0;0m",
  )
  inspect(
    @render.ansi_bg_rgb(0, 128, 255),
    content="\u{1b}[48;2;0;128;255m",
  )
}

///|
test "ansi_fg_color: true color mode emits 24-bit SGR" {
  let color = @core.Color::rgb(12, 34, 56)
  inspect(
    @render.ansi_fg_color(color, color_mode=@render.ColorMode::TrueColor),
    content="\u{1b}[38;2;12;34;56m",
  )
  inspect(
    @render.ansi_bg_color(color, color_mode=@render.ColorMode::TrueColor),
    content="\u{1b}[48;2;12;34;56m",
  )
}

///|
test "ansi_fg_color: defaults to the 256-color palette" {
  let color = @core.Color::rgb(255, 0, 0)
  inspect(@render.ansi_fg_color(color), content="\u{1b}[38;5;196m")
  inspect(@render.ansi_bg_color(color), content="\u{1b}[48;5;196m")
}

///|
test "to_ansi: true color mode emits 24-bit SGR per color change" {
  let buf = @render.CharBuffer::new(2, 1)
  let style : @render.TextStyle = {
    fg: @core.Color::rgb(1, 2, 3),
    bg: @core.Color::transparent(),
    bold: false,
    underline: false,
  }
  let _ = buf.write_text(0, 0, "AB", style, 2)
  inspect(
    buf.to_ansi(color_mode=@render.ColorMode::TrueColor),
    content="\u{1b}[1;1H\u{1b}[38;2;1;2;3m\u{1b}[49mAB\u{1b}[0m",
  )
}

///|
test "to_ansi: default color mode keeps 256-color output" {
  let buf = @render.CharBuffer::new(1, 1)
  let style : @render.TextStyle = {
    fg: @core.Color::rgb(1, 2, 3),
    bg: @core.Color::transparent(),
    bold: false,
    underline: false,
  }
  let _ = buf.write_text(0, 0, "A", style, 1)
  let ansi = buf.to_ansi()
  assert_true(ansi.contains("\u{1b}[38;5;"))
  assert_false(ansi.contains("38;2;"))
}

///|
test "to_ansi_offset: true color mode keeps the offset" {
  let buf = @render.CharBuffer::new(1, 1)
  let style : @render.TextStyle = {
    fg: @core.Color::rgb(5, 6, 7),
    bg: @core.Color::transparent(),
    bold: false,
    underline: false,
  }
  let _ = buf.write_text(0, 0, "X", style, 1)
  let ansi = buf.to_ansi_offset(2, 3, color_mode=@render.ColorMode::TrueColor)
  assert_true(ansi.contains("\u{1b}[3;4H"))
  assert_true(ansi.contains("\u{1b}[38;2;5;6;7m"))
}

///|
test "diff_to_ansi: true color mode emits 24-bit SGR for changed cells" {
  let prev = @render.CharBuffer::new(2, 1)
  let current = @render.CharBuffer::new(2, 1)
  let style : @render.TextStyle = {
    fg: @core.Color::rgb(9, 8, 7),
    bg: @core.Color::transparent(),
    bold: false,
    underline: false,
  }
  let _ = current.write_text(0, 0, "A", style, 2)
  let diff = current.diff_to_ansi(prev, color_mode=@render.ColorMode::TrueColor)
  assert_true(diff.contains("\u{1b}[38;2;9;8;7m"))
  assert_false(diff.contains("38;5;"))
}

///|
test "diff_to_ansi_offset: true color mode keeps the offset" {
  let prev = @render.CharBuffer::new(1, 1)
  let current = @render.CharBuffer::new(1, 1)
  let style : @render.TextStyle = {
    fg: @core.Color::rgb(4, 4, 4),
    bg: @core.Color::transparent(),
    bold: false,
    underline: false,
  }
  let _ = current.write_text(0, 0, "Z", style, 1)
  let diff = current.diff_to_ansi_offset(
    prev,
    5,
    6,
    color_mode=@render.ColorMode::TrueColor,
  )
  assert_true(diff.contains("\u{1b}[6;7H"))
  assert_true(diff.contains("\u{1b}[38;2;4;4;4m"))
}
