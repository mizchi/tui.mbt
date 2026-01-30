///|
struct Position {
  line : Int
  col : Int
} derive(Show, Eq)

///|
struct Document {
  lines : Array[String]
}

///|
fn split_text_lines(text : String) -> Array[String] {
  let parts = text.split("\n").map(part => part.to_string()).collect()
  if parts.length() == 0 {
    [""]
  } else {
    parts
  }
}

///|
fn Document::from_text(text : String) -> Document {
  { lines: split_text_lines(text) }
}

///|
fn Document::line_count(self : Document) -> Int {
  self.lines.length()
}

///|
fn Document::line(self : Document, line : Int) -> String {
  if line >= 0 && line < self.lines.length() {
    self.lines[line]
  } else {
    ""
  }
}

///|
fn Document::line_length(self : Document, line : Int) -> Int {
  self.line(line).length()
}

///|
fn Document::to_text(self : Document) -> String {
  let sb = StringBuilder::new()
  for i, line in self.lines {
    if i > 0 {
      sb.write_char('\n')
    }
    sb.write_string(line)
  }
  sb.to_string()
}

///|
fn Document::clamp_position(self : Document, pos : Position) -> Position {
  let count = self.lines.length()
  let line = if count == 0 {
    0
  } else if pos.line < 0 {
    0
  } else if pos.line >= count {
    count - 1
  } else {
    pos.line
  }
  let max_col = if count == 0 { 0 } else { self.lines[line].length() }
  let col = if pos.col < 0 {
    0
  } else if pos.col > max_col {
    max_col
  } else {
    pos.col
  }
  { line, col }
}

///|
fn pos_before_or_equal(a : Position, b : Position) -> Bool {
  if a.line < b.line {
    true
  } else if a.line > b.line {
    false
  } else {
    a.col <= b.col
  }
}

///|
fn order_positions(a : Position, b : Position) -> (Position, Position) {
  if pos_before_or_equal(a, b) {
    (a, b)
  } else {
    (b, a)
  }
}

///|
fn Document::insert_text(
  self : Document,
  pos : Position,
  text : String,
) -> Position {
  let pos = self.clamp_position(pos)
  if text.length() == 0 {
    return pos
  }
  let parts = split_text_lines(text)
  let line_text = self.lines[pos.line]
  let prefix = line_text.unsafe_substring(start=0, end=pos.col)
  let suffix = line_text.unsafe_substring(start=pos.col, end=line_text.length())
  if parts.length() == 1 {
    self.lines[pos.line] = prefix + parts[0] + suffix
    { line: pos.line, col: pos.col + parts[0].length() }
  } else {
    let first = prefix + parts[0]
    let last = parts[parts.length() - 1] + suffix
    self.lines[pos.line] = first
    let mut insert_at = pos.line + 1
    for i in 1..<(parts.length() - 1) {
      self.lines.insert(insert_at, parts[i])
      insert_at = insert_at + 1
    }
    self.lines.insert(insert_at, last)
    {
      line: pos.line + parts.length() - 1,
      col: parts[parts.length() - 1].length(),
    }
  }
}

///|
fn Document::delete_range(
  self : Document,
  start : Position,
  end : Position,
) -> Position {
  let (start, end) = order_positions(
    self.clamp_position(start),
    self.clamp_position(end),
  )
  if start == end {
    return start
  }
  if start.line == end.line {
    let line_text = self.lines[start.line]
    let prefix = line_text.unsafe_substring(start=0, end=start.col)
    let suffix = line_text.unsafe_substring(
      start=end.col,
      end=line_text.length(),
    )
    self.lines[start.line] = prefix + suffix
    start
  } else {
    let first_line = self.lines[start.line]
    let last_line = self.lines[end.line]
    let prefix = first_line.unsafe_substring(start=0, end=start.col)
    let suffix = last_line.unsafe_substring(
      start=end.col,
      end=last_line.length(),
    )
    self.lines[start.line] = prefix + suffix
    let remove_count = end.line - start.line
    for _ in 0..<remove_count {
      let _ = self.lines.remove(start.line + 1)

    }
    start
  }
}

///|
fn Document::delete_backward(self : Document, pos : Position) -> Position {
  let pos = self.clamp_position(pos)
  if pos.line == 0 && pos.col == 0 {
    return pos
  }
  if pos.col > 0 {
    self.delete_range({ line: pos.line, col: pos.col - 1 }, pos)
  } else {
    let prev_len = self.lines[pos.line - 1].length()
    self.delete_range({ line: pos.line - 1, col: prev_len }, pos)
  }
}

///|
fn Document::delete_forward(self : Document, pos : Position) -> Position {
  let pos = self.clamp_position(pos)
  let line_len = self.lines[pos.line].length()
  if pos.line == self.lines.length() - 1 && pos.col == line_len {
    return pos
  }
  if pos.col < line_len {
    self.delete_range(pos, { line: pos.line, col: pos.col + 1 })
  } else {
    self.delete_range(pos, { line: pos.line + 1, col: 0 })
  }
}
