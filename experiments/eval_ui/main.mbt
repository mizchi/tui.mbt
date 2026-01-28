///|
/// Layout evaluation harness for TUI patterns.
using @vnode {type TuiNode, column, row, view, grid, grid_item, grid_area, text}

///|
struct Rect {
  id : String
  x : Int
  y : Int
  width : Int
  height : Int
}

///|
struct BorderGlyphs {
  tl : Char
  tr : Char
  bl : Char
  br : Char
  h : Char
  v : Char
}

///|
extern "js" fn js_write_file(path : String, content : String) -> String =
  #| (path, content) => {
  #|   try {
  #|     const fs = require('fs');
  #|     fs.writeFileSync(path, content, 'utf-8');
  #|     return 'wrote ' + path;
  #|   } catch (e) {
  #|     return '[Error: ' + e.message + ']';
  #|   }
  #| }

///|
fn write_file(path : String, content : String) -> String {
  js_write_file(path, content)
}
///|
struct RectDiff {
  id : String
  dx : Int
  dy : Int
  dw : Int
  dh : Int
  score : Int
}

///|
struct Pattern {
  name : String
  width : Int
  height : Int
  render : () -> TuiNode
  expected : Array[Rect]
}

///|
struct RenderResult {
  plain_lines : Array[String]
  actual_rects : Array[Rect]
}

///|
fn abs_int(n : Int) -> Int {
  if n < 0 {
    -n
  } else {
    n
  }
}

///|
fn rect_diff(pred : Rect, actual : Rect) -> RectDiff {
  let dx = actual.x - pred.x
  let dy = actual.y - pred.y
  let dw = actual.width - pred.width
  let dh = actual.height - pred.height
  let score = abs_int(dx) + abs_int(dy) + abs_int(dw) + abs_int(dh)
  { id: pred.id, dx, dy, dw, dh, score }
}

///|
fn rect_label(rect : Rect) -> String {
  rect.id + "(" +
  rect.x.to_string() + "," +
  rect.y.to_string() + ") " +
  rect.width.to_string() + "x" +
  rect.height.to_string()
}

///|
fn diff_label(diff : RectDiff) -> String {
  diff.id + " dx=" + diff.dx.to_string() +
  " dy=" + diff.dy.to_string() +
  " dw=" + diff.dw.to_string() +
  " dh=" + diff.dh.to_string() +
  " score=" + diff.score.to_string()
}

///|
fn join_lines(lines : Array[String]) -> String {
  lines.iter().fold(init="", fn(acc, line) {
    if acc == "" {
      line
    } else {
      acc + "\n" + line
    }
  })
}

///|
fn plain_lines_from_output(
  output : String,
  width : Int,
  height : Int,
) -> Array[String] {
  let plain = @testing.strip_ansi(output)
  let chars = plain.to_array()
  let lines : Array[String] = []
  let mut pos = 0
  for row in 0..<height {
    let line_chars : Array[Char] = []
    let mut col = 0
    while col < width && pos < chars.length() {
      let c = chars[pos]
      line_chars.push(c)
      pos = pos + 1
      col = col + @core.char_display_width(c)
    }
    lines.push(String::from_array(line_chars))
  }
  lines
}

///|
fn rects_from_ids(app : @vnode.VNodeApp, expected : Array[Rect]) -> Array[Rect] {
  let rects : Array[Rect] = []
  for exp in expected {
    match app.find_by_id(exp.id) {
      Some(hit) => rects.push(
        {
          id: exp.id,
          x: hit.x,
          y: hit.y,
          width: hit.width,
          height: hit.height,
        },
      )
      None => rects.push({ id: exp.id, x: -1, y: -1, width: 0, height: 0 })
    }
  }
  rects
}

///|
fn render_pattern(pattern : Pattern) -> RenderResult {
  let app = @vnode.VNodeApp::new(pattern.width, pattern.height)
  let node = (pattern.render)()
  let output = app.render_frame(node)
  let lines = plain_lines_from_output(output, pattern.width, pattern.height)
  let actual = rects_from_ids(app, pattern.expected)
  { plain_lines: lines, actual_rects: actual }
}

