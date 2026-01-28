///|
using @vnode {type TuiNode, column, row, text, vspace, view}

///|
enum Tile {
  Wall
  Floor
}

///|
struct Pos {
  x : Int
  y : Int
}

///|
struct GameState {
  map_width : Int
  map_height : Int
  tiles : Array[Array[Tile]]
  player : Pos
  enemies : Array[Pos]
  items : Array[Item]
  inventory : Array[ItemKind]
  stairs : Pos
  hp : Int
  turn : Int
  log : Array[String]
  explored : Array[Array[Bool]]
  game_over : Bool
  win : Bool
  seed : Int
}

///|
enum PlayerAction {
  Move(Int, Int)
  Wait
  UsePotion
}

///|
let view_radius = 8

///|
let max_hp = 8

///|
enum ItemKind {
  Relic
  Potion
}

///|
struct Item {
  pos : Pos
  kind : ItemKind
}

///|
fn max_int(a : Int, b : Int) -> Int {
  if a > b {
    a
  } else {
    b
  }
}

///|
fn rebuild_state(
  state : GameState,
  player : Pos,
  enemies : Array[Pos],
  hp : Int,
  turn : Int,
  log : Array[String],
  explored : Array[Array[Bool]],
  items : Array[Item],
  inventory : Array[ItemKind],
  stairs : Pos,
  game_over : Bool,
  win : Bool,
  seed : Int,
) -> GameState {
  GameState::{
    map_width: state.map_width,
    map_height: state.map_height,
    tiles: state.tiles,
    player,
    enemies,
    items,
    inventory,
    stairs,
    hp,
    turn,
    log,
    explored,
    game_over,
    win,
    seed,
  }
}

///|
fn next_seed(seed : Int) -> Int {
  let next = (seed * 1103515245 + 12345) % 2147483647
  if next < 0 {
    -next
  } else {
    next
  }
}

///|
fn rand_range(seed : Int, max : Int) -> (Int, Int) {
  if max <= 0 {
    (0, seed)
  } else {
    let next = next_seed(seed)
    (next % max, next)
  }
}

///|
fn is_floor(tile : Tile) -> Bool {
  match tile {
    Floor => true
    _ => false
  }
}

///|
fn make_map(width : Int, height : Int, seed : Int) -> (Array[Array[Tile]], Int) {
  let tiles = Array::new()
  let mut s = seed
  for y in 0..<height {
    let row = Array::new()
    for x in 0..<width {
      let is_border = x == 0 || y == 0 || x == width - 1 || y == height - 1
      if is_border {
        row.push(Wall)
      } else {
        let (r, s2) = rand_range(s, 100)
        s = s2
        if r < 12 {
          row.push(Wall)
        } else {
          row.push(Floor)
        }
      }
    }
    tiles.push(row)
  }
  let center_x = width / 2
  let center_y = height / 2
  tiles[center_y][center_x] = Floor
  (tiles, s)
}

///|
fn pos_eq(a : Pos, b : Pos) -> Bool {
  a.x == b.x && a.y == b.y
}

///|
fn pos_taken(list : Array[Pos], x : Int, y : Int) -> Bool {
  for i in 0..<list.length() {
    let p = list[i]
    if p.x == x && p.y == y {
      return true
    }
  }
  false
}

///|
fn item_index_at(items : Array[Item], x : Int, y : Int) -> Int? {
  for i in 0..<items.length() {
    let item = items[i]
    if item.pos.x == x && item.pos.y == y {
      return Some(i)
    }
  }
  None
}

///|
fn item_symbol(kind : ItemKind) -> Char {
  match kind {
    Relic => '*'
    Potion => '!'
  }
}

///|
fn item_color(kind : ItemKind) -> String {
  match kind {
    Relic => "magenta"
    Potion => "green"
  }
}

///|
fn item_name(kind : ItemKind) -> String {
  match kind {
    Relic => "relic"
    Potion => "potion"
  }
}

