///|
/// VNode Wizard - inquirer.js style interactive prompts
/// Uses vnode's render_to_lines for inline CLI rendering

///|
fn hide_cursor() -> String {
  @render.ansi_hide_cursor()
}

///|
fn show_cursor() -> String {
  @render.ansi_show_cursor()
}

///|
fn move_up(n : Int) -> String {
  let mut s = ""
  for _ in 0..<n {
    s = s + @render.ansi_move_up()
  }
  s
}

///|
fn clear_line() -> String {
  @render.ansi_clear_line()
}

///|
fn pr(s : String) -> Unit {
  @tui.print_raw(s)
}

///|
fn prln(s : String) -> Unit {
  @tui.print_raw(s + "\n")
}

///|
/// Render a selection prompt using vnode
fn render_select_prompt(
  question : String,
  options : Array[String],
  cursor : Int,
  selected_value : String,
) -> Array[String] {
  let node = if selected_value.length() > 0 {
    // Completed state
    @vnode.column([
      @vnode.row([
        @vnode.text("* ", fg="green"),
        @vnode.text(question + " ", bold=true),
        @vnode.text(selected_value, fg="cyan"),
      ]),
    ])
  } else {
    // Active state
    let children : Array[@vnode.TuiNode] = [
      @vnode.row([
        @vnode.text("? ", fg="yellow"),
        @vnode.text(question, bold=true),
      ]),
      @vnode.text("  (Use arrows, Enter to select)", fg="rgb(128,128,128)"),
    ]
    // Add options
    for i, opt in options {
      if i == cursor {
        children.push(
          @vnode.row([
            @vnode.text("  > ", fg="cyan"),
            @vnode.text(opt, fg="cyan", bold=true),
          ]),
        )
      } else {
        children.push(@vnode.text("    " + opt, fg="rgb(128,128,128)"))
      }
    }
    @vnode.column(children)
  }
  @vnode.render_to_lines(node)
}

///|
/// Render a confirm prompt
fn render_confirm_prompt(
  question : String,
  cursor : Int,
  confirmed : Bool?,
) -> Array[String] {
  let node = match confirmed {
    Some(value) => {
      let answer = if value { "Yes" } else { "No" }
      @vnode.column([
        @vnode.row([
          @vnode.text("* ", fg="green"),
          @vnode.text(question + " ", bold=true),
          @vnode.text(answer, fg="cyan"),
        ]),
      ])
    }
    None => {
      let yes_color = if cursor == 0 { "cyan" } else { "rgb(128,128,128)" }
      let no_color = if cursor == 1 { "cyan" } else { "rgb(128,128,128)" }
      @vnode.column([
        @vnode.row([
          @vnode.text("? ", fg="yellow"),
          @vnode.text(question, bold=true),
        ]),
        @vnode.row([
          @vnode.text("  "),
          @vnode.text("Yes", fg=yes_color, bold=cursor == 0),
          @vnode.text(" / "),
          @vnode.text("No", fg=no_color, bold=cursor == 1),
        ]),
      ])
    }
  }
  @vnode.render_to_lines(node)
}

///|
/// Print lines and return count
fn print_lines(lines : Array[String]) -> Int {
  for line in lines {
    prln(line)
  }
  lines.length()
}

///|
/// Clear lines by moving up and clearing
fn clear_lines(n : Int) -> Unit {
  for _ in 0..<n {
    pr(move_up(1) + "\r" + clear_line())
  }
}

