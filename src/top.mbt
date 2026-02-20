///|
/// Re-exports for convenient access to commonly used types and functions
/// Users can import `@tui` and access most APIs from there.

// === Core (Low-level) ===
pub using @core {
  type Component,
  type Color,
  type BorderChars,
  type RenderStyleMap,
  type TextContentMap,
  type Role,
}

// === VNode (Layout) ===

///|
pub using @vnode {
  column,
  row,
  view,
  grid,
  grid_item,
  grid_area,
  fragment,
  spacer,
  hspace,
  vspace,
}

// === VNode (Basic Components) ===

///|
pub using @vnode {
  input,
  input_plain,
  textarea,
  text,
  text_dyn,
  is_printable_char,
  is_printable_string,
}

// === VNode (Types) ===

///|
pub using @vnode {
  type InputState,
  type EditConfig,
  type VNodeApp,
  type TuiNode,
  type TuiEvent,
  // Grid types
  type DisplayValue,
  type GridAutoFlowValue,
  // Focus management
  type FocusContext,
  // Accessibility
  type A11yNode,
  dump_a11y_tree,
}

// === Headless (State Types) ===

///|
pub using @headless {type ButtonState, resolve_button_state}

// === VNode (Edit/Form) ===

///|
pub using @vnode {
  form_edit_config,
  start_edit,
  start_edit_inplace,
  start_edit_inplace_in_bounds,
}

// === VNode (Rendering) ===

///|
pub using @vnode {render_vnode_once, run_vnode_app, init_vnode_terminal}

// === Headless State Types ===

///|
pub using @headless {
  type ToggleState,
  type SelectionState,
  type ModalState,
  type AccordionState,
  type FocusNav,
}

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
  enable_mouse_all,
  disable_mouse_all,
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
  on_hover? : ((String) -> Unit)? = None,
) -> Unit {
  // Get terminal size
  let (cols, rows) = @io.get_terminal_size()

  // Create the app
  let app = @render.App::new(cols, rows)

  // Store last rendered component for click handling
  let last_component : Ref[@core.Component?] = { val: None }

  // Track hover state
  let last_hover_id : Ref[String] = { val: "" }

  // Initialize terminal
  @io.print_raw(@render.App::init_terminal())
  if mouse {
    @io.print_raw(@render.enable_mouse_all())
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

    // Auto-dispatch mouse events
    match event {
      @events.InputEvent::Mouse(mouse_event) => {
        // Hover dispatch
        match app.dispatch_hover(mouse_event) {
          Some(new_id) => {
            if new_id != last_hover_id.val {
              last_hover_id.val = new_id
              match on_hover {
                Some(cb) => cb(new_id)
                None => ()
              }
              do_render()
            }
            return
          }
          None => ()
        }
        // Click dispatch
        match last_component.val {
          Some(component) => {
            let _ = app.dispatch_click_from_component(mouse_event, component)
          }
          None => ()
        }
      }
      _ => ()
    }
    let continue_running = on_event(event)
    if not(continue_running) {
      // Cleanup and exit
      @io.stop_keypress_listener()
      if mouse {
        @io.print_raw(@render.disable_mouse_all())
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
