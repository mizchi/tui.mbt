///|
test "diff_lines empty inputs" {
  let result = @logics.diff_lines([], [])
  assert_eq(result.length(), 0)
}

///|
test "diff_lines all inserts" {
  let result = @logics.diff_lines([], ["a", "b"])
  assert_eq(result.length(), 2)
  inspect(result[0], content="+ a")
  inspect(result[1], content="+ b")
}

///|
test "diff_lines all deletes" {
  let result = @logics.diff_lines(["a", "b"], [])
  assert_eq(result.length(), 2)
  inspect(result[0], content="- a")
  inspect(result[1], content="- b")
}

///|
test "diff_lines equal lines" {
  let result = @logics.diff_lines(["a", "b", "c"], ["a", "b", "c"])
  assert_eq(result.length(), 3)
  inspect(result[0], content="  a")
  inspect(result[1], content="  b")
  inspect(result[2], content="  c")
}

///|
test "diff_lines mixed changes" {
  let old_text = ["a", "b", "c"]
  let new_text = ["a", "x", "c"]
  let result = @logics.diff_lines(old_text, new_text)
  // Should have: Equal(a), Delete(b), Insert(x), Equal(c)
  let mut has_equal_a = false
  let mut has_equal_c = false
  let mut has_delete_b = false
  let mut has_insert_x = false
  for op in result {
    match op {
      @logics.DiffOp::Equal(s) =>
        if s == "a" {
          has_equal_a = true
        } else if s == "c" {
          has_equal_c = true
        }
      @logics.DiffOp::Delete(s) => if s == "b" { has_delete_b = true }
      @logics.DiffOp::Insert(s) => if s == "x" { has_insert_x = true }
    }
  }
  assert_true(has_equal_a)
  assert_true(has_equal_c)
  assert_true(has_delete_b)
  assert_true(has_insert_x)
}

///|
test "diff_lines insertion in middle" {
  let old_text = ["a", "c"]
  let new_text = ["a", "b", "c"]
  let result = @logics.diff_lines(old_text, new_text)
  let mut has_insert_b = false
  let mut equal_count = 0
  for op in result {
    match op {
      @logics.DiffOp::Equal(_) => equal_count = equal_count + 1
      @logics.DiffOp::Insert(s) => if s == "b" { has_insert_b = true }
      _ => ()
    }
  }
  assert_true(has_insert_b)
  assert_eq(equal_count, 2)
}