///|
fn to_grid(
  lines : Array[String],
  width : Int,
  height : Int,
) -> Array[Array[Char]] {
  let grid : Array[Array[Char]] = []
  for y in 0..<height {
    let line = if y < lines.length() { lines[y] } else { "" }
    let chars = line.to_array()
    let row : Array[Char] = []
    for x in 0..<width {
      if x < chars.length() {
        row.push(chars[x])
      } else {
        row.push(' ')
      }
    }
    grid.push(row)
  }
  grid
}

///|
fn border_styles() -> Array[BorderGlyphs] {
  [
    { tl: '┌', tr: '┐', bl: '└', br: '┘', h: '─', v: '│' }, // single
    { tl: '╭', tr: '╮', bl: '╰', br: '╯', h: '─', v: '│' }, // rounded
    { tl: '╔', tr: '╗', bl: '╚', br: '╝', h: '═', v: '║' }, // double
    { tl: '+', tr: '+', bl: '+', br: '+', h: '-', v: '|' }, // ascii
  ]
}

///|
fn infer_boxes(
  lines : Array[String],
  width : Int,
  height : Int,
) -> Array[Rect] {
  let grid = to_grid(lines, width, height)
  let styles = border_styles()
  let seen : Map[String, Bool] = {}
  let boxes : Array[Rect] = []
  for y in 0..<height {
    for x in 0..<width {
      for style in styles {
        if grid[y][x] == style.tl {
          let mut x2 = x + 1
          let mut top_ok = true
          while x2 < width && grid[y][x2] != style.tr {
            if grid[y][x2] != style.h {
              top_ok = false
              break
            }
            x2 = x2 + 1
          }
          if not(top_ok) || x2 >= width {
            continue
          }
          let mut y2 = y + 1
          let mut left_ok = true
          while y2 < height && grid[y2][x] != style.bl {
            if grid[y2][x] != style.v {
              left_ok = false
              break
            }
            y2 = y2 + 1
          }
          if not(left_ok) || y2 >= height {
            continue
          }
          if grid[y2][x2] != style.br {
            continue
          }
          // Verify bottom and right edges are continuous
          let mut bottom_ok = true
          for bx in (x + 1)..<x2 {
            if grid[y2][bx] != style.h {
              bottom_ok = false
            }
          }
          if not(bottom_ok) {
            continue
          }
          let mut right_ok = true
          for by in (y + 1)..<y2 {
            if grid[by][x2] != style.v {
              right_ok = false
            }
          }
          if not(right_ok) {
            continue
          }
          let w = x2 - x + 1
          let h = y2 - y + 1
          if w < 2 || h < 2 {
            continue
          }
          let key = "\{x},\{y},\{w},\{h}"
          match seen.get(key) {
            Some(_) => ()
            None => {
              seen[key] = true
              boxes.push({ id: "", x, y, width: w, height: h })
            }
          }
        }
      }
    }
  }
  boxes
}

///|
///|
fn eval_predicted(
  pattern : Pattern,
  actual_rects : Array[Rect],
) -> Array[RectDiff] {
  let diffs : Array[RectDiff] = []
  for i in 0..<pattern.expected.length() {
    let pred = pattern.expected[i]
    let actual = actual_rects[i]
    diffs.push(rect_diff(pred, actual))
  }
  diffs
}

