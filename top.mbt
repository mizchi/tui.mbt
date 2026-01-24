///|
/// Re-exports for convenient access to commonly used types and functions
/// Users can import `@tui` and access most APIs from there.

// === Core ===
pub using @core {
  type Component,
  type Color,
  type BorderChars,
  type RenderStyleMap,
  type TextContentMap,
  type Role,
  text,
  spacer,
}

// === Components (Layout) ===

///|
pub using @components {
  column,
  row,
  grid,
  center,
  fill,
  padded,
  fullscreen,
  hspace,
  vspace,
  hdivider,
  vdivider,
  hsplit,
  vsplit,
  hsplit_fixed_top,
  hsplit_fixed_bottom,
  vsplit_fixed_left,
  vsplit_fixed_right,
}

// === Components (Basic) ===

///|
pub using @components {
  button,
  text_button,
  icon_button,
  input,
  input_plain,
  textarea,
  multiline_input,
  checkbox,
  switch,
  radio,
  radiogroup,
  labeled_checkbox,
  labeled_switch,
}

// === Components (Composite) ===

///|
pub using @components {
  tabs,
  tabs_boxed,
  tabs_underline,
  tab_panel,
  tab_container,
  accordion,
  accordion_header,
  listbox,
  listbox_multi,
  listbox_option,
  combobox,
  select,
  autocomplete,
  menu,
  menubar,
  context_menu,
  modal,
  modal_with_backdrop,
  with_modal,
  alert_dialog,
  confirm_dialog,
  window_splitter,
  resizable_pane,
  splitter_handle,
  menu_item,
  menu_separator,
  menu_checkbox,
  menu_radio,
}

// === Components (Display) ===

///|
pub using @components {
  title_bar,
  footer,
  card,
  panel,
  bordered,
  spinner,
  loading_dots,
  progress_bar,
  scrollbar,
  scroll_indicator,
  streaming_text,
  streaming_block,
  labeled_block,
  bold,
  colored,
  percent_text,
  fraction_text,
}

// === Components (State/Helpers) ===

///|
pub using @components {
  type ButtonState,
  type InputState,
  type TextareaState,
  type ScrollState,
  type ProgressStyle,
  type StreamingState,
  type ItemScroller,
  type LineScroller,
  type ActionMenu,
  type ModalState,
  type EditConfig,
  type FocusNav,
  type Theme,
  type TabItem,
  type AccordionItem,
  type RadioOption,
  type ListboxOption,
  type ComboboxOption,
  type MenuItem,
  type MenubarItem,
  type MenubarState,
  type SplitterState,
  type SplitterOrientation,
  type LabelPosition,
  type ComboboxState,
}

// === Components (Dimension/Alignment helpers) ===

///|
pub using @components {
  trait ToDimension,
  dim_auto,
  dim_length,
  dim_percent,
  align_start,
  align_center,
  align_end,
  align_stretch,
  align_space_between,
  align_space_around,
  align_space_evenly,
}

// === Components (Edit/Form) ===

///|
pub using @components {
  form_edit_config,
  start_edit,
  start_edit_inplace,
  start_edit_inplace_in_bounds,
}

// === Components (Testing) ===

///|
pub using @components {type HeadlessApp, snapshot}

// === Render ===

///|
pub using @render {
  type App,
  type CharBuffer,
  type CharCell,
  type TextStyle,
  render_once,
  enable_mouse,
  disable_mouse,
  ansi_full_reset,
}

// === Events ===

///|
pub using @events {
  type InputEvent,
  type KeyEvent,
  type KeyModifier,
  type SpecialKey,
  type MouseEvent,
  type MouseButton,
  type MouseEventType,
  type HitTestResult,
  parse_input,
}

// === I/O ===

///|
pub using @io {
  type InputResult,
  get_terminal_size,
  print_raw,
  start_keypress_listener,
  stop_keypress_listener,
  cleanup_stdin,
  read_key,
  enable_raw_mode,
}

// === App Lifecycle ===

///|
/// Run a TUI application with simplified lifecycle management.
/// Handles terminal setup, event loop, and cleanup automatically.
///
/// Parameters:
/// - render_fn: Function that returns the component tree
/// - on_event: Event handler that returns false to quit
/// - mouse: Whether to enable mouse support (default: true)
///
/// Example:
/// ```
/// @tui.run(
///   fn() { @tui.text("Hello") },
///   fn(event) { if event.is_quit() { false } else { true } },
/// )
/// ```
pub fn run(
  render_fn : () -> @core.Component,
  on_event : (@events.InputEvent) -> Bool,
  mouse? : Bool = true,
) -> Unit {
  // Get terminal size
  let (cols, rows) = @io.get_terminal_size()

  // Create the app
  let app = @render.App::new(cols, rows)

  // Store last rendered component for click handling
  let last_component : Ref[@core.Component?] = { val: None }

  // Initialize terminal
  @io.print_raw(@render.App::init_terminal())
  if mouse {
    @io.print_raw(@render.enable_mouse())
  }

  // Render helper - stores component for click dispatch
  fn do_render() {
    let component = render_fn()
    last_component.val = Some(component)
    @io.print_raw(app.render_frame(component))
  }

  // Initial render
  do_render()

  // Event handler wrapper
  fn handle_key(key : String) {
    if key.length() == 0 {
      return
    }
    let event = @events.parse_input(key)

    // Auto-dispatch mouse clicks to component's on_click handlers
    match event {
      @events.InputEvent::Mouse(mouse_event) =>
        match last_component.val {
          Some(component) => {
            let _ = app.dispatch_click_from_component(mouse_event, component)

          }
          None => ()
        }
      _ => ()
    }
    let continue_running = on_event(event)
    if not(continue_running) {
      // Cleanup and exit
      @io.stop_keypress_listener()
      if mouse {
        @io.print_raw(@render.disable_mouse())
      }
      @io.cleanup_stdin()
      @io.print_raw(@render.App::restore_terminal())
      return
    }
    // Re-render
    do_render()
  }

  // Start event-driven keypress listener
  @io.start_keypress_listener(handle_key)
}
