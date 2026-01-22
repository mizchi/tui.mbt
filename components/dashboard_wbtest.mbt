///|
test "build_table_header" {
  let cols = [
    TableColumn::new("Pid", width=6, align=ColumnAlign::Right),
    TableColumn::new("Name", width=10),
  ]
  let header = build_table_header(cols)
  inspect(header, content="   Pid Name      ")
}

///|
test "build_table_row" {
  let cols = [
    TableColumn::new("Pid", width=6, align=ColumnAlign::Right),
    TableColumn::new("Name", width=10),
  ]
  let row_str = build_table_row(cols, ["1234", "process1"])
  inspect(row_str, content="  1234 process1  ")
}

///|
test "build_sparkline" {
  let s = build_sparkline([1.0, 2.0, 3.0, 4.0])
  inspect(s, content="▁▃▅█")
}

///|
test "build_gauge" {
  let g = build_gauge(0.5, 15)
  inspect(g, content="[██████░░░░░░░]")
}

///|
test "table_component_children" {
  let cols = [
    TableColumn::new("Pid", width=6, align=ColumnAlign::Right),
    TableColumn::new("Name", width=10),
  ]
  let data : Array[Array[String]] = [["1234", "proc1"], ["5678", "proc2"]]
  let component = table(cols, data)
  // Check that the component has the expected structure
  inspect(component.node.children.length(), content="3")
}

///|
test "table_texts_count" {
  let cols = [
    TableColumn::new("Pid", width=6, align=ColumnAlign::Right),
    TableColumn::new("Name", width=10),
  ]
  let data : Array[Array[String]] = [["1234", "proc1"], ["5678", "proc2"]]
  let component = table(cols, data)
  // Each row has 2 columns + 1 separator = 3 texts per row
  // Header + 2 data rows = 3 rows x 3 texts = 9 texts
  inspect(component.texts.0.length(), content="9")
}

///|
test "table_texts_content" {
  let cols = [
    TableColumn::new("Pid", width=6, align=ColumnAlign::Right),
    TableColumn::new("Name", width=10),
  ]
  let data : Array[Array[String]] = [["1234", "proc1"], ["5678", "proc2"]]
  let component = table(cols, data)
  // Get all text values
  let texts : Array[String] = []
  for entry in component.texts.0 {
    texts.push(entry.1)
  }
  // Each row is split into: column1 + separator + column2
  inspect(
    texts,
    content=(
      #|["   Pid", " ", "Name      ", "  1234", " ", "proc1     ", "  5678", " ", "proc2     "]
    ),
  )
}

///|
test "table_render_check" {
  let cols = [
    TableColumn::new("Pid", width=6, align=ColumnAlign::Right),
    TableColumn::new("Name", width=10),
  ]
  let data : Array[Array[String]] = [["1234", "proc1"], ["5678", "proc2"]]
  let component = table(cols, data)
  // Use the render App to check output
  let app = @render.App::new(25, 6)
  let frame = app.render_frame(component)
  // Check frame is not empty
  inspect(frame.length() > 0, content="true")
}