///|
fn eval_inferred(
  actual_rects : Array[Rect],
  inferred : Array[Rect],
) -> Array[RectDiff] {
  let diffs : Array[RectDiff] = []
  let n = actual_rects.length()
  let m = inferred.length()
  if n == 0 {
    return diffs
  }
  let max_mask = 1 << n
  let inf_cost = 1000000000
  let penalty = 9999
  let dp : Array[Int] = Array::makei(max_mask, fn(_) { inf_cost })
  dp[0] = 0
  let parent_mask : Array[Array[Int]] = Array::makei(m + 1, fn(_) {
    Array::makei(max_mask, fn(_) { -1 })
  })
  let parent_match : Array[Array[Int]] = Array::makei(m + 1, fn(_) {
    Array::makei(max_mask, fn(_) { -2 })
  })
  parent_mask[0][0] = 0
  parent_match[0][0] = -1

  for step in 0..<m {
    let next_dp : Array[Int] = Array::makei(max_mask, fn(_) { inf_cost })
    for mask in 0..<max_mask {
      let cur = dp[mask]
      if cur >= inf_cost {
        continue
      }
      if cur < next_dp[mask] {
        next_dp[mask] = cur
        parent_mask[step + 1][mask] = mask
        parent_match[step + 1][mask] = -1
      }
      for i in 0..<n {
        if (mask & (1 << i)) != 0 {
          continue
        }
        let actual = actual_rects[i]
        let pred = inferred[step]
        let diff = rect_diff({ ..pred, id: actual.id }, actual)
        let size_score = abs_int(diff.dw) + abs_int(diff.dh)
        let pos_score = abs_int(diff.dx) + abs_int(diff.dy)
        let cost = size_score * 1000 + pos_score
        let next_mask = mask | (1 << i)
        let next_cost = cur + cost
        if next_cost < next_dp[next_mask] {
          next_dp[next_mask] = next_cost
          parent_mask[step + 1][next_mask] = mask
          parent_match[step + 1][next_mask] = i
        }
      }
    }
    for mask in 0..<max_mask {
      dp[mask] = next_dp[mask]
    }
  }

  let mut best_mask = 0
  let mut best_total = inf_cost
  for mask in 0..<max_mask {
    let mut count = 0
    let mut tmp = mask
    while tmp > 0 {
      if (tmp & 1) != 0 {
        count = count + 1
      }
      tmp = tmp >> 1
    }
    let unmatched = n - count
    let total = dp[mask] + unmatched * penalty
    if total < best_total {
      best_total = total
      best_mask = mask
    }
  }

  let matched : Array[Int] = Array::makei(n, fn(_) { -1 })
  let mut step = m
  let mut mask = best_mask
  while step > 0 {
    let prev = parent_mask[step][mask]
    let m_idx = parent_match[step][mask]
    if m_idx >= 0 {
      matched[m_idx] = step - 1
    }
    mask = prev
    step = step - 1
  }

  for i in 0..<n {
    let actual = actual_rects[i]
    let idx = matched[i]
    if idx >= 0 {
      let pred = inferred[idx]
      diffs.push(rect_diff({ ..pred, id: actual.id }, actual))
    } else {
      diffs.push(
        {
          id: actual.id,
          dx: 0,
          dy: 0,
          dw: 0,
          dh: 0,
          score: penalty,
        },
      )
    }
  }
  diffs
}

///|
fn eval_inferred_filtered(
  actual_rects : Array[Rect],
  inferred : Array[Rect],
  ignore_ids : Array[String],
) -> Array[RectDiff] {
  let filtered : Array[Rect] = []
  for rect in actual_rects {
    let mut ignore = false
    for id in ignore_ids {
      if rect.id == id {
        ignore = true
      }
    }
    if not(ignore) {
      filtered.push(rect)
    }
  }
  eval_inferred(filtered, inferred)
}

///|
fn infer_warning(actual_rects : Array[Rect], inferred : Array[Rect]) -> Bool {
  let total = actual_rects.length()
  if total == 0 {
    false
  } else {
    inferred.length() < total
  }
}

///|
fn expected_split(width : Int, height : Int) -> Array[Rect] {
  let header_h = 3
  let footer_h = 3
  let root_border = 1
  let inner_x = root_border
  let inner_w = width - root_border * 2
  let header_y = root_border
  let body_y = header_y + header_h
  let footer_y = height - footer_h
  let body_h = footer_y - body_y
  let sidebar_w = 12
  [
    { id: "root", x: 0, y: 0, width, height },
    {
      id: "header",
      x: inner_x,
      y: header_y,
      width: inner_w,
      height: header_h,
    },
    { id: "body", x: inner_x, y: body_y, width: inner_w, height: body_h },
    {
      id: "sidebar",
      x: inner_x + 1,
      y: body_y + 1,
      width: sidebar_w,
      height: body_h - 2,
    },
    {
      id: "content",
      x: inner_x + 1 + sidebar_w,
      y: body_y + 1,
      width: inner_w - 2 - sidebar_w,
      height: body_h - 2,
    },
    {
      id: "footer",
      x: inner_x,
      y: footer_y,
      width: inner_w,
      height: footer_h,
    },
  ]
}

