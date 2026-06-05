name = "mizchi/tui"

version = "0.9.4"

import {
  "mizchi/layout@0.1.2",
  "mizchi/signals@0.6.3",
  "mizchi/tui-terminal-buffer@0.1.0",
  "moonbitlang/async@0.17.1",
  "mizchi/syntree@0.2.3",
  "moonbitlang/x@0.4.40",
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
