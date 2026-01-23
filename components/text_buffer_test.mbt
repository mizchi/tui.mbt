///|
/// Tests for TextBuffer

///|
test "CursorPosition::new creates position" {
  let pos = @components.CursorPosition::new(row=5, col=10)
  inspect(pos.row, content="5")
  inspect(pos.col, content="10")
}

///|
test "Selection::is_empty returns true for same position" {
  let pos = @components.CursorPosition::new(row=1, col=1)
  let sel : @components.Selection = { anchor: pos, cursor: pos }
  inspect(sel.is_empty(), content="true")
}

///|
test "Selection::is_empty returns false for different positions" {
  let anchor = @components.CursorPosition::new(row=1, col=1)
  let cursor = @components.CursorPosition::new(row=1, col=5)
  let sel : @components.Selection = { anchor, cursor }
  inspect(sel.is_empty(), content="false")
}

///|
test "TextBuffer::new creates empty buffer" {
  let buf = @components.TextBuffer::new()
  inspect(buf.lines.length(), content="1")
  inspect(buf.lines[0], content="")
  inspect(buf.cursor.row, content="1")
  inspect(buf.cursor.col, content="1")
  inspect(buf.modified, content="false")
}

///|
test "TextBuffer::from_string creates buffer from text" {
  let buf = @components.TextBuffer::from_string("hello\nworld")
  inspect(buf.lines.length(), content="2")
  inspect(buf.lines[0], content="hello")
  inspect(buf.lines[1], content="world")
}

///|
test "TextBuffer::from_file returns empty buffer (stub)" {
  let buf = @components.TextBuffer::from_file("/nonexistent")
  inspect(buf.lines.length(), content="1")
}

///|
test "TextBuffer::cursor returns current position" {
  let buf = @components.TextBuffer::new()
  let cursor = buf.cursor()
  inspect(cursor.row, content="1")
  inspect(cursor.col, content="1")
}

///|
test "TextBuffer::move_to moves cursor" {
  let buf = @components.TextBuffer::from_string("hello\nworld")
  let buf2 = buf.move_to(2, 3)
  inspect(buf2.cursor.row, content="2")
  inspect(buf2.cursor.col, content="3")
}

///|
test "TextBuffer::move_to clamps to valid range" {
  let buf = @components.TextBuffer::from_string("ab")
  // Try to move beyond line length
  let buf2 = buf.move_to(1, 100)
  inspect(buf2.cursor.col, content="3") // "ab" has length 2, max col is 3
  // Try negative row
  let buf3 = buf.move_to(-1, 1)
  inspect(buf3.cursor.row, content="1")
}

///|
test "TextBuffer::current_line returns current line text" {
  let buf = @components.TextBuffer::from_string("hello\nworld")
  inspect(buf.current_line(), content="hello")
  let buf2 = buf.move_to(2, 1)
  inspect(buf2.current_line(), content="world")
}

///|
test "TextBuffer::insert_char inserts character" {
  let buf = @components.TextBuffer::new()
  let buf2 = buf.insert_char('a')
  inspect(buf2.lines[0], content="a")
  inspect(buf2.cursor.col, content="2")
  inspect(buf2.modified, content="true")
}

///|
test "TextBuffer::insert_char inserts at cursor position" {
  let buf = @components.TextBuffer::from_string("hello")
  let buf2 = buf.move_to(1, 3)
  let buf3 = buf2.insert_char('X')
  inspect(buf3.lines[0], content="heXllo")
}

///|
test "TextBuffer::insert_string inserts multiple chars" {
  let buf = @components.TextBuffer::new()
  let buf2 = buf.insert_string("hello")
  inspect(buf2.lines[0], content="hello")
  inspect(buf2.cursor.col, content="6")
}

///|
test "TextBuffer::insert_newline splits line" {
  let buf = @components.TextBuffer::from_string("hello")
  let buf2 = buf.move_to(1, 3) // between "he" and "llo"
  let buf3 = buf2.insert_newline()
  inspect(buf3.lines.length(), content="2")
  inspect(buf3.lines[0], content="he")
  inspect(buf3.lines[1], content="llo")
  inspect(buf3.cursor.row, content="2")
  inspect(buf3.cursor.col, content="1")
}

