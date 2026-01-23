///|
/// Streaming helpers

///|
test "split_lines_handles_newlines" {
  let lines = @components.split_lines("a\nb\n")
  inspect(lines.length(), content="3")
  inspect(lines[0], content="a")
  inspect(lines[1], content="b")
  inspect(lines[2], content="")
}

///|
test "count_lines_counts_empty_and_multi_line" {
  inspect(@components.count_lines(""), content="1")
  inspect(@components.count_lines("a"), content="1")
  inspect(@components.count_lines("a\nb"), content="2")
  inspect(@components.count_lines("a\nb\n"), content="3")
}
