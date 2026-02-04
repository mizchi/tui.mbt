///|

///|
let esc : String = "\u001b"

///|
let status_rows : Int = 3

///|
let rect_count : Int = 48

///|
let image_count : Int = 3

///|
fn cursor_to(row : Int, col : Int) -> String {
  "\{esc}[\{row};\{col}H"
}

///|
fn clear_line() -> String {
  "\{esc}[2K"
}

///|
fn clear_screen() -> String {
  "\{esc}[2J"
}

///|
fn hide_cursor() -> String {
  "\{esc}[?25l"
}

///|
fn show_cursor() -> String {
  "\{esc}[?25h"
}

///|
struct DemoState {
  mut auto : Bool
  target_fps : Int
  mut tick : Int
  mut scroll_count : Int
  rects : Array[RectSprite]
  images : Array[ImageSprite]
}

///|
fn clamp(value : Int, min_value : Int, max_value : Int) -> Int {
  if value < min_value {
    min_value
  } else if value > max_value {
    max_value
  } else {
    value
  }
}

///|
fn render_status(state : DemoState) -> String {
  let auto_label = if state.auto { "on" } else { "off" }
  let fps_label = state.target_fps.to_string()
  let rect_label = state.rects.length().to_string()
  let image_label = state.images.length().to_string()
  let line1 = "kitty rect demo (q: quit)"
  let line2 = "a: auto(\{auto_label}) n: step t: text-only s: scroll"
  let line3 = "fps=\{fps_label} rects=\{rect_label} images=\{image_label} tick=\{state.tick}"
  let lines = [line1, line2, line3]
  let sb = StringBuilder::new()
  for i, line in lines {
    sb.write_string(cursor_to(i + 1, 1))
    sb.write_string(clear_line())
    sb.write_string(line)
  }
  sb.to_string()
}

///|
fn scroll_line(state : DemoState, height : Int) -> String {
  state.scroll_count = state.scroll_count + 1
  let line = "scroll \{state.scroll_count}"
  cursor_to(height, 1) + clear_line() + line + "\n"
}

///|
fn build_ids(base_id : Int, count : Int) -> Array[Int] {
  let total = if count <= 0 { 0 } else { count }
  let out : Array[Int] = []
  for i in 0..<total {
    out.push(base_id + i)
  }
  out
}

///|
fn build_rects(
  count : Int,
  cols : Int,
  rows : Int,
  color_ids : Array[Int],
  placement_base : Int,
) -> Array[RectSprite] {
  let total = if count <= 0 { 0 } else { count }
  let safe_cols = if cols <= 0 { 1 } else { cols }
  let safe_rows = if rows <= 0 { 1 } else { rows }
  let min_w = if safe_cols <= 1 { 1 } else { 2 }
  let max_w = clamp(8, min_w, safe_cols)
  let min_h = 1
  let max_h = clamp(4, min_h, safe_rows)
  let w_range = if max_w >= min_w { max_w - min_w + 1 } else { 1 }
  let h_range = if max_h >= min_h { max_h - min_h + 1 } else { 1 }
  let color_total = color_ids.length()
  let out : Array[RectSprite] = []
  for i in 0..<total {
    let w = min_w + i * 3 % w_range
    let h = min_h + i * 5 % h_range
    let max_x = if safe_cols <= w { 0 } else { safe_cols - w }
    let max_y = if safe_rows <= h { 0 } else { safe_rows - h }
    let x = if max_x <= 0 { 0 } else { i * 7 % (max_x + 1) }
    let y = if max_y <= 0 { 0 } else { i * 11 % (max_y + 1) }
    let vx = if i % 2 == 0 { 1 } else { -1 }
    let vy = if i % 3 == 0 { 1 } else { -1 }
    let color_id = if color_total == 0 { 0 } else { color_ids[i % color_total] }
    out.push(RectSprite::{
      id: color_id,
      placement_id: placement_base + i,
      x,
      y,
      w,
      h,
      vx,
      vy,
    })
  }
  out
}

///|
fn build_images(
  count : Int,
  cols : Int,
  rows : Int,
  image_ids : Array[Int],
  placement_base : Int,
  image_cols : Int,
  image_rows : Int,
) -> Array[ImageSprite] {
  let total = if count <= 0 { 0 } else { count }
  let safe_cols = if cols <= 0 { 1 } else { cols }
  let safe_rows = if rows <= 0 { 1 } else { rows }
  let w = clamp(image_cols, 1, safe_cols)
  let h = clamp(image_rows, 1, safe_rows)
  let id_total = image_ids.length()
  let out : Array[ImageSprite] = []
  for i in 0..<total {
    let max_x = if safe_cols <= w { 0 } else { safe_cols - w }
    let max_y = if safe_rows <= h { 0 } else { safe_rows - h }
    let x = if max_x <= 0 { 0 } else { i * 13 % (max_x + 1) }
    let y = if max_y <= 0 { 0 } else { i * 17 % (max_y + 1) }
    let vx = if i % 2 == 0 { 1 } else { -1 }
    let vy = if i % 2 == 0 { -1 } else { 1 }
    let id = if id_total == 0 { 0 } else { image_ids[i % id_total] }
    out.push(ImageSprite::{
      id,
      placement_id: placement_base + i,
      x,
      y,
      cols: w,
      rows: h,
      vx,
      vy,
    })
  }
  out
}

///|
fn render_rects(rects : Array[RectSprite], row : Int, col : Int) -> String {
  let sb = StringBuilder::new()
  for rect in rects {
    sb.write_string(cursor_to(row + rect.y, col + rect.x))
    sb.write_string(
      kitty_place(
        id=rect.id,
        placement_id=rect.placement_id,
        cols=rect.w,
        rows=rect.h,
      ),
    )
  }
  sb.to_string()
}

