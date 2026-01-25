///|
/// Dashboard components for btop-like UI (vnode version)
///
/// Components:
/// - sparkline: Mini line graph using block characters
/// - gauge: Horizontal bar with label and value
/// - stat: Key-value statistic display
/// - meter: CPU/Memory meter

///|
/// Sparkline characters from lowest to highest
let sparkline_chars : Array[String] = [
  "\u{2581}", "\u{2582}", "\u{2583}", "\u{2584}",
  "\u{2585}", "\u{2586}", "\u{2587}", "\u{2588}",
]

///|
/// Build sparkline string from data values
pub fn build_sparkline(values : Array[Double], width~ : Int = 0) -> String {
  if values.is_empty() {
    return ""
  }
  let mut min_val = values[0]
  let mut max_val = values[0]
  for v in values {
    if v < min_val {
      min_val = v
    }
    if v > max_val {
      max_val = v
    }
  }
  let range = max_val - min_val
  let actual_width = if width > 0 { width } else { values.length() }
  let display_values : Array[Double] = []
  if values.length() >= actual_width {
    let start = values.length() - actual_width
    for i = start; i < values.length(); i = i + 1 {
      display_values.push(values[i])
    }
  } else {
    for i = 0; i < actual_width - values.length(); i = i + 1 {
      display_values.push(min_val)
    }
    for v in values {
      display_values.push(v)
    }
  }
  let result = StringBuilder::new()
  for v in display_values {
    let normalized = if range == 0.0 { 0.5 } else { (v - min_val) / range }
    let idx = (normalized * 7.0).to_int()
    let clamped_idx = if idx < 0 { 0 } else if idx > 7 { 7 } else { idx }
    result.write_string(sparkline_chars[clamped_idx])
  }
  result.to_string()
}

///|
/// Sparkline component
pub fn sparkline(
  values : Array[Double],
  width~ : Int = 0,
  fg~ : String = "cyan",
) -> TuiNode {
  let line = build_sparkline(values, width~)
  text(line, fg~)
}

///|
/// Gauge style for horizontal bars
pub(all) enum GaugeStyle {
  Bar
  Thin
  Blocks
}

///|
/// Build gauge bar string
pub fn build_gauge(ratio : Double, width : Int, style~ : GaugeStyle = Bar) -> String {
  let clamped = if ratio < 0.0 {
    0.0
  } else if ratio > 1.0 {
    1.0
  } else {
    ratio
  }
  let (fill, empty, left, right) = match style {
    Bar => ("\u{2588}", "\u{2591}", "[", "]")
    Thin => ("\u{2501}", "\u{2500}", "", "")
    Blocks => ("\u{2593}", "\u{2591}", "", "")
  }
  let bar_width = width - left.length() - right.length()
  if bar_width <= 0 {
    return ""
  }
  let filled = (bar_width.to_double() * clamped).to_int()
  let empty_count = bar_width - filled
  left + fill.repeat(filled) + empty.repeat(empty_count) + right
}

///|
/// Gauge component - horizontal bar with optional label
pub fn gauge(
  label : String,
  ratio : Double,
  bar_width~ : Int = 15,
  show_percent~ : Bool = true,
) -> TuiNode {
  let bar = build_gauge(ratio, bar_width)
  let percent_str = if show_percent {
    let pct = (ratio * 100.0).to_int()
    " " + pct.to_string() + "%"
  } else {
    ""
  }
  let bar_color = if ratio > 0.9 {
    "red"
  } else if ratio > 0.7 {
    "yellow"
  } else {
    "cyan"
  }
  if label.length() > 0 {
    row(
      [text(label + " "), text(bar, fg=bar_color), text(percent_str, fg="gray")],
      height=1.0,
    )
  } else {
    row([text(bar, fg=bar_color), text(percent_str, fg="gray")], height=1.0)
  }
}

///|
/// Stat component - key-value display
pub fn stat(label : String, value : String, label_width~ : Int = 0) -> TuiNode {
  let padded_label = if label_width > 0 && label.length() < label_width {
    label + " ".repeat(label_width - label.length())
  } else {
    label
  }
  row(
    [text(padded_label + ": ", fg="gray"), text(value, bold=true)],
    height=1.0,
  )
}

