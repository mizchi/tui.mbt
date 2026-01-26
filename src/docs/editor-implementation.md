# Text Editor Implementation Guide

## Core Components

### 1. Text Buffer

A data structure to store and manipulate text efficiently.

**Requirements:**
- Fast insertion/deletion at arbitrary positions
- Efficient line-based access
- Support for large files (lazy loading)
- Track cursor position
- Track selection range

**Implementation Options:**
- **Gap Buffer**: O(1) insertion at gap, O(n) gap movement
- **Rope (Piece Table)**: O(log n) operations, good for large files
- **Array of Lines**: Simple, good for small files

```moonbit
pub struct TextBuffer {
  lines : Array[String]
  cursor_pos : (Int, Int)  // (row, col)
  selection_start : (Int, Int)?
  selection_end : (Int, Int)?
}

pub fn TextBuffer::insert_char(self : TextBuffer, ch : Char) -> TextBuffer
pub fn TextBuffer::insert_string(self : TextBuffer, s : String) -> TextBuffer
pub fn TextBuffer::delete_char(self : TextBuffer, backward : Bool) -> TextBuffer
pub fn TextBuffer::delete_line(self : TextBuffer) -> TextBuffer
```

### 2. Input Handling

Process keyboard input and translate to editor actions.

**Key Events to Handle:**
- Character input: `KeyEvent::Char(ch, mod)`
- Movement: arrows, home, end, page up/down
- Editing: backspace, delete, enter
- Selection: shift + movement
- Actions: save, quit, undo, redo

```moonbit
pub enum EditorAction {
  InsertChar(Char)
  InsertString(String)
  DeleteChar(Bool)  // backward?
  MoveCursor(CursorDirection)
  Select(SelectMode)
  Save
  Quit
  Undo
  Redo
}

fn handle_key_event(key : KeyEvent) -> EditorAction? { ... }
```

### 3. Cursor Movement

Types of cursor movement:
- **Character-level**: left/right by character
- **Word-level**: word boundaries
- **Line-level**: home, end, up/down
- **Document-level**: page up/down, top/bottom
- **Semantic**: matching bracket, function definition

```moonbit
pub enum CursorDirection {
  Left
  Right
  Up
  Down
  Home
  End
  WordLeft
  WordRight
  PageUp
  PageDown
  Top
  Bottom
}
```

### 4. Selection

Support for:
- Character selection (caret mode)
- Line selection (visual line)
- Block selection (visual block)
- Extend selection with shift key

```moonbit
pub enum SelectMode {
  Caret          // Single cursor
  VisualChar     // Character selection
  VisualLine     // Line selection
  VisualBlock    // Block selection
}

pub struct Selection {
  anchor : (Int, Int)
  cursor : (Int, Int)
  mode : SelectMode
}
```

## Advanced Features

### 5. Undo/Redo System

Track changes and allow reverting.

**Implementation:**
- Stack-based approach
- Store operations (insert, delete, cursor move)
- Group consecutive edits
- Merge operations when possible

```moonbit
pub enum EditOp {
  Insert { pos : Int, text : String }
  Delete { pos : Int, text : String }
  MoveCursor { from : (Int, Int), to : (Int, Int) }
}

pub struct UndoStack {
  undos : Array[EditOp]
  redos : Array[EditOp]
  current_group : Array[EditOp]
}
```

### 6. Search & Replace

- Linear search with regex support
- Highlight matches
- Incremental search (find-as-you-type)
- Replace all or confirm each

### 7. Clipboard Operations

- System clipboard integration (if supported)
- Internal clipboard for copy/paste within editor
- Cut operation (delete + copy)

**Terminal Limitation**: Terminal-based editors need OSC 52 escape sequences for system clipboard:

```bash
# Request clipboard content
ESC]52;c;?ESC\

# Set clipboard content
ESC]52;c;<base64_content>ESC\
```

### 8. Syntax Highlighting

- Tokenize text based on language rules
- Map tokens to color schemes
- Efficient re-highlighting on edits

**Implementation:**
- Use language grammars (e.g., tree-sitter)
- Cache token ranges
- Partial re-highlighting around edits

## File Operations

### 9. File I/O

- Read files with encoding detection
- Save with configurable encoding
- Auto-save on timer or on focus lost
- Handle large files with lazy loading

```moonbit
pub fn read_file(path : String) -> Result[TextBuffer, IOError]
pub fn save_file(buf : TextBuffer, path : String) -> Result[Unit, IOError]
pub fn auto_save(buf : TextBuffer) -> Unit
```

### 10. File Watching

