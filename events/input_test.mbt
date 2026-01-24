///|
/// Tests for input parsing

///|
test "parse_input: SGR mouse press format" {
  // ESC[<0;51;13M - Left click at (51, 13)
  let input = "\u001b[<0;51;13M"
  let event = @events.parse_input(input)
  match event {
    @events.InputEvent::Mouse(mouse) => {
      inspect(mouse.button, content="Left")
      inspect(mouse.event_type, content="Press")
      inspect(mouse.x, content="51")
      inspect(mouse.y, content="13")
    }
    _ => fail("Expected Mouse event")
  }
}

///|
test "parse_input: SGR mouse release format" {
  // ESC[<0;10;20m - Left release at (10, 20)
  let input = "\u001b[<0;10;20m"
  let event = @events.parse_input(input)
  match event {
    @events.InputEvent::Mouse(mouse) => {
      inspect(mouse.button, content="Left")
      inspect(mouse.event_type, content="Release")
      inspect(mouse.x, content="10")
      inspect(mouse.y, content="20")
    }
    _ => fail("Expected Mouse event")
  }
}

///|
test "parse_input: SGR mouse right click" {
  // ESC[<2;30;15M - Right click at (30, 15)
  let input = "\u001b[<2;30;15M"
  let event = @events.parse_input(input)
  match event {
    @events.InputEvent::Mouse(mouse) => {
      inspect(mouse.button, content="Right")
      inspect(mouse.event_type, content="Press")
      inspect(mouse.x, content="30")
      inspect(mouse.y, content="15")
    }
    _ => fail("Expected Mouse event")
  }
}

///|
test "parse_input: SGR mouse middle click" {
  // ESC[<1;5;5M - Middle click at (5, 5)
  let input = "\u001b[<1;5;5M"
  let event = @events.parse_input(input)
  match event {
    @events.InputEvent::Mouse(mouse) => {
      inspect(mouse.button, content="Middle")
      inspect(mouse.event_type, content="Press")
      inspect(mouse.x, content="5")
      inspect(mouse.y, content="5")
    }
    _ => fail("Expected Mouse event")
  }
}

///|
test "parse_input: SGR mouse scroll up" {
  // ESC[<64;20;10M - Scroll up at (20, 10)
  let input = "\u001b[<64;20;10M"
  let event = @events.parse_input(input)
  match event {
    @events.InputEvent::Mouse(mouse) => {
      inspect(mouse.button, content="ScrollUp")
      inspect(mouse.x, content="20")
      inspect(mouse.y, content="10")
    }
    _ => fail("Expected Mouse event")
  }
}

///|
test "parse_input: SGR mouse scroll down" {
  // ESC[<65;20;10M - Scroll down at (20, 10)
  let input = "\u001b[<65;20;10M"
  let event = @events.parse_input(input)
  match event {
    @events.InputEvent::Mouse(mouse) => {
      inspect(mouse.button, content="ScrollDown")
      inspect(mouse.x, content="20")
      inspect(mouse.y, content="10")
    }
    _ => fail("Expected Mouse event")
  }
}

///|
test "parse_input: SGR mouse drag" {
  // ESC[<32;25;30M - Left drag at (25, 30) (bit 32 set)
  let input = "\u001b[<32;25;30M"
  let event = @events.parse_input(input)
  match event {
    @events.InputEvent::Mouse(mouse) => {
      inspect(mouse.button, content="Left")
      inspect(mouse.event_type, content="Drag")
      inspect(mouse.x, content="25")
      inspect(mouse.y, content="30")
    }
    _ => fail("Expected Mouse event")
  }
}

///|
test "parse_input: arrow keys" {
  inspect(@events.parse_input("\u001b[A"), content="Key(Special(Up, None))")
  inspect(@events.parse_input("\u001b[B"), content="Key(Special(Down, None))")
  inspect(@events.parse_input("\u001b[C"), content="Key(Special(Right, None))")
  inspect(@events.parse_input("\u001b[D"), content="Key(Special(Left, None))")
}

///|
test "parse_input: printable characters" {
  let event = @events.parse_input("a")
  inspect(event, content="Key(Char('a', None))")
  let event2 = @events.parse_input("Z")
  inspect(event2, content="Key(Char('Z', None))")
}

///|
test "parse_input: control characters" {
  // Ctrl+C
  let event = @events.parse_input("\u0003")
  inspect(event, content="Key(Char('c', Ctrl))")
  // Enter
  let event2 = @events.parse_input("\r")
  inspect(event2, content="Key(Special(Enter, None))")
  // Escape
  let event3 = @events.parse_input("\u001b")
  inspect(event3, content="Key(Special(Escape, None))")
}

