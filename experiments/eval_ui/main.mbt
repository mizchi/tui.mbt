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
struct InferStats {
  boxes : Array[Rect]
  rejected : Int
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
  layout_rects : Array[Rect]
}

///|
struct OutputOptions {
  show_output : Bool
  clip_w : Int
  clip_h : Int
  clip_x : Int
  clip_y : Int
  infer_layout : Bool
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
fn slice_line_by_width(line : String, start : Int, width : Int) -> String {
  let chars = line.to_array()
  let out : Array[Char] = []
  let mut pos = 0
  let mut col = 0
  while pos < chars.length() {
    let c = chars[pos]
    let w = @core.char_display_width(c)
    if col + w <= start {
      col = col + w
      pos = pos + 1
      continue
    }
    if col >= start + width {
      break
    }
    out.push(c)
    col = col + w
    pos = pos + 1
  }
  let mut out_s = String::from_array(out)
  let out_w = display_width(out_s)
  if out_w < width {
    out_s = out_s + " ".repeat(width - out_w)
  }
  out_s
}

///|
fn clip_lines(
  lines : Array[String],
  start_row : Int,
  rows : Int,
  start_col : Int,
  cols : Int,
) -> Array[String] {
  let clipped : Array[String] = []
  for i in 0..<rows {
    let row_idx = start_row + i
    let line = if row_idx < lines.length() { lines[row_idx] } else { "" }
    clipped.push(slice_line_by_width(line, start_col, cols))
  }
  clipped
}

///|
fn parse_arg_int(s : String, default : Int) -> Int {
  try @strconv.parse_int(s) catch {
    _ => default
  } noraise {
    v => v
  }
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
fn rects_from_ids(
  layout_rects : Array[Rect],
  expected : Array[Rect],
) -> Array[Rect] {
  let map : Map[String, Rect] = {}
  for rect in layout_rects {
    if rect.id != "" {
      map[rect.id] = rect
    }
  }
  let rects : Array[Rect] = []
  for exp in expected {
    match map.get(exp.id) {
      Some(rect) => rects.push({ ..rect, id: exp.id })
      None => rects.push({ id: exp.id, x: -1, y: -1, width: 0, height: 0 })
    }
  }
  rects
}

///|
fn rects_from_layout(app : @vnode.VNodeApp) -> Array[Rect] {
  let rects : Array[Rect] = []
  for hit in app.layout_rects() {
    rects.push(
      {
        id: hit.id,
        x: hit.x,
        y: hit.y,
        width: hit.width,
        height: hit.height,
      },
    )
  }
  rects
}

///|
fn is_auto_id(id : String) -> Bool {
  if id.length() < 2 {
    false
  } else {
    let chars = id.to_array()
    if chars[0] != 'v' {
      false
    } else {
      let mut ok = true
      for i in 1..<chars.length() {
        let c = chars[i]
        if c < '0' || c > '9' {
          ok = false
        }
      }
      ok
    }
  }
}

///|
fn named_layout_rects(rects : Array[Rect]) -> Array[Rect] {
  let named : Array[Rect] = []
  for rect in rects {
    let is_root = rect.id == "root" || rect.id.has_suffix("-root")
    if rect.id != "" && !is_auto_id(rect.id) && !is_root {
      named.push(rect)
    }
  }
  named
}

///|
fn render_pattern(pattern : Pattern) -> RenderResult {
  let app = @vnode.VNodeApp::new(pattern.width, pattern.height)
  let node = (pattern.render)()
  let output = app.render_frame(node)
  let lines = plain_lines_from_output(output, pattern.width, pattern.height)
  let layout_rects = rects_from_layout(app)
  let actual = rects_from_ids(layout_rects, pattern.expected)
  { plain_lines: lines, actual_rects: actual, layout_rects }
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
fn is_border_corner(c : Char) -> Bool {
  for style in border_styles() {
    if c == style.tl || c == style.tr || c == style.bl || c == style.br {
      return true
    }
  }
  false
}

///|
fn is_border_horizontal(c : Char) -> Bool {
  for style in border_styles() {
    if c == style.h {
      return true
    }
  }
  is_border_corner(c)
}

///|
fn is_border_vertical(c : Char) -> Bool {
  for style in border_styles() {
    if c == style.v {
      return true
    }
  }
  is_border_corner(c)
}

///|
fn infer_boxes_stats(
  lines : Array[String],
  width : Int,
  height : Int,
) -> InferStats {
  let grid = to_grid(lines, width, height)
  let styles = border_styles()
  let seen : Map[String, Bool] = {}
  let boxes : Array[Rect] = []
  let mut rejected = 0
  for y in 0..<height {
    for x in 0..<width {
      for style in styles {
        if grid[y][x] == style.tl {
          let mut x2 = x + 1
          let mut top_ok = true
          while x2 < width && grid[y][x2] != style.tr {
            if not(is_border_horizontal(grid[y][x2])) {
              top_ok = false
              break
            }
            x2 = x2 + 1
          }
          if not(top_ok) || x2 >= width {
            rejected = rejected + 1
            continue
          }
          let mut y2 = y + 1
          let mut left_ok = true
          while y2 < height && grid[y2][x] != style.bl {
            if not(is_border_vertical(grid[y2][x])) {
              left_ok = false
              break
            }
            y2 = y2 + 1
          }
          if not(left_ok) || y2 >= height {
            rejected = rejected + 1
            continue
          }
          if grid[y2][x2] != style.br {
            rejected = rejected + 1
            continue
          }
          // Verify bottom and right edges are continuous
          let mut bottom_ok = true
          for bx in (x + 1)..<x2 {
            if not(is_border_horizontal(grid[y2][bx])) {
              bottom_ok = false
            }
          }
          if not(bottom_ok) {
            rejected = rejected + 1
            continue
          }
          let mut right_ok = true
          for by in (y + 1)..<y2 {
            if not(is_border_vertical(grid[by][x2])) {
              right_ok = false
            }
          }
          if not(right_ok) {
            rejected = rejected + 1
            continue
          }
          let w = x2 - x + 1
          let h = y2 - y + 1
          if w < 2 || h < 2 {
            rejected = rejected + 1
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
  { boxes, rejected }
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
  if total == 0 { false } else { inferred.length() < total }
}

///|
fn broken_score(actual_total : Int, inferred_total : Int, rejected : Int) -> Int {
  let missing = if actual_total > inferred_total {
    actual_total - inferred_total
  } else {
    0
  }
  missing * 10000 + rejected
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
fn expected_deep(width : Int, height : Int) -> Array[Rect] {
  let root_border = 1
  let outer_x = root_border
  let outer_y = root_border
  let outer_w = width - root_border * 2
  let outer_h = height - root_border * 2
  let outer_content_x = outer_x + 2
  let outer_content_y = outer_y + 2
  let row_x = outer_content_x
  let row_y = outer_content_y
  let row_w = outer_w - 4
  let row_h = 7
  let bottom_x = outer_content_x
  let bottom_y = row_y + row_h + 1
  let bottom_w = row_w
  let bottom_h = 4
  let row_content_x = row_x + 2
  let row_content_y = row_y + 2
  let left_w = 10
  let gap = 1
  [
    { id: "root", x: 0, y: 0, width, height },
    { id: "outer", x: outer_x, y: outer_y, width: outer_w, height: outer_h },
    { id: "row", x: row_x, y: row_y, width: row_w, height: row_h },
    { id: "left", x: row_content_x, y: row_content_y, width: left_w, height: 3 },
    {
      id: "right",
      x: row_content_x + left_w + gap,
      y: row_content_y,
      width: row_w - 4 - left_w - gap,
      height: 3,
    },
    {
      id: "bottom",
      x: bottom_x,
      y: bottom_y,
      width: bottom_w,
      height: bottom_h,
    },
  ]
}

///|
fn render_deep(width : Int, height : Int) -> TuiNode {
  view(
    id="root",
    width=width.to_double(),
    height=height.to_double(),
    border="single",
    [
      view(
        id="outer",
        width=(width - 2).to_double(),
        height=(height - 2).to_double(),
        border="double",
        padding=1.0,
        [
          column(
            gap=1.0,
            [
              row(
                id="row",
                height=7.0,
                border="rounded",
                padding=1.0,
                gap=1.0,
                [
                  view(
                    id="left",
                    width=10.0,
                    border="double",
                    [text("L")],
                  ),
                  view(
                    id="right",
                    flex_grow=1.0,
                    border="single",
                    [text("R")],
                  ),
                ],
              ),
              view(
                id="bottom",
                height=4.0,
                border="single",
                [text("Bottom")],
              ),
            ],
          ),
        ],
      ),
    ],
  )
}

///|
fn expected_asym(width : Int, height : Int) -> Array[Rect] {
  let root_border = 1
  let main_x = root_border
  let main_y = root_border
  let main_w = width - root_border * 2
  let main_h = height - root_border * 2
  let main_content_x = main_x + 1
  let main_content_y = main_y + 1
  let main_content_w = main_w - 2
  let main_content_h = main_h - 2
  let left_w = 14
  let right_w = main_content_w - left_w
  let right_x = main_content_x + left_w
  let right_y = main_content_y
  let right_inner_x = right_x + 1
  let right_inner_y = right_y + 1
  let right_inner_w = right_w - 2
  let right_inner_h = main_content_h - 1
  let top_h = 3
  let bottom_h = right_inner_h - top_h - 1
  [
    { id: "root", x: 0, y: 0, width, height },
    { id: "main", x: main_x, y: main_y, width: main_w, height: main_h },
    { id: "left", x: main_content_x, y: main_content_y, width: left_w, height: main_content_h },
    { id: "right", x: right_x, y: right_y, width: right_w, height: main_content_h },
    {
      id: "top",
      x: right_inner_x,
      y: right_inner_y,
      width: right_inner_w,
      height: top_h,
    },
    {
      id: "bottom",
      x: right_inner_x,
      y: right_inner_y + top_h + 1,
      width: right_inner_w,
      height: bottom_h,
    },
  ]
}

///|
fn render_asym(width : Int, height : Int) -> TuiNode {
  view(
    id="root",
    width=width.to_double(),
    height=height.to_double(),
    border="single",
    [
      row(
        id="main",
        width=(width - 2).to_double(),
        height=(height - 2).to_double(),
        border="single",
        [
          view(
            id="left",
            width=14.0,
            border="double",
            [text("Left")],
          ),
          view(
            id="right",
            flex_grow=1.0,
            border="rounded",
            [
              column(
                gap=1.0,
                [
                  view(
                    id="top",
                    height=3.0,
                    border="single",
                    [text("Top")],
                  ),
                  view(
                    id="bottom",
                    flex_grow=1.0,
                    border="single",
                    [text("Bottom")],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  )
}

///|
fn expected_grid_mix(width : Int, height : Int) -> Array[Rect] {
  let root_border = 1
  let inner_w = width - root_border * 2
  let inner_h = height - root_border * 2
  let col_w = inner_w / 2
  let row_h = inner_h / 2
  let cell_h = row_h
  let cell1_w = 18
  let cell2_w = 5
  let cell3_w = 5
  let cell4_w = 29
  [
    { id: "root", x: 0, y: 0, width, height },
    { id: "cell-1", x: 1, y: 1, width: cell1_w, height: cell_h },
    { id: "cell-2", x: 1 + col_w, y: 1, width: cell2_w, height: cell_h },
    { id: "cell-3", x: 1, y: 1 + cell_h, width: cell3_w, height: cell_h },
    { id: "cell-4", x: 1 + col_w, y: 1 + cell_h, width: cell4_w, height: cell_h },
    { id: "c1-row", x: 2, y: 2, width: 16, height: 5 },
    { id: "c1-left", x: 3, y: 3, width: 10, height: 3 },
    { id: "c1-right", x: 14, y: 3, width: 3, height: 3 },
    { id: "c2-inner", x: 1 + col_w + 1, y: 2, width: 3, height: 5 },
    { id: "c3-inner", x: 2, y: 1 + cell_h + 1, width: 3, height: 5 },
    { id: "c4-row", x: 1 + col_w + 1, y: 1 + cell_h + 1, width: 27, height: 5 },
    { id: "c4-a", x: 1 + col_w + 2, y: 1 + cell_h + 2, width: 12, height: 3 },
    { id: "c4-b", x: 1 + col_w + 15, y: 1 + cell_h + 2, width: 12, height: 3 },
  ]
}

///|
fn render_grid_mix(width : Int, height : Int) -> TuiNode {
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
          view(
            id="cell-1",
            border="single",
            [
              row(
                id="c1-row",
                height=5.0,
                border="rounded",
                gap=1.0,
                [
                  view(
                    id="c1-left",
                    width=10.0,
                    border="double",
                    [text("A")],
                  ),
                  view(
                    id="c1-right",
                    flex_grow=1.0,
                    border="single",
                    [text("B")],
                  ),
                ],
              ),
            ],
          ),
      ),
      grid_item(
        column=2,
        row=1,
        child=
          view(
            id="cell-2",
            border="single",
            [
              view(
                id="c2-inner",
                height=5.0,
                border="double",
                [text("C")],
              ),
            ],
          ),
      ),
      grid_item(
        column=1,
        row=2,
        child=
          view(
            id="cell-3",
            border="single",
            [
              view(
                id="c3-inner",
                height=5.0,
                border="rounded",
                [text("D")],
              ),
            ],
          ),
      ),
      grid_item(
        column=2,
        row=2,
        child=
          view(
            id="cell-4",
            border="single",
            [
              row(
                id="c4-row",
                height=5.0,
                border="single",
                gap=1.0,
                [
                  view(
                    id="c4-a",
                    width=12.0,
                    border="double",
                    [text("E")],
                  ),
                  view(
                    id="c4-b",
                    width=12.0,
                    border="rounded",
                    [text("F")],
                  ),
                ],
              ),
            ],
          ),
      ),
    ],
  )
}

///|
fn expected_p5_menu(width : Int, height : Int) -> Array[Rect] {
  let root_border = 1
  let inner_x = root_border
  let inner_y = root_border
  let inner_w = width - root_border * 2
  let inner_h = height - root_border * 2
  let header_h = 12
  let footer_h = 8
  let body_h = inner_h - header_h - footer_h
  let body_x = inner_x
  let body_y = inner_y + header_h
  let footer_y = body_y + body_h
  let list_w = 120
  let detail_x = body_x + 1 + list_w
  let detail_y = body_y + 1
  let detail_w = inner_w - 2 - list_w
  let detail_h = body_h - 2
  let detail_inner_x = detail_x + 1 + 1
  let detail_inner_y = detail_y + 1 + 1
  let detail_inner_w = detail_w - 2 - 2
  let status_h = 120
  let detail_inner_h = detail_h - 2 - 2
  let info_h = detail_inner_h - status_h - 1
  [
    { id: "menu-root", x: 0, y: 0, width, height },
    { id: "menu-header", x: inner_x, y: inner_y, width: inner_w, height: header_h },
    { id: "menu-body", x: body_x, y: body_y, width: inner_w, height: body_h },
    { id: "menu-list", x: body_x + 1, y: body_y + 1, width: list_w, height: body_h - 2 },
    { id: "menu-detail", x: detail_x, y: detail_y, width: detail_w, height: detail_h },
    { id: "menu-status", x: detail_inner_x, y: detail_inner_y, width: detail_inner_w, height: status_h },
    {
      id: "menu-info",
      x: detail_inner_x,
      y: detail_inner_y + status_h + 1,
      width: detail_inner_w,
      height: info_h,
    },
    { id: "menu-footer", x: inner_x, y: footer_y, width: inner_w, height: footer_h },
  ]
}

///|
fn render_p5_menu(width : Int, height : Int) -> TuiNode {
  let header_h = 12
  let footer_h = 8
  let body_h = height - 2 - header_h - footer_h
  let detail_inner_h = body_h - 6
  let items = [
    "Status",
    "Persona",
    "Skills",
    "Items",
    "Confidant",
    "Save",
  ]
  let selected = 2
  let list_nodes : Array[TuiNode] = []
  for i, item in items {
    if i == selected {
      list_nodes.push(
        view(bg="rgb(200,40,40)", [text(">> " + item, fg="white")]),
      )
    } else {
      list_nodes.push(text("   " + item, fg="white"))
    }
  }
  let header_text = "MENU // 04/15 WED  Evening"
  let footer_text = "ENTER: Select  ESC: Back  /  Q: Quit"
  let status_lines : Array[TuiNode] = [
    text("JOKER  LV 15", fg="white"),
    text("HP  120/150  SP  80/90", fg="white"),
    text("Status: Normal", fg="white"),
  ]
  let info_lines : Array[TuiNode] = [
    text("Current Objective:", fg="rgb(200,40,40)"),
    text("Infiltrate the Palace", fg="white"),
    text("Deadline: 04/30", fg="white"),
  ]
  view(
    id="menu-root",
    width=width.to_double(),
    height=height.to_double(),
    border="single",
    [
      column(
        height=(height - 2).to_double(),
        [
          view(
            id="menu-header",
            height=header_h.to_double(),
            border="double",
            [text(header_text, fg="white")],
          ),
          row(
            id="menu-body",
            height=body_h.to_double(),
            border="single",
            [
              view(
                id="menu-list",
                width=120.0,
                border="double",
                padding=1.0,
                list_nodes,
              ),
              view(
                id="menu-detail",
                flex_grow=1.0,
                border="single",
                padding=1.0,
                [
                  column(
                    gap=1.0,
                    height=detail_inner_h.to_double(),
                    [
                      view(
                        id="menu-status",
                        height=120.0,
                        border="single",
                        status_lines,
                      ),
                      view(
                        id="menu-info",
                        flex_grow=1.0,
                        border="single",
                        info_lines,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          view(
            id="menu-footer",
            height=8.0,
            border="single",
            [text(footer_text, fg="rgb(120,120,120)")],
          ),
        ],
      ),
    ],
  )
}

///|
fn expected_p5_battle(width : Int, height : Int) -> Array[Rect] {
  let root_border = 1
  let inner_x = root_border
  let inner_y = root_border
  let inner_w = width - root_border * 2
  let inner_h = height - root_border * 2
  let enemy_h = 60
  let bottom_h = 120
  let mid_h = inner_h - enemy_h - bottom_h
  let bottom_y = inner_y + enemy_h + mid_h
  let cmd_w = 140
  let party_w = inner_w - cmd_w
  [
    { id: "battle-root", x: 0, y: 0, width, height },
    { id: "battle-enemy", x: inner_x, y: inner_y, width: inner_w, height: enemy_h },
    { id: "battle-log", x: inner_x, y: inner_y + enemy_h, width: inner_w, height: mid_h },
    { id: "battle-bottom", x: inner_x, y: bottom_y, width: inner_w, height: bottom_h },
    { id: "battle-commands", x: inner_x + 1, y: bottom_y + 1, width: cmd_w, height: bottom_h - 2 },
    {
      id: "battle-party",
      x: inner_x + 1 + cmd_w,
      y: bottom_y + 1,
      width: party_w - 2,
      height: bottom_h - 2,
    },
  ]
}

///|
fn render_p5_battle(width : Int, height : Int) -> TuiNode {
  let enemy_name = "SHADOW: BLOOD CURSE"
  let hp_bar = "[##########......]  120/180"
  let log_lines : Array[TuiNode] = [
    text("Joker attacks!", fg="white"),
    text("Weakness hit!", fg="rgb(200,40,40)"),
    text("Enemy down!", fg="white"),
  ]
  let commands : Array[TuiNode] = [
    view(bg="rgb(200,40,40)", [text("Fight", fg="white")]),
    text("Persona", fg="white"),
    text("Skill", fg="white"),
    text("Item", fg="white"),
    text("Guard", fg="white"),
    text("Escape", fg="white"),
  ]
  let party : Array[TuiNode] = [
    text("Joker  HP 120/150  SP 80/90", fg="white"),
    text("Ryuji  HP  90/120  SP 45/60", fg="white"),
    text("Ann    HP  70/100  SP 65/80", fg="white"),
    text("Morgana HP 60/90   SP 50/70", fg="white"),
  ]
  view(
    id="battle-root",
    width=width.to_double(),
    height=height.to_double(),
    border="single",
    [
      column(
        height=(height - 2).to_double(),
        [
          view(
            id="battle-enemy",
            height=60.0,
            border="double",
            [
              text(enemy_name, fg="white"),
              text(hp_bar, fg="white"),
              text("Status: Shock", fg="rgb(200,40,40)"),
            ],
          ),
          view(
            id="battle-log",
            flex_grow=1.0,
            border="single",
            log_lines,
          ),
          row(
            id="battle-bottom",
            height=120.0,
            border="single",
            [
              view(
                id="battle-commands",
                width=140.0,
                border="double",
                padding=1.0,
                commands,
              ),
              view(
                id="battle-party",
                flex_grow=1.0,
                border="single",
                padding=1.0,
                party,
              ),
            ],
          ),
        ],
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
  let deep_width = 44
  let deep_height = 18
  let asym_width = 50
  let asym_height = 12
  let mix_width = 60
  let mix_height = 16
  let pad_width = 42
  let pad_height = 10
  let overflow_width = 28
  let overflow_height = 6
  let list : Array[Pattern] = [
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
      name: "deep-nesting",
      width: deep_width,
      height: deep_height,
      render: fn() { render_deep(deep_width, deep_height) },
      expected: expected_deep(deep_width, deep_height),
    },
    {
      name: "asym-layout",
      width: asym_width,
      height: asym_height,
      render: fn() { render_asym(asym_width, asym_height) },
      expected: expected_asym(asym_width, asym_height),
    },
    {
      name: "grid-mix",
      width: mix_width,
      height: mix_height,
      render: fn() { render_grid_mix(mix_width, mix_height) },
      expected: expected_grid_mix(mix_width, mix_height),
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
  list
}

///|
fn patterns_p5() -> Array[Pattern] {
  let p5_width = 400
  let p5_height = 400
  [
    {
      name: "p5-menu",
      width: p5_width,
      height: p5_height,
      render: fn() { render_p5_menu(p5_width, p5_height) },
      expected: expected_p5_menu(p5_width, p5_height),
    },
    {
      name: "p5-battle",
      width: p5_width,
      height: p5_height,
      render: fn() { render_p5_battle(p5_width, p5_height) },
      expected: expected_p5_battle(p5_width, p5_height),
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
fn run_pattern(pattern : Pattern, out_opts : OutputOptions) -> Unit {
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
  if out_opts.show_output {
    let lines =
      if out_opts.clip_w > 0 && out_opts.clip_h > 0 {
        clip_lines(
          rendered.plain_lines,
          out_opts.clip_y,
          out_opts.clip_h,
          out_opts.clip_x,
          out_opts.clip_w,
        )
      } else {
        rendered.plain_lines
      }
    println("[output]")
    println(join_lines(lines))
    println("")
  }
  print_rects("[actual_rects]", rendered.actual_rects)
  let pred_diffs = eval_predicted(pattern, rendered.actual_rects)
  print_diffs("[eval-1 predicted->actual]", pred_diffs)
  let stats = infer_boxes_stats(
    rendered.plain_lines,
    pattern.width,
    pattern.height,
  )
  let inferred =
    if out_opts.infer_layout {
      rendered.layout_rects
    } else {
      stats.boxes
    }
  let inferred_diffs = eval_inferred(rendered.actual_rects, inferred)
  let inferred_filtered = eval_inferred_filtered(
    rendered.actual_rects,
    inferred,
    ["root"],
  )
  print_diffs("[eval-2 inferred->actual]", inferred_diffs)
  print_diffs("[eval-2b inferred->actual (no root)]", inferred_filtered)
  if out_opts.infer_layout {
    println("[infer-source layout_rects]")
  } else {
    let broken = broken_score(
      rendered.actual_rects.length(),
      inferred.length(),
      stats.rejected,
    )
    println(
      "[eval-2c broken] missing=" +
      (rendered.actual_rects.length() - inferred.length()).to_string() +
      " rejected=" +
      stats.rejected.to_string() +
      " score=" +
      broken.to_string(),
    )
    if infer_warning(rendered.actual_rects, inferred) {
      println("WARNING: inferred boxes < actual boxes")
    }
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
fn layout_block(pattern : Pattern) -> String {
  let rendered = render_pattern(pattern)
  let rects = named_layout_rects(rendered.layout_rects)
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
  for rect in rects {
    sb.write_string("  " + rect_label(rect) + "\n")
  }
  sb.write_string("\n")
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
fn snapshot_eval1_p5(path : String) -> Unit {
  let sb = StringBuilder::new()
  sb.write_string("# eval-1 snapshot (p5)\n\n")
  for pattern in patterns_p5() {
    sb.write_string(eval1_block(pattern))
  }
  let result = write_file(path, sb.to_string())
  println(result)
}

///|
fn snapshot_layout(path : String, list : Array[Pattern], label : String) -> Unit {
  let sb = StringBuilder::new()
  sb.write_string("# layout snapshot" + label + "\n\n")
  for pattern in list {
    sb.write_string(layout_block(pattern))
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
  let mut run_p5 = false
  let mut run_eval1_p5 = false
  let mut run_layout_snapshot = false
  let mut run_layout_snapshot_p5 = false
  let mut show_output = true
  let mut force_full_output = false
  let mut infer_layout = false
  let mut clip_w = 0
  let mut clip_h = 0
  let mut clip_x = 0
  let mut clip_y = 0
  let mut snapshot_path = "../../__snapshots__/eval_ui_scroll.txt"
  let mut eval1_path = "../../__snapshots__/eval_ui_eval1.txt"
  let mut eval1_p5_path = "../../__snapshots__/eval_ui_eval1_p5.txt"
  let mut layout_path = "../../__snapshots__/eval_ui_layout.txt"
  let mut layout_p5_path = "../../__snapshots__/eval_ui_layout_p5.txt"
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
    if arg == "--p5" {
      run_p5 = true
    }
    if arg == "--eval1-p5" {
      run_eval1_p5 = true
    }
    if arg == "--layout-snapshot" {
      run_layout_snapshot = true
    }
    if arg == "--layout-snapshot-p5" {
      run_layout_snapshot_p5 = true
    }
    if arg == "--no-output" {
      show_output = false
    }
    if arg == "--full-output" {
      force_full_output = true
    }
    if arg == "--infer-layout" {
      infer_layout = true
    }
    if arg == "--compact-output" {
      clip_w = 120
      clip_h = 40
      clip_x = 0
      clip_y = 0
    }
    if arg == "--clip" && i + 2 < args.length() {
      clip_w = parse_arg_int(args[i + 1], clip_w)
      clip_h = parse_arg_int(args[i + 2], clip_h)
      i = i + 2
    }
    if arg == "--clip-offset" && i + 2 < args.length() {
      clip_x = parse_arg_int(args[i + 1], clip_x)
      clip_y = parse_arg_int(args[i + 2], clip_y)
      i = i + 2
    }
    if arg == "--snapshot-path" && i + 1 < args.length() {
      snapshot_path = args[i + 1]
      i = i + 1
    }
    if arg == "--eval1-path" && i + 1 < args.length() {
      eval1_path = args[i + 1]
      i = i + 1
    }
    if arg == "--eval1-p5-path" && i + 1 < args.length() {
      eval1_p5_path = args[i + 1]
      i = i + 1
    }
    if arg == "--layout-path" && i + 1 < args.length() {
      layout_path = args[i + 1]
      i = i + 1
    }
    if arg == "--layout-p5-path" && i + 1 < args.length() {
      layout_p5_path = args[i + 1]
      i = i + 1
    }
    i = i + 1
  }
  if run_eval1_p5 {
    snapshot_eval1_p5(eval1_p5_path)
  } else if run_eval1_snapshot {
    snapshot_eval1(eval1_path)
  } else if run_layout_snapshot_p5 {
    snapshot_layout(layout_p5_path, patterns_p5(), " (p5)")
  } else if run_layout_snapshot {
    snapshot_layout(layout_path, patterns(), "")
  } else if run_scroll_snapshot {
    snapshot_scroll(snapshot_path)
  } else if run_scroll {
    run_scroll_ui()
  } else {
    if run_p5 && show_output && !force_full_output && clip_w == 0 && clip_h == 0 {
      clip_w = 120
      clip_h = 40
      clip_x = 0
      clip_y = 0
    }
    let out_opts = {
      show_output,
      clip_w,
      clip_h,
      clip_x,
      clip_y,
      infer_layout,
    }
    let list = if run_p5 { patterns_p5() } else { patterns() }
    for pattern in list {
      run_pattern(pattern, out_opts)
    }
  }
}