///|
fn count_item(inventory : Array[ItemKind], kind : ItemKind) -> Int {
  let mut count = 0
  for i in 0..<inventory.length() {
    match kind {
      Relic =>
        match inventory[i] {
          Relic => count = count + 1
          _ => ()
        }
      Potion =>
        match inventory[i] {
          Potion => count = count + 1
          _ => ()
        }
    }
  }
  count
}

///|
fn has_item(inventory : Array[ItemKind], kind : ItemKind) -> Bool {
  count_item(inventory, kind) > 0
}

///|
fn remove_item(
  inventory : Array[ItemKind],
  kind : ItemKind,
) -> (Array[ItemKind], Bool) {
  let next = Array::new()
  let mut removed = false
  for i in 0..<inventory.length() {
    let item = inventory[i]
    let matches = match kind {
      Relic =>
        match item {
          Relic => true
          _ => false
        }
      Potion =>
        match item {
          Potion => true
          _ => false
        }
    }
    if matches && !removed {
      removed = true
    } else {
      next.push(item)
    }
  }
  (next, removed)
}

///|

///|
fn in_bounds(state : GameState, x : Int, y : Int) -> Bool {
  x >= 0 && y >= 0 && x < state.map_width && y < state.map_height
}

///|
fn is_blocking(state : GameState, x : Int, y : Int) -> Bool {
  match state.tiles[y][x] {
    Wall => true
    Floor => false
  }
}

///|
fn blocks_light(state : GameState, x : Int, y : Int) -> Bool {
  if !in_bounds(state, x, y) {
    true
  } else {
    is_blocking(state, x, y)
  }
}

///|
fn cast_light(
  state : GameState,
  grid : Array[Array[Bool]],
  cx : Int,
  cy : Int,
  row : Int,
  start : Double,
  end : Double,
  radius : Int,
  xx : Int,
  xy : Int,
  yx : Int,
  yy : Int,
) -> Unit {
  if start < end {
    return
  }
  let radius2 = radius * radius
  let mut start_slope = start
  let mut row_i = row
  while row_i <= radius {
    let mut dx = -row_i
    let dy = -row_i
    let mut blocked = false
    let mut new_start = start_slope
    while dx <= 0 {
      let x = cx + dx * xx + dy * xy
      let y = cy + dx * yx + dy * yy
      let l_slope = (dx.to_double() - 0.5) / (dy.to_double() + 0.5)
      let r_slope = (dx.to_double() + 0.5) / (dy.to_double() - 0.5)
      if start_slope < r_slope {
        dx = dx + 1
        continue
      }
      if end > l_slope {
        break
      }
      if dx * dx + dy * dy <= radius2 && in_bounds(state, x, y) {
        grid[y][x] = true
      }
      if blocked {
        if blocks_light(state, x, y) {
          new_start = r_slope
          dx = dx + 1
          continue
        } else {
          blocked = false
          start_slope = new_start
        }
      } else if blocks_light(state, x, y) && row_i < radius {
        blocked = true
        cast_light(
          state,
          grid,
          cx,
          cy,
          row_i + 1,
          start_slope,
          l_slope,
          radius,
          xx,
          xy,
          yx,
          yy,
        )
        new_start = r_slope
      }
      dx = dx + 1
    }
    if blocked {
      break
    }
    row_i = row_i + 1
  }
}

///|
fn make_bool_grid(
  width : Int,
  height : Int,
  value : Bool,
) -> Array[Array[Bool]] {
  let grid = Array::new()
  for _y in 0..<height {
    let row = Array::new()
    for _x in 0..<width {
      row.push(value)
    }
    grid.push(row)
  }
  grid
}

