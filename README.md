# mizchi/tui

Terminal UI library for MoonBit with reactive signals integration.

## Features

- ANSI rendering with diff-based updates
- Reactive signals integration (mizchi/signals)
- Component-based architecture (box, text, input, textarea, button)
- Keyboard and mouse input handling
- Layout powered by mizchi/crater

## Installation

```json
{
  "deps": {
    "mizchi/tui": "0.1.0"
  }
}
```

## Quick Start

```moonbit
fn main {
  let count = @signals.signal(0)

  let app = @tui.App::new(80, 24)
  app.create_render_effect(
    fn() {
      @tui.box([
        @tui.text("Count: " + count.get().to_string())
      ])
    },
    fn(output) { println(output) }
  )
}
```

## Examples

- `examples/counter` - Simple counter with keyboard input
- `examples/chat` - Chat-like interface
- `examples/form` - Form with input fields
- `examples/button` - Button states and interactions
- `examples/layout` - Layout examples

Run examples:
```bash
moon run examples/counter
```

## License

MIT
