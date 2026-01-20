# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/claude-code) when working with code in this repository.

## Project Overview

MoonBit terminal UI library with reactive signals (`mizchi/tui`).

- **Language**: MoonBit
- **Target**: JavaScript (`preferred-target: js`)
- **Dependencies**: mizchi/crater (parser), mizchi/signals (reactivity), moonbitlang/async

## Common Commands

```bash
# Type check
moon check
moon check --deny-warn  # Strict mode

# Run tests
moon test
moon test -u            # Update snapshots
moon test -v            # Verbose output

# Format code
moon fmt

# Generate interface files
moon info

# Run examples
moon run examples/hello
```

## Project Structure

This is a flat package structure (all `.mbt` files in root):

```
tui.mbt/
├── moon.mod.json       # Module metadata
├── moon.pkg            # Package config
├── *.mbt               # Source files
├── *_test.mbt          # Test files
├── components/         # UI components subpackage
├── examples/           # Example applications
└── tests/              # Additional test packages
```

## MoonBit Code Guidelines

### Block Separators

Always use `///|` to separate top-level declarations:

```moonbit
///|
fn foo() -> Unit { ... }

///|
fn bar() -> Unit { ... }
```

### Common Pitfalls

- **No uppercase for variables/functions** - compilation error
- **`mut` is only for reassignment**, not field mutation
- **No `return` needed** - last expression is the return value
- **Methods require `Type::` prefix** - `fn Foo::method(self: Foo)`
- **No `++` `--`** - use `i = i + 1` or `i += 1`
- **No explicit `try` for error propagation** - automatic (unlike Swift)
- **Type parameters after `fn`** - `fn[T] identity(val: T) -> T`

### Error Handling

```moonbit
///| Use `raise` keyword for errors
fn parse(s: String) -> Int raise Error { ... }

///| Convert to Result with try?
let result: Result[Int, Error] = try? parse(s)
```

### API Discovery

Use `moon doc` before searching files:

```bash
moon doc "Type"           # Type and its methods
moon doc "@pkg"           # Package exports
moon doc "Type::*method*" # Wildcard search
```

## Testing

- Use `inspect()` for snapshot testing
- Run `moon test -u` to auto-update `content=""` values
- Black-box tests in `*_test.mbt`, white-box in `*_wbtest.mbt`

## Pre-commit Checklist

```bash
moon fmt && moon info && moon check --deny-warn && moon test
```
