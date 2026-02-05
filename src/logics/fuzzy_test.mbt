///|
test "fuzzy_match empty pattern matches everything" {
  let result = @logics.fuzzy_match("", "hello")
  guard result is Some(m) else { fail("expected Some") }
  assert_eq(m.score, 0)
  assert_eq(m.positions.length(), 0)
}

///|
test "fuzzy_match empty target returns None" {
  let result = @logics.fuzzy_match("a", "")
  assert_true(result is None)
}

///|
test "fuzzy_match exact match" {
  let result = @logics.fuzzy_match("abc", "abc")
  guard result is Some(m) else { fail("expected Some") }
  assert_eq(m.positions, [0, 1, 2])
}

///|
test "fuzzy_match case insensitive" {
  let result = @logics.fuzzy_match("abc", "ABC")
  guard result is Some(m) else { fail("expected Some") }
  assert_eq(m.positions, [0, 1, 2])
}

///|
test "fuzzy_match scattered characters" {
  let result = @logics.fuzzy_match("fb", "foobar")
  guard result is Some(m) else { fail("expected Some") }
  assert_eq(m.positions.length(), 2)
  assert_eq(m.positions[0], 0)
  assert_eq(m.positions[1], 3)
}

///|
test "fuzzy_match no match returns None" {
  let result = @logics.fuzzy_match("xyz", "abc")
  assert_true(result is None)
}

///|
test "fuzzy_match word boundary bonus" {
  let result = @logics.fuzzy_match("fb", "foo_bar")
  guard result is Some(m) else { fail("expected Some") }
  assert_eq(m.positions[0], 0)
  assert_eq(m.positions[1], 4)
}

///|
test "fuzzy_sort returns sorted results" {
  let items = ["foobar", "fb", "xfb", "baz"]
  let results = @logics.fuzzy_sort("fb", items)
  assert_true(results.length() >= 2)
  for result in results {
    assert_true(result.1.positions.length() == 2)
  }
  if results.length() >= 2 {
    assert_true(results[0].1.score >= results[1].1.score)
  }
}

///|
test "fuzzy_sort empty pattern returns all items" {
  let items = ["a", "b", "c"]
  let results = @logics.fuzzy_sort("", items)
  assert_eq(results.length(), 3)
}

///|
test "fuzzy_visible_rows always returns max_show rows" {
  let max_show = 8
  // total < max_show: pad with empty
  let r3 = @logics.fuzzy_visible_rows(3, max_show)
  assert_eq(r3.show, 3)
  assert_eq(r3.rows(), max_show)
  // total == max_show: exact fit
  let r8 = @logics.fuzzy_visible_rows(8, max_show)
  assert_eq(r8.show, 8)
  assert_eq(r8.rows(), max_show)
  // total > max_show: show fewer items + "more" row
  let r13 = @logics.fuzzy_visible_rows(13, max_show)
  assert_true(r13.has_more)
  assert_eq(r13.show, max_show - 1)
  assert_eq(r13.rows(), max_show)
  // total == max_show + 1: still constant
  let r9 = @logics.fuzzy_visible_rows(9, max_show)
  assert_true(r9.has_more)
  assert_eq(r9.rows(), max_show)
  // total == 0
  let r0 = @logics.fuzzy_visible_rows(0, max_show)
  assert_eq(r0.show, 0)
  assert_eq(r0.rows(), max_show)
}
