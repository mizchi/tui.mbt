///|
test "button layout: text should be centered" {
  let btn = button("OK", min_width=10.0)
  let layout = @render.compute_layout(btn.node, 20, 5)

  // Button root
  println(
    "Root: x=\{layout.x}, y=\{layout.y}, w=\{layout.width}, h=\{layout.height}",
  )
  println(
    "Root padding: L=\{layout.padding.left}, R=\{layout.padding.right}, T=\{layout.padding.top}, B=\{layout.padding.bottom}",
  )
  println(
    "Root border: L=\{layout.border.left}, R=\{layout.border.right}, T=\{layout.border.top}, B=\{layout.border.bottom}",
  )

  // Children (text)
  for i, child in layout.children {
    println(
      "Child[\{i}]: id=\{child.id}, x=\{child.x}, y=\{child.y}, w=\{child.width}, h=\{child.height}",
    )
    println(
      "Child[\{i}] padding: L=\{child.padding.left}, R=\{child.padding.right}, T=\{child.padding.top}, B=\{child.padding.bottom}",
    )
    for j, grandchild in child.children {
      println(
        "  Grandchild[\{j}]: id=\{grandchild.id}, x=\{grandchild.x}, y=\{grandchild.y}, w=\{grandchild.width}, h=\{grandchild.height}",
      )
    }
  }

  // min_width=10 with border means inner width = 8
  // Text "OK" is 2 chars, padding_x=2 (default)
  // With justify=Center, text x should be centered
}

///|
test "simple row with justify center" {
  // Simple row without border
  let comp = row(
    [@core.text("X")],
    width=@types.Dimension::Length(10.0),
    justify=@types.Alignment::Center,
  )
  let layout = @render.compute_layout(comp.node, 20, 3)
  println("Simple Row: w=\{layout.width}, h=\{layout.height}")
  println("Simple Row padding: L=\{layout.padding.left}")
  for i, child in layout.children {
    println("Child[\{i}]: x=\{child.x}, w=\{child.width}")
    // With width=10 and single char text, x should be (10-1)/2 = 4.5
  }
}

///|
test "row with padding and justify center" {
  // Row with padding, should still center
  let comp = row(
    [@core.text("X")],
    width=@types.Dimension::Length(10.0),
    padding_x=2.0,
    justify=@types.Alignment::Center,
  )
  let layout = @render.compute_layout(comp.node, 20, 3)
  println("Padded Row: w=\{layout.width}, h=\{layout.height}")
  println(
    "Padded Row padding: L=\{layout.padding.left}, R=\{layout.padding.right}",
  )
  for i, child in layout.children {
    println("Child[\{i}]: x=\{child.x}, w=\{child.width}")
    // With width=10, padding_x=2 on each side, content area = 6
    // Content "X" is 1 char, so x should be 2 + (6-1)/2 = 4.5
  }
}

///|
test "row with border and justify center" {
  // Row with border, should still center
  let comp = row(
    [@core.text("X")],
    width=@types.Dimension::Length(10.0),
    border=Some(@core.BorderChars::rounded()),
    justify=@types.Alignment::Center,
  )
  let layout = @render.compute_layout(comp.node, 20, 3)
  println("Bordered Row: w=\{layout.width}, h=\{layout.height}")
  println(
    "Bordered Row border: L=\{layout.border.left}, R=\{layout.border.right}",
  )
  for i, child in layout.children {
    println("Child[\{i}]: x=\{child.x}, w=\{child.width}")
    // With width=10, border=1 on each side, content area = 8
    // Content "X" is 1 char, so x should be (8-1)/2 = 3.5
  }
}

///|
test "row with padding AND border and justify center" {
  // Row with both padding and border
  let comp = row(
    [@core.text("X")],
    width=@types.Dimension::Length(12.0),
    padding_x=2.0,
    border=Some(@core.BorderChars::rounded()),
    justify=@types.Alignment::Center,
  )
  let layout = @render.compute_layout(comp.node, 20, 3)
  println("Padded+Bordered Row: w=\{layout.width}, h=\{layout.height}")
  println("  padding: L=\{layout.padding.left}, R=\{layout.padding.right}")
  println("  border: L=\{layout.border.left}, R=\{layout.border.right}")
  for i, child in layout.children {
    println("Child[\{i}]: x=\{child.x}, w=\{child.width}")
    // width=12, border=2, padding=4, content area = 6
    // Content "X" is 1 char, x should be centered in content area
    // Expected: (6-1)/2 = 2.5 from content start
  }
}