///|
test "parse_input: Tab and BackTab" {
  // Tab
  let event = @events.parse_input("\t")
  inspect(event, content="Key(Special(Tab, None))")
  // Shift+Tab (BackTab)
  let event2 = @events.parse_input("\u001b[Z")
  inspect(event2, content="Key(Special(BackTab, Shift))")
}

///|
test "parse_input: Backspace and Delete" {
  // Backspace (DEL)
  let event = @events.parse_input("\u007f")
  inspect(event, content="Key(Special(Backspace, None))")
  // Delete key
  let event2 = @events.parse_input("\u001b[3~")
  inspect(event2, content="Key(Special(Delete, None))")
}

///|
test "parse_input: Home and End" {
  // Home
  let event = @events.parse_input("\u001b[H")
  inspect(event, content="Key(Special(Home, None))")
  // End
  let event2 = @events.parse_input("\u001b[F")
  inspect(event2, content="Key(Special(End, None))")
}

///|
test "parse_input: Function keys" {
  // F1 - F4 use SS3 format
  inspect(@events.parse_input("\u001bOP"), content="Key(Special(F(1), None))")
  inspect(@events.parse_input("\u001bOQ"), content="Key(Special(F(2), None))")
  inspect(@events.parse_input("\u001bOR"), content="Key(Special(F(3), None))")
  inspect(@events.parse_input("\u001bOS"), content="Key(Special(F(4), None))")
}

///|
test "parse_input: Page Up/Down" {
  inspect(
    @events.parse_input("\u001b[5~"),
    content="Key(Special(PageUp, None))",
  )
  inspect(
    @events.parse_input("\u001b[6~"),
    content="Key(Special(PageDown, None))",
  )
}

///|
test "parse_input: unknown sequences" {
  // Unknown CSI sequence
  let event = @events.parse_input("\u001b[999X")
  match event {
    @events.InputEvent::Unknown(_) => ()
    _ => fail("Expected Unknown event")
  }
}

///|
test "parse_input: Ctrl+P" {
  // Ctrl+P (byte 16)
  let event = @events.parse_input("\u0010")
  inspect(event, content="Key(Char('p', Ctrl))")
  // Verify is_ctrl helper
  assert_true(event.is_ctrl('p'))
  assert_false(event.is_ctrl('c'))
}

///|
test "parse_input: empty input returns Unknown" {
  let event = @events.parse_input("")
  match event {
    @events.InputEvent::Unknown(s) => inspect(s, content="")
    _ => fail("Expected Unknown event for empty input")
  }
}

///|
test "parse_input: Alt+key" {
  // Alt+a (ESC followed by 'a')
  let event = @events.parse_input("\u001ba")
  inspect(event, content="Key(Char('a', Alt))")
  // Alt+Z
  let event2 = @events.parse_input("\u001bZ")
  inspect(event2, content="Key(Char('Z', Alt))")
}

///|
test "parse_input: Insert key" {
  let event = @events.parse_input("\u001b[2~")
  inspect(event, content="Key(Special(Insert, None))")
}

///|
test "parse_input: F5-F12 keys" {
  inspect(@events.parse_input("\u001b[15~"), content="Key(Special(F(5), None))")
  inspect(@events.parse_input("\u001b[17~"), content="Key(Special(F(6), None))")
  inspect(@events.parse_input("\u001b[18~"), content="Key(Special(F(7), None))")
  inspect(@events.parse_input("\u001b[19~"), content="Key(Special(F(8), None))")
  inspect(@events.parse_input("\u001b[20~"), content="Key(Special(F(9), None))")
  inspect(
    @events.parse_input("\u001b[21~"),
    content="Key(Special(F(10), None))",
  )
  inspect(
    @events.parse_input("\u001b[23~"),
    content="Key(Special(F(11), None))",
  )
  inspect(
    @events.parse_input("\u001b[24~"),
    content="Key(Special(F(12), None))",
  )
}

///|
test "parse_input: short CSI sequence" {
  // ESC[ alone (length 2)
  let event = @events.parse_input("\u001b[")
  match event {
    @events.InputEvent::Unknown(_) => ()
    _ => fail("Expected Unknown for incomplete CSI")
  }
}

///|
test "parse_input: mouse with shift modifier" {
  // Shift+click (button code 4)
  let event = @events.parse_input("\u001b[<4;10;20M")
  match event {
    @events.InputEvent::Mouse(mouse) => {
      inspect(mouse.modifier, content="Shift")
      inspect(mouse.event_type, content="Press")
    }
    _ => fail("Expected Mouse event")
  }
}