///|
fn compute_visibility(state : GameState, radius : Int) -> Array[Array[Bool]] {
  let px = state.player.x
  let py = state.player.y
  let grid = make_bool_grid(state.map_width, state.map_height, false)
  if in_bounds(state, px, py) {
    grid[py][px] = true
  }
  let transforms = [
    (1, 0, 0, 1),
    (0, 1, 1, 0),
    (0, 1, -1, 0),
    (1, 0, 0, -1),
    (-1, 0, 0, -1),
    (0, -1, -1, 0),
    (0, -1, 1, 0),
    (-1, 0, 0, 1),
  ]
  for i in 0..<transforms.length() {
    let (xx, xy, yx, yy) = transforms[i]
    cast_light(state, grid, px, py, 1, 1.0, 0.0, radius, xx, xy, yx, yy)
  }
  grid
}

///|
fn merge_explored(
  explored : Array[Array[Bool]],
  visible : Array[Array[Bool]],
) -> Array[Array[Bool]] {
  let grid = Array::new()
  for y in 0..<explored.length() {
    let row = Array::new()
    let exp_row = explored[y]
    let vis_row = visible[y]
    for x in 0..<exp_row.length() {
      row.push(exp_row[x] || vis_row[x])
    }
    grid.push(row)
  }
  grid
}

///|
fn apply_visibility(state : GameState, radius : Int) -> GameState {
  let visible = compute_visibility(state, radius)
  let explored = merge_explored(state.explored, visible)
  rebuild_state(
    state,
    state.player,
    state.enemies,
    state.hp,
    state.turn,
    state.log,
    explored,
    state.items,
    state.inventory,
    state.stairs,
    state.game_over,
    state.win,
    state.seed,
  )
}

///|
fn find_random_floor(tiles : Array[Array[Tile]], seed : Int) -> (Pos, Int) {
  let height = tiles.length()
  let width = if height == 0 { 0 } else { tiles[0].length() }
  let mut s = seed
  let mut x = 1
  let mut y = 1
  let mut tries = 0
  while tries < 200 {
    let (rx, s1) = rand_range(s, max_int(1, width - 2))
    let (ry, s2) = rand_range(s1, max_int(1, height - 2))
    s = s2
    x = rx + 1
    y = ry + 1
    if is_floor(tiles[y][x]) {
      return (Pos::{ x, y }, s)
    }
    tries = tries + 1
  }
  (Pos::{ x, y }, s)
}

///|
fn find_random_floor_avoiding(
  tiles : Array[Array[Tile]],
  seed : Int,
  avoid : Array[Pos],
) -> (Pos, Int) {
  let height = tiles.length()
  let width = if height == 0 { 0 } else { tiles[0].length() }
  let mut s = seed
  let mut x = 1
  let mut y = 1
  let mut tries = 0
  while tries < 200 {
    let (rx, s1) = rand_range(s, max_int(1, width - 2))
    let (ry, s2) = rand_range(s1, max_int(1, height - 2))
    s = s2
    x = rx + 1
    y = ry + 1
    if is_floor(tiles[y][x]) && !pos_taken(avoid, x, y) {
      return (Pos::{ x, y }, s)
    }
    tries = tries + 1
  }
  (Pos::{ x, y }, s)
}

///|
fn push_log(log : Array[String], msg : String) -> Array[String] {
  let next = log.copy()
  next.push(msg)
  if next.length() > 6 {
    let _ = next.remove(0)

  }
  next
}

///|
fn spawn_enemies(
  tiles : Array[Array[Tile]],
  seed : Int,
  count : Int,
  player : Pos,
) -> (Array[Pos], Int) {
  let enemies = Array::new()
  let mut s = seed
  let mut i = 0
  while i < count {
    let (pos, s2) = find_random_floor(tiles, s)
    s = s2
    if !pos_eq(pos, player) && !pos_taken(enemies, pos.x, pos.y) {
      enemies.push(pos)
      i = i + 1
    }
  }
  (enemies, s)
}

