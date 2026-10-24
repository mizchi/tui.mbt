///|
/// True color (24-bit) rendering demo
/// Run with: moon run examples/true-color --target js
///
/// The same gradient is printed twice: once with 24-bit direct color and once
/// through the 256-color palette that the library uses by default. Lines are
/// emitted with `render_to_lines`, so both variants stay visible instead of
/// clearing each other with full-screen frames.

///|
using @vnode {type TuiNode, row, text}

///|
fn gradient_bar(
  width : Int,
  fg_channels : (Int, Int, Int) -> String,
) -> TuiNode {
  let cells : Array[TuiNode] = []
  for i = 0; i < width; i = i + 1 {
    let t = i.to_double() / (width - 1).to_double()
    let r = (255.0 * (1.0 - t)).to_int()
    let g = (128.0 * t).to_int()
    let b = (255.0 * t).to_int()
    cells.push(text("█", fg=fg_channels(r, g, b)))
  }
  row(cells)
}

///|
fn rgb_literal(r : Int, g : Int, b : Int) -> String {
  "rgb(" + r.to_string() + "," + g.to_string() + "," + b.to_string() + ")"
}

///|
fn print_block(
  title : String,
  bar : TuiNode,
  color_mode? : @render.ColorMode = @render.ColorMode::Ansi256,
) -> Unit {
  println(title)
  for line in @vnode.render_to_lines(bar, color_mode~) {
    println(line)
  }
  println("")
}

///|
/// Both blocks are fed the same `rgb(...)` input. In palette mode every color
/// is quantized to the nearest 256-color index, so the gradient survives with
/// far fewer distinct steps and shows visible banding.
fn main {
  let bar = gradient_bar(48, rgb_literal)
  print_block(
    "24-bit true color (38;2;r;g;b):",
    bar,
    color_mode=@render.ColorMode::TrueColor,
  )
  print_block("256-color palette, default (38;5;n, quantized from the same RGB input):", bar)
  let detected = @render.ColorMode::detect()
  println(
    "ColorMode::detect() on this terminal: " +
    (if detected.is_true_color() { "truecolor" } else { "256-color" }),
  )
}
