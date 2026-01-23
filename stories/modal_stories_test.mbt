///|
/// Snapshot tests for modal stories centering

///|
test "simple text renders" {
  let story = Story::new(
    "test",
    "simple",
    fn() { @components.text("HELLO") },
    width=15,
    height=3,
  )
  let plain = story.to_plain()
  inspect(plain, content="HELLO")
}

///|
test "box with text renders" {
  let story = Story::new(
    "test",
    "boxed",
    fn() {
      @core.box(
        [@components.text("BOX")],
        width=@components.dim_percent(100.0),
        height=@components.dim_percent(100.0),
      )
    },
    width=15,
    height=3,
  )
  let plain = story.to_plain()
  inspect(plain, content="BOX")
}

///|
test "nested box renders" {
  let story = Story::new(
    "test",
    "nested",
    fn() {
      @core.box(
        [
          @core.box(
            [@components.text("NESTED")],
            width=@components.dim_percent(100.0),
            height=@components.dim_percent(100.0),
          ),
        ],
        width=@components.dim_percent(100.0),
        height=@components.dim_percent(100.0),
      )
    },
    width=15,
    height=3,
  )
  let plain = story.to_plain()
  inspect(plain, content="NESTED")
}

///|
test "centered text renders at center" {
  let story = Story::new(
    "test",
    "centered",
    fn() {
      @core.box(
        [@components.fill([@components.center([@components.text("CENTER")])])],
        width=@components.dim_percent(100.0),
        height=@components.dim_percent(100.0),
      )
    },
    width=17,
    height=5,
  )
  let plain = story.to_plain()
  // CENTER should be at row 2 (0-indexed), centered horizontally
  // (17 - 6) / 2 = 5.5 → starts at column 5 or 6
  inspect(plain, content="     CENTER")
}

///|
test "modal/centered_content story snapshot" {
  let stories = modal_stories()
  for s in stories {
    if s.name == "centered_content" {
      let plain = s.to_plain()
      println("=== centered_content (17x5) ===")
      println(plain)
      println("=== end ===")
      inspect(plain, content="     CENTER")
      return
    }
  }
}

///|
test "modal/centered_modal story snapshot" {
  let stories = modal_stories()
  for s in stories {
    if s.name == "centered_modal" {
      let plain = s.to_plain()
      println("=== centered_modal (21x9) ===")
      println(plain)
      println("=== end ===")
      inspect(
        plain,
        content=(
          #|      ╭───────╮
          #|      │       │
          #|      │ Modal │
          #|      │       │
          #|      ╰───────╯
        ),
      )
      return
    }
  }
}

///|
test "modal/stacked_modal story snapshot" {
  let stories = modal_stories()
  for s in stories {
    if s.name == "stacked_modal" {
      let plain = s.to_plain()
      println("=== stacked_modal (25x9) ===")
      println(plain)
      println("=== end ===")
      // Modal overlay should cover background content
      inspect(
        plain,
        content=(
          #|Background
          #|Content Here
          #|       ╭────────╮
          #|.......│        │
          #|       │ Dialog │
          #|       │        │
          #|       ╰────────╯
        ),
      )
      return
    }
  }
}

///|
test "modal/nested_modals story snapshot" {
  let stories = modal_stories()
  for s in stories {
    if s.name == "nested_modals" {
      let plain = s.to_plain()
      println("=== nested_modals (25x9) ===")
      println(plain)
      println("=== end ===")
      // Second modal (Confirm?) should be on top
      inspect(
        plain,
        content=(
          #|App Content
          #|
          #|      ╭──────────╮
          #|      │          │
          #|      │ Confirm? │
          #|      │          │
          #|      ╰──────────╯
        ),
      )
      return
    }
  }
}

///|
test "modal/full_overlay story snapshot" {
  let stories = modal_stories()
  for s in stories {
    if s.name == "full_overlay" {
      let plain = s.to_plain()
      println("=== full_overlay (31x13) ===")
      println(plain)
      println("=== end ===")
      // Full overlay with dark backdrop and centered dialog
      inspect(
        plain,
        content=(
          #|      ╭─────────────────╮
          #|      │                 │
          #|      │  Confirm        │
          #|      │                 │
          #|      │                 │
          #|      │  Save changes?  │
          #|      │                 │
          #|      │                 │
          #|      ╰─ [Yes] ── [No] ─╯
        ),
      )
      return
    }
  }
}

///|
test "modal/alert_modal story snapshot" {
  let stories = modal_stories()
  for s in stories {
    if s.name == "alert_modal" {
      let plain = s.to_plain()
      println("=== alert_modal (25x11) ===")
      println(plain)
      println("=== end ===")
      // Alert modal with error styling
      inspect(
        plain,
        content=(
          #|   ╭─────────────────╮
          #|   │                 │
          #|   │ ! Error !       │
          #|   │                 │
          #|   │                 │
          #|   │ Connection lost │
          #|   │                 │
          #|   │                 │
          #|   ╰─   [OK]   ──────╯
        ),
      )
      return
    }
  }
}

///|
test "modal/command_launcher story snapshot" {
  let stories = modal_stories()
  for s in stories {
    if s.name == "command_launcher" {
      let plain = s.to_plain()
      println("=== command_launcher (24x15) ===")
      println(plain)
      println("=== end ===")
      // Command launcher overlay
      inspect(
        plain,
        content=(
          #|       ╭────────╮
          #|       │        │
          #|       │ > open │
          #|       │        │
          #|       │ * Open │
          #|       ╰────────╯
        ),
      )
      return
    }
  }
}

///|
test "modal/spotlight_top_center story snapshot" {
  let stories = modal_stories()
  for s in stories {
    if s.name == "spotlight_top_center" {
      let plain = s.to_plain()
      println("=== spotlight_top_center (20x10) ===")
      println(plain)
      println("=== end ===")
      return
    }
  }
}