///|
fn render_split(width : Int, height : Int) -> TuiNode {
  column(
    id="root",
    width=width.to_double(),
    height=height.to_double(),
    border="single",
    gap=0.0,
    [
      view(
        id="header",
        height=3.0,
        border="single",
        [text("Header")],
      ),
      row(
        id="body",
        flex_grow=1.0,
        border="single",
        gap=0.0,
        [
          view(
            id="sidebar",
            width=12.0,
            border="single",
            [text("Side")],
          ),
          view(
            id="content",
            flex_grow=1.0,
            border="single",
            [text("Content")],
          ),
        ],
      ),
      view(
        id="footer",
        height=3.0,
        border="single",
        [text("Footer")],
      ),
    ],
  )
}

///|
fn expected_grid(width : Int, height : Int) -> Array[Rect] {
  let root_border = 1
  let inner_w = width - root_border * 2
  let inner_h = height - root_border * 2
  let col_w = inner_w / 2
  let row_h = inner_h / 2
  let cell_w = 3
  [
    { id: "root", x: 0, y: 0, width, height },
    {
      id: "cell-1",
      x: root_border,
      y: root_border,
      width: cell_w,
      height: row_h,
    },
    {
      id: "cell-2",
      x: root_border + col_w,
      y: root_border,
      width: cell_w,
      height: row_h,
    },
    {
      id: "cell-3",
      x: root_border,
      y: root_border + row_h,
      width: cell_w,
      height: row_h,
    },
    {
      id: "cell-4",
      x: root_border + col_w,
      y: root_border + row_h,
      width: cell_w,
      height: row_h,
    },
  ]
}

///|
fn render_grid(width : Int, height : Int) -> TuiNode {
  grid(
    id="root",
    width=width.to_double(),
    height=height.to_double(),
    border="single",
    columns=[1.0, 1.0],
    rows=[1.0, 1.0],
    gap=0.0,
    [
      grid_item(
        column=1,
        row=1,
        child=
          view(id="cell-1", border="single", [text("A")]),
      ),
      grid_item(
        column=2,
        row=1,
        child=
          view(id="cell-2", border="single", [text("B")]),
      ),
      grid_item(
        column=1,
        row=2,
        child=
          view(id="cell-3", border="single", [text("C")]),
      ),
      grid_item(
        column=2,
        row=2,
        child=
          view(id="cell-4", border="single", [text("D")]),
      ),
    ],
  )
}

///|
fn expected_mixed(width : Int, height : Int) -> Array[Rect] {
  let gap = 1
  let left_w = 12
  let mid_w = 12
  let right_w = width - left_w - mid_w - gap * 2
  [
    { id: "root", x: 0, y: 0, width, height },
    { id: "rounded", x: 0, y: 0, width: left_w, height },
    { id: "double", x: left_w + gap, y: 0, width: mid_w, height },
    {
      id: "ascii",
      x: left_w + gap + mid_w + gap,
      y: 0,
      width: right_w,
      height,
    },
  ]
}

///|
fn render_mixed(width : Int, height : Int) -> TuiNode {
  row(
    id="root",
    width=width.to_double(),
    height=height.to_double(),
    gap=1.0,
    [
      view(
        id="rounded",
        width=12.0,
        border="rounded",
        [text("Round")],
      ),
      view(
        id="double",
        width=12.0,
        border="double",
        [text("Double")],
      ),
      view(
        id="ascii",
        flex_grow=1.0,
        border="ascii",
        [text("Ascii")],
      ),
    ],
  )
}

