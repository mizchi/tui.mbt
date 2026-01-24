///|
/// CLI Wizard - inquirer.js style interactive prompts
/// No screen refresh, prompts appear sequentially

// ANSI escape helpers (using @render for consistency)

///|
fn reset() -> String {
  @render.ansi_reset()
}

///|
fn bold() -> String {
  @render.ansi_bold()
}

///|
fn dim() -> String {
  @render.ansi_dim()
}

///|
fn cyan() -> String {
  @render.ansi_fg_cyan()
}

///|
fn green() -> String {
  @render.ansi_fg_green()
}

///|
fn yellow() -> String {
  @render.ansi_fg_yellow()
}

///|
fn red() -> String {
  @render.ansi_fg_red()
}

///|
fn underline() -> String {
  @render.ansi_underline()
}

///|
fn hide_cursor() -> String {
  @render.ansi_hide_cursor()
}

///|
fn show_cursor() -> String {
  @render.ansi_show_cursor()
}

///|
fn move_up() -> String {
  @render.ansi_move_up()
}

///|
fn move_left(n : Int) -> String {
  @render.ansi_move_left(n~)
}

///|
fn clear_line() -> String {
  @render.ansi_clear_line()
}

///|
/// Prompt types
pub(all) enum PromptType {
  Input(String) // placeholder
  Select(Array[String]) // options
  MultiSelect(Array[String]) // options with checkboxes
  Confirm // yes/no
}

///|
/// Prompt definition
pub(all) struct Prompt {
  key : String
  message : String
  prompt_type : PromptType
  default_value : String
}

///|
/// Prompt result
pub(all) struct PromptResult {
  key : String
  value : String
  values : Array[String] // for multiselect
}

///|
fn pr(s : String) -> Unit {
  @io.print_raw(s)
}

///|
fn prln(s : String) -> Unit {
  @io.print_raw(s + "\n")
}

///|
/// Wizard state
struct WizardState {
  prompts : Array[Prompt]
  results : Map[String, PromptResult]
  current_idx : @signals.Signal[Int]
  cursor_idx : @signals.Signal[Int]
  selected_items : Array[Bool]
  input_buffer : @signals.Signal[String]
  running : @signals.Signal[Bool]
}

///|
fn WizardState::new(prompts : Array[Prompt]) -> WizardState {
  {
    prompts,
    results: {},
    current_idx: @signals.signal(0),
    cursor_idx: @signals.signal(0),
    selected_items: [],
    input_buffer: @signals.signal(""),
    running: @signals.signal(true),
  }
}

///|
/// Render a completed prompt
fn render_completed(prompt : Prompt, result : PromptResult) -> Unit {
  let check = green() + "✔" + reset()
  let value_display = match prompt.prompt_type {
    PromptType::MultiSelect(_) =>
      if result.values.length() == 0 {
        dim() + "(none)" + reset()
      } else {
        cyan() +
        result.values
        .iter()
        .fold(init="", fn(acc, v) { if acc == "" { v } else { acc + ", " + v } }) +
        reset()
      }
    PromptType::Confirm =>
      if result.value == "yes" {
        cyan() + "Yes" + reset()
      } else {
        cyan() + "No" + reset()
      }
    _ => cyan() + result.value + reset()
  }
  prln(check + " " + bold() + prompt.message + reset() + " " + value_display)
}

///|
/// Render current active prompt
fn render_active_prompt(prompt : Prompt, state : WizardState) -> Unit {
  let arrow = yellow() + "?" + reset()
  pr(arrow + " " + bold() + prompt.message + reset() + " ")
  match prompt.prompt_type {
    PromptType::Input(placeholder) => {
      let val = state.input_buffer.get()
      if val == "" {
        pr(dim() + placeholder + reset())
        pr(move_left(placeholder.length()))
      } else {
        pr(cyan() + val + reset())
      }
      pr(show_cursor())
    }
    PromptType::Select(options) => {
      prln(dim() + "(Use arrows, Enter to select)" + reset())
      for i, opt in options {
        if i == state.cursor_idx.get() {
          prln("  " + cyan() + "❯ " + opt + reset())
        } else {
          prln("    " + dim() + opt + reset())
        }
      }
    }
    PromptType::MultiSelect(options) => {
      prln(dim() + "(Space to select, Enter to confirm)" + reset())
      for i, opt in options {
        let is_selected = if i < state.selected_items.length() {
          state.selected_items[i]
        } else {
          false
        }
        let checkbox = if is_selected { "◉" } else { "○" }
        if i == state.cursor_idx.get() {
          prln("  " + cyan() + "❯ " + checkbox + " " + opt + reset())
        } else {
          let color = if is_selected { green() } else { dim() }
          prln("    " + color + checkbox + " " + opt + reset())
        }
      }
    }
    PromptType::Confirm => {
      let yes_style = if state.cursor_idx.get() == 0 {
        cyan() + underline()
      } else {
        dim()
      }
      let no_style = if state.cursor_idx.get() == 1 {
        cyan() + underline()
      } else {
        dim()
      }
      prln(yes_style + "Yes" + reset() + " / " + no_style + "No" + reset())
    }
  }
}