///|
test "TextBuffer::insert_newline at end of file" {
  let buf = @components.TextBuffer::from_string("hello\nworld")
  let buf2 = buf.move_to(2, 6) // end of "world"
  let buf3 = buf2.insert_newline()
  inspect(buf3.lines.length(), content="3")
  inspect(buf3.lines[2], content="")
}

///|
test "TextBuffer::insert_newline in middle of multiline file" {
  let buf = @components.TextBuffer::from_string("a\nb\nc")
  let buf2 = buf.move_to(1, 2) // end of "a"
  let buf3 = buf2.insert_newline()
  inspect(buf3.lines.length(), content="4")
  inspect(buf3.lines[0], content="a")
  inspect(buf3.lines[1], content="")
  inspect(buf3.lines[2], content="b")
  inspect(buf3.lines[3], content="c")
}

///|
test "TextBuffer::delete_backwards at start does nothing" {
  let buf = @components.TextBuffer::new()
  let buf2 = buf.delete_backwards()
  inspect(buf2.lines[0], content="")
}

///|
test "TextBuffer::delete_backwards deletes char" {
  let buf = @components.TextBuffer::from_string("hello")
  let buf2 = buf.move_to(1, 6)
  let buf3 = buf2.delete_backwards()
  inspect(buf3.lines[0], content="hell")
  inspect(buf3.cursor.col, content="5")
}

///|
test "TextBuffer::delete_backwards merges lines" {
  let buf = @components.TextBuffer::from_string("hello\nworld")
  let buf2 = buf.move_to(2, 1) // start of "world"
  let buf3 = buf2.delete_backwards()
  inspect(buf3.lines.length(), content="1")
  inspect(buf3.lines[0], content="helloworld")
  inspect(buf3.cursor.row, content="1")
  inspect(buf3.cursor.col, content="6")
}

///|
test "TextBuffer::delete_forwards deletes char at cursor" {
  let buf = @components.TextBuffer::from_string("hello")
  let buf2 = buf.move_to(1, 1)
  let buf3 = buf2.delete_forwards()
  inspect(buf3.lines[0], content="ello")
}

///|
test "TextBuffer::delete_forwards merges lines at end" {
  let buf = @components.TextBuffer::from_string("hello\nworld")
  let buf2 = buf.move_to(1, 6) // end of "hello"
  let buf3 = buf2.delete_forwards()
  inspect(buf3.lines.length(), content="1")
  inspect(buf3.lines[0], content="helloworld")
}

///|
test "TextBuffer::delete_forwards at end of buffer does nothing" {
  let buf = @components.TextBuffer::from_string("hello")
  let buf2 = buf.move_to(1, 6)
  let buf3 = buf2.delete_forwards()
  inspect(buf3.lines[0], content="hello")
}

///|
test "TextBuffer::delete_line single line" {
  let buf = @components.TextBuffer::from_string("hello")
  let buf2 = buf.delete_line()
  inspect(buf2.lines.length(), content="1")
  inspect(buf2.lines[0], content="")
}

///|
test "TextBuffer::delete_line last line" {
  let buf = @components.TextBuffer::from_string("hello\nworld")
  let buf2 = buf.move_to(2, 1)
  let buf3 = buf2.delete_line()
  inspect(buf3.lines.length(), content="1")
  inspect(buf3.lines[0], content="hello")
}

///|
test "TextBuffer::delete_line middle line" {
  let buf = @components.TextBuffer::from_string("a\nb\nc")
  let buf2 = buf.move_to(2, 1)
  let buf3 = buf2.delete_line()
  inspect(buf3.lines.length(), content="2")
  inspect(buf3.lines[0], content="a")
  inspect(buf3.lines[1], content="c")
}

///|
test "TextBuffer::to_string converts to string" {
  let buf = @components.TextBuffer::from_string("hello\nworld")
  inspect(buf.to_string(), content="hello\nworld")
}

///|
test "TextBuffer::line_count returns number of lines" {
  let buf = @components.TextBuffer::from_string("a\nb\nc")
  inspect(buf.line_count(), content="3")
}