///|
fn expected_areas(width : Int, height : Int) -> Array[Rect] {
  let root_border = 1
  let inner_w = width - root_border * 2
  let inner_h = height - root_border * 2
  let col_w = inner_w / 2
  let row_h = inner_h / 3
  let row2_h = inner_h / 3
  [
    { id: "root", x: 0, y: 0, width, height },
    {
      id: "head",
      x: root_border,
      y: root_border,
      width: 8,
      height: 3,
    },
    {
      id: "side",
      x: root_border,
      y: root_border + row_h,
      width: 6,
      height: 3,
    },
    {
      id: "main",
      x: root_border + col_w,
      y: root_border + row_h,
      width: 6,
      height: 3,
    },
    {
      id: "foot",
      x: root_border,
      y: root_border + row_h + row2_h,
      width: 8,
      height: 3,
    },
  ]
}

///|
fn render_areas(width : Int, height : Int) -> TuiNode {
  grid(
    id="root",
    width=width.to_double(),
    height=height.to_double(),
    border="double",
    areas=[
      "head head",
      "side main",
      "foot foot",
    ],
    [
      grid_area(
        "head",
        view(id="head", border="ascii", [text("Header")]),
      ),
      grid_area(
        "side",
        view(id="side", border="rounded", [text("Side")]),
      ),
      grid_area(
        "main",
        view(id="main", border="single", [text("Main")]),
      ),
      grid_area(
        "foot",
        view(id="foot", border="double", [text("Footer")]),
      ),
    ],
  )
}

///|
fn expected_padding_gap(width : Int, height : Int) -> Array[Rect] {
  let root_border = 1
  let pad = 1
  let gap = 1
  let row_x = root_border + pad
  let row_y = root_border + pad
  let row_w = width - root_border * 2 - pad * 2
  let row_h = height - root_border * 2 - pad * 2 + gap
  let inner_pad = 1
  let left_w = 10
  [
    { id: "root", x: 0, y: 0, width, height },
    { id: "row", x: row_x, y: row_y, width: row_w, height: row_h },
    {
      id: "left",
      x: row_x + 1 + inner_pad,
      y: row_y + 1 + inner_pad,
      width: left_w,
      height: row_h - 2 - inner_pad * 2,
    },
    {
      id: "right",
      x: row_x + 1 + inner_pad + left_w + gap,
      y: row_y + 1 + inner_pad,
      width: row_w - 2 - inner_pad * 2 - left_w - gap,
      height: row_h - 2 - inner_pad * 2,
    },
  ]
}

///|
fn render_padding_gap(width : Int, height : Int) -> TuiNode {
  column(
    id="root",
    width=width.to_double(),
    height=height.to_double(),
    border="single",
    padding=1.0,
    gap=1.0,
    [
      row(
        id="row",
        flex_grow=1.0,
        border="rounded",
        padding=1.0,
        gap=1.0,
        [
          view(
            id="left",
            width=10.0,
            border="double",
            [text("Left")],
          ),
          view(
            id="right",
            flex_grow=1.0,
            border="single",
            [text("Right")],
          ),
        ],
      ),
    ],
  )
}

///|
fn expected_overflow(width : Int, height : Int) -> Array[Rect] {
  [
    { id: "root", x: 0, y: 0, width, height },
    { id: "body", x: 0, y: 0, width, height },
  ]
}

///|
fn render_overflow(width : Int, height : Int) -> TuiNode {
  let lines : Array[TuiNode] = []
  for i in 0..<10 {
    lines.push(text("Line " + i.to_string()))
  }
  view(
    id="root",
    width=width.to_double(),
    height=height.to_double(),
    border="single",
    [
      column(
        id="body",
        height=(height - 2).to_double(),
        lines,
      ),
    ],
  )
}