///|
/// Clear current prompt display
fn clear_active_prompt(prompt : Prompt) -> Unit {
  let lines_to_clear = match prompt.prompt_type {
    PromptType::Input(_) => 0
    PromptType::Select(options) => options.length() + 1
    PromptType::MultiSelect(options) => options.length() + 1
    PromptType::Confirm => 1
  }
  if lines_to_clear == 0 {
    pr("\r" + clear_line())
  } else {
    for i = 0; i < lines_to_clear; i = i + 1 {
      pr(move_up() + clear_line())
    }
  }
}

///|
/// Initialize selected_items for multiselect
fn init_multiselect(state : WizardState, count : Int) -> Unit {
  state.selected_items.clear()
  for i = 0; i < count; i = i + 1 {
    state.selected_items.push(false)
  }
}

///|
/// Create result from current prompt
fn create_result(prompt : Prompt, state : WizardState) -> PromptResult {
  match prompt.prompt_type {
    PromptType::Input(placeholder) => {
      let val = state.input_buffer.get()
      {
        key: prompt.key,
        value: if val == "" {
          placeholder
        } else {
          val
        },
        values: [],
      }
    }
    PromptType::Select(options) =>
      { key: prompt.key, value: options[state.cursor_idx.get()], values: [] }
    PromptType::MultiSelect(options) => {
      let vals : Array[String] = []
      for i, opt in options {
        if i < state.selected_items.length() && state.selected_items[i] {
          vals.push(opt)
        }
      }
      { key: prompt.key, value: "", values: vals }
    }
    PromptType::Confirm => {
      let val = if state.cursor_idx.get() == 0 { "yes" } else { "no" }
      { key: prompt.key, value: val, values: [] }
    }
  }
}

///|
/// Show completion summary
fn show_summary(state : WizardState) -> Unit {
  prln("")
  prln(bold() + cyan() + "✨ Setup complete!" + reset())
  prln("")
  for entry in state.results.iter() {
    let r = entry.1
    let val = if r.values.length() > 0 {
      r.values
      .iter()
      .fold(init="", fn(acc, v) { if acc == "" { v } else { acc + ", " + v } })
    } else {
      r.value
    }
    prln("  " + dim() + r.key + ":" + reset() + " " + val)
  }
  prln("")
}

///|
/// Submit current answer and move to next prompt
fn submit_answer(state : WizardState) -> Unit {
  let idx = state.current_idx.get()
  if idx >= state.prompts.length() {
    return
  }
  let prompt = state.prompts[idx]
  let result = create_result(prompt, state)
  state.results[prompt.key] = result
  clear_active_prompt(prompt)
  render_completed(prompt, result)
  let next_idx = idx + 1
  if next_idx >= state.prompts.length() {
    show_summary(state)
    @io.stop_keypress_listener()
    pr(show_cursor())
    state.running.set(false)
    return
  }
  state.current_idx.set(next_idx)
  state.cursor_idx.set(0)
  state.input_buffer.set("")
  match state.prompts[next_idx].prompt_type {
    PromptType::MultiSelect(options) =>
      init_multiselect(state, options.length())
    _ => state.selected_items.clear()
  }
  render_active_prompt(state.prompts[next_idx], state)
}

///|
/// Handle input prompt key
fn handle_input_key(
  event : @events.InputEvent,
  prompt : Prompt,
  state : WizardState,
) -> Unit {
  match event {
    @events.InputEvent::Key(@events.KeyEvent::Char(c, modifier)) =>
      match modifier {
        @events.KeyModifier::Ctrl =>
          // Ctrl+A: move to start, Ctrl+E: move to end (no-op for simple input)
          // Ctrl+U: clear input
          if c == 'u' || c == 'U' {
            state.input_buffer.set("")
            pr("\r" + clear_line())
            render_active_prompt(prompt, state)
          }
        _ => {
          state.input_buffer.set(state.input_buffer.get() + c.to_string())
          pr("\r" + clear_line())
          render_active_prompt(prompt, state)
        }
      }
    @events.InputEvent::Key(
      @events.KeyEvent::Special(@events.SpecialKey::Backspace, _)
    ) => {
      let buf = state.input_buffer.get()
      if buf.length() > 0 {
        let chars = buf.iter().collect()
        let new_buf = String::from_array(
          chars.iter().take(chars.length() - 1).collect(),
        )
        state.input_buffer.set(new_buf)
        pr("\r" + clear_line())
        render_active_prompt(prompt, state)
      }
    }
    @events.InputEvent::Key(
      @events.KeyEvent::Special(@events.SpecialKey::Tab, _)
    ) =>
      // Tab to complete placeholder
      match prompt.prompt_type {
        PromptType::Input(placeholder) =>
          if state.input_buffer.get() == "" {
            state.input_buffer.set(placeholder)
            pr("\r" + clear_line())
            render_active_prompt(prompt, state)
          }
        _ => ()
      }
    _ => ()
  }
}