///|
fn spawn_items(
  tiles : Array[Array[Tile]],
  seed : Int,
  player : Pos,
  enemies : Array[Pos],
  stairs : Pos,
) -> (Array[Item], Int) {
  let items = Array::new()
  let mut s = seed
  let avoid0 = enemies.copy()
  avoid0.push(player)
  avoid0.push(stairs)
  let (relic_pos, s1) = find_random_floor_avoiding(tiles, s, avoid0)
  s = s1
  items.push(Item::{ pos: relic_pos, kind: Relic })
  let avoid = avoid0.copy()
  avoid.push(relic_pos)
  let mut i = 0
  while i < 3 {
    let (pos, s2) = find_random_floor_avoiding(tiles, s, avoid)
    s = s2
    items.push(Item::{ pos, kind: Potion })
    avoid.push(pos)
    i = i + 1
  }
  (items, s)
}

///|
fn calc_map_width(width : Int, panel_width : Int) -> Int {
  let base = if width > panel_width + 6 {
    width - panel_width - 6
  } else {
    width - 6
  }
  max_int(10, base)
}

///|
fn calc_map_height(height : Int) -> Int {
  max_int(8, height - 8)
}

///|
fn init_game(width : Int, height : Int, seed : Int) -> GameState {
  let panel_width = 24
  let map_width = calc_map_width(width, panel_width)
  let map_height = calc_map_height(height)
  let (tiles, s1) = make_map(map_width, map_height, seed)
  let (player, s2) = find_random_floor(tiles, s1)
  let (enemies, s3) = spawn_enemies(tiles, s2, 5, player)
  let avoid0 = enemies.copy()
  avoid0.push(player)
  let (stairs, s4) = find_random_floor_avoiding(tiles, s3, avoid0)
  let (items, s5) = spawn_items(tiles, s4, player, enemies, stairs)
  let log = ["Welcome to Crater Rogue.", "Move with arrows or WASD. '.' waits."]
  let explored = make_bool_grid(map_width, map_height, false)
  let inventory = Array::new()
  let base = GameState::{
    map_width,
    map_height,
    tiles,
    player,
    enemies,
    items,
    inventory,
    stairs,
    hp: 5,
    turn: 0,
    log,
    explored,
    game_over: false,
    win: false,
    seed: s5,
  }
  apply_visibility(base, view_radius)
}

///|
fn is_walkable(state : GameState, x : Int, y : Int) -> Bool {
  if x < 0 || y < 0 || x >= state.map_width || y >= state.map_height {
    false
  } else {
    is_floor(state.tiles[y][x])
  }
}

///|
fn enemy_index_at(enemies : Array[Pos], x : Int, y : Int) -> Int? {
  for i in 0..<enemies.length() {
    let p = enemies[i]
    if p.x == x && p.y == y {
      return Some(i)
    }
  }
  None
}

///|
fn try_player_move(state : GameState, dx : Int, dy : Int) -> (GameState, Bool) {
  let nx = state.player.x + dx
  let ny = state.player.y + dy
  if !is_walkable(state, nx, ny) {
    (state, false)
  } else {
    match enemy_index_at(state.enemies, nx, ny) {
      Some(index) => {
        let enemies = state.enemies.copy()
        let _ = enemies.remove(index)
        let log = push_log(state.log, "You hit the goblin.")
        (
          rebuild_state(
            state,
            state.player,
            enemies,
            state.hp,
            state.turn,
            log,
            state.explored,
            state.items,
            state.inventory,
            state.stairs,
            state.game_over,
            state.win,
            state.seed,
          ),
          true,
        )
      }
      None => {
        let next_player = Pos::{ x: nx, y: ny }
        let mut log = state.log
        let items = state.items.copy()
        let inventory = state.inventory.copy()
        let mut game_over = state.game_over
        let mut win = state.win
        match item_index_at(state.items, nx, ny) {
          Some(index) => {
            let item = state.items[index]
            let _ = items.remove(index)
            inventory.push(item.kind)
            log = push_log(log, "You pick up a " + item_name(item.kind) + ".")
          }
          None => ()
        }
        if pos_eq(next_player, state.stairs) {
          if has_item(inventory, Relic) {
            game_over = true
            win = true
            log = push_log(log, "You descend the stairs. Victory!")
          } else {
            log = push_log(log, "The stairs are locked. Find the relic.")
          }
        }
        (
          rebuild_state(
            state,
            next_player,
            state.enemies,
            state.hp,
            state.turn,
            log,
            state.explored,
            items,
            inventory,
            state.stairs,
            game_over,
            win,
            state.seed,
          ),
          true,
        )
      }
    }
  }
}