///|
fn patterns() -> Array[Pattern] {
  let split_width = 40
  let split_height = 12
  let grid_width = 40
  let grid_height = 12
  let mixed_width = 42
  let mixed_height = 7
  let areas_width = 42
  let areas_height = 12
  let pad_width = 42
  let pad_height = 10
  let overflow_width = 28
  let overflow_height = 6
  [
    {
      name: "split",
      width: split_width,
      height: split_height,
      render: fn() { render_split(split_width, split_height) },
      expected: expected_split(split_width, split_height),
    },
    {
      name: "grid",
      width: grid_width,
      height: grid_height,
      render: fn() { render_grid(grid_width, grid_height) },
      expected: expected_grid(grid_width, grid_height),
    },
    {
      name: "mixed-borders",
      width: mixed_width,
      height: mixed_height,
      render: fn() { render_mixed(mixed_width, mixed_height) },
      expected: expected_mixed(mixed_width, mixed_height),
    },
    {
      name: "areas",
      width: areas_width,
      height: areas_height,
      render: fn() { render_areas(areas_width, areas_height) },
      expected: expected_areas(areas_width, areas_height),
    },
    {
      name: "padding-gap",
      width: pad_width,
      height: pad_height,
      render: fn() { render_padding_gap(pad_width, pad_height) },
      expected: expected_padding_gap(pad_width, pad_height),
    },
    {
      name: "overflow",
      width: overflow_width,
      height: overflow_height,
      render: fn() { render_overflow(overflow_width, overflow_height) },
      expected: expected_overflow(overflow_width, overflow_height),
    },
  ]
}

///|
fn print_rects(title : String, rects : Array[Rect]) -> Unit {
  println(title)
  for rect in rects {
    println("  " + rect_label(rect))
  }
}

///|
fn print_diffs(title : String, diffs : Array[RectDiff]) -> Unit {
  println(title)
  let mut total = 0
  for diff in diffs {
    println("  " + diff_label(diff))
    total = total + diff.score
  }
  println("  total_score=" + total.to_string())
}

///|
fn run_pattern(pattern : Pattern) -> Unit {
  println(
    "=== " +
    pattern.name +
    " (" +
    pattern.width.to_string() +
    "x" +
    pattern.height.to_string() +
    ") ===",
  )
  let rendered = render_pattern(pattern)
  println("[output]")
  println(join_lines(rendered.plain_lines))
  println("")
  print_rects("[actual_rects]", rendered.actual_rects)
  let pred_diffs = eval_predicted(pattern, rendered.actual_rects)
  print_diffs("[eval-1 predicted->actual]", pred_diffs)
  let inferred = infer_boxes(
    rendered.plain_lines,
    pattern.width,
    pattern.height,
  )
  let inferred_diffs = eval_inferred(rendered.actual_rects, inferred)
  let inferred_filtered = eval_inferred_filtered(
    rendered.actual_rects,
    inferred,
    ["root"],
  )
  print_diffs("[eval-2 inferred->actual]", inferred_diffs)
  print_diffs("[eval-2b inferred->actual (no root)]", inferred_filtered)
  if infer_warning(rendered.actual_rects, inferred) {
    println("WARNING: inferred boxes < actual boxes")
  }
  println("inferred_boxes=" + inferred.length().to_string())
  println("")
}

///|
fn eval1_block(pattern : Pattern) -> String {
  let rendered = render_pattern(pattern)
  let diffs = eval_predicted(pattern, rendered.actual_rects)
  let sb = StringBuilder::new()
  sb.write_string(
    "==== " +
    pattern.name +
    " (" +
    pattern.width.to_string() +
    "x" +
    pattern.height.to_string() +
    ") ====\n",
  )
  let mut total = 0
  for diff in diffs {
    sb.write_string("  " + diff_label(diff) + "\n")
    total = total + diff.score
  }
  sb.write_string("  total_score=" + total.to_string() + "\n\n")
  sb.to_string()
}

///|
fn snapshot_eval1(path : String) -> Unit {
  let sb = StringBuilder::new()
  sb.write_string("# eval-1 snapshot\n\n")
  for pattern in patterns() {
    sb.write_string(eval1_block(pattern))
  }
  let result = write_file(path, sb.to_string())
  println(result)
}