///|
/// Handle select prompt key (with wrap-around)
fn handle_select_key(
  event : @events.InputEvent,
  prompt : Prompt,
  options : Array[String],
  state : WizardState,
) -> Unit {
  let arrow = event.is_arrow()
  match arrow {
    Some(@events.SpecialKey::Up) => {
      let cur = state.cursor_idx.get()
      let next = if cur > 0 { cur - 1 } else { options.length() - 1 }
      state.cursor_idx.set(next)
      clear_active_prompt(prompt)
      render_active_prompt(prompt, state)
    }
    Some(@events.SpecialKey::Down) => {
      let cur = state.cursor_idx.get()
      let next = if cur < options.length() - 1 { cur + 1 } else { 0 }
      state.cursor_idx.set(next)
      clear_active_prompt(prompt)
      render_active_prompt(prompt, state)
    }
    _ => ()
  }
}

///|
/// Handle multiselect prompt key (with wrap-around)
fn handle_multiselect_key(
  event : @events.InputEvent,
  prompt : Prompt,
  options : Array[String],
  state : WizardState,
) -> Unit {
  let arrow = event.is_arrow()
  match arrow {
    Some(@events.SpecialKey::Up) => {
      let cur = state.cursor_idx.get()
      let next = if cur > 0 { cur - 1 } else { options.length() - 1 }
      state.cursor_idx.set(next)
      clear_active_prompt(prompt)
      render_active_prompt(prompt, state)
    }
    Some(@events.SpecialKey::Down) => {
      let cur = state.cursor_idx.get()
      let next = if cur < options.length() - 1 { cur + 1 } else { 0 }
      state.cursor_idx.set(next)
      clear_active_prompt(prompt)
      render_active_prompt(prompt, state)
    }
    _ =>
      if event.is_char(' ') {
        let cur = state.cursor_idx.get()
        if cur < state.selected_items.length() {
          state.selected_items[cur] = not(state.selected_items[cur])
          clear_active_prompt(prompt)
          render_active_prompt(prompt, state)
        }
      }
  }
}

///|
/// Handle confirm prompt key
fn handle_confirm_key(
  event : @events.InputEvent,
  prompt : Prompt,
  state : WizardState,
) -> Unit {
  let arrow = event.is_arrow()
  match arrow {
    Some(@events.SpecialKey::Left) => {
      state.cursor_idx.set(0)
      clear_active_prompt(prompt)
      render_active_prompt(prompt, state)
    }
    Some(@events.SpecialKey::Right) => {
      state.cursor_idx.set(1)
      clear_active_prompt(prompt)
      render_active_prompt(prompt, state)
    }
    _ =>
      if event.is_char('y') || event.is_char('Y') {
        state.cursor_idx.set(0)
        submit_answer(state)
      } else if event.is_char('n') || event.is_char('N') {
        state.cursor_idx.set(1)
        submit_answer(state)
      }
  }
}

///|
/// Handle key input
fn handle_key(key : String, state : WizardState) -> Unit {
  if key.length() == 0 || not(state.running.get()) {
    return
  }
  let event = @events.parse_input(key)
  let idx = state.current_idx.get()
  if idx >= state.prompts.length() {
    return
  }
  let prompt = state.prompts[idx]
  if event.is_ctrl_c() {
    @io.stop_keypress_listener()
    pr(show_cursor())
    prln("\n" + red() + "Aborted." + reset())
    state.running.set(false)
    return
  }
  if event.is_enter() {
    pr(hide_cursor())
    submit_answer(state)
    return
  }
  match prompt.prompt_type {
    PromptType::Input(_) => handle_input_key(event, prompt, state)
    PromptType::Select(options) =>
      handle_select_key(event, prompt, options, state)
    PromptType::MultiSelect(options) =>
      handle_multiselect_key(event, prompt, options, state)
    PromptType::Confirm => handle_confirm_key(event, prompt, state)
  }
}

///|
fn main {
  let prompts : Array[Prompt] = [
    {
      key: "name",
      message: "What is your project name?",
      prompt_type: PromptType::Input("my-project"),
      default_value: "my-project",
    },
    {
      key: "template",
      message: "Which template would you like to use?",
      prompt_type: PromptType::Select(["React", "Vue", "Svelte", "Vanilla"]),
      default_value: "React",
    },
    {
      key: "features",
      message: "Select features to include:",
      prompt_type: PromptType::MultiSelect([
        "TypeScript", "ESLint", "Prettier", "Testing", "CI/CD",
      ]),
      default_value: "",
    },
    {
      key: "package_manager",
      message: "Which package manager?",
      prompt_type: PromptType::Select(["npm", "pnpm", "yarn", "bun"]),
      default_value: "pnpm",
    },
    {
      key: "git_init",
      message: "Initialize git repository?",
      prompt_type: PromptType::Confirm,
      default_value: "yes",
    },
  ]
  let state = WizardState::new(prompts)
  pr(hide_cursor())
  prln("")
  prln(bold() + cyan() + "◆ Project Setup Wizard" + reset())
  prln("")
  match state.prompts[0].prompt_type {
    PromptType::MultiSelect(options) =>
      init_multiselect(state, options.length())
    _ => ()
  }
  render_active_prompt(state.prompts[0], state)
  @io.start_keypress_listener(fn(key) { handle_key(key, state) })
}
