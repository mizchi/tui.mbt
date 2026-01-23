///|
test "get_current_word extracts word at cursor" {
  assert_eq(get_current_word("fun", 3), "fun")
  assert_eq(get_current_word("let x = fun", 11), "fun")
  assert_eq(get_current_word("ret", 3), "ret")
  assert_eq(get_current_word("", 0), "")
}

///|
test "find_completion returns suffix" {
  // "fun" -> "ction" (function)
  let result = find_completion("fun", 3)
  inspect(result, content="Some(\"ction\")")

  // "ret" -> "urn" (return)
  let result2 = find_completion("ret", 3)
  inspect(result2, content="Some(\"urn\")")

  // "xyz" -> None (no match)
  let result3 = find_completion("xyz", 3)
  inspect(result3, content="None")
}
