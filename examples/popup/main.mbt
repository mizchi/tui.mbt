///|
/// Popup/Overlay Demo
/// Demonstrates the overlay rendering system with backdrop and positioning.
/// Press 1-4 to open different popup types, Escape to close, q to quit.
/// In Confirm dialog: Tab/Shift+Tab to cycle focus, mouse hover/click on buttons.

///|
using @vnode {
  type TuiNode,
  type VNodeApp,
  type OverlayEntry,
  type PopupPosition,
  view,
  row,
  column,
  text,
  vspace,
}

///|
enum PopupMode {
  None
  CenterAlert
  TopNotice
  BottomStatus
  ConfirmDialog
}

///|
fn render_background(
  width : Int,
  height : Int,
  last_action : String,
) -> TuiNode {
  view(
    width=width.to_double(),
    height=height.to_double(),
    border="rounded",
    border_color="cyan",
    [
      row(justify="center", margin_y=1.0, [
        text("Popup Overlay Demo", fg="yellow", bold=true),
      ]),
      view(flex_grow=1.0, padding_x=2.0, gap=1.0, [
        text("Background content is rendered first,"),
        text("then overlays are drawn on top of the same buffer."),
        row(gap=1.0, [text("1", fg="cyan", bold=true), text(": Center alert")]),
        row(gap=1.0, [text("2", fg="cyan", bold=true), text(": Top notice")]),
        row(gap=1.0, [text("3", fg="cyan", bold=true), text(": Bottom status")]),
        row(gap=1.0, [
          text("4", fg="cyan", bold=true),
          text(": Confirm dialog (mouse + Tab)"),
        ]),
        vspace(1.0),
        if last_action.length() > 0 {
          row(gap=1.0, [
            text("Last action:", fg="green"),
            text(last_action, fg="white", bold=true),
          ])
        } else {
          text("No action yet", fg="rgb(80,80,80)")
        },
        text("Line A: The quick brown fox jumps over the lazy dog"),
        text("Line B: Lorem ipsum dolor sit amet, consectetur"),
      ]),
      row(justify="center", [
        text("q: quit | 1-4: open popup | Esc: close", fg="rgb(128,128,128)"),
      ]),
    ],
  )
}

///|
fn button_state(
  id : String,
  focus : @tui.FocusNav,
  hover_id : String,
) -> @tui.ButtonState {
  @tui.resolve_button_state(id, hover_id, focus=Some(focus))
}

///|
fn build_overlays(
  mode : PopupMode,
  focus : @tui.FocusNav,
  hover_id : String,
) -> Array[OverlayEntry] {
  match mode {
    PopupMode::None => []
    PopupMode::CenterAlert =>
      [
        @components.popup(
          @components.alert_dialog(
            "Something important happened!",
            title="Notice",
          ),
        ),
      ]
    PopupMode::TopNotice =>
      [
        @components.popup(
          column(border="rounded", border_color="yellow", padding=1.0, [
            text("Info", fg="yellow", bold=true),
            text("This notice appears at the top."),
          ]),
          backdrop=false,
          position=PopupPosition::Top,
        ),
      ]
    PopupMode::BottomStatus =>
      [
        @components.popup(
          column(border="single", border_color="green", padding_x=2.0, [
            text("Status: All systems operational", fg="green"),
          ]),
          backdrop=false,
          position=PopupPosition::Bottom,
        ),
      ]
    PopupMode::ConfirmDialog => {
      let ok_state = button_state("confirm-ok", focus, hover_id)
      let cancel_state = button_state("confirm-cancel", focus, hover_id)
      [
        @components.popup(
          column(
            border="rounded",
            border_color="cyan",
            padding=1.0,
            width=45.0,
            [
              row(padding_x=1.0, padding_y=0.5, [
                text("Confirm Action", fg="cyan", bold=true),
              ]),
              row([text("-".repeat(41), fg="rgb(60,60,60)")]),
              vspace(1.0),
              row(padding_x=1.0, [text("Are you sure you want to proceed?")]),
              vspace(1.0),
              row(justify="space-between", padding_x=1.0, [
                @components.button(
                  "OK",
                  id="confirm-ok",
                  state=ok_state,
                  min_width=10.0,
                ),
                @components.button(
                  "Cancel",
                  id="confirm-cancel",
                  state=cancel_state,
                  min_width=10.0,
                ),
              ]),
            ],
          ),
        ),
      ]
    }
  }
}

