///|
/// Dashboard components for btop-like UI
///
/// Components:
/// - titled_box: Box with title embedded in border (like btop's panels)
/// - sparkline: Mini line graph using block characters
/// - gauge: Horizontal bar with label and value
/// - stat: Key-value statistic display
/// - table: Aligned table with headers
/// - meter: CPU/Memory meter

///|
/// Sparkline characters from lowest to highest
let sparkline_chars : Array[String] = [
  "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█",
]

///|
/// Build sparkline string from data values
/// values: Array of values (will be normalized to 0.0-1.0 range)
/// width: Number of characters to display (truncates or pads data)
pub fn build_sparkline(values : Array[Double], width? : Int = 0) -> String {
  if values.is_empty() {
    return ""
  }

  // Find min/max for normalization
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

  // Take last 'width' values or pad with first value
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

  // Build sparkline string
  let result : Array[String] = []
  for v in display_values {
    let normalized = if range == 0.0 { 0.5 } else { (v - min_val) / range }
    let idx = (normalized * 7.0).to_int()
    let clamped_idx = if idx < 0 { 0 } else if idx > 7 { 7 } else { idx }
    result.push(sparkline_chars[clamped_idx])
  }
  result.iter().fold(init="", fn(acc, s) { acc + s })
}

///|
/// Sparkline component
pub fn sparkline(
  values : Array[Double],
  width? : Int = 0,
  fg? : @core.Color = @core.Color::cyan(),
  theme? : @components.Theme = @components.Theme::default(),
) -> @core.Component {
  let actual_fg = if fg == @core.Color::cyan() { theme.primary } else { fg }
  let line = build_sparkline(values, width~)
  @components.text(line, fg=actual_fg)
}

///|
/// Gauge style for horizontal bars
pub(all) enum GaugeStyle {
  Bar // [████████░░░░]
  Thin // ━━━━━━━━────
  Blocks // ▓▓▓▓▓▓▓▓░░░░
}