///|
fn render_images(images : Array[ImageSprite], row : Int, col : Int) -> String {
  let sb = StringBuilder::new()
  for image in images {
    sb.write_string(cursor_to(row + image.y, col + image.x))
    sb.write_string(
      kitty_place(
        id=image.id,
        placement_id=image.placement_id,
        cols=image.cols,
        rows=image.rows,
      ),
    )
  }
  sb.to_string()
}

///|
fn render_scene(state : DemoState, row~ : Int, col~ : Int) -> String {
  let sb = StringBuilder::new()
  sb.write_string(render_rects(state.rects, row, col))
  sb.write_string(render_images(state.images, row, col))
  sb.to_string()
}

///|
fn step_scene(state : DemoState, cols : Int, rows : Int) -> Unit {
  for i in 0..<state.rects.length() {
    state.rects[i] = step_rect(state.rects[i], cols, rows)
  }
  for i in 0..<state.images.length() {
    state.images[i] = step_image(state.images[i], cols, rows)
  }
  state.tick = state.tick + 1
}

///|
fn transmit_palette(base_id : Int, colors : Array[(Int, Int, Int)]) -> String {
  let sb = StringBuilder::new()
  for i, color in colors {
    let id = base_id + i
    let (r, g, b) = color
    let bytes = solid_rgb(1, 1, r, g, b)
    let payload = base64_encode(bytes)
    let cmds = kitty_transmit_rgb(id, 1, 1, payload)
    for cmd in cmds {
      sb.write_string(cmd)
    }
  }
  sb.to_string()
}

///|
fn transmit_patterns(base_id : Int, count : Int, size : Int) -> String {
  let total = if count <= 0 { 0 } else { count }
  let sb = StringBuilder::new()
  for i in 0..<total {
    let id = base_id + i
    let bytes = pattern_rgb(size, size, i + 1)
    let payload = base64_encode(bytes)
    let cmds = kitty_transmit_rgb(id, size, size, payload)
    for cmd in cmds {
      sb.write_string(cmd)
    }
  }
  sb.to_string()
}

///|
async fn main {
  let (width, height) = @tui.get_terminal_size()
  let draw_cols = if width <= 0 { 1 } else { width }
  let draw_rows = if height > status_rows { height - status_rows } else { 1 }
  let draw_row = status_rows + 1
  let draw_col = 1
  let rect_palette : Array[(Int, Int, Int)] = [
    (239, 71, 111),
    (255, 209, 102),
    (6, 214, 160),
    (17, 138, 178),
  ]
  let rect_base_id = 900
  let image_base_id = 950
  let rect_place_base = 2000
  let image_place_base = 3000
  let rect_ids = build_ids(rect_base_id, rect_palette.length())
  let image_ids = build_ids(image_base_id, image_count)
  let rects = build_rects(
    rect_count, draw_cols, draw_rows, rect_ids, rect_place_base,
  )
  let images = build_images(
    image_count, draw_cols, draw_rows, image_ids, image_place_base, 12, 6,
  )
  let state = DemoState::{
    auto: false,
    target_fps: 60,
    tick: 0,
    scroll_count: 0,
    rects,
    images,
  }
  @tui.print_raw(hide_cursor() + clear_screen() + cursor_to(1, 1))
  @tui.enable_raw_mode()
  @tui.print_raw(transmit_palette(rect_base_id, rect_palette))
  @tui.print_raw(transmit_patterns(image_base_id, image_count, 64))
  @tui.print_raw(render_scene(state, row=draw_row, col=draw_col))
  @tui.print_raw(render_status(state))
  let fps = if state.target_fps <= 0 { 30 } else { state.target_fps }
  let ticker_interval_ms = 1000 / fps
  let mut ticker_id : Int? = None
  let mut running = true
  while running {
    let key = @tui.read_key()
    if key.length() == 0 {
      continue
    }
    let event = @tui.parse_input(key)
    if event.is_quit() {
      running = false
      continue
    }
    let mut need_scene = false
    let mut need_status = false
    match event.is_arrow() {
      Some(_) => ()
      None => ()
    }
    if event.is_char('a') {
      state.auto = !state.auto
      if state.auto {
        if ticker_id is None {
          ticker_id = Some(
            @io.start_render_ticker(ticker_interval_ms, fn() {
              if state.auto {
                step_scene(state, draw_cols, draw_rows)
                @tui.print_raw(render_scene(state, row=draw_row, col=draw_col))
                @tui.print_raw(render_status(state))
              }
            }),
          )
        }
      } else {
        match ticker_id {
          Some(id) => @io.stop_render_ticker(id)
          None => ()
        }
        ticker_id = None
      }
      need_status = true
    }
    if event.is_char('n') {
      step_scene(state, draw_cols, draw_rows)
      need_scene = true
      need_status = true
    }
    if event.is_char('t') {
      state.tick = state.tick + 1
      need_status = true
    }
    if event.is_char('s') {
      state.tick = state.tick + 1
      @tui.print_raw(scroll_line(state, height))
      need_status = true
    }
    if need_scene {
      @tui.print_raw(render_scene(state, row=draw_row, col=draw_col))
    }
    if need_status {
      @tui.print_raw(render_status(state))
    }
  }
  match ticker_id {
    Some(id) => @io.stop_render_ticker(id)
    None => ()
  }
  @tui.print_raw(kitty_delete_all_visible())
  @tui.print_raw(show_cursor())
  @tui.cleanup_stdin()
}