Detect external file changes:
- Watch for modification time changes
- Prompt user on conflict
- Auto-reload if no local edits

## IME (Input Method Editor) Support

**Terminal Challenge**: Most terminals don't support IME. This is a major limitation for non-Latin languages.

### Terminal IME Capabilities

**Native Support:**
- **kitty**: Keyboard protocol with IME
- **WezTerm**: IME support via text input protocol
- **Alacritty**: No IME support
- **iTerm2**: Limited IME support

### IME Input Flow

```
User Input → Pre-edit Text → Conversion → Selection → Confirmation
     ↓           ↓              ↓           ↓            ↓
  Keystroke  Display with   Show       Navigate    Replace
  events     underline      candidates   candidates  text
```

### IME Protocols

#### kitty Keyboard Protocol

Request with IME support:
```bash
ESC[?u
```

IME events:
- Pre-edit start: CSI 103 ; <start> ; <end> u
- Pre-edit update: CSI 103 ; <start> ; <end> ; <text> u
- Pre-edit end: CSI 103 u
- Candidate window: CSI 103 ; <idx> ; <candidates> u

#### WezTerm IME Protocol

WezTerm uses extended keyboard protocol with IME fields.

### Implementation Strategy

```moonbit
pub struct IMEState {
  pre_edit_text : String
  cursor_offset : Int
  candidates : Array[String]
  selected_idx : Int
  active : Bool
}

pub enum IMEEvent {
  PreEditStart
  PreEditUpdate { text : String, cursor : Int }
  PreEditEnd
  CandidatesShow { items : Array[String], selected : Int }
  CandidatesSelect { idx : Int }
}

fn handle_ime_event(event : IMEEvent, buffer : TextBuffer) -> TextBuffer {
  match event {
    IMEEvent::PreEditUpdate { text, cursor } =>
      buffer.display_pre_edit(text, cursor)
    IMEEvent::PreEditEnd =>
      buffer.commit_pre_edit()
    ...
  }
}
```

### Fallback: External IME

For terminals without IME support:
1. Spawn external IME process (e.g., fcitx, ibus)
2. Send keystrokes to IME
3. Receive converted text via IPC
4. Insert into buffer

**Complexity**: High, not recommended for simple editors.

## UI Components for Editor

### Status Bar

Display:
- Current mode (normal, insert, visual)
- Cursor position (line:col)
- File name and status (modified)
- Encoding
- Language

```moonbit
pub fn render_status_bar(
  buffer : TextBuffer,
  mode : EditorMode,
  filename : String,
) -> @core.Component
```

### Line Numbers

- Display line numbers in gutter
- Sync scrolling with main buffer
- Highlight current line
- Support relative line numbers

### Minimap

- Display overview of file content
- Highlight visible area
- Click to scroll to position
- Scale down by 4-10x

### Command Palette

- Fuzzy search for commands
- Keyboard-driven
- Quick access to actions

## Performance Considerations

### Large File Handling

- **Lazy loading**: Load file in chunks
- **Virtual scrolling**: Only render visible lines
- **Incremental parsing**: Parse syntax on-demand
- **Debounced rendering**: Limit render frequency

### Rendering Optimization

- **Diff-based updates**: Only redraw changed cells
- **Double buffering**: Render off-screen first
- **Dirty tracking**: Mark lines that need redraw
- **Batch writes**: Minimize terminal I/O

## Testing Strategy

```moonbit
// Text buffer operations
test "insert character at cursor"
test "delete character backwards"
test "undo single operation"
test "redo after undo"

// Selection
test "select with shift+arrow"
test "visual line selection"
test "block selection"

// File I/O
test "read UTF-8 file"
test "save with BOM"
test "detect encoding"
```

## Resources

### Terminal Protocols
- [kitty Keyboard Protocol](https://sw.kovidgoyal.net/kitty/keyboard-protocol/)
- [XTerm Control Sequences](http://invisible-island.net/xterm/ctlseqs/ctlseqs.html)
- [WezTerm Protocol](https://wezfurlong.org/wezterm/config/lua/config/wezterm.ime.html)

### Text Editor Internals
- [Kakoune Design](https://kakoune.org/)
- [Neovim Architecture](https://neovim.io/doc/dev/internals.html)
- [Micro Editor](https://github.com/zyedidia/micro)

### IME Implementation
- [Fcitx](https://fcitx-im.org/)
- [IBus](https://github.com/ibus/ibus)
- [kitty IME Example](https://github.com/kovidgoyal/kitty/blob/master/kittens/hints/unicode_input.py)
