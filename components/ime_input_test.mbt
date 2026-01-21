///|
/// IME view rendering with multibyte characters

///|
test "ime_input_renders_multibyte_character" {
  let comp = ime_input("あ", true, id="ime-wide")
  inspect(comp.texts.get("ime-wide"), content="Some(\"あ_\")")
}

///|
test "ime_textarea_renders_multiline_unicode" {
  let comp = ime_textarea("あ\nい", true, rows=2)
  let output = @render.render_once(20, 4, comp)
  assert_true(output.contains("あ"))
  assert_true(output.contains("い_"))
}