///|
fn run_scroll_ui() -> Unit {
  let (initial_width, initial_height) = @io.get_terminal_size()
  let width = Ref::new(initial_width)
  let height = Ref::new(initial_height)
  let lines : Array[String] = []
  for i in 0..<200 {
    lines.push("Line " + i.to_string() + " - lorem ipsum dolor sit amet")
  }
  let offset = Ref::new(0)

  let (app, cleanup) = @vnode.init_vnode_terminal(
    initial_width,
    initial_height,
    @io.print_raw,
  )

  fn max_offset() -> Int { scroll_max_offset(lines, height.val) }

  fn clamp_offset(next : Int) -> Int {
    clamp_scroll_offset(next, max_offset())
  }

  fn render_ui() -> TuiNode {
    render_scroll_node(
      width.val,
      height.val,
      offset.val,
      lines,
      max_offset(),
    )
  }

  fn do_render() -> Unit {
    @io.print_raw(app.render_frame(render_ui()))
  }

  fn update_offset(next : Int, force : Bool) -> Unit {
    let v = clamp_offset(next)
    if force || v != offset.val {
      offset.val = v
      do_render()
    }
  }

  fn handle_resize(new_width : Int, new_height : Int) -> Unit {
    width.val = new_width
    height.val = new_height
    app.resize(new_width, new_height)
    update_offset(offset.val, true)
  }

  fn handle_key(key : String) -> Unit {
    if key.length() == 0 {
      return
    }
    let event = @events.parse_input(key)
    if event.is_quit() {
      cleanup()
      return
    }
    if event.is_scroll_up() {
      update_offset(offset.val - 3, false)
      return
    }
    if event.is_scroll_down() {
      update_offset(offset.val + 3, false)
      return
    }
    match event.is_arrow() {
      Some(@events.SpecialKey::Up) => update_offset(offset.val - 1, false)
      Some(@events.SpecialKey::Down) => update_offset(offset.val + 1, false)
      _ => ()
    }
    if event.is_char('j') {
      update_offset(offset.val + 1, false)
      return
    }
    if event.is_char('k') {
      update_offset(offset.val - 1, false)
      return
    }
    if event.is_char('g') {
      update_offset(0, false)
      return
    }
    if event.is_char('G') {
      update_offset(max_offset(), false)
      return
    }
  }

  @io.start_resize_listener(handle_resize)
  do_render()
  @io.start_keypress_listener(handle_key)
}

///|
fn scroll_list_height(height : Int) -> Int {
  let h = height - 3
  if h < 1 { 1 } else { h }
}

///|
fn scroll_max_offset(lines : Array[String], height : Int) -> Int {
  let max = lines.length() - scroll_list_height(height)
  if max < 0 { 0 } else { max }
}

///|
fn clamp_scroll_offset(next : Int, max : Int) -> Int {
  if next < 0 {
    0
  } else if next > max {
    max
  } else {
    next
  }
}

///|
fn render_scroll_node(
  width : Int,
  height : Int,
  offset : Int,
  lines : Array[String],
  max_offset : Int,
) -> TuiNode {
  let list_h = scroll_list_height(height)
  let start = offset
  let end = start + list_h
  let items : Array[TuiNode] = []
  let mut i = start
  while i < lines.length() && i < end {
    items.push(text(lines[i]))
    i = i + 1
  }
  let status = "offset " +
    start.to_string() +
    "/" +
    max_offset.to_string() +
    "  (j/k, up/down, g/G, q)"
  view(
    id="root",
    width=width.to_double(),
    height=height.to_double(),
    border="single",
    [
      column(
        id="container",
        height=(height - 2).to_double(),
        [
          view(id="list", flex_grow=1.0, items),
          view(
            id="status",
            height=1.0,
            [text(status, fg="rgb(120,120,120)")],
          ),
        ],
      ),
    ],
  )
}

///|
fn render_scroll_snapshot(
  width : Int,
  height : Int,
  offset : Int,
  lines : Array[String],
) -> Array[String] {
  let app = @vnode.VNodeApp::new(width, height)
  let max_off = scroll_max_offset(lines, height)
  let node = render_scroll_node(width, height, offset, lines, max_off)
  let output = app.render_frame(node)
  plain_lines_from_output(output, width, height)
}