///|
/// Build gauge bar string
pub fn build_gauge(
  ratio : Double,
  width : Int,
  style? : GaugeStyle = GaugeStyle::Bar,
) -> String {
  let clamped = if ratio < 0.0 {
    0.0
  } else if ratio > 1.0 {
    1.0
  } else {
    ratio
  }
  let (fill, empty, left, right) = match style {
    GaugeStyle::Bar => ("█", "░", "[", "]")
    GaugeStyle::Thin => ("━", "─", "", "")
    GaugeStyle::Blocks => ("▓", "░", "", "")
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
  bar_width? : Int = 15,
  show_percent? : Bool = true,
  style? : GaugeStyle = GaugeStyle::Bar,
  theme? : @components.Theme = @components.Theme::default(),
) -> @core.Component {
  let bar = build_gauge(ratio, bar_width, style~)
  let percent_str = if show_percent {
    let pct = (ratio * 100.0).to_int()
    " " + pct.to_string() + "%"
  } else {
    ""
  }
  let bar_color = if ratio > 0.9 {
    theme.error
  } else if ratio > 0.7 {
    @core.Color::yellow()
  } else {
    theme.primary
  }
  if label.length() > 0 {
    @components.row(
      [
        @components.text(label + " ", fg=theme.fg),
        @components.text(bar, fg=bar_color),
        @components.text(percent_str, fg=theme.muted),
      ],
      height=@types.Dimension::Length(1.0),
    )
  } else {
    @components.row(
      [
        @components.text(bar, fg=bar_color),
        @components.text(percent_str, fg=theme.muted),
      ],
      height=@types.Dimension::Length(1.0),
    )
  }
}

///|
/// Stat component - key-value display (like "Total: 32.0 GiB")
pub fn stat(
  label : String,
  value : String,
  label_width? : Int = 0,
  theme? : @components.Theme = @components.Theme::default(),
) -> @core.Component {
  let padded_label = if label_width > 0 && label.length() < label_width {
    label + " ".repeat(label_width - label.length())
  } else {
    label
  }
  @components.row(
    [
      @components.text(padded_label + ": ", fg=theme.muted),
      @components.text(value, fg=theme.fg, bold=true),
    ],
    height=@types.Dimension::Length(1.0),
  )
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
  width? : Int = 0,
  align? : ColumnAlign = ColumnAlign::Left,
) -> TableColumn {
  let actual_width = if width > 0 { width } else { header.length() }
  { header, width: actual_width, align }
}

///|
/// Convert ColumnAlign to TextAlign
fn column_align_to_text_align(align : ColumnAlign) -> @components.TextAlign {
  match align {
    ColumnAlign::Left => @components.TextAlign::Left
    ColumnAlign::Right => @components.TextAlign::Right
    ColumnAlign::Center => @components.TextAlign::Center
  }
}

///|
/// Align text within given width using ColumnAlign
fn align_column_text(s : String, width : Int, align : ColumnAlign) -> String {
  @components.align_text(s, width, align=column_align_to_text_align(align))
}

///|
/// Build table header string
pub fn build_table_header(
  columns : Array[TableColumn],
  separator? : String = " ",
) -> String {
  let parts : Array[String] = []
  for col in columns {
    parts.push(align_column_text(col.header, col.width, col.align))
  }
  parts
  .iter()
  .fold(init="", fn(acc, s) { if acc == "" { s } else { acc + separator + s } })
}

///|
/// Build table row string
pub fn build_table_row(
  columns : Array[TableColumn],
  values : Array[String],
  separator? : String = " ",
) -> String {
  let parts : Array[String] = []
  for i = 0; i < columns.length(); i = i + 1 {
    let value = if i < values.length() { values[i] } else { "" }
    parts.push(align_column_text(value, columns[i].width, columns[i].align))
  }
  parts
  .iter()
  .fold(init="", fn(acc, s) { if acc == "" { s } else { acc + separator + s } })
}

///|
/// Table header component
pub fn table_header(
  columns : Array[TableColumn],
  separator? : String = " ",
  theme? : @components.Theme = @components.Theme::default(),
) -> @core.Component {
  let parts : Array[@core.Component] = []
  for i = 0; i < columns.length(); i = i + 1 {
    let col = columns[i]
    let aligned = align_column_text(col.header, col.width, col.align)
    parts.push(@components.text(aligned, fg=theme.fg, bold=true))
    if i < columns.length() - 1 {
      parts.push(@components.text(separator, fg=theme.fg))
    }
  }
  @components.row(parts, height=@types.Dimension::Length(1.0))
}

///|
/// Table row component
pub fn table_row(
  columns : Array[TableColumn],
  values : Array[String],
  separator? : String = " ",
  selected? : Bool = false,
  theme? : @components.Theme = @components.Theme::default(),
) -> @core.Component {
  let parts : Array[@core.Component] = []
  let fg_color = if selected { theme.bg } else { theme.fg }
  let bg_color = if selected {
    theme.primary
  } else {
    @core.Color::transparent()
  }
  for i = 0; i < columns.length(); i = i + 1 {
    let col = columns[i]
    let value = if i < values.length() { values[i] } else { "" }
    let aligned = align_column_text(value, col.width, col.align)
    parts.push(@components.text(aligned, fg=fg_color, bg=bg_color))
    if i < columns.length() - 1 {
      parts.push(@components.text(separator, fg=fg_color, bg=bg_color))
    }
  }
  @components.row(parts, height=@types.Dimension::Length(1.0))
}

///|
/// Simple table component (header + rows)
pub fn table(
  columns : Array[TableColumn],
  rows : Array[Array[String]],
  separator? : String = " ",
  selected_row? : Int = -1,
  theme? : @components.Theme = @components.Theme::default(),
) -> @core.Component {
  let children : Array[@core.Component] = []
  children.push(table_header(columns, separator~, theme~))
  for i = 0; i < rows.length(); i = i + 1 {
    let is_selected = i == selected_row
    children.push(
      table_row(columns, rows[i], separator~, selected=is_selected, theme~),
    )
  }
  @components.column(children, align=@types.Alignment::FlexStart)
}

///|
/// Build titled border string (top line with embedded title)
pub fn build_titled_border_top(
  title : String,
  width : Int,
  border? : @core.BorderChars = @core.BorderChars::single(),
) -> String {
  if width < title.length() + 4 {
    return border.top_left.to_string() +
      border.horizontal.to_string().repeat(width - 2) +
      border.top_right.to_string()
  }
  let title_with_delim = border.horizontal.to_string() +
    title +
    border.horizontal.to_string()
  let remaining = width - 2 - title_with_delim.length()
  let left_fill = remaining / 2
  let right_fill = remaining - left_fill
  border.top_left.to_string() +
  border.horizontal.to_string().repeat(left_fill) +
  title_with_delim +
  border.horizontal.to_string().repeat(right_fill) +
  border.top_right.to_string()
}

///|
/// Titled box - renders a box with title at the top
pub fn titled_box(
  title : String,
  children : Array[@core.Component],
  width? : Int = 30,
  border? : @core.BorderChars = @core.BorderChars::single(),
  border_color? : @core.Color = @core.Color::white(),
  title_color? : @core.Color = @core.Color::cyan(),
  theme? : @components.Theme = @components.Theme::default(),
) -> @core.Component {
  let actual_border_color = if border_color == @core.Color::white() {
    theme.border
  } else {
    border_color
  }
  let actual_title_color = if title_color == @core.Color::cyan() {
    theme.primary
  } else {
    title_color
  }
  let all_children : Array[@core.Component] = []
  all_children.push(@components.text(title, fg=actual_title_color, bold=true))
  for child in children {
    all_children.push(child)
  }
  @components.column(
    all_children,
    width=@types.Dimension::Length(width.to_double()),
    border=Some(border),
    border_color=actual_border_color,
    align=@types.Alignment::FlexStart,
  )
}

///|
/// Meter component - CPU/Memory meter with label and bar
pub fn meter(
  label : String,
  ratio : Double,
  width? : Int = 30,
  label_width? : Int = 3,
  theme? : @components.Theme = @components.Theme::default(),
) -> @core.Component {
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
    @components.truncate_text(label, label_width)
  }
  let bar_width = width - label_width - 1 - 5
  if bar_width <= 0 {
    return @components.text(padded_label, fg=theme.fg)
  }
  let filled = (bar_width.to_double() * clamped).to_int()
  let empty = bar_width - filled
  let bar_color = if ratio > 0.9 {
    theme.error
  } else if ratio > 0.7 {
    @core.Color::yellow()
  } else {
    theme.primary
  }
  let pct = (clamped * 100.0).to_int()
  let pct_str = if pct < 10 {
    "  " + pct.to_string() + "%"
  } else if pct < 100 {
    " " + pct.to_string() + "%"
  } else {
    pct.to_string() + "%"
  }
  @components.row(
    [
      @components.text(padded_label + " ", fg=theme.muted),
      @components.text("█".repeat(filled), fg=bar_color),
      @components.text("░".repeat(empty), fg=theme.muted),
      @components.text(pct_str, fg=theme.fg),
    ],
    height=@types.Dimension::Length(1.0),
  )
}
