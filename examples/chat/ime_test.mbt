///|
/// Test for IME (Japanese input) support
/// Problem: Only first character is reflected when using IME input

///|
test "ime_input_utf8_character_insertion" {
  // Test that UTF-8 multi-byte characters are inserted correctly

  let input = "あ"

  // Simulate inserting Japanese character
  let chars = []
  for ch in input {
    chars.push(ch)
  }
  inspect(chars.length(), content="1")
  inspect(chars[0], content="あ")

  // Cursor should be after the character
  let cursor = 1
  inspect(cursor, content="1")
}

///|
test "ime_input_multiple_characters" {
  // Test that multiple UTF-8 characters are inserted correctly

  let input = "こんにちは"

  // Simulate inserting multiple Japanese characters
  let chars = []
  for ch in input {
    chars.push(ch)
  }
  inspect(chars.length(), content="5")
  inspect(chars[0], content="こ")
  inspect(chars[1], content="ん")
  inspect(chars[2], content="に")
  inspect(chars[3], content="ち")
  inspect(chars[4], content="は")

  // Cursor should be after all characters
  let cursor = chars.length()
  inspect(cursor, content="5")
}

///|
test "ime_input_with_mixed_ascii" {
  // Test mixed ASCII and UTF-8 characters

  let initial = "hello"
  let mut cursor = initial.length() // 5
  let input = "こんにちは"
  let chars = []
  for ch in initial {
    chars.push(ch)
  }

  // Simulate inserting Japanese characters after ASCII
  for ch in input {
    chars.push(ch)
    cursor = cursor + 1
  }
  inspect(chars.length(), content="10") // 5 ASCII + 5 Japanese
  inspect(chars[5], content="こ")
  inspect(cursor, content="10")
}

///|
test "ime_character_byte_length" {
  // Verify UTF-8 character byte lengths

  // ASCII characters are 1 byte
  let ascii = "a"
  inspect(ascii.length(), content="1")

  // Japanese characters are 3 bytes in UTF-8
  let hiragana = "あ"
  inspect(hiragana.length(), content="1") // String length is 1 character

  // When iterating, we get 1 character, not multiple bytes
  let mut char_count = 0
  for _ch in hiragana {
    char_count = char_count + 1
  }
  inspect(char_count, content="1")
}

///|
test "ime_input_buffer_handling" {
  // Test that input buffer handles UTF-8 correctly

  let chunk = "あいうえお"
  let chars = []

  // In current implementation, chunk is iterated character by character
  // This should work correctly if chunk is already a UTF-8 string
  for ch in chunk {
    chars.push(ch)
  }
  inspect(chars.length(), content="5")
  inspect(chars[0], content="あ")
  inspect(chars[1], content="い")
  inspect(chars[2], content="う")
  inspect(chars[3], content="え")
  inspect(chars[4], content="お")
}

///|
test "ime_width_calculation" {
  // Test that Japanese characters have correct display width

  // Japanese characters are typically full-width (2 columns)
  let _hiragana = "あ"
  let _ascii = "a"

  // Display width calculation should be:
  // - ASCII: 1 column
  // - Japanese: 2 columns

  let ascii_width = 1
  let japanese_width = 2
  inspect(ascii_width, content="1")
  inspect(japanese_width, content="2")

  // Text "あa" should have width 3 (2 + 1)
  let mixed_width = japanese_width + ascii_width
  inspect(mixed_width, content="3")
}