///|
fn display_width(s : String) -> Int {
  let mut w = 0
  for c in s {
    w = w + @core.char_display_width(c)
  }
  w
}

///|
fn pad_right(s : String, width : Int) -> String {
  let w = display_width(s)
  if w >= width {
    s
  } else {
    s + " ".repeat(width - w)
  }
}

///|
fn pad_left_int(n : Int, width : Int) -> String {
  let s = n.to_string()
  if s.length() >= width {
    s
  } else {
    " ".repeat(width - s.length()) + s
  }
}

///|
fn format_snapshot_block(
  width : Int,
  height : Int,
  offset : Int,
  lines : Array[String],
) -> String {
  let max_row = offset + height - 1
  let row_digits = if max_row < 10 {
    2
  } else {
    max_row.to_string().length()
  }
  let sb = StringBuilder::new()
  let header = "==== offset " +
    offset.to_string() +
    " (" +
    width.to_string() +
    "x" +
    height.to_string() +
    ") ===="
  sb.write_string(header + "\n")
  sb.write_string(" ".repeat(row_digits) + "+" + "#".repeat(width) + "+\n")
  for i in 0..<height {
    let line = if i < lines.length() { lines[i] } else { "" }
    let padded = pad_right(line, width)
    sb.write_string(pad_left_int(offset + i, row_digits))
    sb.write_string("|")
    sb.write_string(padded)
    sb.write_string("|\n")
  }
  sb.write_string(" ".repeat(row_digits) + "+" + "#".repeat(width) + "+\n")
  sb.to_string()
}

///|
fn snapshot_scroll(path : String) -> Unit {
  let width = 40
  let height = 10
  let lines : Array[String] = []
  for i in 0..<120 {
    lines.push("Line " + i.to_string() + " - lorem ipsum dolor sit amet")
  }
  let max_off = scroll_max_offset(lines, height)
  let candidates : Array[Int] = [0, 1, 3, 10, max_off / 2, max_off]
  let seen : Map[Int, Bool] = {}
  let offsets : Array[Int] = []
  for c in candidates {
    let v = clamp_scroll_offset(c, max_off)
    match seen.get(v) {
      Some(_) => ()
      None => {
        seen[v] = true
        offsets.push(v)
      }
    }
  }

  let sb = StringBuilder::new()
  sb.write_string(
    "# scroll snapshot " +
    width.to_string() +
    "x" +
    height.to_string() +
    "\n\n",
  )
  for off in offsets {
    let lines = render_scroll_snapshot(width, height, off, lines)
    sb.write_string(format_snapshot_block(width, height, off, lines))
    sb.write_string("\n")
  }
  let result = write_file(path, sb.to_string())
  println(result)
}

///|
fn main {
  let args = @io.get_args()
  let mut run_scroll = false
  let mut run_scroll_snapshot = false
  let mut run_eval1_snapshot = false
  let mut snapshot_path = "../../__snapshots__/eval_ui_scroll.txt"
  let mut eval1_path = "../../__snapshots__/eval_ui_eval1.txt"
  let mut i = 0
  while i < args.length() {
    let arg = args[i]
    if arg == "--scroll" {
      run_scroll = true
    }
    if arg == "--scroll-snapshot" {
      run_scroll_snapshot = true
    }
    if arg == "--eval1-snapshot" {
      run_eval1_snapshot = true
    }
    if arg == "--snapshot-path" && i + 1 < args.length() {
      snapshot_path = args[i + 1]
      i = i + 1
    }
    if arg == "--eval1-path" && i + 1 < args.length() {
      eval1_path = args[i + 1]
      i = i + 1
    }
    i = i + 1
  }
  if run_eval1_snapshot {
    snapshot_eval1(eval1_path)
  } else if run_scroll_snapshot {
    snapshot_scroll(snapshot_path)
  } else if run_scroll {
    run_scroll_ui()
  } else {
    for pattern in patterns() {
      run_pattern(pattern)
    }
  }
}
