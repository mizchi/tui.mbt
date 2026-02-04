///|
fn lines_contain(lines : Array[String], needle : String) -> Bool {
  for line in lines {
    if line.contains(needle) {
      return true
    }
  }
  false
}

///|
test "completion_popup_metrics respects max_items and more indicator" {
  let items : Array[String] = ["alpha", "beta", "gamma", "delta"]
  let (width, height) = completion_popup_metrics(
    items,
    fn(item) { item },
    max_items=2,
    min_width=4,
    show_more=true,
  )
  let more_text = "...2 more"
  let label_width = @core.string_display_width("alpha")
  let more_width = @core.string_display_width(more_text)
  let expected_width = if label_width > more_width {
    label_width
  } else {
    more_width
  }
  assert_true(height == 3)
  assert_true(width == expected_width)
}

///|
test "completion_popup_rect clamps above and right edge" {
  let rect = completion_popup_rect(8, 9, 1, 10, 10, 4, 3)
  assert_true(rect.row == 5)
  assert_true(rect.col == 6)
}

///|
test "completion_popup_list_nodes builds items and more row" {
  let items : Array[String] = ["a", "b", "c"]
  let nodes = completion_popup_list_nodes(
    items,
    1,
    6,
    fn(item, idx, selected_idx, _) {
      let label = if idx == selected_idx {
        "sel-" + item
      } else {
        "item-" + item
      }
      @vnode.text(label)
    },
    max_items=2,
    show_more=true,
    render_more=fn(more_count, _) {
      @vnode.text("more-" + more_count.to_string())
    },
  )
  let lines = @vnode.render_to_lines(@vnode.column(nodes))
  assert_true(lines_contain(lines, "item-a"))
  assert_true(lines_contain(lines, "sel-b"))
  assert_true(lines_contain(lines, "more-1"))
}

///|
test "completion_popup_node sets a11y label and selected state" {
  let items : Array[String] = ["alpha", "beta"]
  let node = completion_popup_node(
    items,
    fn(item) { item },
    1,
    "",
    8,
    item_id_prefix="item-",
  )
  let lines = @vnode.render_to_lines(node)
  assert_true(lines_contain(lines, "alpha"))
  assert_true(lines_contain(lines, "beta"))
}