///|
async fn main {
  // Wizard data
  let templates = ["React", "Vue", "Svelte", "Vanilla"]
  let managers = ["npm", "pnpm", "yarn", "bun"]

  // State
  let step = @signals.signal(0)
  let cursor = @signals.signal(0)
  let template = @signals.signal("")
  let package_manager = @signals.signal("")
  let git_init : @signals.Signal[Bool?] = @signals.signal(None)
  let completed = @signals.signal(false)

  // Track lines rendered for clearing
  let mut lines_rendered = 0
  pr(hide_cursor())
  prln("")
  prln(
    @render.ansi_bold() +
    @render.ansi_fg_cyan() +
    "◆ Project Setup Wizard" +
    @render.ansi_reset(),
  )
  prln("")

  // Render function
  fn render() -> Int {
    let current_step = step.get()
    let cur = cursor.get()
    let lines = match current_step {
      0 =>
        render_select_prompt(
          "Which template would you like to use?",
          templates,
          cur,
          template.get(),
        )
      1 =>
        render_select_prompt(
          "Which package manager?",
          managers,
          cur,
          package_manager.get(),
        )
      2 =>
        render_confirm_prompt("Initialize git repository?", cur, git_init.get())
      _ => []
    }
    print_lines(lines)
  }

  // Initial render
  lines_rendered = render()

  // Enable raw mode for key input
  @tui.enable_raw_mode()

  // Event loop
  let mut running = true
  while running {
    let key = @tui.read_key()
    if key.length() == 0 {
      continue
    }
    let event = @tui.parse_input(key)
    let current_step = step.get()
    let mut need_render = true
    match event {
      @tui.InputEvent::Key(key_event) =>
        match key_event {
          // Quit on Ctrl+C
          @tui.KeyEvent::Char('c', @tui.KeyModifier::Ctrl) => {
            clear_lines(lines_rendered)
            prln(@render.ansi_fg_red() + "Aborted." + @render.ansi_reset())
            running = false
          }
          // Navigation
          @tui.KeyEvent::Special(@tui.SpecialKey::Up, _) => {
            let max = match current_step {
              0 => templates.length()
              1 => managers.length()
              _ => 2
            }
            let cur = cursor.get()
            cursor.set(if cur > 0 { cur - 1 } else { max - 1 })
          }
          @tui.KeyEvent::Special(@tui.SpecialKey::Down, _) => {
            let max = match current_step {
              0 => templates.length()
              1 => managers.length()
              _ => 2
            }
            let cur = cursor.get()
            cursor.set(if cur < max - 1 { cur + 1 } else { 0 })
          }
          @tui.KeyEvent::Special(@tui.SpecialKey::Left, _) =>
            if current_step == 2 {
              cursor.set(0)
            }
          @tui.KeyEvent::Special(@tui.SpecialKey::Right, _) =>
            if current_step == 2 {
              cursor.set(1)
            }
          // Select / Confirm
          @tui.KeyEvent::Special(@tui.SpecialKey::Enter, _) =>
            match current_step {
              0 => {
                clear_lines(lines_rendered)
                template.set(templates[cursor.get()])
                lines_rendered = render()
                prln("")
                lines_rendered = 0
                step.set(1)
                cursor.set(0)
              }
              1 => {
                clear_lines(lines_rendered)
                package_manager.set(managers[cursor.get()])
                lines_rendered = render()
                prln("")
                lines_rendered = 0
                step.set(2)
                cursor.set(0)
              }
              2 => {
                clear_lines(lines_rendered)
                git_init.set(Some(cursor.get() == 0))
                lines_rendered = render()
                prln("")
                completed.set(true)
                running = false
              }
              _ => ()
            }
          _ => need_render = false
        }
      _ => need_render = false
    }

    // Re-render
    if need_render && running {
      clear_lines(lines_rendered)
      lines_rendered = render()
    }
  }

  // Restore terminal
  @tui.cleanup_stdin()
  pr(show_cursor())
  if completed.get() {
    prln("")
    prln(
      @render.ansi_bold() +
      @render.ansi_fg_green() +
      "✨ Setup complete!" +
      @render.ansi_reset(),
    )
    prln("")
    prln("  Template: " + template.get())
    prln("  Package Manager: " + package_manager.get())
    prln(
      "  Git Init: " +
      (if git_init.get().unwrap_or(false) { "Yes" } else { "No" }),
    )
    prln("")
  }
}