///|
fn advance_enemies(state : GameState) -> GameState {
  let enemies = Array::new()
  let mut s = state.seed
  let mut log = state.log
  let mut hp = state.hp
  let mut game_over = state.game_over
  let mut win = state.win
  for i in 0..<state.enemies.length() {
    let enemy = state.enemies[i]
    let (dir, s2) = rand_range(s, 4)
    s = s2
    let (dx, dy) = match dir {
      0 => (-1, 0)
      1 => (1, 0)
      2 => (0, -1)
      _ => (0, 1)
    }
    let nx = enemy.x + dx
    let ny = enemy.y + dy
    if nx == state.player.x && ny == state.player.y {
      hp = hp - 1
      log = push_log(log, "Goblin hits you!")
      enemies.push(enemy)
    } else if is_walkable(state, nx, ny) && !pos_taken(enemies, nx, ny) {
      enemies.push(Pos::{ x: nx, y: ny })
    } else {
      enemies.push(enemy)
    }
  }
  if hp <= 0 {
    log = push_log(log, "You died. Press q to quit.")
    game_over = true
    win = false
  }
  rebuild_state(
    state,
    state.player,
    enemies,
    hp,
    state.turn,
    log,
    state.explored,
    state.items,
    state.inventory,
    state.stairs,
    game_over,
    win,
    s,
  )
}

///|
fn action_from_key(key_event : @tui.KeyEvent) -> PlayerAction? {
  match key_event {
    @tui.KeyEvent::Char('w', _) => Some(PlayerAction::Move(0, -1))
    @tui.KeyEvent::Char('k', _) => Some(PlayerAction::Move(0, -1))
    @tui.KeyEvent::Char('s', _) => Some(PlayerAction::Move(0, 1))
    @tui.KeyEvent::Char('j', _) => Some(PlayerAction::Move(0, 1))
    @tui.KeyEvent::Char('a', _) => Some(PlayerAction::Move(-1, 0))
    @tui.KeyEvent::Char('h', _) => Some(PlayerAction::Move(-1, 0))
    @tui.KeyEvent::Char('d', _) => Some(PlayerAction::Move(1, 0))
    @tui.KeyEvent::Char('l', _) => Some(PlayerAction::Move(1, 0))
    @tui.KeyEvent::Special(@tui.SpecialKey::Up, _) =>
      Some(PlayerAction::Move(0, -1))
    @tui.KeyEvent::Special(@tui.SpecialKey::Down, _) =>
      Some(PlayerAction::Move(0, 1))
    @tui.KeyEvent::Special(@tui.SpecialKey::Left, _) =>
      Some(PlayerAction::Move(-1, 0))
    @tui.KeyEvent::Special(@tui.SpecialKey::Right, _) =>
      Some(PlayerAction::Move(1, 0))
    @tui.KeyEvent::Char('.', _) => Some(PlayerAction::Wait)
    @tui.KeyEvent::Char(' ', _) => Some(PlayerAction::Wait)
    @tui.KeyEvent::Char('p', _) => Some(PlayerAction::UsePotion)
    _ => None
  }
}

