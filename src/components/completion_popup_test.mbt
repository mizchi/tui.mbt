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

///|
test "completion_popup_rect_directed Below places below anchor" {
  // viewport 20 rows, anchor at row 5, height 1, popup height 3
  // space below = 20 - 6 = 14, plenty of room
  let (rect, dir) = completion_popup_rect_directed(
    5,
    0,
    1,
    40,
    20,
    10,
    3,
    direction=PopupDirection::Below,
  )
  assert_true(rect.row == 6)
  guard dir is PopupDirection::Below
}

///|
test "completion_popup_rect_directed Above places above anchor" {
  // anchor at row 10, popup height 3 → above = 10 - 3 = 7
  let (rect, dir) = completion_popup_rect_directed(
    10,
    0,
    1,
    40,
    20,
    10,
    3,
    direction=PopupDirection::Above,
  )
  assert_true(rect.row == 7)
  guard dir is PopupDirection::Above
}

///|
test "completion_popup_rect_directed Auto prefers Below when both fit" {
  // anchor at row 5, popup height 3
  // space below = 20 - 6 = 14 (fits), space above = 5 (fits)
  let (rect, dir) = completion_popup_rect_directed(
    5,
    0,
    1,
    40,
    20,
    10,
    3,
    direction=PopupDirection::Auto,
  )
  assert_true(rect.row == 6)
  guard dir is PopupDirection::Below
}

///|
test "completion_popup_rect_directed Auto chooses Above when below doesn't fit" {
  // anchor at row 18, popup height 5
  // space below = 20 - 19 = 1 (doesn't fit), space above = 18 (fits)
  let (rect, dir) = completion_popup_rect_directed(
    18,
    0,
    1,
    40,
    20,
    10,
    5,
    direction=PopupDirection::Auto,
  )
  assert_true(rect.row == 13) // 18 - 5
  guard dir is PopupDirection::Above
}

///|
test "completion_popup_rect_directed Auto fallback picks larger space" {
  // anchor at row 3, viewport 10, popup height 8
  // space below = 10 - 4 = 6 (doesn't fit), space above = 3 (doesn't fit)
  // 6 > 3, so Below wins
  let (rect, dir) = completion_popup_rect_directed(
    3,
    0,
    1,
    40,
    10,
    10,
    8,
    direction=PopupDirection::Auto,
  )
  assert_true(rect.row == 4)
  guard dir is PopupDirection::Below
}

///|
test "completion_popup_rect_directed Auto fallback picks Above when above is larger" {
  // anchor at row 7, viewport 10, popup height 8
  // space below = 10 - 8 = 2 (doesn't fit), space above = 7 (doesn't fit)
  // 7 > 2, so Above wins
  let (rect, dir) = completion_popup_rect_directed(
    7,
    0,
    1,
    40,
    10,
    10,
    8,
    direction=PopupDirection::Auto,
  )
  // above = 7 - 8 = -1, clamped to 0
  assert_true(rect.row == 0)
  guard dir is PopupDirection::Above
}