///|
test "parse_input: mouse with alt modifier" {
  // Alt+click (button code 8)
  let event = @events.parse_input("\u001b[<8;10;20M")
  match event {
    @events.InputEvent::Mouse(mouse) => inspect(mouse.modifier, content="Alt")
    _ => fail("Expected Mouse event")
  }
}

///|
test "parse_input: mouse with ctrl modifier" {
  // Ctrl+click (button code 16)
  let event = @events.parse_input("\u001b[<16;10;20M")
  match event {
    @events.InputEvent::Mouse(mouse) => inspect(mouse.modifier, content="Ctrl")
    _ => fail("Expected Mouse event")
  }
}

///|
test "parse_input: multi-character printable input (pasted text)" {
  // Simulates pasted text - should return first character
  let event = @events.parse_input("abc")
  inspect(event, content="Key(Char('a', None))")
}

///|
test "parse_input: urxvt mouse format (M final char)" {
  // urxvt format: ESC [ button ; x ; y M
  // This triggers the 'M' => parse_mouse_x10 path but returns Unknown
  // because parse_mouse_x10 expects X10 6-byte format
  let event = @events.parse_input("\u001b[0;10;20M")
  // Current implementation returns Unknown because the format doesn't match X10
  match event {
    @events.InputEvent::Unknown(_) => ()
    @events.InputEvent::Mouse(_) => ()
    _ => fail("Expected Unknown or Mouse event")
  }
}

///|
test "parse_input: tilde Home/End variants" {
  // ESC[1~ = Home (alternative format)
  inspect(@events.parse_input("\u001b[1~"), content="Key(Special(Home, None))")
  // ESC[4~ = End (alternative format)
  inspect(@events.parse_input("\u001b[4~"), content="Key(Special(End, None))")
  // ESC[7~ = Home (alternative format)
  inspect(@events.parse_input("\u001b[7~"), content="Key(Special(Home, None))")
  // ESC[8~ = End (alternative format)
  inspect(@events.parse_input("\u001b[8~"), content="Key(Special(End, None))")
}

///|
test "parse_input: unknown tilde sequence" {
  // Unknown tilde sequence number
  let event = @events.parse_input("\u001b[99~")
  match event {
    @events.InputEvent::Unknown(_) => ()
    _ => fail("Expected Unknown event")
  }
}

///|
test "parse_input: tilde sequence without number" {
  // Invalid tilde sequence (no number)
  let event = @events.parse_input("\u001b[~")
  match event {
    @events.InputEvent::Unknown(_) => ()
    _ => fail("Expected Unknown event")
  }
}

///|
test "parse_input: short SS3 sequence" {
  // ESC O alone (length 2) - incomplete
  let event = @events.parse_input("\u001bO")
  match event {
    @events.InputEvent::Unknown(_) => ()
    _ => fail("Expected Unknown for incomplete SS3")
  }
}

///|
test "parse_input: unknown SS3 sequence" {
  // Unknown SS3 character
  let event = @events.parse_input("\u001bOZ")
  match event {
    @events.InputEvent::Unknown(_) => ()
    _ => fail("Expected Unknown for unknown SS3")
  }
}

///|
test "parse_input: CSI params with semicolons" {
  // Mouse SGR with semicolons (already tested but ensures semicolon parsing)
  let event = @events.parse_input("\u001b[<0;100;200M")
  match event {
    @events.InputEvent::Mouse(mouse) => {
      inspect(mouse.x, content="100")
      inspect(mouse.y, content="200")
    }
    _ => fail("Expected Mouse event")
  }
}

///|
test "parse_input: X10 mouse short sequence" {
  // X10 mouse too short (less than 6 chars)
  let event = @events.parse_input("\u001b[M ")
  match event {
    @events.InputEvent::Unknown(_) => ()
    _ => fail("Expected Unknown for short X10 sequence")
  }
}

///|
test "parse_input: non-SGR m final char" {
  // ESC [ ... m without '<' (not SGR) - triggers line 120
  let event = @events.parse_input("\u001b[0;10;20m")
  match event {
    @events.InputEvent::Mouse(_) => ()
    @events.InputEvent::Unknown(_) => ()
    _ => fail("Expected Mouse or Unknown event")
  }
}

///|
test "parse_input: tilde with modifier params (semicolon in params)" {
  // Some terminals send ESC[3;5~ for Ctrl+Delete (code;modifier format)
  // This tests the semicolon parsing in extract_csi_params
  let event = @events.parse_input("\u001b[3;5~")
  match event {
    // Returns Delete (first param is 3) - modifier handling may vary
    @events.InputEvent::Key(_) => ()
    @events.InputEvent::Unknown(_) => ()
    _ => fail("Expected Key or Unknown event")
  }
}