///|
fn main {
  let (width, height) = @tui.get_terminal_size()
  let mode = @signals.signal(PopupMode::None)
  let focus = @signals.signal(
    @tui.FocusNav::new(["confirm-ok", "confirm-cancel"]),
  )
  let hover_id = @signals.signal("")
  let last_action = @signals.signal("")
  let app = VNodeApp::new(width, height)
  fn do_render() {
    let main = render_background(width, height, last_action.get())
    let overlays = build_overlays(mode.get(), focus.get(), hover_id.get())
    if overlays.length() > 0 {
      @tui.print_raw(app.render_frame_with_overlays(main, overlays))
    } else {
      @tui.print_raw(app.render_frame(main))
    }
  }

  fn do_quit() {
    @io.stop_keypress_listener()
    @tui.print_raw(@tui.disable_mouse_all())
    @tui.print_raw(VNodeApp::restore_terminal())
    println("Bye!")
  }

  fn do_action(action : String) {
    last_action.set(action)
    mode.set(PopupMode::None)
    hover_id.set("")
    do_render()
  }

  fn handle_key(key : String) {
    if key.length() == 0 {
      return
    }
    let event = @tui.parse_input(key)
    if event.is_ctrl_c() {
      do_quit()
      return
    }

    // Mouse events
    match event {
      @tui.InputEvent::Mouse(mouse) => {
        let is_confirm = mode.get() is PopupMode::ConfirmDialog
        if not(is_confirm) {
          return
        }
        match (mouse.event_type, mouse.button) {
          // Hover: motion with no button pressed
          (@tui.MouseEventType::Drag, @tui.MouseButton::None)
          | (@tui.MouseEventType::Move, _) => {
            let hit = app.hit_test(mouse.x, mouse.y)
            let new_hover = match hit {
              Some(h) => h.id
              None => ""
            }
            if new_hover != hover_id.get() {
              hover_id.set(new_hover)
              do_render()
            }
          }
          // Left click
          (@tui.MouseEventType::Press, @tui.MouseButton::Left) => {
            let hit = app.hit_test(mouse.x, mouse.y)
            match hit {
              Some(h) =>
                if h.id == "confirm-ok" {
                  do_action("Confirmed (click)")
                } else if h.id == "confirm-cancel" {
                  do_action("Cancelled (click)")
                }
              None => ()
            }
          }
          _ => ()
        }
        return
      }
      _ => ()
    }

    // Keyboard events
    match event {
      @tui.InputEvent::Key(key_event) =>
        match key_event {
          @tui.KeyEvent::Char('q', @tui.KeyModifier::None) => {
            if not(mode.get() is PopupMode::ConfirmDialog) {
              do_quit()
            }
            return
          }
          @tui.KeyEvent::Special(@tui.SpecialKey::Escape, _) => {
            mode.set(PopupMode::None)
            hover_id.set("")
            do_render()
          }
          @tui.KeyEvent::Char('1', _) => {
            mode.set(PopupMode::CenterAlert)
            do_render()
          }
          @tui.KeyEvent::Char('2', _) => {
            mode.set(PopupMode::TopNotice)
            do_render()
          }
          @tui.KeyEvent::Char('3', _) => {
            mode.set(PopupMode::BottomStatus)
            do_render()
          }
          @tui.KeyEvent::Char('4', _) => {
            mode.set(PopupMode::ConfirmDialog)
            focus.set(@tui.FocusNav::new(["confirm-ok", "confirm-cancel"]))
            hover_id.set("")
            do_render()
          }
          // Tab: next focus
          @tui.KeyEvent::Special(@tui.SpecialKey::Tab, @tui.KeyModifier::None) =>
            if mode.get() is PopupMode::ConfirmDialog {
              focus.set(focus.get().next())
              hover_id.set("")
              do_render()
            }
          // Shift+Tab: previous focus
          @tui.KeyEvent::Special(@tui.SpecialKey::BackTab, _) =>
            if mode.get() is PopupMode::ConfirmDialog {
              focus.set(focus.get().prev())
              hover_id.set("")
              do_render()
            }
          // Enter: activate focused button
          @tui.KeyEvent::Special(@tui.SpecialKey::Enter, _) =>
            if mode.get() is PopupMode::ConfirmDialog {
              let current = focus.get().current()
              if current == "confirm-ok" {
                do_action("Confirmed (Enter)")
              } else if current == "confirm-cancel" {
                do_action("Cancelled (Enter)")
              }
            }
          _ => ()
        }
      _ => ()
    }
  }

  @tui.print_raw(VNodeApp::init_terminal())
  @tui.enable_raw_mode()
  // Enable mouse with motion tracking for hover detection
  @tui.print_raw(@tui.enable_mouse_all())
  do_render()
  @io.start_keypress_listener(handle_key)
}