///|
test "workaround: use spacers for centering" {
  // Use flex-grow spacers instead of padding + justify
  let spacer = @core.box([], flex_grow=1.0)
  let comp = row(
    [spacer, @core.text("X"), spacer],
    width=@types.Dimension::Length(10.0),
    border=Some(@core.BorderChars::rounded()),
  )
  let layout = @render.compute_layout(comp.node, 20, 3)
  println("Spacer Row: w=\{layout.width}, h=\{layout.height}")
  for i, child in layout.children {
    println("Child[\{i}]: x=\{child.x}, w=\{child.width}")
    // With flex-grow spacers, text should be centered
  }
}

///|
test "vertical centering with fixed height" {
  // Check align=Center for vertical centering
  let comp = row(
    [@core.text("X")],
    width=@types.Dimension::Length(10.0),
    height=@types.Dimension::Length(5.0),
    border=Some(@core.BorderChars::rounded()),
    justify=@types.Alignment::Center,
    align=@types.Alignment::Center,
  )
  let layout = @render.compute_layout(comp.node, 20, 10)
  println("Tall Row: w=\{layout.width}, h=\{layout.height}")
  for i, child in layout.children {
    println(
      "Child[\{i}]: x=\{child.x}, y=\{child.y}, w=\{child.width}, h=\{child.height}",
    )
    // height=5, border=2, content area=3
    // text height=1, should be centered: y = 1 + (3-1)/2 = 2
  }
}

///|
test "2D centering with spacers" {
  // Use nested spacers for 2D centering
  let hspacer = @core.box([], flex_grow=1.0)
  let vspacer = @core.box(
    [],
    flex_grow=1.0,
    width=@types.Dimension::Percent(100.0),
  )
  let comp = column(
    [vspacer, row([hspacer, @core.text("X"), hspacer]), vspacer],
    width=@types.Dimension::Length(10.0),
    height=@types.Dimension::Length(5.0),
    border=Some(@core.BorderChars::rounded()),
  )
  let layout = @render.compute_layout(comp.node, 20, 10)
  println("2D Centered: w=\{layout.width}, h=\{layout.height}")
  // Find text position recursively
  fn find_text(l : @types.Layout, depth : Int) -> Unit {
    if l.text != None {
      println("  Text at x=\{l.x}, y=\{l.y}, w=\{l.width}, h=\{l.height}")
    }
    for child in l.children {
      find_text(child, depth + 1)
    }
  }

  find_text(layout, 0)
}

///|
test "min_width vs width with justify center" {
  // Compare min_width and width behavior
  let comp1 = row(
    [@core.text("OK")],
    min_width=@types.Dimension::Length(10.0),
    border=Some(@core.BorderChars::rounded()),
    justify=@types.Alignment::Center,
  )
  let layout1 = @render.compute_layout(comp1.node, 20, 3)
  println("min_width Row: w=\{layout1.width}, h=\{layout1.height}")
  for i, child in layout1.children {
    println("  Child[\{i}]: x=\{child.x}, w=\{child.width}")
  }
  let comp2 = row(
    [@core.text("OK")],
    width=@types.Dimension::Length(10.0),
    border=Some(@core.BorderChars::rounded()),
    justify=@types.Alignment::Center,
  )
  let layout2 = @render.compute_layout(comp2.node, 20, 3)
  println("fixed width Row: w=\{layout2.width}, h=\{layout2.height}")
  for i, child in layout2.children {
    println("  Child[\{i}]: x=\{child.x}, w=\{child.width}")
  }
}

///|
test "button on_click handler is registered" {
  let clicked = Ref::new(false)
  let btn = button(
    "OK",
    id="my-btn",
    on_click=Some(fn() { clicked.val = true }),
  )

  // Check that click handler is registered
  match btn.click_handlers.get("my-btn") {
    Some(handler) => {
      // Invoke handler
      handler.invoke()
      inspect(clicked.val, content="true")
    }
    None => fail("Click handler not found")
  }
}

///|
test "button has role Button" {
  let btn = button("OK", id="my-btn")

  // Check that button has Role::Button
  match btn.roles.get("my-btn") {
    Some(role) => inspect(role, content="Button")
    None => fail("Role not found for button")
  }
}

///|
test "button texts map" {
  let btn = button("OK", min_width=10.0)

  // Check texts map content
  println("button texts count: \{btn.texts.0.length()}")
  for entry in btn.texts.0 {
    println("  text id=\{entry.0}, content=\{entry.1}")
  }

  // Check layout tree IDs
  let layout = @render.compute_layout(btn.node, 20, 5)
  fn print_layout_tree(l : @types.Layout, depth : Int) -> Unit {
    let has_text = btn.texts.get(l.id) != None
    let prefix = if depth == 0 {
      ""
    } else if depth == 1 {
      "  "
    } else if depth == 2 {
      "    "
    } else {
      "      "
    }
    println(
      "\{prefix}id=\{l.id}, w=\{l.width}, h=\{l.height}, hasText=\{has_text}",
    )
    for child in l.children {
      print_layout_tree(child, depth + 1)
    }
  }

  print_layout_tree(layout, 0)
}
