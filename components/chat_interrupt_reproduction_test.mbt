///|
/// Streaming helpers

///|
test "split_lines_handles_newlines" {
  let lines = split_lines("a\nb\n")
  inspect(lines.length(), content="3")
  inspect(lines[0], content="a")
  inspect(lines[1], content="b")
  inspect(lines[2], content="")
}

///|
test "count_lines_counts_empty_and_multi_line" {
  inspect(count_lines(""), content="1")
  inspect(count_lines("a"), content="1")
  inspect(count_lines("a\nb"), content="2")
  inspect(count_lines("a\nb\n"), content="3")
}