///|
/// Meter component - CPU/Memory meter with label and bar
pub fn meter(
  label : String,
  ratio : Double,
  width~ : Int = 30,
  label_width~ : Int = 3,
) -> TuiNode {
  let clamped = if ratio < 0.0 {
    0.0
  } else if ratio > 1.0 {
    1.0
  } else {
    ratio
  }
  let padded_label = if label.length() < label_width {
    label + " ".repeat(label_width - label.length())
  } else {
    truncate_string(label, label_width)
  }
  let bar_width = width - label_width - 1 - 5
  if bar_width <= 0 {
    return text(padded_label)
  }
  let filled = (bar_width.to_double() * clamped).to_int()
  let empty = bar_width - filled
  let bar_color = if ratio > 0.9 {
    "red"
  } else if ratio > 0.7 {
    "yellow"
  } else {
    "cyan"
  }
  let pct = (clamped * 100.0).to_int()
  let pct_str = if pct < 10 {
    "  " + pct.to_string() + "%"
  } else if pct < 100 {
    " " + pct.to_string() + "%"
  } else {
    pct.to_string() + "%"
  }
  row(
    [
      text(padded_label + " ", fg="gray"),
      text("\u{2588}".repeat(filled), fg=bar_color),
      text("\u{2591}".repeat(empty), fg="gray"),
      text(pct_str),
    ],
    height=1.0,
  )
}

///|
fn truncate_string(s : String, max_len : Int) -> String {
  if s.length() <= max_len {
    return s
  }
  let buf = StringBuilder::new()
  let mut count = 0
  for c in s {
    if count >= max_len {
      break
    }
    buf.write_char(c)
    count = count + 1
  }
  buf.to_string()
}

///|
/// Table column alignment
pub(all) enum ColumnAlign {
  Left
  Right
  Center
}

///|
/// Table column definition
pub(all) struct TableColumn {
  header : String
  width : Int
  align : ColumnAlign
}

///|
/// Create a table column
pub fn TableColumn::new(
  header : String,
  width~ : Int = 0,
  align~ : ColumnAlign = Left,
) -> TableColumn {
  let actual_width = if width > 0 { width } else { header.length() }
  { header, width: actual_width, align }
}

///|
fn align_text_column(s : String, width : Int, align : ColumnAlign) -> String {
  let len = s.length()
  if len >= width {
    return truncate_string(s, width)
  }
  let padding = width - len
  match align {
    Left => s + " ".repeat(padding)
    Right => " ".repeat(padding) + s
    Center => {
      let left = padding / 2
      let right = padding - left
      " ".repeat(left) + s + " ".repeat(right)
    }
  }
}

///|
/// Table header row
pub fn table_header(
  columns : Array[TableColumn],
  separator~ : String = " ",
) -> TuiNode {
  let parts : Array[TuiNode] = []
  for i, col in columns {
    let aligned = align_text_column(col.header, col.width, col.align)
    parts.push(text(aligned, bold=true))
    if i < columns.length() - 1 {
      parts.push(text(separator))
    }
  }
  row(parts, height=1.0)
}

///|
/// Table data row
pub fn table_row(
  columns : Array[TableColumn],
  values : Array[String],
  separator~ : String = " ",
  selected~ : Bool = false,
) -> TuiNode {
  let parts : Array[TuiNode] = []
  let fg = if selected { "black" } else { "white" }
  for i, col in columns {
    let value = if i < values.length() { values[i] } else { "" }
    let aligned = align_text_column(value, col.width, col.align)
    parts.push(text(aligned, fg~))
    if i < columns.length() - 1 {
      parts.push(text(separator, fg~))
    }
  }
  let bg = if selected { "cyan" } else { "" }
  row(parts, height=1.0, bg~)
}

///|
/// Simple table component (header + rows)
pub fn table(
  columns : Array[TableColumn],
  rows : Array[Array[String]],
  separator~ : String = " ",
  selected_row~ : Int = -1,
) -> TuiNode {
  let children : Array[TuiNode] = []
  children.push(table_header(columns, separator~))
  for i, row_data in rows {
    let is_selected = i == selected_row
    children.push(table_row(columns, row_data, separator~, selected=is_selected))
  }
  column(children)
}
