///|
/// Tests for Editor component

// ============================================
// Text Buffer Tests
// ============================================

///|
test "text_buffer: create empty buffer" {
  let buffer = @components.TextBuffer::new()
  inspect(buffer.line_count(), content="1")
  inspect(buffer.cursor.row, content="1")
  inspect(buffer.cursor.col, content="1")
}

///|
test "text_buffer: create from string" {
  let text = "Hello\nWorld"
  let buffer = @components.TextBuffer::from_string(text)
  inspect(buffer.line_count(), content="2")
  inspect(buffer.lines[0], content="Hello")
  inspect(buffer.lines[1], content="World")
}

///|
test "text_buffer: insert character" {
  let buffer = @components.TextBuffer::new()
  let result = buffer.insert_char('A')
  inspect(result.lines[0], content="A")
  inspect(result.cursor.col, content="2")
}

///|
test "text_buffer: insert string" {
  let buffer = @components.TextBuffer::new()
  let result = buffer.insert_string("Hello")
  inspect(result.lines[0], content="Hello")
  inspect(result.cursor.col, content="6")
}

///|
test "text_buffer: insert newline" {
  let buffer = @components.TextBuffer::new().insert_string("Hello")
  let result = buffer.insert_newline()
  inspect(result.line_count(), content="2")
  inspect(result.lines[0], content="Hello")
  inspect(result.lines[1], content="")
  inspect(result.cursor.row, content="2")
  inspect(result.cursor.col, content="1")
}

///|
test "text_buffer: delete backwards" {
  let buffer = @components.TextBuffer::new().insert_string("Hello")
  let result = buffer.delete_backwards()
  inspect(result.lines[0], content="Hell")
  inspect(result.cursor.col, content="4")
}

///|
test "text_buffer: delete forwards" {
  let buffer = @components.TextBuffer::new()
    .insert_string("Hi")
    .move_to(1, 1)
  let result = buffer.delete_forwards()
  inspect(result.lines[0], content="i")
}

///|
test "text_buffer: delete newline" {
  let buffer = @components.TextBuffer::new()
    .insert_string("Hello")
    .insert_newline()
    .move_to(1, 6)
  let result = buffer.delete_backwards()
  inspect(result.line_count(), content="1")
  inspect(result.lines[0], content="Hello")
}

///|
test "text_buffer: move cursor" {
  let buffer = @components.TextBuffer::new().insert_string("Hello")
  let result = buffer.move_to(1, 3)
  inspect(result.cursor.row, content="1")
  inspect(result.cursor.col, content="3")
}

///|
test "text_buffer: to_string" {
  let buffer = @components.TextBuffer::from_string("Line1\nLine2\nLine3")
  let text = buffer.to_string()
  inspect(text, content="Line1\nLine2\nLine3")
}

// ============================================
// Undo Stack Tests
// ============================================

///|
test "undo_stack: create empty" {
  let stack = @components.UndoStack::new()
  inspect(stack.can_undo(), content="false")
  inspect(stack.can_redo(), content="false")
}

///|
test "undo_stack: push and begin group" {
  let stack = @components.UndoStack::new()
  let result = stack.begin_group()
  assert_eq(result.current_group.length(), 0)
}

///|
test "undo_stack: push operation" {
  let stack = @components.UndoStack::new()
  let op = @components.EditOp::Insert {
    pos: @components.CursorPosition::new(row=1, col=1),
    text: "A",
  }
  let result = stack.push(op)
  assert_eq(result.current_group.length(), 1)
}

///|
test "undo_stack: end group" {
  let stack = @components.UndoStack::new()
    .begin_group()
    .push(@components.EditOp::Insert {
      pos: @components.CursorPosition::new(row=1, col=1),
      text: "A",
    })
  let result = stack.end_group()
  assert_eq(result.undos.length(), 1)
  inspect(result.can_undo(), content="true")
}

// ============================================
// Editor Component Tests
// ============================================

///|
test "editor: create empty state" {
  let state = @components.EditorState::new()
  inspect(state.filename, content="untitled")
  inspect(state.modified, content="false")
  inspect(state.buffer.line_count(), content="1")
}

///|
test "editor: render simple editor" {
  let state = @components.EditorState::new()
  let buffer = state.buffer.insert_string("Hello World")
  let editor_state = @components.EditorState::{ buffer, ..state }
  let component = @components.simple_editor(buffer, id="editor")
  let output = @render.render_once(80, 20, component)
  inspect(output.contains("Hello World"), content="true")
}
