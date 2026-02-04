///|

///|
let esc : String = "\u001b"

///|
let status_rows : Int = 3

///|
let rect_count : Int = 48

///|
let image_sprite_count : Int = 3

///|
let pattern_asset_count : Int = 3

///|
let rect_move_stride : Int = 3

///|
let image_move_stride : Int = 2

///|
let image_crop_w : Int = 160

///|
let image_crop_h : Int = 120

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
struct ImageAssetEntry {
  id : Int
  asset : @image.ImageAsset
}

///|
struct DemoState {
  mut auto : Bool
  target_fps : Int
  mut tick : Int
  mut scroll_count : Int
  rects : Array[RectSprite]
  images : Array[ImageSprite]
  mut last_dirty_rects : Int
  mut last_dirty_images : Int
  mut last_dirty_total : Int
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
  let dirty_total = state.last_dirty_total.to_string()
  let dirty_rects = state.last_dirty_rects.to_string()
  let dirty_images = state.last_dirty_images.to_string()
  let line1 = "kitty rect demo (q: quit)"
  let line2 = "a: auto(\{auto_label}) n: step t: text-only s: scroll"
  let line3 = "fps=\{fps_label} rects=\{rect_label} images=\{image_label} dirty=\{dirty_total} r=\{dirty_rects} i=\{dirty_images} tick=\{state.tick}"
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
fn parse_env_int(name : String) -> Int? {
  match @sys.get_env_var(name) {
    Some(text) =>
      try @strconv.parse_int(text) catch {
        _ => None
      } noraise {
        value => Some(value)
      }
    None => None
  }
}

///|
fn load_custom_asset(base_id : Int) -> ImageAssetEntry? {
  match @sys.get_env_var("KITTY_IMAGE_PATH") {
    Some(path) =>
      if path.length() == 0 {
        None
      } else {
        match parse_env_int("KITTY_IMAGE_W") {
          Some(width) =>
            match parse_env_int("KITTY_IMAGE_H") {
              Some(height) =>
                if width <= 0 || height <= 0 {
                  None
                } else {
                  match @image.read_png_asset(path, width, height) {
                    Some(asset) => Some(ImageAssetEntry::{ id: base_id, asset })
                    None => None
                  }
                }
              None => None
            }
          None => None
        }
      }
    None => None
  }
}

///|
fn build_rect_assets(
  base_id : Int,
  palette : Array[(Int, Int, Int)],
) -> Array[ImageAssetEntry] {
  let total = if palette.length() <= 0 { 0 } else { palette.length() }
  let out : Array[ImageAssetEntry] = []
  for i in 0..<total {
    let (r, g, b) = palette[i]
    let bytes = solid_rgb(1, 1, r, g, b)
    let asset = @image.image_asset_rgb(1, 1, bytes)
    out.push(ImageAssetEntry::{ id: base_id + i, asset })
  }
  out
}

///|
fn build_pattern_assets(
  base_id : Int,
  count : Int,
  size : Int,
) -> Array[ImageAssetEntry] {
  let total = if count <= 0 { 0 } else { count }
  let out : Array[ImageAssetEntry] = []
  for i in 0..<total {
    let bytes = pattern_rgb(size, size, i + 1)
    let asset = @image.image_asset_rgb(size, size, bytes)
    out.push(ImageAssetEntry::{ id: base_id + i, asset })
  }
  out
}

///|
fn build_image_assets(
  base_id : Int,
  pattern_count : Int,
  pattern_size : Int,
) -> Array[ImageAssetEntry] {
  let out : Array[ImageAssetEntry] = []
  let mut next_id = base_id
  match load_custom_asset(next_id) {
    Some(entry) => {
      out.push(entry)
      next_id = next_id + 1
    }
    None => ()
  }
  let patterns = build_pattern_assets(next_id, pattern_count, pattern_size)
  for entry in patterns {
    out.push(entry)
  }
  out
}

///|
fn asset_ids(entries : Array[ImageAssetEntry]) -> Array[Int] {
  let out : Array[Int] = []
  for entry in entries {
    out.push(entry.id)
  }
  out
}

///|
fn transmit_assets(entries : Array[ImageAssetEntry]) -> String {
  let sb = StringBuilder::new()
  for entry in entries {
    let asset = entry.asset
    let cmds = match asset.format {
      @image.ImageFormat::Png =>
        kitty_transmit_png(entry.id, asset.payload_base64)
      @image.ImageFormat::Rgb =>
        kitty_transmit_rgb(
          entry.id,
          asset.width,
          asset.height,
          asset.payload_base64,
        )
    }
    for cmd in cmds {
      sb.write_string(cmd)
    }
  }
  sb.to_string()
}

///|
fn build_rects(
  count : Int,
  cols : Int,
  rows : Int,
  color_ids : Array[Int],
  placement_base : Int,
  move_stride : Int,
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
    let moving = move_stride <= 1 || i % move_stride != 0
    let vx = if moving { if i % 2 == 0 { 1 } else { -1 } } else { 0 }
    let vy = if moving { if i % 3 == 0 { 1 } else { -1 } } else { 0 }
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
fn build_image_crop(
  asset : @image.ImageAsset,
  crop_w : Int,
  crop_h : Int,
) -> @image.ImageRect? {
  let w = asset.width
  let h = asset.height
  if w <= 0 || h <= 0 {
    None
  } else {
    let cw = clamp(crop_w, 1, w)
    let ch = clamp(crop_h, 1, h)
    if cw == w && ch == h {
      None
    } else {
      Some(@image.center_rect(w, h, cw, ch))
    }
  }
}

///|
fn build_images(
  count : Int,
  cols : Int,
  rows : Int,
  assets : Array[ImageAssetEntry],
  placement_base : Int,
  image_cols : Int,
  image_rows : Int,
  crop_w : Int,
  crop_h : Int,
  move_stride : Int,
) -> Array[ImageSprite] {
  let total = if count <= 0 { 0 } else { count }
  let asset_total = assets.length()
  if asset_total == 0 || total == 0 {
    return []
  }
  let safe_cols = if cols <= 0 { 1 } else { cols }
  let safe_rows = if rows <= 0 { 1 } else { rows }
  let w = clamp(image_cols, 1, safe_cols)
  let h = clamp(image_rows, 1, safe_rows)
  let out : Array[ImageSprite] = []
  for i in 0..<total {
    let entry = assets[i % asset_total]
    let max_x = if safe_cols <= w { 0 } else { safe_cols - w }
    let max_y = if safe_rows <= h { 0 } else { safe_rows - h }
    let x = if max_x <= 0 { 0 } else { i * 13 % (max_x + 1) }
    let y = if max_y <= 0 { 0 } else { i * 17 % (max_y + 1) }
    let moving = move_stride <= 1 || i % move_stride != 0
    let vx = if moving { if i % 2 == 0 { 1 } else { -1 } } else { 0 }
    let vy = if moving { if i % 2 == 0 { -1 } else { 1 } } else { 0 }
    let crop = build_image_crop(entry.asset, crop_w, crop_h)
    let sprite = match crop {
      Some(rect) =>
        image_sprite_with_crop(
          entry.id,
          placement_base + i,
          x,
          y,
          w,
          h,
          rect,
          vx,
          vy,
        )
      None => image_sprite(entry.id, placement_base + i, x, y, w, h, vx, vy)
    }
    out.push(sprite)
  }
  out
}

///|
fn to_crop_rect(rect : @image.ImageRect) -> CropRect {
  CropRect::{ x: rect.x, y: rect.y, w: rect.w, h: rect.h }
}

///|
fn place_rect(rect : RectSprite, row : Int, col : Int) -> String {
  let sb = StringBuilder::new()
  sb.write_string(cursor_to(row + rect.y, col + rect.x))
  sb.write_string(
    kitty_place(
      id=rect.id,
      placement_id=rect.placement_id,
      cols=rect.w,
      rows=rect.h,
    ),
  )
  sb.to_string()
}

///|
fn place_image(image : ImageSprite, row : Int, col : Int) -> String {
  let head = cursor_to(row + image.y, col + image.x)
  match image.crop {
    Some(rect) => {
      let sb = StringBuilder::new()
      sb.write_string(head)
      sb.write_string(
        kitty_place(
          id=image.id,
          placement_id=image.placement_id,
          crop=to_crop_rect(rect),
          cols=image.cols,
          rows=image.rows,
        ),
      )
      sb.to_string()
    }
    None => {
      let sb = StringBuilder::new()
      sb.write_string(head)
      sb.write_string(
        kitty_place(
          id=image.id,
          placement_id=image.placement_id,
          cols=image.cols,
          rows=image.rows,
        ),
      )
      sb.to_string()
    }
  }
}

///|
fn render_rects(rects : Array[RectSprite], row : Int, col : Int) -> String {
  let sb = StringBuilder::new()
  for rect in rects {
    sb.write_string(place_rect(rect, row, col))
  }
  sb.to_string()
}

///|
fn render_images(images : Array[ImageSprite], row : Int, col : Int) -> String {
  let sb = StringBuilder::new()
  for image in images {
    sb.write_string(place_image(image, row, col))
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
fn step_scene(
  state : DemoState,
  cols : Int,
  rows : Int,
  row : Int,
  col : Int,
) -> String {
  let sb = StringBuilder::new()
  let mut dirty_rects = 0
  let mut dirty_images = 0
  for i in 0..<state.rects.length() {
    let prev = state.rects[i]
    let next = step_rect(prev, cols, rows)
    state.rects[i] = next
    if rect_changed(prev, next) {
      dirty_rects = dirty_rects + 1
      sb.write_string(place_rect(next, row, col))
    }
  }
  for i in 0..<state.images.length() {
    let prev = state.images[i]
    let next = step_image(prev, cols, rows)
    state.images[i] = next
    if image_changed(prev, next) {
      dirty_images = dirty_images + 1
      sb.write_string(place_image(next, row, col))
    }
  }
  state.tick = state.tick + 1
  state.last_dirty_rects = dirty_rects
  state.last_dirty_images = dirty_images
  state.last_dirty_total = dirty_rects + dirty_images
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
  let rect_assets = build_rect_assets(rect_base_id, rect_palette)
  let image_assets = build_image_assets(image_base_id, pattern_asset_count, 64)
  let rect_ids = asset_ids(rect_assets)
  let rects = build_rects(
    rect_count, draw_cols, draw_rows, rect_ids, rect_place_base, rect_move_stride,
  )
  let images = build_images(
    image_sprite_count, draw_cols, draw_rows, image_assets, image_place_base, 12,
    6, image_crop_w, image_crop_h, image_move_stride,
  )
  let state = DemoState::{
    auto: false,
    target_fps: 60,
    tick: 0,
    scroll_count: 0,
    rects,
    images,
    last_dirty_rects: 0,
    last_dirty_images: 0,
    last_dirty_total: 0,
  }
  @tui.print_raw(hide_cursor() + clear_screen() + cursor_to(1, 1))
  @tui.enable_raw_mode()
  @tui.print_raw(transmit_assets(rect_assets))
  @tui.print_raw(transmit_assets(image_assets))
  state.last_dirty_rects = state.rects.length()
  state.last_dirty_images = state.images.length()
  state.last_dirty_total = state.last_dirty_rects + state.last_dirty_images
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
                let diff = step_scene(
                  state, draw_cols, draw_rows, draw_row, draw_col,
                )
                if diff.length() > 0 {
                  @tui.print_raw(diff)
                }
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
      let diff = step_scene(state, draw_cols, draw_rows, draw_row, draw_col)
      if diff.length() > 0 {
        @tui.print_raw(diff)
      }
      need_status = true
    }
    if event.is_char('t') {
      state.tick = state.tick + 1
      state.last_dirty_rects = 0
      state.last_dirty_images = 0
      state.last_dirty_total = 0
      need_status = true
    }
    if event.is_char('s') {
      state.tick = state.tick + 1
      state.last_dirty_rects = 0
      state.last_dirty_images = 0
      state.last_dirty_total = 0
      @tui.print_raw(scroll_line(state, height))
      need_status = true
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