///|
fn use_potion(state : GameState) -> (GameState, Bool) {
  let (inventory, removed) = remove_item(state.inventory, Potion)
  if removed {
    let mut hp = state.hp + 2
    if hp > max_hp {
      hp = max_hp
    }
    let log = push_log(state.log, "You drink a potion.")
    (
      rebuild_state(
        state,
        state.player,
        state.enemies,
        hp,
        state.turn,
        log,
        state.explored,
        state.items,
        inventory,
        state.stairs,
        state.game_over,
        state.win,
        state.seed,
      ),
      true,
    )
  } else {
    let log = push_log(state.log, "No potions.")
    (
      rebuild_state(
        state,
        state.player,
        state.enemies,
        state.hp,
        state.turn,
        log,
        state.explored,
        state.items,
        inventory,
        state.stairs,
        state.game_over,
        state.win,
        state.seed,
      ),
      true,
    )
  }
}

///|
fn apply_action(state : GameState, action : PlayerAction) -> (GameState, Bool) {
  match action {
    PlayerAction::Wait =>
      (
        rebuild_state(
          state,
          state.player,
          state.enemies,
          state.hp,
          state.turn,
          push_log(state.log, "You wait."),
          state.explored,
          state.items,
          state.inventory,
          state.stairs,
          state.game_over,
          state.win,
          state.seed,
        ),
        true,
      )
    PlayerAction::UsePotion => use_potion(state)
    PlayerAction::Move(dx, dy) => try_player_move(state, dx, dy)
  }
}

///|
fn render_map_nodes(state : GameState) -> Array[TuiNode] {
  let rows = Array::new()
  let visible = compute_visibility(state, view_radius)
  for y in 0..<state.map_height {
    let row_nodes = Array::new()
    let vis_row = visible[y]
    let exp_row = state.explored[y]
    for x in 0..<state.map_width {
      let is_visible = vis_row[x]
      let is_explored = exp_row[x]
      let mut ch = ' '
      let mut color = "rgb(30,30,30)"
      if is_visible {
        if state.player.x == x && state.player.y == y {
          ch = '@'
          color = "yellow"
        } else {
          match enemy_index_at(state.enemies, x, y) {
            Some(_) => {
              ch = 'g'
              color = "red"
            }
            None =>
              match item_index_at(state.items, x, y) {
                Some(index) => {
                  let item = state.items[index]
                  ch = item_symbol(item.kind)
                  color = item_color(item.kind)
                }
                None =>
                  if pos_eq(state.stairs, Pos::{ x, y }) {
                    ch = '>'
                    color = "cyan"
                  } else {
                    match state.tiles[y][x] {
                      Wall => {
                        ch = '#'
                        color = "rgb(160,160,160)"
                      }
                      Floor => {
                        ch = '.'
                        color = "rgb(90,90,90)"
                      }
                    }
                  }
              }
          }
        }
      } else if is_explored {
        match state.tiles[y][x] {
          Wall => {
            ch = '#'
            color = "rgb(70,70,70)"
          }
          Floor => {
            ch = '.'
            color = "rgb(50,50,50)"
          }
        }
      }
      row_nodes.push(text(ch.to_string(), fg=color))
    }
    rows.push(row(gap=0.0, row_nodes))
  }
  rows
}

