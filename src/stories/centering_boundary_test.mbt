///|
/// Boundary tests for center alignment under floating-point layout values.

///|
fn abs_int(a : Int, b : Int) -> Int {
  if a >= b {
    a - b
  } else {
    b - a
  }
}

///|
fn assert_center_balance(
  container_x : Int,
  container_y : Int,
  container_width : Int,
  container_height : Int,
  child_x : Int,
  child_y : Int,
  child_width : Int,
  child_height : Int,
) -> Unit raise {
  let left = child_x - container_x
  let right = container_width - left - child_width
  let top = child_y - container_y
  let bottom = container_height - top - child_height
  assert_true(abs_int(left, right) <= 1)
  assert_true(abs_int(top, bottom) <= 1)
}

///|
fn split_lines(s : String) -> Array[String] {
  s.split("\n").map(part => part.to_string()).collect()
}

///|
fn leading_spaces(s : String) -> Int {
  let chars = s.to_array()
  let mut i = 0
  while i < chars.length() && chars[i] == ' ' {
    i = i + 1
  }
  i
}

///|
fn content_width(s : String) -> Int {
  let chars = s.to_array()
  let mut start = 0
  while start < chars.length() && chars[start] == ' ' {
    start = start + 1
  }
  if start >= chars.length() {
    return 0
  }
  let mut end = chars.length() - 1
  while end > start && chars[end] == ' ' {
    end = end - 1
  }
  end - start + 1
}

///|
fn find_top_border_line(lines : Array[String]) -> String? {
  for line in lines {
    if line.contains("╭") || line.contains("┌") {
      return Some(line)
    }
  }
  None
}

///|
test "center alignment: odd/even integer boundaries stay balanced" {
  for width = 9; width <= 23; width = width + 1 {
    for height = 3; height <= 9; height = height + 1 {
      for label_len = 1; label_len <= 9; label_len = label_len + 1 {
        let app = @vnode.VNodeApp::new(width, height)
        let label = "X".repeat(label_len)
        let node = @vnode.column(
          id="root",
          width=width.to_double(),
          height=height.to_double(),
          justify="center",
          align="center",
          [@vnode.row(id="child", [@vnode.text(label)])],
        )
        let _ = app.render(node)
        match app.find_by_id("root") {
          Some(root) =>
            match app.find_by_id("child") {
              Some(child) =>
                assert_center_balance(
                  root.x,
                  root.y,
                  root.width,
                  root.height,
                  child.x,
                  child.y,
                  child.width,
                  child.height,
                )
              None => assert_true(false)
            }
          None => assert_true(false)
        }
      }
    }
  }
}

///|
test "center alignment: fractional width containers stay balanced" {
  let widths = [15.5, 16.5, 17.5, 18.5, 19.5, 20.5, 21.5]
  for frac_width in widths {
    for label_len = 1; label_len <= 10; label_len = label_len + 1 {
      let app = @vnode.VNodeApp::new(40, 9)
      let node = @vnode.column(
        id="root",
        width=frac_width,
        height=7.5,
        justify="center",
        align="center",
        [@vnode.row(id="child", [@vnode.text("Y".repeat(label_len))])],
      )
      let _ = app.render(node)
        match app.find_by_id("root") {
          Some(root) =>
            match app.find_by_id("child") {
              Some(child) =>
                assert_center_balance(
                  root.x,
                  root.y,
                  root.width,
                  root.height,
                  child.x,
                  child.y,
                  child.width,
                  child.height,
                )
              None => assert_true(false)
            }
        None => assert_true(false)
      }
    }
  }
}

///|
test "center alignment: repeated renders keep the same centered position" {
  let app = @vnode.VNodeApp::new(37, 11)
  let node = @vnode.column(
    id="root",
    width=37.0,
    height=11.0,
    justify="center",
    align="center",
    [
      @vnode.row([@vnode.text("header")]),
      @vnode.row(id="child", [@vnode.text("CENTERED")]),
      @vnode.row([@vnode.text("footer")]),
    ],
  )
  let mut last_x = -1
  let mut last_y = -1
  for i = 0; i < 30; i = i + 1 {
    let _ = app.render(node)
    match app.find_by_id("child") {
      Some(child) => {
        if i > 0 {
          assert_eq(child.x, last_x)
          assert_eq(child.y, last_y)
        }
        last_x = child.x
        last_y = child.y
      }
      None => assert_true(false)
    }
  }
}

///|
test "overlay center: boundary widths follow deterministic snap rule" {
  let labels = ["A", "AB", "ABC", "ABCD", "ABCDE", "ABCDEF", "ABCDEFG"]
  for viewport_w = 18; viewport_w <= 32; viewport_w = viewport_w + 1 {
    for label in labels {
      let main = @vnode.column(width=viewport_w.to_double(), height=7.0, [])
      let overlay = @components.popup(
        @vnode.column(border="rounded", padding=1.0, [@vnode.text(label)]),
        backdrop=false,
        position=@vnode.PopupPosition::Center,
        shrink=true,
      )
      let plain = render_overlay_plain(viewport_w, 7, main, [overlay])
      let lines = split_lines(plain)
      match find_top_border_line(lines) {
        Some(top_line) => {
          let left = leading_spaces(top_line)
          let popup_w = content_width(top_line)
          // Overlay centering in VNodeApp uses integer division ((W - w) / 2).
          let expected_left = (viewport_w - popup_w) / 2
          assert_eq(left, expected_left)
        }
        None => assert_true(false)
      }
    }
  }
}
