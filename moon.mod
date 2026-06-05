name = "mizchi/tui"

version = "0.9.4"

import {
  "mizchi/layout@0.2.0",
  "mizchi/crater-core@0.18.0",
  "mizchi/crater-layout@0.18.0",
  "mizchi/css@0.2.0",
  "mizchi/signals@0.6.4",
  "mizchi/tui-terminal-buffer@0.1.3",
  "moonbitlang/async@0.19.2",
  "mizchi/syntree@0.2.3",
  "moonbitlang/x@0.4.45",
}

readme = "README.md"

repository = "https://github.com/mizchi/tui.mbt"

license = "MIT"

keywords = [ "tui", "terminal", "ui", "cli" ]

description = "Terminal UI library for MoonBit with reactive signals"

preferred_target = "js"

options(
  source: "src",
)
