///|
/// Toadlike - Demo gallery for toad-inspired components
/// Showcases: Toast, Breadcrumb, Grid Select, Diff, Tree, Fuzzy Search

///|
using @vnode {type TuiNode, type VNodeApp, column, row, text, vspace, spacer}

// Demo indices

///|
let demo_toast : Int = 0

///|
let demo_breadcrumb : Int = 1

///|
let demo_grid : Int = 2

///|
let demo_diff : Int = 3

///|
let demo_tree : Int = 4

///|
let demo_fuzzy : Int = 5

///|
async fn main {
  let (width, height) = @tui.get_terminal_size()

  // State
  let current_demo = @signals.signal(0)
  let message = @signals.signal("Tab/Shift+Tab: demos | q: quit")

  // Toast state
  let toast_level = @signals.signal(0)
  let toast_visible = @signals.signal(true)

  // Grid state
  let grid_state = @signals.signal(
    @headless.GridSelectState::new(4, 12, selected=0),
  )

  // Tree state (start with root focused and expanded so tree is interactive)
  let tree_state = @signals.signal(@headless.TreeState::{
    expanded_ids: ["root"],
    selected_id: "",
    focused_id: "root",
  })

  // Fuzzy state
  let fuzzy_query = @signals.signal("")
  let fuzzy_cursor = @signals.signal(0)

  // Demo names
  let demos = ["Toast", "Breadcrumb", "Grid", "Diff", "Tree", "Fuzzy"]

  // Create the vnode app
  let app = VNodeApp::new(width, height)

  // ==========================================================================
  // Demo data
  // ==========================================================================

  let toast_levels : Array[@headless.ToastLevel] = [
    @headless.ToastLevel::Info,
    @headless.ToastLevel::Success,
    @headless.ToastLevel::Warning,
    @headless.ToastLevel::Error,
  ]
  let toast_labels = ["Info", "Success", "Warning", "Error"]
  let grid_items = [
    "Alpha", "Beta", "Gamma", "Delta", "Epsilon", "Zeta", "Eta", "Theta", "Iota",
    "Kappa", "Lambda", "Mu",
  ]
  let old_text = [
    "fn main() {", "  let x = 1", "  let y = 2", "  println(x + y)", "}",
  ]
  let new_text = [
    "fn main() {", "  let x = 10", "  let y = 20", "  let z = x + y", "  println(z)",
    "}",
  ]
  let sample_tree : @logics.TreeNode[String] = @logics.TreeNode::branch(
    "root",
    "project",
    [
      @logics.TreeNode::branch("src", "src", [
        @logics.TreeNode::leaf("main", "main.mbt", data="source"),
        @logics.TreeNode::leaf("lib", "lib.mbt", data="source"),
        @logics.TreeNode::branch("utils", "utils", [
          @logics.TreeNode::leaf("fmt", "format.mbt", data="source"),
          @logics.TreeNode::leaf("parse", "parser.mbt", data="source"),
        ]),
      ]),
      @logics.TreeNode::branch("test", "test", [
        @logics.TreeNode::leaf("t1", "main_test.mbt", data="test"),
        @logics.TreeNode::leaf("t2", "lib_test.mbt", data="test"),
      ]),
      @logics.TreeNode::leaf("readme", "README.md", data="doc"),
      @logics.TreeNode::leaf("mod", "moon.mod.json", data="config"),
    ],
  )
  let fuzzy_items = [
    "main.mbt", "lib.mbt", "format.mbt", "parser.mbt", "main_test.mbt", "lib_test.mbt",
    "README.md", "moon.mod.json", "moon.pkg", "utils/helper.mbt", "components/button.mbt",
    "components/toast.mbt", "headless/types.mbt",
  ]

  // ==========================================================================
  // Demo Renderers
  // ==========================================================================

  fn render_toast_demo() -> TuiNode {
    let level_idx = toast_level.get()
    let visible = toast_visible.get()
    let level = toast_levels[level_idx]
    let state = @headless.ToastState::{
      message: "This is a " + toast_labels[level_idx] + " notification!",
      level,
      visible,
    }
    column(gap=0.5, [
      text("Toast Notification", fg="yellow", bold=true),
      text(
        "1-4: change level | Space: toggle visibility",
        fg="rgb(128,128,128)",
      ),
      vspace(1.0),
      @ui.toast(state, id="toast-demo"),
      vspace(0.5),
      text(
        "Level: " +
        toast_labels[level_idx] +
        " | Visible: " +
        visible.to_string(),
        fg="green",
      ),
    ])
  }

  fn render_breadcrumb_demo() -> TuiNode {
    column(gap=0.5, [
      text("Breadcrumb Navigation", fg="yellow", bold=true),
      text("Static display demos", fg="rgb(128,128,128)"),
      vspace(1.0),
      text("Simple breadcrumb:", fg="rgb(150,150,150)"),
      @ui.breadcrumb(["Home", "Projects", "tui.mbt"], id="bc1"),
      vspace(1.0),
      text("Custom separator:", fg="rgb(150,150,150)"),
      @ui.breadcrumb(
        ["Dashboard", "Settings", "Theme", "Colors"],
        separator=" / ",
        id="bc2",
      ),
      vspace(1.0),
      text("Condensed path:", fg="rgb(150,150,150)"),
      @ui.condensed_breadcrumb(
        "home/user/projects/moonbit/tui/src/components/tree.mbt",
        max_segments=4,
        id="bc3",
      ),
      vspace(1.0),
      text("Short path (no condensing):", fg="rgb(150,150,150)"),
      @ui.condensed_breadcrumb("src/main.mbt", id="bc4"),
    ])
  }

  fn render_grid_demo() -> TuiNode {
    let gs = grid_state.get()
    let (r, c) = gs.position()
    column(gap=0.5, [
      text("Grid Select", fg="yellow", bold=true),
      text("↑/↓/←/→: navigate grid", fg="rgb(128,128,128)"),
      vspace(1.0),
      @ui.grid_select(grid_items, gs, id="grid-demo", min_item_width=12.0),
      vspace(0.5),
      text(
        "Selected: " +
        grid_items[gs.selected] +
        " (row=" +
        r.to_string() +
        ", col=" +
        c.to_string() +
        ")",
        fg="green",
      ),
    ])
  }

  fn render_diff_demo() -> TuiNode {
    // Join lines into single text nodes to avoid flex space distribution
    let mut old_content = ""
    for i, line in old_text {
      if i > 0 {
        old_content = old_content + "\n"
      }
      old_content = old_content + line
    }
    let mut new_content = ""
    for i, line in new_text {
      if i > 0 {
        new_content = new_content + "\n"
      }
      new_content = new_content + line
    }
    column(gap=0.5, [
      text("Diff View", fg="yellow", bold=true),
      text("Unified diff display", fg="rgb(128,128,128)"),
      vspace(1.0),
      row(gap=2.0, align="start", [
        column([
          text("Old:", fg="rgb(150,150,150)"),
          column(border="single", border_color="rgb(60,60,60)", padding_x=1.0, [
            text(old_content, fg="rgb(150,150,150)"),
          ]),
        ]),
        column([
          text("New:", fg="rgb(150,150,150)"),
          column(border="single", border_color="rgb(60,60,60)", padding_x=1.0, [
            text(new_content, fg="rgb(150,150,150)"),
          ]),
        ]),
      ]),
      vspace(0.5),
      text("Unified diff:", fg="rgb(150,150,150)"),
      @ui.diff_view(old_text, new_text, id="diff-demo"),
    ])
  }

  fn render_tree_demo() -> TuiNode {
    let ts = tree_state.get()
    let selected_info = if ts.selected_id.length() > 0 {
      match sample_tree.find(ts.selected_id) {
        Some(node) => node.label
        None => "none"
      }
    } else {
      "none"
    }
    column(gap=0.5, [
      text("Tree View", fg="yellow", bold=true),
      text(
        "↑/↓: navigate | Space: expand/collapse | Enter: select",
        fg="rgb(128,128,128)",
      ),
      vspace(1.0),
      @ui.tree_view(sample_tree, ts, id="tree-demo"),
      vspace(0.5),
      text("Selected: " + selected_info, fg="green"),
      text(
        "Expanded: " + ts.expanded_ids.length().to_string() + " nodes",
        fg="rgb(100,100,100)",
      ),
    ])
  }

  fn render_fuzzy_demo() -> TuiNode {
    let query = fuzzy_query.get()
    let cursor = fuzzy_cursor.get()
    let results = if query.length() > 0 {
      @logics.fuzzy_sort(query, fuzzy_items)
    } else {
      let all : Array[(Int, @logics.FuzzyMatch)] = []
      for i, _item in fuzzy_items {
        all.push((i, @logics.FuzzyMatch::{ score: 0, positions: [] }))
      }
      all
    }
    let max_show = 8
    let layout = @logics.fuzzy_visible_rows(results.length(), max_show)
    let result_nodes : Array[TuiNode] = []
    for i = 0; i < layout.show; i = i + 1 {
      let (idx, m) = results[i]
      let item = fuzzy_items[idx]
      let is_focused = i == cursor
      let fg = if is_focused { "cyan" } else { "white" }
      let bg = if is_focused { "rgb(40,60,90)" } else { "" }
      let score_text = if query.length() > 0 {
        " (score: " + m.score.to_string() + ")"
      } else {
        ""
      }
      let prefix = if is_focused { "> " } else { "  " }
      result_nodes.push(
        row(bg~, padding_x=1.0, [
          text(prefix + item + score_text, fg~, bold=is_focused),
        ]),
      )
    }
    if layout.has_more {
      let remaining = results.length() - layout.show
      result_nodes.push(
        row(padding_x=1.0, [
          text(
            "  ... and " + remaining.to_string() + " more",
            fg="rgb(100,100,100)",
          ),
        ]),
      )
    }
    for _i = 0; _i < layout.pad; _i = _i + 1 {
      result_nodes.push(row(padding_x=1.0, [text(" ")]))
    }
    let query_display = if query.length() > 0 {
      query
    } else {
      "(type to filter)"
    }
    let count_text = results.length().to_string() + " results"
    let results_height = max_show.to_double()
    column([
      text("Fuzzy Search", fg="yellow", bold=true),
      text(
        "Type chars to filter | ↑/↓: navigate | Backspace: delete",
        fg="rgb(128,128,128)",
      ),
      vspace(1.0),
      // Search input
      row(
        id="fuzzy-input",
        border="single",
        border_color="cyan",
        padding_x=1.0,
        [
          text("> ", fg="cyan"),
          text(
            query_display,
            fg=if query.length() > 0 { "white" } else { "rgb(100,100,100)" },
          ),
          spacer(),
          text(count_text, fg="rgb(100,100,100)"),
        ],
      ),
      // Results in fixed-height container
      column(height=results_height, result_nodes),
    ])
  }

  // ==========================================================================
  // Main Render
  // ==========================================================================

  fn render_ui() -> TuiNode {
    let current = current_demo.get()

    // Navigation tabs
    let nav_items : Array[TuiNode] = []
    for i, d in demos {
      nav_items.push(@ui.tab(d, current == i, id="nav-" + i.to_string()))
    }

    // Demo content
    let demo_content = match current {
      _ if current == demo_toast => render_toast_demo()
      _ if current == demo_breadcrumb => render_breadcrumb_demo()
      _ if current == demo_grid => render_grid_demo()
      _ if current == demo_diff => render_diff_demo()
      _ if current == demo_tree => render_tree_demo()
      _ if current == demo_fuzzy => render_fuzzy_demo()
      _ => text("Unknown demo")
    }
    column(width=width.to_double(), height=height.to_double(), [
      // Header
      row(justify="center", padding_y=0.5, [
        text("Toadlike Component Gallery", fg="yellow", bold=true),
      ]),
      // Navigation
      row(justify="center", gap=0.5, nav_items),
      // Demo content
      column(
        flex_grow=1.0,
        padding_x=1.0,
        padding_y=0.5,
        border="rounded",
        border_color="rgb(80,80,100)",
        justify="start",
        [demo_content, spacer()],
      ),
      // Footer
      row(justify="center", padding_y=1.0, [
        text(message.get(), fg="rgb(100,100,100)"),
      ]),
    ])
  }

  // ==========================================================================
  // Tree navigation helpers
  // ==========================================================================

  fn get_tree_visible_ids() -> Array[String] {
    let ts = tree_state.get()
    let flat = sample_tree.flatten(ts.expanded_ids)
    flat.map(fn(item) { item.1.id })
  }

  fn tree_move_focus(delta : Int) -> Unit {
    let ids = get_tree_visible_ids()
    if ids.length() == 0 {
      return
    }
    let ts = tree_state.get()
    // If no focus yet, set focus to first visible node
    if ts.focused_id.length() == 0 {
      tree_state.set(ts.focus(ids[0]))
      return
    }
    let mut current_idx = 0
    for i, id in ids {
      if id == ts.focused_id {
        current_idx = i
        break
      }
    }
    let next_idx = current_idx + delta
    if next_idx >= 0 && next_idx < ids.length() {
      tree_state.set(ts.focus(ids[next_idx]))
    }
  }

  // ==========================================================================
  // Event Handling
  // ==========================================================================

  fn do_render() -> Unit {
    let frame = app.render_frame(render_ui())
    @tui.print_raw(frame)
    // Position cursor at fuzzy input when on fuzzy demo
    if current_demo.get() == demo_fuzzy {
      match app.find_by_id("fuzzy-input") {
        Some(hit) => {
          let query = fuzzy_query.get()
          // cursor after "> " + query text, +1 for border
          let col = hit.x + 1 + 2 + query.length()
          let cursor_row = hit.y + 1
          @tui.print_raw(
            @render.ansi_move_to(cursor_row, col) + @render.ansi_show_cursor(),
          )
        }
        None => @tui.print_raw(@render.ansi_hide_cursor())
      }
    } else {
      @tui.print_raw(@render.ansi_hide_cursor())
    }
  }

  @tui.print_raw(VNodeApp::init_terminal())
  @tui.enable_raw_mode()

  // Initial render
  do_render()
  let mut running = true
  while running {
    let key = @tui.read_key()
    if key.length() == 0 {
      continue
    }
    let event = @tui.parse_input(key)
    let mut need_render = true
    let current = current_demo.get()
    match event {
      @tui.InputEvent::Key(key_event) =>
        match key_event {
          // Quit
          @tui.KeyEvent::Char('q', @tui.KeyModifier::None) =>
            if current == demo_fuzzy && fuzzy_query.get().length() > 0 {
              fuzzy_query.set("")
              fuzzy_cursor.set(0)
            } else {
              running = false
            }
          @tui.KeyEvent::Char('c', @tui.KeyModifier::Ctrl) => running = false
          @tui.KeyEvent::Special(@tui.SpecialKey::Escape, _) => running = false
          // Navigate demos with Tab / Shift+Tab
          @tui.KeyEvent::Special(@tui.SpecialKey::Tab, _) =>
            if current < demos.length() - 1 {
              current_demo.set(current + 1)
              message.set("Demo: " + demos[current + 1])
            } else {
              need_render = false
            }
          @tui.KeyEvent::Special(@tui.SpecialKey::BackTab, _) =>
            if current > 0 {
              current_demo.set(current - 1)
              message.set("Demo: " + demos[current - 1])
            } else {
              need_render = false
            }
          // Arrow keys: demo-specific
          @tui.KeyEvent::Special(@tui.SpecialKey::Left, _) =>
            if current == demo_grid {
              grid_state.set(grid_state.get().move_left())
            } else {
              need_render = false
            }
          @tui.KeyEvent::Special(@tui.SpecialKey::Right, _) =>
            if current == demo_grid {
              grid_state.set(grid_state.get().move_right())
            } else {
              need_render = false
            }
          @tui.KeyEvent::Special(@tui.SpecialKey::Up, _) =>
            if current == demo_grid {
              grid_state.set(grid_state.get().move_up())
            } else if current == demo_tree {
              tree_move_focus(-1)
            } else if current == demo_fuzzy {
              let c = fuzzy_cursor.get()
              if c > 0 {
                fuzzy_cursor.set(c - 1)
              }
            } else {
              need_render = false
            }
          @tui.KeyEvent::Special(@tui.SpecialKey::Down, _) =>
            if current == demo_grid {
              grid_state.set(grid_state.get().move_down())
            } else if current == demo_tree {
              tree_move_focus(1)
            } else if current == demo_fuzzy {
              let c = fuzzy_cursor.get()
              let query = fuzzy_query.get()
              let total = if query.length() > 0 {
                @logics.fuzzy_sort(query, fuzzy_items).length()
              } else {
                fuzzy_items.length()
              }
              let layout = @logics.fuzzy_visible_rows(total, 8)
              if c < layout.show - 1 {
                fuzzy_cursor.set(c + 1)
              }
            } else {
              need_render = false
            }
          // Space
          @tui.KeyEvent::Char(' ', _) =>
            if current == demo_toast {
              toast_visible.set(not(toast_visible.get()))
            } else if current == demo_tree {
              let ts = tree_state.get()
              if ts.focused_id.length() > 0 {
                tree_state.set(ts.toggle_expand(ts.focused_id))
              }
            } else {
              need_render = false
            }
          // Enter
          @tui.KeyEvent::Special(@tui.SpecialKey::Enter, _) =>
            if current == demo_tree {
              let ts = tree_state.get()
              if ts.focused_id.length() > 0 {
                tree_state.set(ts.select(ts.focused_id))
                message.set("Selected: " + ts.focused_id)
              }
            } else {
              need_render = false
            }
          // Number keys for toast levels
          @tui.KeyEvent::Char('1', _) =>
            if current == demo_toast {
              toast_level.set(0)
              toast_visible.set(true)
            } else {
              need_render = false
            }
          @tui.KeyEvent::Char('2', _) =>
            if current == demo_toast {
              toast_level.set(1)
              toast_visible.set(true)
            } else {
              need_render = false
            }
          @tui.KeyEvent::Char('3', _) =>
            if current == demo_toast {
              toast_level.set(2)
              toast_visible.set(true)
            } else {
              need_render = false
            }
          @tui.KeyEvent::Char('4', _) =>
            if current == demo_toast {
              toast_level.set(3)
              toast_visible.set(true)
            } else {
              need_render = false
            }
          // Backspace for fuzzy
          @tui.KeyEvent::Special(@tui.SpecialKey::Backspace, _) =>
            if current == demo_fuzzy {
              let q = fuzzy_query.get()
              if q.length() > 0 {
                let chars = q.to_array()
                let new_chars = chars[:chars.length() - 1]
                fuzzy_query.set(String::from_array(new_chars))
                fuzzy_cursor.set(0)
              }
            } else {
              need_render = false
            }
          // Printable chars for fuzzy
          @tui.KeyEvent::Char(ch, @tui.KeyModifier::None) =>
            if current == demo_fuzzy {
              fuzzy_query.set(fuzzy_query.get() + ch.to_string())
              fuzzy_cursor.set(0)
            } else {
              need_render = false
            }
          _ => need_render = false
        }
      _ => need_render = false
    }
    if need_render && running {
      do_render()
    }
  }

  // Restore terminal
  @tui.cleanup_stdin()
  @tui.print_raw(VNodeApp::restore_terminal())
  println("Goodbye!")
}