///|
fn render_game_ui(width : Int, height : Int, state : GameState) -> TuiNode {
  if width < 50 || height < 18 {
    return view(
      width=width.to_double(),
      height=height.to_double(),
      border="rounded",
      border_color="red",
      [
        row(justify="center", [text("Terminal too small", fg="red", bold=true)]),
        row(justify="center", [text("Resize to at least 50x18.")]),
      ],
    )
  }
  let map_nodes = render_map_nodes(state)
  let enemy_count = state.enemies.length()
  let hp_color = if state.hp <= 2 { "red" } else { "green" }
  let relic_count = count_item(state.inventory, Relic)
  let potion_count = count_item(state.inventory, Potion)
  let relic_status = if relic_count > 0 { "Yes" } else { "No" }
  let outcome_color = if state.win { "green" } else { "red" }
  let panel_width = 24
  view(
    width=width.to_double(),
    height=height.to_double(),
    border="rounded",
    border_color="cyan",
    padding=1.0,
    [
      row(justify="space-between", [
        text("Crater Rogue", fg="yellow", bold=true),
        text("Turn: " + state.turn.to_string()),
      ]),
      row(flex_grow=1.0, gap=2.0, [
        view(flex_grow=1.0, border="single", border_color="rgb(96,96,96)", [
          column(gap=0.0, map_nodes),
        ]),
        view(
          width=panel_width.to_double(),
          border="single",
          border_color="rgb(96,96,96)",
          padding=1.0,
          [
            text("Status", bold=true),
            text("HP: " + state.hp.to_string(), fg=hp_color),
            text("Enemies: " + enemy_count.to_string()),
            text("Relic: " + relic_status),
            text("Potions: " + potion_count.to_string()),
            text("Stairs: >"),
            if state.game_over {
              text(
                if state.win {
                  "Victory!"
                } else {
                  "Defeat..."
                },
                fg=outcome_color,
                bold=true,
              )
            } else {
              vspace(0.0)
            },
            vspace(1.0),
            text("Log", bold=true),
            column(gap=0.0, state.log.map(fn(line) { text(line) })),
          ],
        ),
      ]),
      row(justify="center", [
        text(
          "Move: WASD/Arrows  Wait: .  Potion: p  Relic: *  Stairs: >  Quit: q",
          fg="rgb(128,128,128)",
        ),
      ]),
    ],
  )
}

///|
fn handle_key(
  state : GameState,
  key_event : @tui.KeyEvent,
) -> (GameState, Bool, Bool) {
  if state.game_over {
    match key_event {
      @tui.KeyEvent::Char('q', _) => (state, false, true)
      @tui.KeyEvent::Char('Q', _) => (state, false, true)
      _ => (state, false, false)
    }
  } else {
    match key_event {
      @tui.KeyEvent::Char('q', _) => (state, false, true)
      @tui.KeyEvent::Char('Q', _) => (state, false, true)
      @tui.KeyEvent::Char('?', _) =>
        (
          apply_visibility(
            rebuild_state(
              state,
              state.player,
              state.enemies,
              state.hp,
              state.turn,
              push_log(state.log, "You see flickering torches."),
              state.explored,
              state.items,
              state.inventory,
              state.stairs,
              state.game_over,
              state.win,
              state.seed,
            ),
            view_radius,
          ),
          true,
          false,
        )
      _ =>
        match action_from_key(key_event) {
          Some(action) => {
            let (next_state, acted) = apply_action(state, action)
            if acted {
              let advanced = advance_enemies(next_state)
              let updated = rebuild_state(
                advanced,
                advanced.player,
                advanced.enemies,
                advanced.hp,
                state.turn + 1,
                advanced.log,
                advanced.explored,
                advanced.items,
                advanced.inventory,
                advanced.stairs,
                advanced.game_over,
                advanced.win,
                advanced.seed,
              )
              (apply_visibility(updated, view_radius), true, false)
            } else {
              (state, false, false)
            }
          }
          None => (state, false, false)
        }
    }
  }
}

///|
async fn main {
  let (width, height) = @tui.get_terminal_size()
  let seed = width * 97 + height * 13
  let init_state = init_game(width, height, seed)
  let state = @signals.signal(init_state)
  let (app, cleanup) = @vnode.init_vnode_terminal(
    width,
    height,
    @tui.print_raw,
  )
  fn render_ui() -> TuiNode {
    render_game_ui(width, height, state.get())
  }

  @tui.print_raw(app.render_frame(render_ui()))
  let mut running = true
  while running {
    let key = @tui.read_key()
    if key.length() == 0 {
      continue
    }
    let event = @tui.parse_input(key)
    let mut need_render = false
    match event {
      @tui.InputEvent::Key(key_event) => {
        let (next_state, updated, quit) = handle_key(state.get(), key_event)
        if quit {
          running = false
        }
        if updated {
          state.set(next_state)
          need_render = true
        }
      }
      _ => ()
    }
    if need_render && running {
      @tui.print_raw(app.render_frame(render_ui()))
    }
  }
  cleanup()
  println("Goodbye!")
}
