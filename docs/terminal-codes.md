# Terminal Control Codes

## ANSI Escape Sequences

Terminal control codes use ANSI escape sequences starting with ESC (`\u001b` or `\033`) followed by `[` and parameters.

### Basic Format

```
ESC[<parameters><final_char>
```

- `ESC`: `\u001b` (escape character)
- `<parameters>`: Semicolon-separated numbers
- `<final_char>`: Character that terminates the sequence

### Text Styling

| Sequence | Effect |
|----------|--------|
| `\u001b[0m` | Reset all attributes |
| `\u001b[1m` | Bold/bright |
| `\u001b[4m` | Underline |
| `\u001b[7m` | Reverse video |

### Cursor Movement

| Sequence | Effect |
|----------|--------|
| `\u001b[H` | Move cursor to home (1,1) |
| `\u001b[<row>;<col>H` | Move cursor to row, column |
| `\u001b[<n>A` | Move cursor up n lines |
| `\u001b[<n>B` | Move cursor down n lines |
| `\u001b[<n>C` | Move cursor right n chars |
| `\u001b[<n>D` | Move cursor left n chars |

### Screen Control

| Sequence | Effect |
|----------|--------|
| `\u001b[2J` | Clear entire screen |
| `\u001b[2K` | Clear entire line |
| `\u001b[?25l` | Hide cursor |
| `\u001b[?25h` | Show cursor |

### Alternative Screen Buffer

| Sequence | Effect |
|----------|--------|
| `\u001b[?1049h` | Enter alternate screen |
| `\u001b[?1049l` | Leave alternate screen |

**Use Case**: TUI applications should use alternate screen to preserve previous terminal content.

## Colors

### 16 Standard Colors (SGR)

Foreground: `\u001b[3<n>m` where n = 0-7 (black to white)
Background: `\u001b[4<n>m` where n = 0-7

Bright variants: `\u001b[9<n>m` / `\u001b[10<n>m` for n = 0-7

### 256-Color Palette

Foreground: `\u001b[38;5;<n>m`
Background: `\u001b[48;5;<n>m`

Where `<n>` is 0-255:
- **0-7**: Standard colors
- **8-15**: High-intensity colors
- **16-231**: 6×6×6 RGB cube (16 + r×36 + g×6 + b)
- **232-255**: Grayscale ramp

**RGB to 256 conversion**:
```
if r == g == b (grayscale):
  if r < 8: return 16
  if r > 248: return 231
  return 232 + (r - 8) × 24 / 240
else:
  r6 = r × 6 / 255
  g6 = g × 6 / 255
  b6 = b × 6 / 255
  return 16 + r6×36 + g6×6 + b6
```

### True Color (24-bit)

Foreground: `\u001b[38;2;<r>;<g>;<b>m`
Background: `\u001b[48;2;<r>;<g>;<b>m`

Where r, g, b are 0-255.

## Mouse Support

### Enable/Disable Mouse Tracking

| Sequence | Effect |
|----------|--------|
| `\u001b[?1000h` | Enable X11 mouse tracking |
| `\u001b[?1000l` | Disable X11 mouse tracking |
| `\u001b[?1006h` | Enable SGR mouse tracking |
| `\u001b[?1006l` | Disable SGR mouse tracking |

**Note**: SGR format is preferred for compatibility.

### Mouse Event Formats

**X10 Format** (limited, no drag support):
```
ESC[M<cb><cx><cy>
```

**SGR Format** (recommended, supports drag):
```
ESC[<Pb>;<Px>;<Py>M  (press)
ESC[<Pb>;<Px>;<Py>m  (release)
```

Where:
- `Pb`: Button code (bit mask)
  - 0-3: Left, Middle, Right, Release
  - bit 4: Motion (drag)
  - bit 6: Scroll wheel
  - bit 7: Reserved (often 1)
- `Px`, `Py`: X, Y coordinates (1-indexed)

## Special Keys

Control keys are sent as single byte codes:

| Key | Code | Key | Code |
|-----|------|-----|------|
| Enter | `\r` or `\n` | Tab | `\t` |
| Escape | `\u001b` | Backspace | `\u007f` |
| Ctrl+C | `\u0003` | Ctrl+D | `\u0004` |

### CSI Sequences for Special Keys

Arrows and navigation keys use CSI sequences starting with `ESC[`:

| Key | Sequence |
|-----|----------|
| Up | `ESC[A` |
| Down | `ESC[B` |
| Right | `ESC[C` |
| Left | `ESC[D` |
| Home | `ESC[H` |
| End | `ESC[F` |
| Page Up | `ESC[5~` |
| Page Down | `ESC[6~` |
| Delete | `ESC[3~` |
| Insert | `ESC[2~` |
| F1-F4 | `ESC[OP`..`ESC[OS` |
| F5-F12 | `ESC[15~`..`ESC[24~` |

## Implementation Notes

### Character Codes in MoonBit

- Escape: `\u001b`
- Backspace: `\u007f`
- Enter: `\r` (carriage return, 13)
- Tab: `\t` (tab, 9)

### Performance Tips

1. **Minimize state changes**: Track last state and only send sequences when changed
2. **Use differential updates**: Only redraw changed cells
3. **Batch cursor movements**: Move to position, then output multiple characters
4. **Reset sparingly**: Only reset when necessary (e.g., style changes)

### Common Pitfalls

1. **Coordinate systems**: Terminal coordinates are typically 1-indexed
2. **Line endings**: Use `\r\n` for proper newline handling
3. **Buffer flushing**: Flush output buffer after sending sequences
4. **State leakage**: Always reset styles at end of output to prevent bleeding
5. **Alt screen cleanup**: Restore original screen on exit

## References

- [ANSI Escape Sequences](https://en.wikipedia.org/wiki/ANSI_escape_code)
- [XTerm Control Sequences](http://invisible-island.net/xterm/ctlseqs/ctlseqs.html)
- [VT100 Reference](https://vt100.net/docs/vt100-ug/chapter3.html)
